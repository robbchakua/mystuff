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
        $newImagePath = $image ?? $current["image_path"];

        $statement = $db->prepare(
            "UPDATE bins SET parent_id = ?, name = ?, description = ?, image_path = ?, " .
                "latitude = ?, longitude = ?, color = ? WHERE id = ?",
        );
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
        if ($image !== null) {
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
        $image = uploaded_image("image", "items", true);

        $statement = $db->prepare(
            "INSERT INTO items " .
                "(bin_id, created_by, name, stored_at, image_path, is_multiple, quantity, description) " .
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
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
        ]);
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
        $image = uploaded_image("image", "items", false);
        $newImagePath = $image ?? $item["image_path"];

        $statement = $db->prepare(
            "UPDATE items SET bin_id = ?, name = ?, image_path = ?, " .
                "is_multiple = ?, quantity = ?, description = ? WHERE id = ?",
        );
        $statement->execute([
            $binId,
            $name,
            $newImagePath,
            $multiple ? 1 : 0,
            $multiple ? $quantity : 1,
            $description === "" ? null : $description,
            $itemId,
        ]);
        if ($image !== null) {
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
