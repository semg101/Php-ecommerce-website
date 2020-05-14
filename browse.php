<?php
    require('./includes/config.inc.php');

    $type = $sp_cat = $category = false; 

    if (isset($_GET['type'], $_GET['category'], $_GET['id']) && filter_var($_GET['id'],FILTER_VALIDATE_INT, array('min_range' => 1))) {
        $category = $_GET['category'];
        
        $sp_cat = $_GET['id'];
        
        if ($_GET['type'] === 'goodies') {
            $type = 'goodies';
        } elseif ($_GET['type'] === 'coffee') {
            $type = 'coffee';
        }

        if (!$type || !$sp_cat || !$category) {
            $page_title = 'Error!';
            include('./includes/header.html');
            include('./views/error.html');
            include('./includes/footer.html');
            exit();
        }

        $page_title = ucfirst($type) . ' to Buy::' . $category;
        include('./includes/header.html');
        

        require(MYSQL);
        $r = mysqli_query($dbc, "CALL select_products('$type', $sp_cat)");
        
        if (mysqli_num_rows($r) > 0) {
            if ($type === 'goodies') {
                include('./views/list_goodies.html');
            } elseif ($type === 'coffee') {
                include('./views/list_coffees.html'); 
            }
        } else { // Include the "noproducts" page:
            include('./views/noproducts.html');
        }
    }

    include('./includes/footer.html');
?>