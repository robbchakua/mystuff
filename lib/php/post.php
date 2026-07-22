<?php
declare(strict_types=1);

require_once __DIR__ . "/common.php";

function parse_coordinates(): array
{
    $latitude = input("latitude");
    $longitude = input("longitude");
    $legacy = trim(
        (string) input("location", input("newLocationCoordinates", "")),
    );
    if (
        ($latitude === null || $longitude === null) &&
        str_contains($legacy, ",")
    ) {
        [$latitude, $longitude] = array_pad(explode(",", $legacy, 2), 2, null);
    }
    if (
        $latitude === null ||
        $latitude === "" ||
        $longitude === null ||
        $longitude === ""
    ) {
        return [null, null];
    }
    if (!is_numeric($latitude) || !is_numeric($longitude)) {
        throw new InvalidArgumentException("The bin coordinates are invalid");
    }
    $latitude = (float) $latitude;
    $longitude = (float) $longitude;
    if (
        $latitude < -90 ||
        $latitude > 90 ||
        $longitude < -180 ||
        $longitude > 180
    ) {
        throw new InvalidArgumentException(
            "The bin coordinates are outside the map",
        );
    }
    return [$latitude, $longitude];
}

function parse_color(mixed $value): string
{
    $color = strtoupper(ltrim(trim((string) $value), "#"));
    if (preg_match('/^[0-9A-F]{6}$/', $color) !== 1) {
        return "F44336";
    }
    return $color;
}

function parse_tags(mixed $value): array
{
    if (is_array($value)) {
        $values = $value;
    } else {
        $source = trim((string) $value);
        if ($source === "") {
            return [];
        }
        try {
            $decoded = json_decode($source, true, 512, JSON_THROW_ON_ERROR);
            $values = is_array($decoded) ? $decoded : [$decoded];
        } catch (JsonException) {
            // This also supports a simple comma-separated manual import.
            $values = explode(",", $source);
        }
    }
    if (!array_is_list($values)) {
        throw new InvalidArgumentException("Item tags must be a list");
    }

    $tags = [];
    $seen = [];
    foreach ($values as $value) {
        if (!is_scalar($value)) {
            throw new InvalidArgumentException("Each item tag must be text");
        }
        $tag = clean_text(
            preg_replace('/\s+/u', " ", trim((string) $value)) ?? "",
            30,
            false,
        );
        if ($tag === "") {
            continue;
        }
        $key = function_exists("mb_strtolower")
            ? mb_strtolower($tag)
            : strtolower($tag);
        if (isset($seen[$key])) {
            continue;
        }
        if (count($tags) >= 10) {
            throw new InvalidArgumentException(
                "An item can have up to 10 tags",
            );
        }
        $seen[$key] = true;
        $tags[] = $tag;
    }
    return $tags;
}

function tags_json(mixed $value): string
{
    return json_encode(
        parse_tags($value),
        JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR,
    );
}

function parse_item_status(mixed $value): string
{
    $status = strtolower(trim((string) $value));
    if (!in_array($status, ["missing", "in_use", "in_location"], true)) {
        throw new InvalidArgumentException("The selected item status is invalid");
    }
    return $status;
}

function record_item_history(
    PDO $db,
    int $itemId,
    array $user,
    string $action,
    ?int $fromBinId,
    ?int $toBinId,
    ?string $fromBinName,
    ?string $toBinName,
    ?string $fromStatus,
    ?string $toStatus,
): void {
    $statement = $db->prepare(
        "INSERT INTO item_history " .
            "(item_id, changed_by, changed_by_name, action, from_bin_id, to_bin_id, " .
            "from_bin_name, to_bin_name, from_status, to_status) " .
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    );
    $statement->execute([
        $itemId,
        (int) $user["id"],
        (string) $user["name"],
        $action,
        $fromBinId,
        $toBinId,
        $fromBinName,
        $toBinName,
        $fromStatus,
        $toStatus,
    ]);
}

