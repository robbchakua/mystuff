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
    string $user = 'null',
    string $items = 'null',
    string $locations = 'null'
) {
    echo implode(',,,', [
        $status,
        $error,
        $message,
        $user,
        $items,
        $locations,
    ]);
    exit;
}

function uploaded_image(): array {
    if (!isset($_FILES['image'])
        || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
        throw new RuntimeException('A valid image upload is required');
    }

    if ($_FILES['image']['size'] > 8 * 1024 * 1024) {
        throw new RuntimeException('The image is too large');
    }

    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($_FILES['image']['tmp_name']);
    $extensions = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ];
    if (!isset($extensions[$mime])) {
        throw new RuntimeException('Unsupported image type');
    }

    $originalStem = pathinfo(
        basename((string) $_FILES['image']['name']),
        PATHINFO_FILENAME
    );
    $safeStem = preg_replace('/[^A-Za-z0-9_-]/', '_', $originalStem);
    $safeStem = trim((string) $safeStem, '_');
    if ($safeStem === '') {
        $safeStem = 'item';
    }

    $directory = __DIR__ . '/images/items';
    if (!is_dir($directory)
        && !mkdir($directory, 0750, true)
        && !is_dir($directory)) {
        throw new RuntimeException('The image directory is unavailable');
    }

    $filename = $safeStem . '.' . $extensions[$mime];
    if (file_exists($directory . '/' . $filename)) {
        $filename = $safeStem . '-' . bin2hex(random_bytes(6))
            . '.' . $extensions[$mime];
    }

    $absolutePath = $directory . '/' . $filename;
    if (!move_uploaded_file($_FILES['image']['tmp_name'], $absolutePath)) {
        throw new RuntimeException('The image could not be saved');
    }

    return ['images/items/' . $filename, $absolutePath];
}

