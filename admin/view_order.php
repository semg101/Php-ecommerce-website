<?php
require('../includes/config.inc.php');

$page_title = 'View An Order';
include('./includes/header.html');

$order_id = false;
if (isset($_GET['oid']) && (filter_var($_GET['oid'], FILTER_VALIDATE_INT, array('min_range' => 1))) ) {
    $order_id = $_GET['oid'];
    $_SESSION['order_id'] = $order_id;
} elseif (isset($_SESSION['order_id']) && (filter_var($_SESSION['order_id'], FILTER_VALIDATE_INT, array('min_range' => 1))) ) {
    $order_id = $_SESSION['order_id'];
}

if (!$order_id) {
    echo '<h3>Error!</h3><p>This page has been accessed in error.</p>';
    include('./includes/footer.html');
    exit();
}

require(MYSQL);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
	$q = "SELECT customer_id, total, transaction_id FROM orders AS o JOIN transactions AS t ON (o.id=t.order_id AND t.type='auth_only' AND t.response_code=1) WHERE o.id=$order_id";
    $r = mysqli_query($dbc, $q);
    
    if (mysqli_num_rows($r) === 1) {
        list($customer_id, $order_total, $trans_id) = mysqli_fetch_array($r, MYSQL_NUM);

        if ($order_total > 0) {
        	require('../includes/vendor/anet_php_sdk/AuthorizeNet.php');
            $aim = new AuthorizeNetAIM(API_LOGIN_ID, TRANSACTION_KEY);

            $response = $aim->priorAuthCapture($trans_id, $order_total/100);

            $reason = addslashes($response->response_reason_text);
            $full_response = addslashes($response->response);
            $r = mysqli_query($dbc, "CALL add_transaction($order_id, '{$response->transaction_type}', $order_total, {$response->response_code}, '$reason', {$response->transaction_id}, '$full_response')");

            if ($response->approved) {
                $message = 'The payment has been made. You may now ship the order.';
                
                $q = "UPDATE order_contents SET ship_date=NOW() WHERE order_id=$order_id";
                $r = mysqli_query($dbc, $q);

                $q = 'UPDATE specific_coffees AS sc, order_contents AS oc SET sc.stock=sc.stockoc.quantity WHERE sc.id=oc.product_id AND oc.product_type="coffee" AND oc.order_id='. $order_id;
                $r = mysqli_query($dbc, $q);
                
                $q = 'UPDATE non_coffee_products AS ncp, order_contents AS oc SET ncp.stock=ncp.stock-oc.quantity WHERE ncp.id=oc.product_id AND oc.product_type="goodies" AND oc.order_id=' . $order_id;
                $r = mysqli_query($dbc, $q);
            } else { // Do different things based upon the response:
                $error = 'The payment could not be processed because: ' . $response->response_reason_text;
            } // End of payment response IF-ELSE.
        } else { // Invalid order total!
            $error = "The order total (\$$order_total) is invalid.";
        } // End of $order_total IF-ELSE.
    } else { // No matching order!
        $error = 'No matching order could be found.';
    } // End of transaction ID IF-ELSE.

    echo '<h3>Order Shipping Results</h3>';
    if (isset($message)) echo "<p>$message</p>";
    if (isset($error)) echo "<p class=\"error\">$error</p>";
} // End of the submission IF.

