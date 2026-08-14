<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['token']) || !isset($input['title']) || !isset($input['body'])) {
    http_response_code(400);
    echo json_encode(["error" => "Missing parameters"]);
    exit;
}

$deviceToken = $input['token'];
$title = $input['title'];
$body = $input['body'];
$data = isset($input['data']) ? $input['data'] : (object)[];

$keyFile = __DIR__ . '/service_account.json';
if (!file_exists($keyFile)) {
    http_response_code(500);
    echo json_encode(["error" => "service_account.json not found. Please place your Firebase service account JSON here."]);
    exit;
}

$keyData = json_decode(file_get_contents($keyFile), true);

function base64url_encode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

$header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
$now = time();
$claim = json_encode([
    'iss' => $keyData['client_email'],
    'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
    'aud' => 'https://oauth2.googleapis.com/token',
    'exp' => $now + 3600,
    'iat' => $now
]);

$signature = '';
openssl_sign(base64url_encode($header) . '.' . base64url_encode($claim), $signature, $keyData['private_key'], 'sha256');

$jwt = base64url_encode($header) . '.' . base64url_encode($claim) . '.' . base64url_encode($signature);

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'assertion' => $jwt
]));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);

$tokenData = json_decode($response, true);
if (!isset($tokenData['access_token'])) {
    http_response_code(500);
    echo json_encode(["error" => "Failed to obtain access token from Google OAuth2", "details" => $tokenData]);
    exit;
}

$accessToken = $tokenData['access_token'];
$projectId = $keyData['project_id'];

$message = [
    'message' => [
        'token' => $deviceToken,
        'notification' => [
            'title' => $title,
            'body' => $body
        ],
        'data' => $data
    ]
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/v1/projects/' . $projectId . '/messages:send');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $accessToken,
    'Content-Type: application/json'
]);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$result = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

http_response_code($httpCode);
echo $result;
?>