function bin_path(array $bins, int $binId): string
{
    $names = [];
    $visited = [];
    $current = find_bin($bins, $binId);
    while ($current !== null && !isset($visited[(int) $current["id"]])) {
        $visited[(int) $current["id"]] = true;
        array_unshift($names, (string) $current["name"]);
        $current = $current["parent_id"] === null
            ? null
            : find_bin($bins, (int) $current["parent_id"]);
    }
    return implode(" / ", $names);
}

function write_csv_row($stream, array $row): void
{
    $safeRow = array_map(
        static function (mixed $value): mixed {
            if (
                is_string($value) &&
                preg_match('/^[\t\r\n ]*[=+\-@]/u', $value) === 1
            ) {
                return "'" . $value;
            }
            return $value;
        },
        $row,
    );
    if (fputcsv($stream, $safeRow, ",", '"', "") === false) {
        throw new RuntimeException("The export could not be created");
    }
}

function find_bin(array $bins, int $binId): ?array
{
    foreach ($bins as $bin) {
        if ((int) $bin["id"] === $binId) {
            return $bin;
        }
    }
    return null;
}

function bin_json(array $bin, string $permission, bool $admin): array
{
    $location = "";
    if ($bin["latitude"] !== null && $bin["longitude"] !== null) {
        $location =
            rtrim(rtrim((string) $bin["latitude"], "0"), ".") .
            "," .
            rtrim(rtrim((string) $bin["longitude"], "0"), ".");
    }
    return [
        "id" => (int) $bin["id"],
        "userid" => $bin["creator_userid"] ?? null,
        "parentId" =>
            $bin["parent_id"] === null ? null : (int) $bin["parent_id"],
        "name" => (string) $bin["name"],
        "description" => $bin["description"] ?? "",
        "location" => $location,
        "latitude" =>
            $bin["latitude"] === null ? null : (float) $bin["latitude"],
        "longitude" =>
            $bin["longitude"] === null ? null : (float) $bin["longitude"],
        "color" => (string) $bin["color"],
        "image" => $bin["image_path"],
        "permission" => $permission,
        "canEdit" => permission_rank($permission) >= permission_rank("edit"),
        "canManageAccess" => $admin,
    ];
}

function load_data(PDO $db, array $user): array
{
    $bins = $db
        ->query(
            "SELECT b.*, creator.userid AS creator_userid " .
                "FROM bins b LEFT JOIN users creator ON creator.id = b.created_by " .
                "ORDER BY b.parent_id, b.name, b.id",
        )
        ->fetchAll();
    $permissions = effective_bin_permissions($db, $user, $bins);
    $visibleBins = [];
    foreach ($bins as $bin) {
        $id = (int) $bin["id"];
        if (isset($permissions[$id])) {
            $visibleBins[] = bin_json(
                $bin,
                $permissions[$id],
                ($user["role"] ?? "") === "admin",
            );
        }
    }

    $items = [];
    $binIds = array_keys($permissions);
    if ($binIds !== []) {
        $statement = $db->prepare(
            "SELECT i.*, b.name AS bin_name, creator.userid AS creator_userid " .
                "FROM items i JOIN bins b ON b.id = i.bin_id " .
                "LEFT JOIN users creator ON creator.id = i.created_by " .
                "WHERE i.bin_id IN (" .
                placeholders(count($binIds)) .
                ") " .
                "ORDER BY i.id",
        );
        $statement->execute($binIds);
        foreach ($statement->fetchAll() as $item) {
            $items[] = [
                "id" => (int) $item["id"],
                "userid" => $item["creator_userid"] ?? null,
                "name" => (string) $item["name"],
                "storeDate" => (string) $item["stored_at"],
                "binId" => (int) $item["bin_id"],
                "location" => (string) $item["bin_name"],
                "image" => $item["image_path"],
                "multiple" => (bool) $item["is_multiple"],
                "quantity" => (int) $item["quantity"],
                "description" => $item["description"] ?? "",
                "tags" => parse_tags($item["tags"] ?? "[]"),
                "status" => (string) ($item["status"] ?? "in_location"),
                "canEdit" =>
                    permission_rank($permissions[(int) $item["bin_id"]]) >=
                    permission_rank("edit"),
            ];
        }
    }
    return [
        "items" => $items,
        "bins" => $visibleBins,
        "locations" => $visibleBins,
    ];
}

