<?php
declare(strict_types=1);

header("Content-Type: application/json; charset=utf-8");
header("Cache-Control: no-store");
header("X-Content-Type-Options: nosniff");

$allowedOrigin = getenv("MYSTUFF_ALLOWED_ORIGIN") ?: "";
$requestOrigin = (string) ($_SERVER["HTTP_ORIGIN"] ?? "");
if ($allowedOrigin !== "" && hash_equals($allowedOrigin, $requestOrigin)) {
    header("Access-Control-Allow-Origin: " . $allowedOrigin);
    header("Vary: Origin");
}
header("Access-Control-Allow-Headers: Authorization, Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");

if (($_SERVER["REQUEST_METHOD"] ?? "") === "OPTIONS") {
    http_response_code(204);
    exit();
}

function respond(
    string $status,
    string $message = "",
    array $data = [],
    int $httpStatus = 200,
): never {
    http_response_code($httpStatus);
    echo json_encode(
        array_merge(["status" => $status, "message" => $message], $data),
        JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR,
    );
    exit();
}

function request_payload(): array
{
    static $payload = null;
    if ($payload !== null) {
        return $payload;
    }

    $payload = $_POST;
    $contentType = (string) ($_SERVER["CONTENT_TYPE"] ?? "");
    if (str_contains(strtolower($contentType), "application/json")) {
        $decoded = json_decode((string) file_get_contents("php://input"), true);
        if (is_array($decoded)) {
            $payload = array_merge($payload, $decoded);
        }
    }
    return $payload;
}

function input(string $key, mixed $default = null): mixed
{
    $payload = request_payload();
    return $payload[$key] ?? $default;
}

function request_name(): string
{
    return str_replace("RequestType.", "", trim((string) input("request", "")));
}

function database(): PDO
{
    static $connection = null;
    if ($connection instanceof PDO) {
        return $connection;
    }

    $configFile = __DIR__ . "/db.php";
    if (!is_file($configFile)) {
        throw new RuntimeException("Server database configuration is missing");
    }
    $config = require $configFile;
    if (!is_array($config)) {
        throw new RuntimeException("Server database configuration is invalid");
    }

    $host = (string) ($config["host"] ?? "localhost");
    $port = (int) ($config["port"] ?? 3306);
    $name = (string) ($config["database"] ?? "rusmark_mystuff");
    $username = (string) ($config["username"] ?? "");
    $password = (string) ($config["password"] ?? "");
    $dsn = "mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4";

    $connection = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
    return $connection;
}

function clean_text(
    mixed $value,
    int $maximumLength,
    bool $required = true,
): string {
    $text = trim((string) $value);
    if ($required && $text === "") {
        throw new InvalidArgumentException("A required value is missing");
    }
    $length = function_exists("mb_strlen") ? mb_strlen($text) : strlen($text);
    if ($length > $maximumLength) {
        throw new InvalidArgumentException("A value is too long");
    }
    return $text;
}

function nullable_int(mixed $value): ?int
{
    if ($value === null || $value === "" || $value === "null") {
        return null;
    }
    $number = filter_var($value, FILTER_VALIDATE_INT);
    if ($number === false || $number < 1) {
        throw new InvalidArgumentException("An invalid ID was supplied");
    }
    return (int) $number;
}

function boolean_input(string $key, bool $default = false): bool
{
    $value = input($key, $default);
    if (is_bool($value)) {
        return $value;
    }
    return filter_var($value, FILTER_VALIDATE_BOOLEAN);
}

function public_user(array $row, ?string $sessionToken = null): array
{
    $user = [
        "id" => (int) $row["id"],
        "userid" => (string) $row["userid"],
        "name" => (string) $row["name"],
        "email" => $row["email"] ?? "NO-EMAIL",
        "role" => (string) $row["role"],
        "isActive" => (bool) $row["is_active"],
        "joinDate" => substr((string) $row["created_at"], 0, 10),
    ];
    if ($sessionToken !== null) {
        $user["sessionToken"] = $sessionToken;
    }
    return $user;
}

