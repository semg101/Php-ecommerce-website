<?php
    require('./includes/config.inc.php');

    if (isset($_COOKIE['SESSION']) && (strlen($_COOKIE['SESSION']) === 32)) {
        $uid = $_COOKIE['SESSION'];
    } else {
        $uid = openssl_random_pseudo_bytes(16);
        $uid = bin2hex($uid);
    }

    //setcookie('SESSION', $uid, time()+(60*60*24*30), '/', 'www.example.com');
    setcookie('SESSION', $uid, time()+(60*60*24*30), '/', 'localhost');

    session_start();
    $uid = session_id();

    $page_title = 'Coffee - Your Shopping Cart';
    include('./includes/header.html');

    require (MYSQL);
    include('./includes/product_functions.inc.php');

    if (isset($_GET['sku'])) {
        list($type, $pid) = parse_sku($_GET['sku']);
    }

    if (isset($pid, $type, $_GET['action']) && ($_GET['action'] === 'add') ) {

        $r = mysqli_query($dbc, "CALL add_to_cart('$uid', '$type', $pid, 1)");
        if (!$r) echo mysqli_error($dbc);

    } elseif (isset($type, $pid, $_GET['action']) && ($_GET['action'] === 'remove') ) {

        $r = mysqli_query($dbc, "CALL remove_from_cart('$uid', '$type', $pid)");
        if (!$r) echo mysqli_error($dbc);

    } elseif (isset($type, $pid, $_GET['action'], $_GET['qty']) && ($_GET['action'] === 'move') ) {

        $qty = (filter_var($_GET['qty'], FILTER_VALIDATE_INT, array('min_range' => 1)) !== false) ? $_GET['qty'] : 1;
        $r = mysqli_query($dbc, "CALL add_to_cart('$uid', '$type', $pid, $qty)");
        $r = mysqli_query($dbc, "CALL remove_from_wish_list('$uid', '$type', $pid)");
        if (!$r) echo mysqli_error($dbc);

    } elseif (isset($_POST['quantity'])) {

    	foreach ($_POST['quantity'] as $sku => $qty) {

            list($type, $pid) = parse_sku($sku);

            if (isset($type, $pid)) {

                $qty = (filter_var($qty, FILTER_VALIDATE_INT, array('min_range' => 0)) !== false) ? $qty : 1;
                $r = mysqli_query($dbc, "CALL update_cart('$uid', '$type', $pid, $qty)");
                if (!$r) echo mysqli_error($dbc);
            }
        }
    }// End of main IF.
            
            $r = mysqli_query($dbc, "CALL get_shopping_cart_contents('$uid')");
            if (!$r) echo mysqli_error($dbc);

            if (mysqli_num_rows($r) > 0) {
                include('./views/cart.html');
            } else { // Empty cart!
                include('./views/emptycart.html');
            }

    include('./includes/footer.html');
?>