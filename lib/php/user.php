<?php
declare(strict_types=1);

require_once __DIR__ . "/common.php";

function validate_password(string $password): void
{
    if (
        strlen($password) < 10 ||
        strlen($password) > 200 ||
        preg_match('/[A-Z]/', $password) !== 1 ||
        preg_match('/[0-9]/', $password) !== 1 ||
        preg_match('/[^a-zA-Z0-9]/', $password) !== 1
    ) {
        throw new InvalidArgumentException(
            "Passwords need 10 characters, an uppercase letter, a number, and a symbol",
        );
    }
}

function userid_for_email(PDO $db, string $email): string
{
    $localPart = explode("@", $email, 2)[0];
    $base = strtolower(
        preg_replace('/[^a-z0-9._-]/i', "", $localPart) ?? "user",
    );
    $base = substr($base === "" ? "user" : $base, 0, 48);
    if (strlen($base) < 3) {
        $base .= "user";
    }
    $candidate = $base;
    $suffix = 1;
    $statement = $db->prepare("SELECT COUNT(*) FROM users WHERE userid = ?");
    while (true) {
        $statement->execute([$candidate]);
        if ((int) $statement->fetchColumn() === 0) {
            return $candidate;
        }
        $candidate = substr($base, 0, 52) . "-" . $suffix;
        $suffix++;
    }
}

