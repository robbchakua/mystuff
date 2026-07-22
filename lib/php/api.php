<?php
// This unauthenticated legacy books endpoint was not referenced by the Flutter
// app and interpolated a user ID directly into SQL. Keep the route closed if an
// old deployment still points at this file.
http_response_code(410);
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
echo json_encode(['error' => 'This endpoint has been retired']);
