<?php
    require('./includes/config.inc.php');

    $page_title = 'Coffee - Wouldn\'t You Love a Cup Right Now?';
    include('./includes/header.html');

    require(MYSQL);
    
    $r = mysqli_query($dbc, "CALL select_sale_items(false)");
    
    include('./views/home.html');
    
    include('./includes/footer.html');
?>