function bearer_token(): string
{
    $authorization = (string) ($_SERVER["HTTP_AUTHORIZATION"] ?? "");
    if (preg_match('/^Bearer\s+(.+)$/i', $authorization, $match) === 1) {
        return trim($match[1]);
    }
    return trim((string) input("token", ""));
}

function require_auth(PDO $db): array
{
    $token = bearer_token();
    if ($token === "" || strlen($token) < 32) {
        respond("unauthorized", "Please log in again", [], 401);
    }

    $statement = $db->prepare(
        "SELECT u.*, s.id AS session_id " .
            "FROM user_sessions s " .
            "JOIN users u ON u.id = s.user_id " .
            "WHERE s.token_hash = ? AND s.revoked_at IS NULL " .
            "AND s.expires_at > NOW() AND u.is_active = 1 LIMIT 1",
    );
    $statement->execute([hash("sha256", $token)]);
    $user = $statement->fetch();
    if (!$user) {
        respond("unauthorized", "Your session has expired", [], 401);
    }

    $touch = $db->prepare(
        "UPDATE user_sessions SET last_used_at = NOW() WHERE id = ?",
    );
    $touch->execute([(int) $user["session_id"]]);
    return $user;
}

function require_admin(array $user): void
{
    if (($user["role"] ?? "") !== "admin") {
        respond("forbidden", "Administrator access is required", [], 403);
    }
}

function all_bins(PDO $db): array
{
    return $db
        ->query("SELECT * FROM bins ORDER BY parent_id, name, id")
        ->fetchAll();
}

function permission_rank(string $permission): int
{
    return $permission === "edit" ? 2 : ($permission === "view" ? 1 : 0);
}

/**
 * Return effective inherited bin permissions as [bin id => view|edit].
 */
function effective_bin_permissions(
    PDO $db,
    array $user,
    ?array $bins = null,
): array {
    $bins ??= all_bins($db);
    if (($user["role"] ?? "") === "admin") {
        $result = [];
        foreach ($bins as $bin) {
            $result[(int) $bin["id"]] = "edit";
        }
        return $result;
    }

    $children = [];
    foreach ($bins as $bin) {
        $parentKey = $bin["parent_id"] === null ? 0 : (int) $bin["parent_id"];
        $children[$parentKey][] = (int) $bin["id"];
    }

    $statement = $db->prepare(
        "SELECT bin_id, permission FROM bin_permissions WHERE user_id = ?",
    );
    $statement->execute([(int) $user["id"]]);
    $explicit = $statement->fetchAll();
    $effective = [];

    foreach ($explicit as $grant) {
        $permission = (string) $grant["permission"];
        $stack = [(int) $grant["bin_id"]];
        while ($stack !== []) {
            $binId = array_pop($stack);
            $current = $effective[$binId] ?? "";
            if (permission_rank($permission) > permission_rank($current)) {
                $effective[$binId] = $permission;
            }
            foreach ($children[$binId] ?? [] as $childId) {
                $stack[] = $childId;
            }
        }
    }
    return $effective;
}

function require_bin_permission(
    PDO $db,
    array $user,
    int $binId,
    string $required = "view",
): string {
    $permissions = effective_bin_permissions($db, $user);
    $actual = $permissions[$binId] ?? "";
    if (permission_rank($actual) < permission_rank($required)) {
        respond(
            "forbidden",
            "You do not have {$required} access to this bin",
            [],
            403,
        );
    }
    return $actual;
}

function descendant_ids(
    array $bins,
    int $rootId,
    bool $includeRoot = true,
): array {
    $children = [];
    foreach ($bins as $bin) {
        if ($bin["parent_id"] !== null) {
            $children[(int) $bin["parent_id"]][] = (int) $bin["id"];
        }
    }
    $result = $includeRoot ? [$rootId] : [];
    $stack = $children[$rootId] ?? [];
    while ($stack !== []) {
        $id = array_pop($stack);
        $result[] = $id;
        foreach ($children[$id] ?? [] as $childId) {
            $stack[] = $childId;
        }
    }
    return array_values(array_unique($result));
}

function placeholders(int $count): string
{
    return implode(",", array_fill(0, $count, "?"));
}

