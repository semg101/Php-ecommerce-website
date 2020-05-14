<?php
require('./includes/config.inc.php');

session_start();
$uid = session_id();

if (!isset($_SESSION['customer_id'])) {
    $location = 'https://' . BASE_URL . 'checkout.php';
    header("Location: $location");
    exit();
} elseif (!isset($_SESSION['response_code']) || ($_SESSION['response_code'] != 1)) {
    $location = 'https://' . BASE_URL . 'billing.php';
    header("Location: $location");
    exit();
}

require (MYSQL);

$r = mysqli_query($dbc, "CALL clear_cart('$uid')");

$page_title = 'Coffee - Checkout - Your Order is Complete';
include('./includes/checkout_header.html');

include('./views/final.html');

$_SESSION = array();
session_destroy();

include('./includes/footer.html');
?>