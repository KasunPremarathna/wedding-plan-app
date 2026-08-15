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
    
    // Check file size (Max 15MB)
    if ($file['size'] > 15 * 1024 * 1024) {
        $response['message'] = 'File size is too large. Maximum limit is 15MB.';
        echo json_encode($response);
        exit;
    }
    
    // Sanitize filename and add timestamp to avoid duplicates
    $filename = time() . '_' . preg_replace("/[^a-zA-Z0-9.]/", "", basename($file['name']));
    $target_file = $target_dir . $filename;
    
    // Check file type
    $fileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));
    $allowed_types = array("jpg", "jpeg", "png", "gif", "webp", "pdf");
    
    if (in_array($fileType, $allowed_types)) {
        if (move_uploaded_file($file['tmp_name'], $target_file)) {
            // Build the URL to the uploaded file
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
            $domain = $_SERVER['HTTP_HOST'];
            
            // If you put this script in a subfolder, adjust the URL path here
            $file_url = $protocol . "://" . $domain . "/uploads/" . $filename;
            
            $response['success'] = true;
            $response['message'] = 'File uploaded successfully';
            $response['url'] = $file_url;
        } else {
            $response['message'] = 'Error saving the file to server';
        }
    } else {
        $response['message'] = 'Uploaded file is not a valid format. Only Images and PDFs are allowed.';
    }
} else {
    $response['message'] = 'No image provided in request';
}

echo json_encode($response);
?>
