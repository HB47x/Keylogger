<?php
$targetDir = __DIR__ . "/uploaded_logs/";
if (!file_exists($targetDir)) {
    mkdir($targetDir, 0755, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {
    $file = $_FILES['file'];
    $fileName = basename($file['name']);
    $fileSize = $file['size'];
    $fileTmp = $file['tmp_name'];
    $fileError = $file['error'];
    $ext = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));

    $allowedExts = ['txt', 'log', 'csv'];
    $allowedMimeTypes = ['text/plain', 'text/csv'];

    $maxFileSize = 2 * 1024 * 1024; // 2 MB

    if (!in_array($ext, $allowedExts)) {
        die("Error: Invalid file extension.");
    }

    if ($fileSize > $maxFileSize) {
        die("Error: File size exceeds limit.");
    }

    if ($fileError !== UPLOAD_ERR_OK) {
        die("Error: File upload failed with code $fileError.");
    }

    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime = finfo_file($finfo, $fileTmp);
    finfo_close($finfo);

    if (!in_array($mime, $allowedMimeTypes)) {
        die("Error: Invalid MIME type. Detected: $mime");
    }

    $newFileName = uniqid('log_', true) . '.' . $ext;
    $targetFilePath = $targetDir . $newFileName;

    if (move_uploaded_file($fileTmp, $targetFilePath)) {
        echo "File uploaded successfully!";
    } else {
        echo "Error: Could not move uploaded file.";
    }
} else {
    echo "Error: No file uploaded.";
}
?>
