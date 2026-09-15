<?php
session_start();
require_once __DIR__ . '/models.php';

if (!is_logged_in() || get_user_role() !== 'admin') {
    header("Location: login.php");
    exit;
}

$action = $_POST['action'] ?? $_GET['action'] ?? '';
$response = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if ($action === 'create_booking') {
        $user_id = (int)$_POST['user_id'];
        $room_id = (int)$_POST['room_id'];
        $amount = (int)$_POST['amount'];
        $method = htmlspecialchars($_POST['method']);
        $guests = (int)$_POST['guests'];
        $adults = (int)$_POST['adults'];
        $children = (int)$_POST['children'];
        $check_in = $_POST['check_in'];
        $check_out = $_POST['check_out'];

        $response = createBooking($user_id, $room_id, $amount, $method, $guests, $adults, $children, $check_in, $check_out);
    } 
    
    elseif ($action === 'cancel_booking') {
        $booking_id = (int)$_POST['booking_id'];
        $response = cancelBooking($booking_id);
    }
}

if ($response) {
    $_SESSION['flash_message'] = $response['message'];
    $_SESSION['flash_type'] = $response['success'] ? 'success' : 'error';
}

header("Location: dashboard.php");
exit;
?>