$q = 'SELECT FORMAT(total/100, 2) AS total, FORMAT (shipping/100,2) AS shipping,
credit_card_number, DATE_FORMAT(order_date, "%a %b %e, %Y at %h:%i%p") AS od, email,
CONCAT(last_name, ", ", first_name) AS name, CONCAT_WS(" ", address1, address2,
city, state, zip) AS address, phone, customer_id, CONCAT_WS(" - ", ncc.category,
ncp.name) AS item, ncp.stock, quantity, FORMAT(price_per/100,2) AS price_per,
DATE_FORMAT(ship_date, "%b %e, %Y") AS sd FROM orders AS o INNER JOIN customers AS c
ON (o.customer_id = c.id) INNER JOIN order_contents AS oc ON (oc.order_id = o.id)
INNER JOIN non_coffee_products AS ncp ON (oc.product_id = ncp.id AND
oc.product_type="goodies") INNER JOIN non_coffee_categories AS ncc ON (ncc.id =
ncp.non_coffee_category_id) WHERE o.id=' . $order_id . '
UNION
SELECT FORMAT(total/100, 2), FORMAT(shipping/100,2), credit_card_number,
DATE_FORMAT(order_date, "%a %b %e, %Y at %l:%i%p"), email, CONCAT(last_name, ", ",
first_name), CONCAT_WS(" ", address1, address2, city, state, zip), phone,
customer_id, CONCAT_WS(" - ", gc.category, s.size, sc.caf_decaf, sc.ground_whole) AS
item, sc.stock, quantity, FORMAT(price_per/100,2), DATE_FORMAT(ship_date, "%b %e,
%Y") FROM orders AS o INNER JOIN customers AS c ON (o.customer_id = c.id) INNER JOIN
order_contents AS oc ON (oc.order_id = o.id) INNER JOIN specific_coffees AS sc ON
(oc.product_id = sc.id AND oc.product_type="coffee") INNER JOIN sizes AS s ON
(s.id=sc.size_id) INNER JOIN general_coffees AS gc ON (gc.id=sc.general_coffee_id)
WHERE o.id=' . $order_id;

$r = mysqli_query($dbc, $q);

if (mysqli_num_rows($r) > 0) {
    echo '<h3>View an Order</h3>
        <form action="view_order.php" method="post" accept-charset="utf-8">
        <fieldset>';

    $row = mysqli_fetch_array($r, MYSQLI_ASSOC);

    echo '<p><strong>Order ID</strong>: ' . $order_id . '<br />
        <strong>Total</strong>: $' . $row['total'] . '<br />
        <strong>Shipping</strong>: $' . $row['shipping'] . '<br/>
        <strong>Order Date</strong>: ' . $row['od'] . '<br />
        <strong>Customer Name</strong>: ' . htmlspecialchars($row['name']) . '<br />
        <strong>Customer Address</strong>: ' . htmlspecialchars($row['address']) . '<br />
        <strong>Customer Email</strong>: ' . htmlspecialchars($row['email']) . '<br />
        <strong>Customer Phone</strong>: ' . htmlspecialchars($row['phone']) . '<br />
        <strong>Credit Card Number Used</strong>: *' . $row['credit_card_number'] . '</p>';

    echo '<table border="0" width="100%" cellspacing="8" cellpadding="6">
        <thead>
            <tr>
                <th align="center">Item</th>
                <th align="right">Price Paid</th>
                <th align="center">Quantity in Stock</th>
                <th align="center">Quantity Ordered</th>
                <th align="center">Shipped?</th>
            </tr>
        </thead>
        <tbody>';

    $shipped = true;

    do {
        echo '<tr>
            <td align="left">' . $row['item'] . '</td>
            <td align="right">' . $row['price_per'] . '</td>
            <td align="center">' . $row['stock'] . '</td>
            <td align="center">' . $row['quantity'] . '</td>
            <td align="center">' . $row['sd'] . '</td>
            </tr>';
        if (!$row['sd']) $shipped = false;
    } while ($row = mysqli_fetch_array($r));
    
    echo '</tbody></table>';

    if (!$shipped) {
        echo '<div class="field">
                <p class="error">Note that actual payments will be collected once you click this button!</p>
                <input type="submit" value="Ship This Order" class="button" />
            </div>';
    }

    echo '</fieldset> </form>';
} else {
    echo '<h3>Error!</h3><p>This page has been accessed in error.</p>';
    include('./includes/footer.html');
    exit();
}

include('./includes/footer.html');
?>
