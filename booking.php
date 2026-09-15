<?php
session_start();
require_once 'models.php';

if (!is_logged_in()) {
    header("Location: login.php");
    exit;
}

$response = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $room_id = (int)$_POST['room_id'];
    $amount = (int)$_POST['amount'];
    $method = htmlspecialchars($_POST['method']);
    $guests = (int)$_POST['guests'];
    $adults = (int)$_POST['adults'];
    $children = (int)$_POST['children'];
    $check_in = $_POST['check_in'];
    $check_out = $_POST['check_out'];
    $user_id = $_SESSION['user_id'];

    $response = createBooking($user_id, $room_id, $amount, $method, $guests, $adults, $children, $check_in, $check_out);

    if ($response['success']) {
        $_SESSION['success_msg'] = $response['message'];
        header("Location: dashboard.php");
        exit;
    } else {
        $error_msg = $response['message'];
    }
}
?>