function remove_item_image(?string $relativePath): void {
    if ($relativePath === null || $relativePath === '') {
        return;
    }

    $imageDirectory = realpath(__DIR__ . '/images/items');
    $candidate = realpath(__DIR__ . '/' . ltrim($relativePath, '/'));
    if ($imageDirectory !== false
        && $candidate !== false
        && strpos($candidate, $imageDirectory . DIRECTORY_SEPARATOR) === 0
        && is_file($candidate)) {
        unlink($candidate);
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond('SQLResponseStatusTypes.codeError', 'POST required');
}

$request = (string) ($_POST['request'] ?? '');
$userid = trim((string) ($_POST['userid'] ?? ''));
$id = (int) ($_POST['id'] ?? 0);
$name = trim((string) ($_POST['name'] ?? ''));
$storeDate = (string) ($_POST['storeDate'] ?? '');
$location = trim((string) ($_POST['location'] ?? ''));
$multiple = (string) ($_POST['multiple'] ?? 'false');
$quantity = (int) ($_POST['quantity'] ?? 0);
$description = trim((string) ($_POST['description'] ?? ''));
$newLocation = filter_var(
    $_POST['newLocation'] ?? false,
    FILTER_VALIDATE_BOOLEAN
);
$newLocationColor = trim((string) ($_POST['newLocationColor'] ?? ''));
$newLocationCoordinates = trim(
    (string) ($_POST['newLocationCoordinates'] ?? '')
);
$oldName = trim((string) ($_POST['oldName'] ?? ''));
$color = trim((string) ($_POST['color'] ?? ''));

try {
    $conn = new mysqli($servername, $username, $password, $dbname);
    $conn->set_charset('utf8mb4');

    if ($request === 'GET' || $request === 'RequestType.get') {
        $statement = $conn->prepare('SELECT * FROM items WHERE userid = ?');
        $statement->bind_param('s', $userid);
        $statement->execute();
        $items = $statement->get_result()->fetch_all(MYSQLI_ASSOC);
        $statement->close();

        $statement = $conn->prepare(
            'SELECT * FROM locations WHERE userid = ?'
        );
        $statement->bind_param('s', $userid);
        $statement->execute();
        $locations = $statement->get_result()->fetch_all(MYSQLI_ASSOC);
        $statement->close();

        respond(
            'SQLResponseStatusTypes.success',
            'null',
            'Data retrieval was successful',
            'null',
            json_encode($items, JSON_THROW_ON_ERROR),
            json_encode($locations, JSON_THROW_ON_ERROR)
        );
    }

    if ($request === 'POST-ITEM' || $request === 'RequestType.postItem') {
        [$imagePath, $absoluteImagePath] = uploaded_image();
        $conn->begin_transaction();
        try {
            $statement = $conn->prepare(
                'INSERT INTO items '
                . '(userid, name, storeDate, location, image, multiple, quantity, description) '
                . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $statement->bind_param(
                'ssssssis',
                $userid,
                $name,
                $storeDate,
                $location,
                $imagePath,
                $multiple,
                $quantity,
                $description
            );
            $statement->execute();
            $statement->close();

            if ($newLocation) {
                $statement = $conn->prepare(
                    'INSERT INTO locations (userid, name, location, color) '
                    . 'VALUES (?, ?, ?, ?)'
                );
                $statement->bind_param(
                    'ssss',
                    $userid,
                    $location,
                    $newLocationCoordinates,
                    $newLocationColor
                );
                $statement->execute();
                $statement->close();
            }
            $conn->commit();
        } catch (Throwable $error) {
            $conn->rollback();
            if (is_file($absoluteImagePath)) {
                unlink($absoluteImagePath);
            }
            throw $error;
        }

        respond(
            'SQLResponseStatusTypes.success',
            'null',
            'Item creation was successful'
        );
    }

    if ($request === 'PUT-ITEM' || $request === 'RequestType.putItem') {
        $statement = $conn->prepare(
            'SELECT image FROM items WHERE id = ? AND userid = ? LIMIT 1'
        );
        $statement->bind_param('is', $id, $userid);
        $statement->execute();
        $oldItem = $statement->get_result()->fetch_assoc();
        $statement->close();
        if ($oldItem === null) {
            respond('SQLResponseStatusTypes.codeError', 'Item not found');
        }

        [$imagePath, $absoluteImagePath] = uploaded_image();
        $conn->begin_transaction();
        try {
            $statement = $conn->prepare(
                'UPDATE items SET name = ?, location = ?, image = ?, '
                . 'multiple = ?, quantity = ?, description = ? '
                . 'WHERE id = ? AND userid = ?'
            );
            $statement->bind_param(
                'ssssisis',
                $name,
                $location,
                $imagePath,
                $multiple,
                $quantity,
                $description,
                $id,
                $userid
            );
            $statement->execute();
            $statement->close();

            if ($newLocation) {
                $statement = $conn->prepare(
                    'INSERT INTO locations (userid, name, location, color) '
                    . 'VALUES (?, ?, ?, ?)'
                );
                $statement->bind_param(
                    'ssss',
                    $userid,
                    $location,
                    $newLocationCoordinates,
                    $newLocationColor
                );
                $statement->execute();
                $statement->close();
            }
            $conn->commit();
        } catch (Throwable $error) {
            $conn->rollback();
            if (is_file($absoluteImagePath)) {
                unlink($absoluteImagePath);
            }
            throw $error;
        }

        remove_item_image(is_array($oldItem) ? ($oldItem['image'] ?? null) : null);
        respond(
            'SQLResponseStatusTypes.success',
            'null',
            'Item update was successful'
        );
    }

    if ($request === 'DROP-ITEM' || $request === 'RequestType.dropItem') {
        $statement = $conn->prepare(
            'SELECT image FROM items WHERE id = ? AND userid = ? LIMIT 1'
        );
        $statement->bind_param('is', $id, $userid);
        $statement->execute();
        $oldItem = $statement->get_result()->fetch_assoc();
        $statement->close();

        $statement = $conn->prepare(
            'DELETE FROM items WHERE id = ? AND userid = ?'
        );
        $statement->bind_param('is', $id, $userid);
        $statement->execute();
        $statement->close();
        remove_item_image(is_array($oldItem) ? ($oldItem['image'] ?? null) : null);
        respond(
            'SQLResponseStatusTypes.success',
            'null',
            'Item deletion was successful'
        );
    }

    if ($request === 'PUT-LOCATION'
        || $request === 'RequestType.putLocation') {
        $conn->begin_transaction();
        try {
            $statement = $conn->prepare(
                'UPDATE locations SET name = ?, color = ? '
                . 'WHERE id = ? AND userid = ?'
            );
            $statement->bind_param('ssis', $name, $color, $id, $userid);
            $statement->execute();
            $statement->close();

            $statement = $conn->prepare(
                'UPDATE items SET location = ? '
                . 'WHERE location = ? AND userid = ?'
            );
            $statement->bind_param('sss', $name, $oldName, $userid);
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
            'Location update was successful'
        );
    }

    if ($request === 'DROP-LOCATION-NEW'
        || $request === 'RequestType.dropLocationSetNew') {
        $conn->begin_transaction();
        try {
            $statement = $conn->prepare(
                'DELETE FROM locations WHERE id = ? AND userid = ?'
            );
            $statement->bind_param('is', $id, $userid);
            $statement->execute();
            $statement->close();

            $statement = $conn->prepare(
                'UPDATE items SET location = ? '
                . 'WHERE location = ? AND userid = ?'
            );
            $statement->bind_param('sss', $name, $oldName, $userid);
            $statement->execute();
            $statement->close();

            $statement = $conn->prepare(
                'INSERT INTO locations (userid, name, location, color) '
                . 'VALUES (?, ?, ?, ?)'
            );
            $statement->bind_param(
                'ssss',
                $userid,
                $name,
                $location,
                $color
            );
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
            'Location replacement was successful'
        );
    }

    if ($request === 'DROP-LOCATION-ALL'
        || $request === 'RequestType.dropLocationWithAll') {
        $conn->begin_transaction();
        try {
            $statement = $conn->prepare(
                'DELETE FROM locations WHERE id = ? AND userid = ?'
            );
            $statement->bind_param('is', $id, $userid);
            $statement->execute();
            $statement->close();

            $statement = $conn->prepare(
                'DELETE FROM items WHERE location = ? AND userid = ?'
            );
            $statement->bind_param('ss', $name, $userid);
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
            'Location deletion was successful'
        );
    }

    respond('SQLResponseStatusTypes.codeError', 'Unknown request type');
} catch (mysqli_sql_exception $error) {
    error_log('MyStuff data API database error: ' . $error->getMessage());
    respond(
        'SQLResponseStatusTypes.sql',
        'The database request could not be completed'
    );
} catch (Throwable $error) {
    error_log('MyStuff data API error: ' . $error->getMessage());
    respond(
        'SQLResponseStatusTypes.codeError',
        'The request could not be completed'
    );
}
