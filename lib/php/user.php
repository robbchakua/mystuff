<?php
declare(strict_types=1);

require_once __DIR__ . '/db.php';

header('Content-Type: text/plain; charset=utf-8');
header('Cache-Control: no-store');

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

function respond(
    string $status,
    string $error = 'null',
    string $message = 'null',
    string $user = 'null'
) {
    echo implode(',,,', [$status, $error, $message, $user, 'null', 'null']);
    exit;
}

function public_user(array $row): array {
    unset($row['password']);
    return $row;
}

function find_user(mysqli $conn, string $login): ?array {
    $statement = $conn->prepare(
        'SELECT userid, name, email, password, joinDate '
        . 'FROM users WHERE userid = ? OR email = ? LIMIT 1'
    );
    $statement->bind_param('ss', $login, $login);
    $statement->execute();
    $row = $statement->get_result()->fetch_assoc();
    $statement->close();
    return $row ?: null;
}

/**
 * Supports the old plain-text rows once, then replaces them with a secure hash.
 * Remove the legacy branch after every active account has logged in successfully.
 */
function verify_password_and_upgrade(
    mysqli $conn,
    array $user,
    string $candidate
): bool {
    $stored = (string) $user['password'];

    if (password_verify($candidate, $stored)) {
        if (password_needs_rehash($stored, PASSWORD_DEFAULT)) {
            $replacement = password_hash($candidate, PASSWORD_DEFAULT);
            $statement = $conn->prepare(
                'UPDATE users SET password = ? WHERE userid = ?'
            );
            $userId = (string) $user['userid'];
            $statement->bind_param('ss', $replacement, $userId);
            $statement->execute();
            $statement->close();
        }
        return true;
    }

    if (!hash_equals($stored, $candidate)) {
        return false;
    }

    $replacement = password_hash($candidate, PASSWORD_DEFAULT);
    $statement = $conn->prepare(
        'UPDATE users SET password = ? WHERE userid = ?'
    );
    $userId = (string) $user['userid'];
    $statement->bind_param('ss', $replacement, $userId);
    $statement->execute();
    $statement->close();
    return true;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond('SQLResponseStatusTypes.codeError', 'POST required');
}

$request = (string) ($_POST['request'] ?? '');
$userid = trim((string) ($_POST['userid'] ?? ''));
$name = trim((string) ($_POST['name'] ?? ''));
$email = trim((string) ($_POST['email'] ?? ''));
$userPassword = (string) ($_POST['password'] ?? '');
$joinDate = (string) ($_POST['joinDate'] ?? '');

try {
    $conn = new mysqli($servername, $username, $password, $dbname);
    $conn->set_charset('utf8mb4');

    if ($request === 'GET' || $request === 'RequestType.get') {
        $row = find_user($conn, $userid);
        $users = $row === null ? [] : [public_user($row)];
        respond(
            'SQLResponseStatusTypes.success',
            'null',
            'User lookup was successful',
            json_encode($users, JSON_THROW_ON_ERROR)
        );
    }

    if ($request === 'LOGIN' || $request === 'RequestType.login') {
        $row = find_user($conn, $userid);
        if ($row === null
            || !verify_password_and_upgrade($conn, $row, $userPassword)) {
            // A single response avoids revealing whether an account exists.
            respond(
                'SQLResponseStatusTypes.success',
                'null',
                'Invalid credentials',
                '[]'
            );
        }

        respond(
            'SQLResponseStatusTypes.success',
            'null',
            'Login was successful',
            json_encode([public_user($row)], JSON_THROW_ON_ERROR)
        );
    }

    if ($request === 'POST-USER' || $request === 'RequestType.postUser') {
        if ($userid === '' || $name === '' || $userPassword === '') {
            respond(
                'SQLResponseStatusTypes.codeError',
                'Missing required user fields'
            );
        }

        $passwordHash = password_hash($userPassword, PASSWORD_DEFAULT);
        $statement = $conn->prepare(
            'INSERT INTO users (userid, name, email, password, joinDate) '
            . 'VALUES (?, ?, ?, ?, ?)'
        );
        $statement->bind_param(
            'sssss',
            $userid,
            $name,
            $email,
            $passwordHash,
            $joinDate
        );
        $statement->execute();
        $statement->close();
        respond(
            'SQLResponseStatusTypes.success',
            'null',
            'User creation was successful'
        );
    }

    if ($request === 'PUT-USER' || $request === 'RequestType.putUser') {
        $statement = $conn->prepare(
            'UPDATE users SET name = ?, email = ? WHERE userid = ?'
        );
        $statement->bind_param('sss', $name, $email, $userid);
        $statement->execute();
        $statement->close();
        respond(
            'SQLResponseStatusTypes.success',
            'null',
            'User update was successful'
        );
    }

    if ($request === 'DROP-USER' || $request === 'RequestType.dropUser') {
        $row = find_user($conn, $userid);
        if ($row === null
            || !verify_password_and_upgrade($conn, $row, $userPassword)) {
            respond('SQLResponseStatusTypes.codeError', 'Invalid credentials');
        }

        $conn->begin_transaction();
        try {
            $statement = $conn->prepare('DELETE FROM items WHERE userid = ?');
            $statement->bind_param('s', $userid);
            $statement->execute();
            $statement->close();

            $statement = $conn->prepare(
                'DELETE FROM locations WHERE userid = ?'
            );
            $statement->bind_param('s', $userid);
            $statement->execute();
            $statement->close();

            $statement = $conn->prepare('DELETE FROM users WHERE userid = ?');
            $statement->bind_param('s', $userid);
            $statement->execute();
            $statement->close();

            $conn->commit();
        } catch (Throwable $error) {
            $conn->rollback();
            throw $error;
        }

        respond(
            'SQLResponseStatusTypes.success',
            'null',
            'Account deletion was successful'
        );
    }

    respond(
        'SQLResponseStatusTypes.codeError',
        'Unknown request type'
    );
} catch (mysqli_sql_exception $error) {
    error_log('MyStuff user API database error: ' . $error->getMessage());
    respond(
        'SQLResponseStatusTypes.sql',
        'The database request could not be completed'
    );
} catch (Throwable $error) {
    error_log('MyStuff user API error: ' . $error->getMessage());
    respond(
        'SQLResponseStatusTypes.codeError',
        'The request could not be completed'
    );
}