function uploaded_image_mime(string $path): string
{
    // getimagesize validates the image structure and is part of PHP's standard
    // image support, so it remains available on hosts that disable Fileinfo.
    $details = function_exists("getimagesize") ? @getimagesize($path) : false;
    if (!is_array($details) || !isset($details["mime"])) {
        throw new InvalidArgumentException("The uploaded file is not an image");
    }
    $imageMime = strtolower((string) $details["mime"]);

    // Fileinfo provides a useful second opinion when the extension is enabled,
    // but it is optional because some shared hosts do not provide the class.
    if (class_exists("finfo") && defined("FILEINFO_MIME_TYPE")) {
        $fileInfo = new finfo(FILEINFO_MIME_TYPE);
        $detected = $fileInfo->file($path);
        if (
            is_string($detected) &&
            $detected !== "" &&
            $detected !== "application/octet-stream" &&
            !hash_equals($imageMime, strtolower($detected))
        ) {
            throw new InvalidArgumentException(
                "The picture contents do not match its image type",
            );
        }
    }
    return $imageMime;
}

function uploaded_image(
    string $field,
    string $folder,
    bool $required = false,
): ?string {
    if (
        !isset($_FILES[$field]) ||
        $_FILES[$field]["error"] === UPLOAD_ERR_NO_FILE
    ) {
        if ($required) {
            throw new InvalidArgumentException("A picture is required");
        }
        return null;
    }
    if ($_FILES[$field]["error"] !== UPLOAD_ERR_OK) {
        throw new RuntimeException("The picture upload failed");
    }
    if ((int) $_FILES[$field]["size"] > 8 * 1024 * 1024) {
        throw new InvalidArgumentException("The picture is too large");
    }
    $temporaryPath = (string) $_FILES[$field]["tmp_name"];
    if (!is_uploaded_file($temporaryPath)) {
        throw new InvalidArgumentException("The picture upload is invalid");
    }

    $mime = uploaded_image_mime($temporaryPath);
    $extensions = [
        "image/jpeg" => "jpg",
        "image/png" => "png",
        "image/webp" => "webp",
    ];
    if (!isset($extensions[$mime])) {
        throw new InvalidArgumentException(
            "Only JPG, PNG, and WebP pictures are supported",
        );
    }

    $safeFolder = preg_replace("/[^a-z0-9_-]/i", "", $folder);
    $directory = __DIR__ . "/images/" . $safeFolder;
    if (
        !is_dir($directory) &&
        !mkdir($directory, 0750, true) &&
        !is_dir($directory)
    ) {
        throw new RuntimeException("The picture directory is unavailable");
    }
    $apacheGuard = $directory . "/.htaccess";
    if (!is_file($apacheGuard)) {
        @file_put_contents(
            $apacheGuard,
            "Options -Indexes\n<FilesMatch \"\\.(php|phtml|phar)$\">\nRequire all denied\n</FilesMatch>\n",
        );
    }
    $filename = bin2hex(random_bytes(16)) . "." . $extensions[$mime];
    if (
        !move_uploaded_file(
            $temporaryPath,
            $directory . "/" . $filename,
        )
    ) {
        throw new RuntimeException("The picture could not be saved");
    }
    return "images/" . $safeFolder . "/" . $filename;
}

function remove_image(?string $relativePath): void
{
    if ($relativePath === null || $relativePath === "") {
        return;
    }
    $imageRoot = realpath(__DIR__ . "/images");
    $candidate = realpath(__DIR__ . "/" . ltrim($relativePath, "/"));
    if (
        $imageRoot !== false &&
        $candidate !== false &&
        str_starts_with($candidate, $imageRoot . DIRECTORY_SEPARATOR) &&
        is_file($candidate)
    ) {
        unlink($candidate);
    }
}

function handle_api_error(Throwable $error): never
{
    if ($error instanceof InvalidArgumentException) {
        respond("invalid", $error->getMessage(), [], 422);
    }
    error_log("MyStuff API error: " . $error->getMessage());
    respond("error", "The server could not complete the request", [], 500);
}

if (($_SERVER["REQUEST_METHOD"] ?? "") !== "POST") {
    respond("invalid", "POST requests only", [], 405);
}
