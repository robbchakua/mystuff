<?php
declare(strict_types=1);

require_once __DIR__ . "/common.php";

try {
    $db = database();
    $request = request_name();

    if ($request === "health") {
        respond("success", "API and database connection are healthy");
    }

    if ($request === "login") {
        $identifier = clean_text(input("userid", input("email", "")), 190);
        $password = (string) input("password", "");
        if ($password === "") {
            throw new InvalidArgumentException("Password is required");
        }

        $statement = $db->prepare(
            "SELECT * FROM users " .
                "WHERE (userid = ? OR email = ?) AND is_active = 1 LIMIT 1",
        );
        $statement->execute([$identifier, strtolower($identifier)]);
        $user = $statement->fetch();
        if (
            !$user ||
            !password_verify($password, (string) $user["password_hash"])
        ) {
            respond(
                "unauthorized",
                "Incorrect username, email, or password",
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

        $userid = strtolower(clean_text(input("userid"), 60));
        if (preg_match('/^[a-z0-9._-]{3,60}$/', $userid) !== 1) {
            throw new InvalidArgumentException(
                "Usernames need 3-60 letters, numbers, dots, dashes, or underscores",
            );
        }
        $name = clean_text(input("name"), 120);
        $emailText = strtolower(clean_text(input("email", ""), 190, false));
        $email =
            $emailText === "" || $emailText === "no-email" ? null : $emailText;
        if (
            $email !== null &&
            filter_var($email, FILTER_VALIDATE_EMAIL) === false
        ) {
            throw new InvalidArgumentException("The email address is invalid");
        }
        $password = (string) input("password", "");
        if (strlen($password) < 10 || strlen($password) > 200) {
            throw new InvalidArgumentException(
                "Passwords must contain at least 10 characters",
            );
        }

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
                    "That username or email is already in use",
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
        $emailText = strtolower(
            clean_text(input("email", $target["email"] ?? ""), 190, false),
        );
        $email =
            $emailText === "" || $emailText === "no-email" ? null : $emailText;
        if (
            $email !== null &&
            filter_var($email, FILTER_VALIDATE_EMAIL) === false
        ) {
            throw new InvalidArgumentException("The email address is invalid");
        }

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
        if (
            $password !== "" &&
            (strlen($password) < 10 || strlen($password) > 200)
        ) {
            throw new InvalidArgumentException(
                "Passwords must contain at least 10 characters",
            );
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
