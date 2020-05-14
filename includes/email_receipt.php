<?php
$body_plain = "Thank you for your order. Your order number is
{$_SESSION['order_id']}. All orders are processed on the next business day. You will
be contacted in case of any delays.\n\n";

$body_html = file_get_contents('includes/plain_header.html');
$body_html .=  '<p>Thank you for your order. Your order number is ' .
$_SESSION['order_id'] . '. All orders are processed on the next business day. You
will be contacted in case of any delays.</p>
<table border="0" cellspacing="3" cellpadding="3">
<tr>
<th align="center">Item</th>
<th align="center">Quantity</th>
<th align="right">Price</th>
<th align="right">Subtotal</th>
</tr>';

$r = mysqli_query($dbc, "CALL get_order_contents({$_SESSION['order_id']})");
while ($row = mysqli_fetch_array($r, MYSQLI_ASSOC)) {
	$body_plain .= "{$row['category']}::{$row['name']} ({$row['quantity']}) @ \$" . number_format($row['price_per']/100, 2) . " each: $" .number_format($row['subtotal']/100, 2) . "\n";
    $body_html .= '<tr><td>' . $row['category'] . '::' . $row['name'] . '</td>
        <td align="center">' . $row['quantity'] . '</td>
        <td align="right">$' . number_format($row['price_per']/100, 2) . '</td>
        <td align="right">$' . number_format($row['subtotal']/100, 2) . '</td>
        </tr>';

    $shipping = number_format($row['shipping']/100, 2);
    $total = number_format($row['total']/100, 2);
} // End of WHILE loop.

mysqli_next_result($dbc);

$body_plain .= "Shipping: \$$shipping\n";
$body_html .= '<tr>
    <td colspan="2"> </td><th align="right">Shipping</th>
    <td align="right">$' . $shipping . '</td>
    </tr>';

$body_plain .= "Total: \$$total\n";
$body_html .= '<tr>
    <td colspan="2"> </td><th align="right">Total</th>
    <td align="right">$' . $total . '</td>
    </tr>';

$body_html .= '</table></body></html>';

require('includes/vendor/autoload.php');

use Zend\Mail;
use Zend\Mime\Message as MimeMessage;
use Zend\Mime\Part as MimePart;

$html = new MimePart($body_html);
$html->type = "text/html";
$plain = new MimePart($body_plain);
$plain->type = "text/plain";
$body = new MimeMessage();
$body->setParts(array($plain, $html));

$mail = new Mail\Message();
$mail->setFrom('admin@example.com');
$mail->addTo($_SESSION['email']);
$mail->setSubject("Order #{$_SESSION['order_id']} at the Coffee Site");
$mail->setEncoding("UTF-8");
$mail->setBody($body);
$mail->getHeaders()->get('content-type')->setType('multipart/alternative');

$transport = new Mail\Transport\Sendmail();
$transport->send($mail);