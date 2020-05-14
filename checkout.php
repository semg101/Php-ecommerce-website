<?php
    
    require('./includes/config.inc.php');

    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        //if (isset($_COOKIE['SESSION']) && (strlen($_COOKIE['SESSION']) === 32)) {
            //$uid = $_COOKIE['SESSION'];
            //session_id($uid);
            //session_start();
        //} else {
            //$location = 'http://' . BASE_URL . 'cart.php';
            //header("Location: $location");
            //exit();
        //}
        session_start();
        $uid = session_id();
    } else { // POST request.
        session_start();
        $uid = session_id();
    }

    
   

    require (MYSQL);
    $shipping_errors = array();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (preg_match ('/^[A-Z \'.-]{2,20}$/i', $_POST['first_name'])) {
            $fn = addslashes($_POST['first_name']);
        } else {
            $shipping_errors['first_name'] = 'Please enter your first name!';
        }
        
        if (preg_match ('/^[A-Z \'.-]{2,40}$/i', $_POST['last_name'])) {
            $ln  = addslashes($_POST['last_name']);
        } else {
            $shipping_errors['last_name'] = 'Please enter your last name!';
        }

        if (get_magic_quotes_gpc()) {
            $_POST['first_name'] = stripslashes($_POST['first_name']);
            // Repeat for other variables that could be affected.
        }

        if (preg_match ('/^[A-Z0-9 \',.#-]{2,80}$/i', $_POST['address1'])) {
            $a1  = addslashes($_POST['address1']);
        } else {
            $shipping_errors['address1'] = 'Please enter your street address!';
        }
        
        if (empty($_POST['address2'])) {
            $a2 = NULL;
        } elseif (preg_match ('/^[A-Z0-9 \',.#-]{2,80}$/i', $_POST['address2'])) {
            $a2 = addslashes($_POST['address2']);
        } else {
            $shipping_errors['address2'] = 'Please enter your street address!';
        }

        if (preg_match ('/^[A-Z \'.-]{2,60}$/i', $_POST['city'])) {
            $c = addslashes($_POST['city']);
        } else {
            $shipping_errors['city'] = 'Please enter your city!';
        }

        if (preg_match ('/^[A-Z]{2}$/', $_POST['state'])) {
            $s = $_POST['state'];
        } else {
            $shipping_errors['state'] = 'Please enter your state!';
        }

        if (preg_match ('/^(\d{5}$)|(^\d{5}-\d{4})$/', $_POST['zip'])) {
            $z = $_POST['zip'];
        } else {
            $shipping_errors['zip'] = 'Please enter your zip code!';
        }

        $phone = str_replace(array(' ', '-', '(', ')'), '', $_POST['phone']);
        
        if (preg_match ('/^[0-9]{10}$/', $phone)) {
            $p  = $phone;
        } else {
            $shipping_errors['phone'] = 'Please enter your phone number!';
        }

        if (filter_var($_POST['email'], FILTER_VALIDATE_EMAIL)) {
            $e = $_POST['email'];
            $_SESSION['email'] = $_POST['email'];
        } else {
            $shipping_errors['email'] = 'Please enter a valid email address!';
        }

        if (isset($_POST['use']) && ($_POST['use'] === 'Y')) {
            $_SESSION['shipping_for_billing'] = true;
            $_SESSION['cc_first_name']  = $_POST['first_name'];
            $_SESSION['cc_last_name']  = $_POST['last_name'];
            $_SESSION['cc_address']  = $_POST['address1'] . ' ' . $_POST['address2'];
            $_SESSION['cc_city'] = $_POST['city'];
            $_SESSION['cc_state'] = $_POST['state'];
            $_SESSION['cc_zip'] = $_POST['zip'];
        }

        if (empty($shipping_errors)) {
            $r = mysqli_query($dbc, "CALL add_customer('$e', '$fn', '$ln', '$a1', '$a2', '$c', '$s', $z, $p, @cid)");
            if ($r) {
                $r = mysqli_query($dbc, 'SELECT @cid');
                if (mysqli_num_rows($r) == 1) {
                    list($_SESSION['customer_id']) = mysqli_fetch_array($r);
                    $location = 'https://' . BASE_URL . 'billing.php';
                    header("Location: $location");
                    exit();
                }
            }
            
            trigger_error('Your order could not be processed due to a system error. We apologize for the inconvenience.');
        } // Errors occurred IF.
    } // End of REQUEST_METHOD IF.

    $page_title = 'Coffee - Checkout - Your Shipping Information';
    include('./includes/checkout_header.html');

    $r = mysqli_query($dbc, "CALL get_shopping_cart_contents('$uid')");

    if (mysqli_num_rows($r) > 0) {
        include('./views/checkout.html');
    } else { // Empty cart!
        include('./views/emptycart.html');
    }

    include('./includes/footer.html');
?>