try {
    $db = database();
    $request = request_name();

    if ($request === "health") {
        respond("success", "API and database connection are healthy");
    }

    if ($request === "login") {
        $email = strtolower(clean_text(input("email"), 190));
        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            throw new InvalidArgumentException("Enter a valid email address");
        }
        $password = (string) input("password", "");
        if ($password === "") {
            throw new InvalidArgumentException("Password is required");
        }

        $statement = $db->prepare(
            "SELECT * FROM users WHERE email = ? AND is_active = 1 LIMIT 1",
        );
        $statement->execute([$email]);
        $user = $statement->fetch();
        if (
            !$user ||
            !password_verify($password, (string) $user["password_hash"])
        ) {
            respond(
                "unauthorized",
                "Incorrect email or password",
                [],
                401,
            );
        }

        if (
            password_needs_rehash(
                (string) $user["password_hash"],
                PASSWORD_DEFAULT,
            )
        ) {
            $rehash = $db->prepare(
                "UPDATE users SET password_hash = ? WHERE id = ?",
            );
            $rehash->execute([
                password_hash($password, PASSWORD_DEFAULT),
                (int) $user["id"],
            ]);
        }

        $token = bin2hex(random_bytes(32));
        $db->prepare(
            "DELETE FROM user_sessions WHERE expires_at <= NOW() OR revoked_at IS NOT NULL",
        )->execute();
        $session = $db->prepare(
            "INSERT INTO user_sessions (user_id, token_hash, expires_at) " .
                "VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))",
        );
        $session->execute([(int) $user["id"], hash("sha256", $token)]);

        respond("success", "Login successful", [
            "user" => public_user($user, $token),
        ]);
    }

    if ($request === "postUser") {
        $count = (int) $db->query("SELECT COUNT(*) FROM users")->fetchColumn();
        $actor = null;
        if ($count > 0) {
            $actor = require_auth($db);
            require_admin($actor);
        }

        $name = clean_text(input("name"), 120);
        $email = strtolower(clean_text(input("email"), 190));
        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            throw new InvalidArgumentException("The email address is invalid");
        }
        $userid = userid_for_email($db, $email);
        $password = (string) input("password", "");
        validate_password($password);

        $role = $count === 0 ? "admin" : (string) input("role", "observer");
        if (!in_array($role, ["admin", "observer"], true)) {
            throw new InvalidArgumentException(
                "The selected user role is invalid",
            );
        }

        $statement = $db->prepare(
            "INSERT INTO users (userid, name, email, password_hash, role) " .
                "VALUES (?, ?, ?, ?, ?)",
        );
        try {
            $statement->execute([
                $userid,
                $name,
                $email,
                password_hash($password, PASSWORD_DEFAULT),
                $role,
            ]);
        } catch (PDOException $error) {
            if ((string) $error->getCode() === "23000") {
                respond(
                    "conflict",
                    "That email address is already in use",
                    [],
                    409,
                );
            }
            throw $error;
        }

        $newId = (int) $db->lastInsertId();
        $newUser = $db->prepare("SELECT * FROM users WHERE id = ?");
        $newUser->execute([$newId]);
        $created = $newUser->fetch();

        // The very first account is also logged in. Accounts created by an
        // existing admin are returned without a session.
        if ($count === 0) {
            $token = bin2hex(random_bytes(32));
            $session = $db->prepare(
                "INSERT INTO user_sessions (user_id, token_hash, expires_at) " .
                    "VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))",
            );
            $session->execute([$newId, hash("sha256", $token)]);
            respond(
                "success",
                "Administrator account created",
                [
                    "user" => public_user($created, $token),
                ],
                201,
            );
        }

        respond(
            "success",
            "Team member created",
            [
                "user" => public_user($created),
            ],
            201,
        );
    }

    if ($request === "session") {
        $user = require_auth($db);
        respond("success", "Session valid", ["user" => public_user($user)]);
    }

    if ($request === "logout") {
        require_auth($db);
        $statement = $db->prepare(
            "UPDATE user_sessions SET revoked_at = NOW() WHERE token_hash = ?",
        );
        $statement->execute([hash("sha256", bearer_token())]);
        respond("success", "Logged out");
    }

    if ($request === "listUsers") {
        $actor = require_auth($db);
        require_admin($actor);
        $rows = $db
            ->query(
                "SELECT * FROM users ORDER BY is_active DESC, role, name, id",
            )
            ->fetchAll();
        respond("success", "Team members loaded", [
            "users" => array_map("public_user", $rows),
        ]);
    }

    if ($request === "emailCheck") {
        $actor = require_auth($db);
        $email = strtolower(clean_text(input("email"), 190));
        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            throw new InvalidArgumentException("The email address is invalid");
        }
        $statement = $db->prepare(
            "SELECT COUNT(*) FROM users WHERE email = ? AND id <> ?",
        );
        $statement->execute([$email, (int) $actor["id"]]);
        respond("success", "Email checked", [
            "emailExists" => (int) $statement->fetchColumn() > 0,
        ]);
    }

    if ($request === "putUser") {
        $actor = require_auth($db);
        $targetId = nullable_int(input("userId")) ?? (int) $actor["id"];
        $isAdminEditingAnotherUser = (int) $actor["id"] !== $targetId;
        if ($isAdminEditingAnotherUser) {
            require_admin($actor);
        }

        $targetStatement = $db->prepare(
            "SELECT * FROM users WHERE id = ? LIMIT 1",
        );
        $targetStatement->execute([$targetId]);
        $target = $targetStatement->fetch();
        if (!$target) {
            respond("notFound", "Team member not found", [], 404);
        }

        $name = clean_text(input("name", $target["name"]), 120);
        $email = strtolower(
            clean_text(input("email", $target["email"] ?? ""), 190),
        );
        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            throw new InvalidArgumentException("The email address is invalid");
        }
        $emailChanged = strcasecmp(
            $email,
            (string) ($target["email"] ?? ""),
        ) !== 0;

        $role = (string) $target["role"];
        $isActive = (int) $target["is_active"];
        if (($actor["role"] ?? "") === "admin") {
            $requestedRole = (string) input("role", $role);
            if (!in_array($requestedRole, ["admin", "observer"], true)) {
                throw new InvalidArgumentException(
                    "The selected user role is invalid",
                );
            }
            $role = $requestedRole;
            $isActive = boolean_input("isActive", (bool) $isActive) ? 1 : 0;
        }

        if (
            (int) $target["id"] === (int) $actor["id"] &&
            ($role !== "admin" || $isActive !== 1) &&
            ($actor["role"] ?? "") === "admin"
        ) {
            throw new InvalidArgumentException(
                "Administrators cannot disable or demote themselves",
            );
        }

        $password = (string) input("newPassword", "");
        if ($password !== "") {
            validate_password($password);
        }
        if (
            !$isAdminEditingAnotherUser &&
            ($password !== "" || $emailChanged)
        ) {
            $currentPassword = (string) input("currentPassword", "");
            if (
                !password_verify(
                    $currentPassword,
                    (string) $actor["password_hash"],
                )
            ) {
                respond(
                    "unauthorized",
                    "The current password is incorrect",
                    [],
                    401,
                );
            }
        }

        $db->beginTransaction();
        try {
            $update = $db->prepare(
                "UPDATE users SET name = ?, email = ?, role = ?, is_active = ? " .
                    "WHERE id = ?",
            );
            $update->execute([$name, $email, $role, $isActive, $targetId]);
            if ($password !== "") {
                $passwordUpdate = $db->prepare(
                    "UPDATE users SET password_hash = ? WHERE id = ?",
                );
                $passwordUpdate->execute([
                    password_hash($password, PASSWORD_DEFAULT),
                    $targetId,
                ]);
            }
            if ($password !== "" || $emailChanged) {
                $db->prepare(
                    "UPDATE user_sessions SET revoked_at = NOW() WHERE user_id = ? AND id <> ?",
                )->execute([$targetId, (int) $actor["session_id"]]);
            }
            if ($isActive !== 1) {
                $db->prepare(
                    "UPDATE user_sessions SET revoked_at = NOW() WHERE user_id = ?",
                )->execute([$targetId]);
            }
            $db->commit();
        } catch (Throwable $error) {
            $db->rollBack();
            if (
                $error instanceof PDOException &&
                (string) $error->getCode() === "23000"
            ) {
                respond(
                    "conflict",
                    "That email address is already in use",
                    [],
                    409,
                );
            }
            throw $error;
        }

        $updatedStatement = $db->prepare("SELECT * FROM users WHERE id = ?");
        $updatedStatement->execute([$targetId]);
        respond("success", "Team member updated", [
            "user" => public_user($updatedStatement->fetch()),
        ]);
    }

    if ($request === "dropUser") {
        $actor = require_auth($db);
        $targetId = nullable_int(input("userId")) ?? (int) $actor["id"];
        $deletingSelf = $targetId === (int) $actor["id"];
        if (!$deletingSelf) {
            require_admin($actor);
        } else {
            $password = (string) input("password", "");
            if (!password_verify($password, (string) $actor["password_hash"])) {
                respond(
                    "unauthorized",
                    "The current password is incorrect",
                    [],
                    401,
                );
            }
        }

        $targetStatement = $db->prepare("SELECT * FROM users WHERE id = ?");
        $targetStatement->execute([$targetId]);
        $target = $targetStatement->fetch();
        if (!$target) {
            respond("notFound", "Team member not found", [], 404);
        }
        if (($target["role"] ?? "") === "admin") {
            $adminCount = (int) $db
                ->query(
                    "SELECT COUNT(*) FROM users WHERE role = 'admin' AND is_active = 1",
                )
                ->fetchColumn();
            if ($adminCount <= 1) {
                throw new InvalidArgumentException(
                    "The final active administrator cannot be deleted",
                );
            }
        }

        $delete = $db->prepare("DELETE FROM users WHERE id = ?");
        $delete->execute([$targetId]);
        respond("success", "Team member deleted");
    }

    respond("invalid", "Unknown user request", [], 400);
} catch (Throwable $error) {
    handle_api_error($error);
}