try {
    $db = database();
    $user = require_auth($db);
    $request = request_name();

    if ($request === "get") {
        respond("success", "Data loaded", load_data($db, $user));
    }

    if ($request === "exportCsv") {
        require_admin($user);
        $bins = all_bins($db);
        $creatorRows = $db->query("SELECT id, name FROM users")->fetchAll();
        $creatorNames = array_column($creatorRows, "name", "id");
        $items = $db
            ->query(
                "SELECT i.*, b.name AS bin_name, u.name AS creator_name " .
                    "FROM items i JOIN bins b ON b.id = i.bin_id " .
                    "LEFT JOIN users u ON u.id = i.created_by ORDER BY i.id",
            )
            ->fetchAll();
        $stream = fopen("php://temp", "w+");
        if ($stream === false) {
            throw new RuntimeException("The export could not be created");
        }
        write_csv_row($stream, [
            "record_type",
            "id",
            "name",
            "bin_or_parent_id",
            "bin_or_parent_path",
            "description",
            "status",
            "is_multiple",
            "quantity",
            "tags",
            "latitude",
            "longitude",
            "image_path",
            "created_by",
            "created_at",
        ]);
        foreach ($bins as $bin) {
            $parentPath = $bin["parent_id"] === null
                ? ""
                : bin_path($bins, (int) $bin["parent_id"]);
            write_csv_row($stream, [
                "bin",
                $bin["id"],
                $bin["name"],
                $bin["parent_id"],
                $parentPath,
                $bin["description"] ?? "",
                "",
                "",
                "",
                "",
                $bin["latitude"],
                $bin["longitude"],
                $bin["image_path"],
                $creatorNames[(int) $bin["created_by"]] ?? "",
                $bin["created_at"],
            ]);
        }
        foreach ($items as $item) {
            write_csv_row($stream, [
                "item",
                $item["id"],
                $item["name"],
                $item["bin_id"],
                bin_path($bins, (int) $item["bin_id"]),
                $item["description"] ?? "",
                $item["status"],
                (int) $item["is_multiple"],
                $item["quantity"],
                implode("; ", parse_tags($item["tags"] ?? "[]")),
                "",
                "",
                $item["image_path"],
                $item["creator_name"] ?? "",
                $item["created_at"],
            ]);
        }
        rewind($stream);
        $csv = stream_get_contents($stream);
        fclose($stream);
        if ($csv === false) {
            throw new RuntimeException("The export could not be created");
        }
        header("Content-Type: text/csv; charset=utf-8");
        header(
            'Content-Disposition: attachment; filename="mystuff-inventory-' .
                date("Y-m-d") .
                '.csv"',
        );
        echo "\xEF\xBB\xBF" . $csv;
        exit();
    }

    if ($request === "getItemHistory") {
        $itemId =
            nullable_int(input("id")) ??
            throw new InvalidArgumentException("Item ID is required");
        $itemStatement = $db->prepare(
            "SELECT bin_id FROM items WHERE id = ? LIMIT 1",
        );
        $itemStatement->execute([$itemId]);
        $item = $itemStatement->fetch();
        if (!$item) {
            respond("notFound", "Item not found", [], 404);
        }
        require_bin_permission($db, $user, (int) $item["bin_id"], "view");
        $historyStatement = $db->prepare(
            "SELECT id, item_id, changed_by, changed_by_name, action, " .
                "from_bin_id, to_bin_id, from_bin_name, to_bin_name, " .
                "from_status, to_status, created_at " .
                "FROM item_history WHERE item_id = ? ORDER BY created_at DESC, id DESC",
        );
        $historyStatement->execute([$itemId]);
        $history = $historyStatement->fetchAll();
        if (($user["role"] ?? "") !== "admin") {
            $visibleBins = effective_bin_permissions($db, $user);
            foreach ($history as &$entry) {
                foreach (["from", "to"] as $side) {
                    $historyBinId = $entry[$side . "_bin_id"];
                    if (
                        $historyBinId === null ||
                        !isset($visibleBins[(int) $historyBinId])
                    ) {
                        $entry[$side . "_bin_name"] = null;
                    }
                }
            }
            unset($entry);
        }
        respond("success", "Item history loaded", [
            "history" => $history,
        ]);
    }

    if ($request === "postBin") {
        $parentId = nullable_int(input("parentId"));
        if ($parentId === null) {
            require_admin($user);
        } else {
            require_bin_permission($db, $user, $parentId, "edit");
        }
        $name = clean_text(input("name"), 160);
        $description = clean_text(input("description", ""), 10000, false);
        [$latitude, $longitude] = parse_coordinates();
        $color = parse_color(
            input("color", input("newLocationColor", "F44336")),
        );
        $image = uploaded_image("image", "bins", false);

        $statement = $db->prepare(
            "INSERT INTO bins " .
                "(parent_id, created_by, name, description, image_path, latitude, longitude, color) " .
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        );
        try {
            $statement->execute([
                $parentId,
                (int) $user["id"],
                $name,
                $description === "" ? null : $description,
                $image,
                $latitude,
                $longitude,
                $color,
            ]);
        } catch (Throwable $error) {
            remove_image($image);
            throw $error;
        }
        respond(
            "success",
            "Bin created",
            array_merge(
                ["binId" => (int) $db->lastInsertId()],
                load_data($db, $user),
            ),
            201,
        );
    }

    if ($request === "putBin" || $request === "putLocation") {
        $binId =
            nullable_int(input("binId", input("id"))) ??
            throw new InvalidArgumentException("Bin ID is required");
        require_bin_permission($db, $user, $binId, "edit");
        $bins = all_bins($db);
        $current = find_bin($bins, $binId);
        if ($current === null) {
            respond("notFound", "Bin not found", [], 404);
        }

        $parentId = input("parentId", $current["parent_id"]);
        $parentId = nullable_int($parentId);
        if ($parentId === null && ($user["role"] ?? "") !== "admin") {
            respond(
                "forbidden",
                "Only administrators can create top-level bins",
                [],
                403,
            );
        }
        if ($parentId !== null) {
            require_bin_permission($db, $user, $parentId, "edit");
            if (in_array($parentId, descendant_ids($bins, $binId), true)) {
                throw new InvalidArgumentException(
                    "A bin cannot be moved inside itself",
                );
            }
        }

        $name = clean_text(input("name", $current["name"]), 160);
        $description = clean_text(
            input("description", $current["description"] ?? ""),
            10000,
            false,
        );
        [$latitude, $longitude] = parse_coordinates();
        if (
            input("latitude") === null &&
            input("longitude") === null &&
            trim((string) input("location", "")) === ""
        ) {
            $latitude = $current["latitude"];
            $longitude = $current["longitude"];
        }
        $color = parse_color(input("color", $current["color"]));
        $image = uploaded_image("image", "bins", false);
        $removeImage = boolean_input("removeImage");
        if ($removeImage && $image !== null) {
            remove_image($image);
            $image = null;
        }
        $newImagePath = $removeImage ? null : ($image ?? $current["image_path"]);

        $statement = $db->prepare(
            "UPDATE bins SET parent_id = ?, name = ?, description = ?, image_path = ?, " .
                "latitude = ?, longitude = ?, color = ? WHERE id = ?",
        );
        try {
            $statement->execute([
                $parentId,
                $name,
                $description === "" ? null : $description,
                $newImagePath,
                $latitude,
                $longitude,
                $color,
                $binId,
            ]);
        } catch (Throwable $error) {
            remove_image($image);
            throw $error;
        }
        if ($image !== null || $removeImage) {
            remove_image($current["image_path"]);
        }
        respond("success", "Bin updated", load_data($db, $user));
    }

    if (
        in_array(
            $request,
            ["dropBin", "dropLocationWithAll", "dropLocationSetNew"],
            true,
        )
    ) {
        $binId =
            nullable_int(input("binId", input("id"))) ??
            throw new InvalidArgumentException("Bin ID is required");
        require_bin_permission($db, $user, $binId, "edit");
        $bins = all_bins($db);
        $current = find_bin($bins, $binId);
        if ($current === null) {
            respond("notFound", "Bin not found", [], 404);
        }
        $deleteContents =
            $request === "dropLocationWithAll" ||
            boolean_input("deleteContents");
        $replacementId = nullable_int(input("replacementBinId"));
        $affectedIds = descendant_ids($bins, $binId);

        if (!$deleteContents) {
            if ($replacementId === null) {
                throw new InvalidArgumentException(
                    "Choose another bin before deleting this bin without its contents",
                );
            }
            if (in_array($replacementId, $affectedIds, true)) {
                throw new InvalidArgumentException(
                    "The replacement cannot be inside the deleted bin",
                );
            }
            require_bin_permission($db, $user, $replacementId, "edit");
        }

        $images = [];
        $binImageQuery = $db->prepare(
            "SELECT image_path FROM bins WHERE id IN (" .
                placeholders(count($affectedIds)) .
                ")",
        );
        $binImageQuery->execute($affectedIds);
        $images = array_column($binImageQuery->fetchAll(), "image_path");
        $itemImageQuery = $db->prepare(
            "SELECT image_path FROM items WHERE bin_id IN (" .
                placeholders(count($affectedIds)) .
                ")",
        );
        $itemImageQuery->execute($affectedIds);
        $itemImages = array_column($itemImageQuery->fetchAll(), "image_path");

        $db->beginTransaction();
        try {
            if (!$deleteContents) {
                $replacement = find_bin($bins, $replacementId);
                $movedItems = $db
                    ->prepare("SELECT id, status FROM items WHERE bin_id = ?");
                $movedItems->execute([$binId]);
                foreach ($movedItems->fetchAll() as $movedItem) {
                    record_item_history(
                        $db,
                        (int) $movedItem["id"],
                        $user,
                        "moved_due_to_bin_delete",
                        $binId,
                        $replacementId,
                        (string) $current["name"],
                        $replacement["name"] ?? null,
                        (string) $movedItem["status"],
                        (string) $movedItem["status"],
                    );
                }
                $db->prepare(
                    "UPDATE items SET bin_id = ? WHERE bin_id = ?",
                )->execute([$replacementId, $binId]);
                $db->prepare(
                    "UPDATE bins SET parent_id = ? WHERE parent_id = ?",
                )->execute([$replacementId, $binId]);
                $db->prepare("DELETE FROM bins WHERE id = ?")->execute([
                    $binId,
                ]);
            } else {
                // Delete deepest children first instead of relying on MySQL's
                // finite self-referential cascade depth.
                foreach (array_reverse($affectedIds) as $affectedId) {
                    $db->prepare("DELETE FROM bins WHERE id = ?")->execute([
                        $affectedId,
                    ]);
                }
            }
            $db->commit();
        } catch (Throwable $error) {
            $db->rollBack();
            throw $error;
        }

        if ($deleteContents) {
            foreach (array_merge($images, $itemImages) as $path) {
                remove_image($path);
            }
        } else {
            remove_image($current["image_path"]);
        }
        respond("success", "Bin deleted", load_data($db, $user));
    }

    if ($request === "postItem") {
        $binId =
            nullable_int(input("binId")) ??
            throw new InvalidArgumentException(
                "Every item must be assigned to a bin",
            );
        require_bin_permission($db, $user, $binId, "edit");
        $name = clean_text(input("name"), 180);
        $storedAt = (string) input("storeDate", date("Y-m-d"));
        $date = DateTimeImmutable::createFromFormat("Y-m-d", $storedAt);
        if (!$date || $date->format("Y-m-d") !== $storedAt) {
            throw new InvalidArgumentException("The stored date is invalid");
        }
        $multiple = boolean_input("multiple");
        $quantity = max(1, (int) input("quantity", 1));
        $description = clean_text(input("description", ""), 10000, false);
        $tags = tags_json(input("tags", "[]"));
        $status = parse_item_status(input("status", "in_location"));
        $image = uploaded_image("image", "items", false);

        $db->beginTransaction();
        try {
            $statement = $db->prepare(
                "INSERT INTO items " .
                    "(bin_id, created_by, name, stored_at, image_path, is_multiple, quantity, description, tags, status) " .
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            );
            $statement->execute([
                $binId,
                (int) $user["id"],
                $name,
                $storedAt,
                $image,
                $multiple ? 1 : 0,
                $multiple ? $quantity : 1,
                $description === "" ? null : $description,
                $tags,
                $status,
            ]);
            $itemId = (int) $db->lastInsertId();
            $bin = find_bin(all_bins($db), $binId);
            record_item_history(
                $db,
                $itemId,
                $user,
                "created",
                null,
                $binId,
                null,
                $bin["name"] ?? null,
                null,
                $status,
            );
            $db->commit();
        } catch (Throwable $error) {
            $db->rollBack();
            remove_image($image);
            throw $error;
        }
        respond("success", "Item created", load_data($db, $user), 201);
    }

    if ($request === "putItem") {
        $itemId =
            nullable_int(input("id")) ??
            throw new InvalidArgumentException("Item ID is required");
        $itemStatement = $db->prepare(
            "SELECT * FROM items WHERE id = ? LIMIT 1",
        );
        $itemStatement->execute([$itemId]);
        $item = $itemStatement->fetch();
        if (!$item) {
            respond("notFound", "Item not found", [], 404);
        }
        require_bin_permission($db, $user, (int) $item["bin_id"], "edit");
        $binId =
            nullable_int(input("binId", $item["bin_id"])) ??
            throw new InvalidArgumentException(
                "Every item must be assigned to a bin",
            );
        require_bin_permission($db, $user, $binId, "edit");

        $name = clean_text(input("name", $item["name"]), 180);
        $multiple = boolean_input("multiple", (bool) $item["is_multiple"]);
        $quantity = max(1, (int) input("quantity", $item["quantity"]));
        $description = clean_text(
            input("description", $item["description"] ?? ""),
            10000,
            false,
        );
        $tags = tags_json(input("tags", $item["tags"] ?? "[]"));
        $status = parse_item_status(input("status", $item["status"]));
        $image = uploaded_image("image", "items", false);
        $removeImage = boolean_input("removeImage");
        if ($removeImage && $image !== null) {
            remove_image($image);
            $image = null;
        }
        $newImagePath = $removeImage ? null : ($image ?? $item["image_path"]);

        $bins = all_bins($db);
        $oldBin = find_bin($bins, (int) $item["bin_id"]);
        $newBin = find_bin($bins, $binId);
        $binChanged = (int) $item["bin_id"] !== $binId;
        $statusChanged = (string) $item["status"] !== $status;
        $action = $binChanged && $statusChanged
            ? "moved_and_status_changed"
            : ($binChanged
                ? "moved"
                : ($statusChanged ? "status_changed" : "updated"));

        $db->beginTransaction();
        try {
            $statement = $db->prepare(
                "UPDATE items SET bin_id = ?, name = ?, image_path = ?, " .
                    "is_multiple = ?, quantity = ?, description = ?, tags = ?, status = ? WHERE id = ?",
            );
            $statement->execute([
                $binId,
                $name,
                $newImagePath,
                $multiple ? 1 : 0,
                $multiple ? $quantity : 1,
                $description === "" ? null : $description,
                $tags,
                $status,
                $itemId,
            ]);
            record_item_history(
                $db,
                $itemId,
                $user,
                $action,
                (int) $item["bin_id"],
                $binId,
                $oldBin["name"] ?? null,
                $newBin["name"] ?? null,
                (string) $item["status"],
                $status,
            );
            $db->commit();
        } catch (Throwable $error) {
            $db->rollBack();
            remove_image($image);
            throw $error;
        }
        if ($image !== null || $removeImage) {
            remove_image($item["image_path"]);
        }
        respond("success", "Item updated", load_data($db, $user));
    }

    if ($request === "dropItem") {
        $itemId =
            nullable_int(input("id")) ??
            throw new InvalidArgumentException("Item ID is required");
        $statement = $db->prepare("SELECT * FROM items WHERE id = ? LIMIT 1");
        $statement->execute([$itemId]);
        $item = $statement->fetch();
        if (!$item) {
            respond("notFound", "Item not found", [], 404);
        }
        require_bin_permission($db, $user, (int) $item["bin_id"], "edit");
        $db->prepare("DELETE FROM items WHERE id = ?")->execute([$itemId]);
        remove_image($item["image_path"]);
        respond("success", "Item deleted", load_data($db, $user));
    }

    if ($request === "getBinAccess") {
        require_admin($user);
        $binId =
            nullable_int(input("binId")) ??
            throw new InvalidArgumentException("Bin ID is required");
        $users = $db
            ->query(
                "SELECT * FROM users WHERE is_active = 1 ORDER BY role, name, id",
            )
            ->fetchAll();
        $statement = $db->prepare(
            "SELECT bp.bin_id, bp.user_id, bp.permission, u.userid, u.name " .
                "FROM bin_permissions bp JOIN users u ON u.id = bp.user_id " .
                "WHERE bp.bin_id = ? ORDER BY u.name",
        );
        $statement->execute([$binId]);
        respond("success", "Bin access loaded", [
            "users" => array_map("public_user", $users),
            "permissions" => $statement->fetchAll(),
        ]);
    }

    if ($request === "grantBinAccess") {
        require_admin($user);
        $binId =
            nullable_int(input("binId")) ??
            throw new InvalidArgumentException("Bin ID is required");
        $targetUserId =
            nullable_int(input("userId")) ??
            throw new InvalidArgumentException("Team member ID is required");
        $permission = (string) input("permission", "view");
        if (!in_array($permission, ["view", "edit"], true)) {
            throw new InvalidArgumentException(
                "The selected permission is invalid",
            );
        }
        if (find_bin(all_bins($db), $binId) === null) {
            respond("notFound", "Bin not found", [], 404);
        }
        $target = $db->prepare(
            "SELECT id FROM users WHERE id = ? AND is_active = 1",
        );
        $target->execute([$targetUserId]);
        if (!$target->fetch()) {
            respond("notFound", "Team member not found", [], 404);
        }

        $statement = $db->prepare(
            "INSERT INTO bin_permissions (bin_id, user_id, permission, granted_by) " .
                "VALUES (?, ?, ?, ?) " .
                "ON DUPLICATE KEY UPDATE permission = VALUES(permission), " .
                "granted_by = VALUES(granted_by), updated_at = CURRENT_TIMESTAMP",
        );
        $statement->execute([
            $binId,
            $targetUserId,
            $permission,
            (int) $user["id"],
        ]);
        respond("success", "Bin access updated");
    }

    if ($request === "revokeBinAccess") {
        require_admin($user);
        $binId =
            nullable_int(input("binId")) ??
            throw new InvalidArgumentException("Bin ID is required");
        $targetUserId =
            nullable_int(input("userId")) ??
            throw new InvalidArgumentException("Team member ID is required");
        $statement = $db->prepare(
            "DELETE FROM bin_permissions WHERE bin_id = ? AND user_id = ?",
        );
        $statement->execute([$binId, $targetUserId]);
        respond("success", "Bin access removed");
    }

    respond("invalid", "Unknown data request", [], 400);
} catch (Throwable $error) {
    handle_api_error($error);
}
