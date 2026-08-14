<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Content-Type: application/json; charset=UTF-8");

$target_dir = "uploads/";

// Create uploads folder if it doesn't exist
if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
    // Create a blank index.php inside uploads to prevent directory listing
    file_put_contents($target_dir . 'index.php', '<?php header("Location: ../"); exit(); ?>');
}

$response = array('success' => false, 'message' => 'Something went wrong');

if(isset($_FILES['image'])) {
    $file = $_FILES['image'];
    
    // Sanitize filename and add timestamp to avoid duplicates
    $filename = time() . '_' . preg_replace("/[^a-zA-Z0-9.]/", "", basename($file['name']));
    $target_file = $target_dir . $filename;
    
    // Check if it's an actual image
    $check = getimagesize($file['tmp_name']);
    if($check !== false) {
        if (move_uploaded_file($file['tmp_name'], $target_file)) {
            // Build the URL to the uploaded file
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
            $domain = $_SERVER['HTTP_HOST'];
            
            // If you put this script in a subfolder, adjust the URL path here
            // Example: apiwedding.kasunpremarathna.com/upload.php -> /uploads/filename.jpg
            $file_url = $protocol . "://" . $domain . "/uploads/" . $filename;
            
            $response['success'] = true;
            $response['message'] = 'File uploaded successfully';
            $response['url'] = $file_url;
        } else {
            $response['message'] = 'Error saving the file to server';
        }
    } else {
        $response['message'] = 'Uploaded file is not a valid image';
    }
} else {
    $response['message'] = 'No image provided in request';
}

echo json_encode($response);
?>
