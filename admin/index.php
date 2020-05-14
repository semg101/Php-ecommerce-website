<?php
require('../includes/config.inc.php');

$page_title = 'Coffee - Administration';
include('./includes/header.html');

?>
<h3>Links</h3>
<ul>
<li><a href="add_specific_coffees.php">Add Coffee Products</a></li>
<li><a href="add_other_products.php">Add Non-Coffee Products</a></li>
<li><a href="add_inventory.php">Add Inventory</a></li>
</ul>

<?php include('./includes/footer.html'); ?>