<?php
// 1. Start session safely (Prevents "session already started" errors)
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// 2. Define Root Directory
if (!defined('APP_ROOT')) {
    // Note: If config.php is in your main folder, use __DIR__ instead of dirname(__DIR__)
    define('APP_ROOT', __DIR__); 
}

// 3. Database Credentials
define('DB_HOST', '127.0.0.1');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'hotel_db');

// 4. Create Connection
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

if ($conn->connect_error) {
    error_log("Database Connection Failed: " . $conn->connect_error);
    die("⚠️ Database connection failed. Please contact the administrator.");
}

// 5. Set Charset and Strict Mode
$conn->set_charset("utf8mb4");
$conn->query("SET SESSION sql_mode = 'STRICT_ALL_TABLES'");

// 6. Helper Functions
function is_logged_in() {
    return isset($_SESSION['user_id']) && !empty($_SESSION['user_id']);
}

function get_user_role() {
    return $_SESSION['role'] ?? 'guest';
}

function e($string) {
    return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
}
?>