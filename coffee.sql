-- phpMyAdmin SQL Dump
-- version 4.5.1
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: Aug 01, 2017 at 06:42 PM
-- Server version: 10.1.9-MariaDB
-- PHP Version: 5.6.15

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `coffee`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_customer` (`e` VARCHAR(80), `f` VARCHAR(20), `l` VARCHAR(40), `a1` VARCHAR(80), `a2` VARCHAR(80), `c` VARCHAR(60), `s` CHAR(2), `z` MEDIUMINT, `p` INT, OUT `cid` INT)  BEGIN
INSERT INTO customers (email, first_name, last_name, address1, address2, city,
state, zip, phone) VALUES (e, f, l, a1, a2, c, s, z, p);
SELECT LAST_INSERT_ID() INTO cid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_order` (`cid` INT, `uid` CHAR(32), `ship` INT(10), `cc` MEDIUMINT, OUT `total` INT(10), OUT `oid` INT)  BEGIN
DECLARE subtotal INT(10);
INSERT INTO orders (customer_id, shipping, credit_card_number, order_date) VALUES
(cid, ship, cc, NOW());
SELECT LAST_INSERT_ID() INTO oid;
INSERT INTO order_contents (order_id, product_type, product_id, quantity,
price_per) SELECT oid, c.product_type, c.product_id, c.quantity, IFNULL(sales.price,
ncp.price) FROM carts AS c INNER JOIN non_coffee_products AS ncp ON
c.product_id=ncp.id LEFT OUTER JOIN sales ON (sales.product_id=ncp.id AND
sales.product_type='goodies' AND ((NOW() BETWEEN sales.start_date AND sales.end_date)
OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE
c.product_type="goodies" AND c.user_session_id=uid UNION SELECT oid, c.product_type,
c.product_id, c.quantity, IFNULL(sales.price, sc.price) FROM carts AS c INNER JOIN
specific_coffees AS sc ON c.product_id=sc.id LEFT OUTER JOIN sales ON
(sales.product_id=sc.id AND sales.product_type='coffee' AND ((NOW() BETWEEN
sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date
IS NULL)) ) WHERE c.product_type="coffee" AND c.user_session_id=uid;
SELECT SUM(quantity*price_per) INTO subtotal FROM order_contents WHERE
order_id=oid;
UPDATE orders SET total = (subtotal + ship) WHERE id=oid;
SELECT (subtotal + ship) INTO total;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_to_cart` (`uid` CHAR(32), `type` VARCHAR(7), `pid` MEDIUMINT, `qty` TINYINT)  BEGIN
DECLARE cid INT;
SELECT id INTO cid FROM carts WHERE user_session_id=uid AND product_type=type AND
product_id=pid;
IF (cid > 0) THEN
UPDATE carts SET quantity=quantity+qty, date_modified=NOW() WHERE id=cid;
ELSE
INSERT INTO carts (user_session_id, product_type, product_id, quantity) VALUES
(uid, type, pid, qty);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_to_wish_list` (`uid` CHAR(32), `type` VARCHAR(7), `pid` MEDIUMINT, `qty` TINYINT)  BEGIN
DECLARE cid INT;
SELECT id INTO cid FROM carts WHERE user_session_id=uid AND product_type=type AND
product_id=pid;
IF cid > 0 THEN
UPDATE carts SET quantity=quantity+qty, date_modified=NOW() WHERE id=cid;
ELSE
INSERT INTO carts (user_session_id, product_type, product_id, quantity) VALUES
(uid, type, pid, qty);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_transaction` (`oid` INT, `trans_type` VARCHAR(18), `amt` INT(10), `rc` TINYINT, `rrc` TINYTEXT, `tid` BIGINT, `r` TEXT)  BEGIN
INSERT INTO transactions VALUES (NULL, oid, trans_type, amt, rc, rrc, tid, r,
NOW());
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_cart` (`uid` CHAR(32))  BEGIN
DELETE FROM carts WHERE user_session_id=uid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_order_contents` (`oid` INT)  BEGIN
SELECT oc.quantity, oc.price_per,
(oc.quantity*oc.price_per) AS subtotal, ncc.category, ncp.name,
o.total, o.shipping
FROM order_contents AS oc
INNER JOIN non_coffee_products AS ncp ON oc.product_id=ncp.id
INNER JOIN non_coffee_categories AS ncc
ON ncc.id=ncp.non_coffee_category_id
INNER JOIN orders AS o ON oc.order_id=o.id
WHERE oc.product_type="goodies" AND oc.order_id=oid
UNION
SELECT oc.quantity, oc.price_per, (oc.quantity*oc.price_per),
gc.category,
CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole),
o.total, o.shipping
FROM order_contents AS oc
INNER JOIN specific_coffees AS sc ON oc.product_id=sc.id
INNER JOIN sizes AS s ON s.id=sc.size_id
INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id
INNER JOIN orders AS o ON oc.order_id=o.id
WHERE oc.product_type="coffee" AND oc.order_id=oid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_shopping_cart_contents` (`uid` CHAR(32))  BEGIN
SELECT CONCAT("G", ncp.id) AS sku, c.quantity, ncc.category,
ncp.name, ncp.price, ncp.stock, sales.price AS sale_price
FROM carts AS c
INNER JOIN non_coffee_products AS ncp ON c.product_id=ncp.id
INNER JOIN non_coffee_categories AS ncc
ON ncc.id=ncp.non_coffee_category_id
LEFT OUTER JOIN sales
ON (sales.product_id=ncp.id AND sales.product_type='goodies'
AND ((NOW() BETWEEN sales.start_date AND sales.end_date)
OR (NOW() > sales.start_date AND sales.end_date IS NULL)) )
WHERE c.product_type="goodies" AND c.user_session_id=uid
UNION
SELECT CONCAT("C", sc.id), c.quantity, gc.category,
CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole), sc.price,
sc.stock, sales.price
FROM carts AS c
INNER JOIN specific_coffees AS sc ON c.product_id=sc.id
INNER JOIN sizes AS s ON s.id=sc.size_id
INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id
LEFT OUTER JOIN sales
ON (sales.product_id=sc.id AND sales.product_type='coffee'
AND ((NOW() BETWEEN sales.start_date AND sales.end_date)
OR (NOW() > sales.start_date AND sales.end_date IS NULL)) )
WHERE c.product_type="coffee" AND c.user_session_id=uid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `remove_from_cart` (`uid` CHAR(32), `type` VARCHAR(7), `pid` MEDIUMINT)  BEGIN
DELETE FROM carts WHERE user_session_id=uid AND product_type=type AND
product_id=pid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `remove_from_wish_list` (`uid` CHAR(32), `type` VARCHAR(7), `pid` MEDIUMINT)  BEGIN
DELETE FROM carts WHERE user_session_id=uid AND product_type=type AND
product_id=pid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `select_categories` (`type` VARCHAR(7))  BEGIN 
IF (type = 'coffee') THEN
SELECT * FROM general_coffees ORDER by category;
ELSEIF (type = 'goodies') THEN
SELECT * FROM non_coffee_categories ORDER by category;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_cart` (`uid` CHAR(32), `type` VARCHAR(7), `pid` MEDIUMINT, `qty` TINYINT)  BEGIN
IF (qty > 0) THEN
UPDATE carts SET quantity=qty, date_modified=NOW() WHERE user_session_id=uid AND
product_type=type AND product_id=pid;
ELSEIF (qty = 0) THEN
CALL remove_from_cart (uid, type, pid);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_wish_list_contents` (IN `uid` CHAR(32))  BEGIN
SELECT CONCAT("G", ncp.id) AS sku, c.quantity, ncc.category,
ncp.name, ncp.price, ncp.stock, sales.price AS sale_price
FROM carts AS c
INNER JOIN non_coffee_products AS ncp ON c.product_id=ncp.id
INNER JOIN non_coffee_categories AS ncc
ON ncc.id=ncp.non_coffee_category_id
LEFT OUTER JOIN sales
ON (sales.product_id=ncp.id AND sales.product_type='goodies'
AND ((NOW() BETWEEN sales.start_date AND sales.end_date)
OR (NOW() > sales.start_date AND sales.end_date IS NULL)) )
WHERE c.product_type="goodies" AND c.user_session_id=uid
UNION
SELECT CONCAT("C", sc.id), c.quantity, gc.category,
CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole), sc.price,
sc.stock, sales.price
FROM carts AS c
INNER JOIN specific_coffees AS sc ON c.product_id=sc.id
INNER JOIN sizes AS s ON s.id=sc.size_id
INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id
LEFT OUTER JOIN sales
ON (sales.product_id=sc.id AND sales.product_type='coffee'
AND ((NOW() BETWEEN sales.start_date AND sales.end_date)
OR (NOW() > sales.start_date AND sales.end_date IS NULL)) )
WHERE c.product_type="coffee" AND c.user_session_id=uid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `select_products` (IN `type` VARCHAR(7), IN `cat` TINYINT)  BEGIN
IF (type = 'coffee') THEN
SELECT gc.description, gc.image, CONCAT("C", sc.id) AS sku,
CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole,
CONCAT("$", FORMAT(sc.price/100, 2))) AS name, sc.stock, sc.price, sales.price AS sale_price
FROM specific_coffees AS sc
INNER JOIN sizes AS s ON s.id=sc.size_id
INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id
LEFT OUTER JOIN sales ON (sales.product_id=sc.id
AND sales.product_type='coffee' AND
((NOW() BETWEEN sales.start_date AND sales.end_date)
OR (NOW() > sales.start_date AND sales.end_date IS NULL)) )
WHERE general_coffee_id=cat AND stock>0
ORDER by name ASC;
ELSEIF (type = 'goodies') THEN
SELECT ncc.description AS g_description, ncc.image AS g_image,
CONCAT("G", ncp.id) AS sku, ncp.name, ncp.description, ncp.image, ncp.price, ncp.stock, sales.price AS sale_price
FROM non_coffee_products AS ncp
INNER JOIN non_coffee_categories AS ncc
ON ncc.id=ncp.non_coffee_category_id
LEFT OUTER JOIN sales ON (sales.product_id=ncp.id
AND sales.product_type='goodies' AND
((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND
sales.end_date IS NULL)) )
WHERE non_coffee_category_id=cat
ORDER by date_created DESC;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `select_sale_items` (IN `get_all` BOOLEAN)  BEGIN
IF get_all = 1 THEN
SELECT CONCAT("G", ncp.id) AS sku, CONCAT("$",
FORMAT(sa.price/100, 2)) AS sale_price, ncc.category,
ncp.image, ncp.name, CONCAT("$", FORMAT(ncp.price/100, 2))
AS price, ncp.stock, ncp.description
FROM sales AS sa
INNER JOIN non_coffee_products AS ncp
ON sa.product_id=ncp.id
INNER JOIN non_coffee_categories AS ncc
ON ncc.id=ncp.non_coffee_category_id
WHERE sa.product_type="goodies" AND
((NOW() BETWEEN sa.start_date AND sa.end_date) OR
(NOW() > sa.start_date AND sa.end_date IS NULL) )
UNION
SELECT CONCAT("C", sc.id), CONCAT("$", FORMAT(sa.price/100,
2)), gc.category, gc.image, CONCAT_WS(" - ", s.size,
sc.caf_decaf, sc.ground_whole), CONCAT("$",
FORMAT(sc.price/100, 2)), sc.stock, gc.description
FROM sales AS sa
INNER JOIN specific_coffees AS sc
ON sa.product_id=sc.id
INNER JOIN sizes AS s ON s.id=sc.size_id
INNER JOIN general_coffees AS gc
ON gc.id=sc.general_coffee_id
WHERE sa.product_type="coffee" AND
((NOW() BETWEEN sa.start_date AND sa.end_date) OR
(NOW() > sa.start_date AND sa.end_date IS NULL) );
ELSE
(SELECT CONCAT("G", ncp.id) AS sku, CONCAT("$",
FORMAT(sa.price/100, 2)) AS sale_price, ncc.category,
ncp.image, ncp.name
FROM sales AS sa
INNER JOIN non_coffee_products AS ncp
ON sa.product_id=ncp.id
INNER JOIN non_coffee_categories AS ncc
ON ncc.id=ncp.non_coffee_category_id
WHERE sa.product_type="goodies" AND
((NOW() BETWEEN sa.start_date AND sa.end_date) OR
(NOW() > sa.start_date AND sa.end_date IS NULL) )
ORDER BY RAND() LIMIT 2)
UNION
(SELECT CONCAT("C", sc.id), CONCAT("$",
FORMAT(sa.price/100, 2)), gc.category, gc.image,
CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole)
FROM sales AS sa
INNER JOIN specific_coffees AS sc
ON sa.product_id=sc.id
INNER JOIN sizes AS s ON s.id=sc.size_id
INNER JOIN general_coffees AS gc
ON gc.id=sc.general_coffee_id
WHERE sa.product_type="coffee" AND
((NOW() BETWEEN sa.start_date AND sa.end_date) OR
(NOW() > sa.start_date AND sa.end_date IS NULL) )
ORDER BY RAND() LIMIT 2);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_wish_list` (`uid` CHAR(32), `type` VARCHAR(7), `pid` MEDIUMINT, `qty` TINYINT)  BEGIN
IF (qty > 0) THEN
UPDATE carts SET quantity=qty, date_modified=NOW() WHERE user_session_id=uid AND
product_type=type AND product_id=pid;
ELSEIF qty = 0 THEN
CALL remove_from_wish_list (uid, type, pid);
END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `carts`
--

CREATE TABLE `carts` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_session_id` char(32) NOT NULL,
  `product_type` enum('coffee','goodies') NOT NULL,
  `product_id` mediumint(8) UNSIGNED NOT NULL,
  `quantity` tinyint(3) UNSIGNED NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modified` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `carts`
--

INSERT INTO `carts` (`id`, `user_session_id`, `product_type`, `product_id`, `quantity`, `date_created`, `date_modified`) VALUES
(1, 'a04ce778b0dea3398708e6d61e7754cb', 'goodies', 1, 1, '2017-07-19 19:50:17', '0000-00-00 00:00:00'),
(2, '3e0a23c79a73dc3a0750cefb3ce58127', 'goodies', 2, 1, '2017-07-19 19:52:44', '0000-00-00 00:00:00'),
(3, 'b94409ef4633f67419aaac120e175bcf', 'coffee', 9, 1, '2017-07-19 20:05:05', '0000-00-00 00:00:00'),
(4, 'a01bd24fc2142b2a58c0b54acac750f1', 'goodies', 1, 1, '2017-07-24 13:30:41', '0000-00-00 00:00:00'),
(6, '99b9b362dea7af73bc26d94c254f807b', 'coffee', 7, 1, '2017-07-24 13:32:05', '0000-00-00 00:00:00'),
(8, '42c292038e01adcc3e03c304df4d07fa', 'coffee', 7, 1, '2017-07-24 13:38:41', '0000-00-00 00:00:00'),
(9, '657dba21135f4cd4055527fb15c8bb4c', 'coffee', 7, 1, '2017-07-24 13:39:18', '0000-00-00 00:00:00'),
(10, 'd49acce737e594247f0fbdc46e70f5e1', 'coffee', 7, 1, '2017-07-24 13:40:04', '0000-00-00 00:00:00'),
(11, '5ef741ed4b30127818c0baf58415cc41', 'goodies', 1, 1, '2017-07-26 17:20:55', '0000-00-00 00:00:00'),
(13, '52c9b1f72d09d61da03db36a3418558b', 'coffee', 10, 1, '2017-07-26 19:02:58', '0000-00-00 00:00:00'),
(14, '93c7bb2fb19e868f12ee2eb8bd33ebbb', 'goodies', 1, 1, '2017-07-26 19:46:19', '0000-00-00 00:00:00'),
(15, 'e308bb4a5cd88230fa6cd00440e10ed4', 'goodies', 1, 1, '2017-07-26 19:49:37', '0000-00-00 00:00:00'),
(16, '5f15416ae89dafb0fdaf96fcc5e8acee', 'goodies', 1, 1, '2017-07-26 19:50:58', '0000-00-00 00:00:00'),
(17, '269dcb8e3ee4090c66446e0ba7809f14', 'goodies', 1, 1, '2017-07-26 19:52:20', '0000-00-00 00:00:00'),
(18, 'e909e748744cf57f1777b1a8cc511877', 'goodies', 1, 1, '2017-07-26 19:53:54', '0000-00-00 00:00:00'),
(19, 'c7a103927e157f8280e1b8396cb74819', 'goodies', 1, 1, '2017-07-28 19:39:09', '0000-00-00 00:00:00'),
(20, 'c3b26a1d54d2e8896f55630678364b67', 'goodies', 1, 1, '2017-07-28 19:41:25', '0000-00-00 00:00:00'),
(34, 'lqttbcume8eflfruggg4ktu9m6', 'coffee', 9, 5, '2017-07-28 19:50:18', '2017-07-28 19:57:13'),
(35, 'lqttbcume8eflfruggg4ktu9m6', 'goodies', 1, 1, '2017-07-28 20:07:38', '0000-00-00 00:00:00'),
(36, 'rlm395qk8qvlm19dsdi5urptr1', 'goodies', 2, 3, '2017-07-28 20:08:35', '2017-07-28 20:10:09'),
(37, 'dq71f0ca0qdkije6v7k5sdh2i2', 'goodies', 2, 2, '2017-07-28 20:21:29', '2017-07-28 20:24:20'),
(38, 'e9t4eebqggt9c7ndfc944k09t1', 'coffee', 7, 1, '2017-07-28 20:26:03', '0000-00-00 00:00:00'),
(39, 'oku5j3f60k2qeabgnqkcjhnis7', 'goodies', 1, 1, '2017-07-28 20:26:42', '0000-00-00 00:00:00'),
(41, '1s63um37vcbtp5uonv9r3pii45', 'goodies', 2, 1, '2017-07-31 14:47:41', '2017-07-31 14:51:37'),
(47, '1s63um37vcbtp5uonv9r3pii45', 'coffee', 9, 1, '2017-07-31 14:50:34', '2017-07-31 14:51:37'),
(48, '1s63um37vcbtp5uonv9r3pii45', 'coffee', 10, 3, '2017-07-31 14:50:44', '2017-07-31 14:53:44'),
(51, '1s63um37vcbtp5uonv9r3pii45', 'coffee', 7, 1, '2017-07-31 14:54:19', '0000-00-00 00:00:00'),
(65, '13123bpto5tupeqilsphnl9k36', 'goodies', 1, 1, '2017-07-31 14:57:26', '0000-00-00 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `id` int(10) UNSIGNED NOT NULL,
  `email` varchar(80) NOT NULL,
  `first_name` varchar(20) NOT NULL,
  `last_name` varchar(40) NOT NULL,
  `address1` varchar(80) NOT NULL,
  `address2` varchar(80) DEFAULT NULL,
  `city` varchar(60) NOT NULL,
  `state` char(2) NOT NULL,
  `zip` mediumint(5) UNSIGNED ZEROFILL NOT NULL,
  `phone` char(10) NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `general_coffees`
--

CREATE TABLE `general_coffees` (
  `id` tinyint(3) UNSIGNED NOT NULL,
  `category` varchar(40) NOT NULL,
  `description` tinytext,
  `image` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `general_coffees`
--

INSERT INTO `general_coffees` (`id`, `category`, `description`, `image`) VALUES
(1, 'Original Blend', 'Our original blend, featuring a quality mixture of bean and a\r\nmedium roast for a rich color and smooth flavor.', 'original_coffee.jpg'),
(2, 'Dark Roast', 'Our darkest, non-espresso roast, with a full flavor and a slightly\r\nbitter aftertaste.', 'dark_roast.jpg'),
(3, 'Kona', 'A real treat! Kona coffee, fresh from the lush mountains of Hawaii. Smooth\r\nin flavor and perfectly roasted!', 'kona.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `non_coffee_categories`
--

CREATE TABLE `non_coffee_categories` (
  `id` tinyint(3) UNSIGNED NOT NULL,
  `category` varchar(40) NOT NULL,
  `description` tinytext NOT NULL,
  `image` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `non_coffee_categories`
--

INSERT INTO `non_coffee_categories` (`id`, `category`, `description`, `image`) VALUES
(1, 'Edibles', 'A wonderful assortment of goodies to eat. Includes biscotti, baklava,\r\nlemon bars, and more!', 'goodies.jpg'),
(2, 'Gift Baskets', 'Gift baskets for any occasion! Including our many coffees and\r\nother goodies.', 'gift_basket.jpg'),
(3, 'Mugs', 'A selection of lovely mugs for enjoying your coffee, tea, hot cocoa or\r\nother hot beverages.', '781426_32573620.jpg'),
(4, 'Books', 'Our recommended books about coffee, goodies, plus anything written by\r\nLarry Ullman!', 'books.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `non_coffee_products`
--

CREATE TABLE `non_coffee_products` (
  `id` mediumint(8) UNSIGNED NOT NULL,
  `non_coffee_category_id` tinyint(3) UNSIGNED NOT NULL,
  `name` varchar(60) NOT NULL,
  `description` tinytext,
  `image` varchar(45) NOT NULL,
  `price` int(10) UNSIGNED NOT NULL,
  `stock` mediumint(8) UNSIGNED NOT NULL DEFAULT '0',
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `non_coffee_products`
--

INSERT INTO `non_coffee_products` (`id`, `non_coffee_category_id`, `name`, `description`, `image`, `price`, `stock`, `date_created`) VALUES
(1, 3, 'Pretty Flower Coffee Mug', 'A pretty coffee mug with a flower design on a white\r\nbackground.', 'd9996aee5639209b3fb618b07e10a34b27baad12.jpg', 650, 115, '2017-07-08 20:22:32'),
(2, 3, 'Red Dragon Mug', 'An elaborate, painted gold dragon on a red background. With\r\npartially detached, fancy handle.', '847a1a3bef0fb5c2f2299b06dd63669000f5c6c4.jpg', 795, 14, '2017-07-08 20:22:32');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` int(10) UNSIGNED NOT NULL,
  `customer_id` int(10) UNSIGNED NOT NULL,
  `total` int(10) UNSIGNED DEFAULT NULL,
  `shipping` int(10) UNSIGNED NOT NULL DEFAULT '0',
  `credit_card_number` mediumint(4) UNSIGNED ZEROFILL NOT NULL,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `order_contents`
--

CREATE TABLE `order_contents` (
  `id` int(10) UNSIGNED NOT NULL,
  `order_id` int(10) UNSIGNED NOT NULL,
  `product_type` enum('coffee','goodies') DEFAULT NULL,
  `product_id` mediumint(8) UNSIGNED NOT NULL,
  `quantity` tinyint(3) UNSIGNED NOT NULL,
  `price_per` int(10) UNSIGNED NOT NULL,
  `ship_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `sales`
--

CREATE TABLE `sales` (
  `id` int(10) UNSIGNED NOT NULL,
  `product_type` enum('coffee','goodies') DEFAULT NULL,
  `product_id` mediumint(8) UNSIGNED NOT NULL,
  `price` int(10) UNSIGNED NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `sales`
--

INSERT INTO `sales` (`id`, `product_type`, `product_id`, `price`, `start_date`, `end_date`) VALUES
(1, 'goodies', 1, 500, '2017-07-07', '2017-08-31'),
(2, 'coffee', 7, 700, '2017-07-03', NULL),
(3, 'coffee', 9, 1300, '2017-07-02', '2017-08-26'),
(4, 'goodies', 2, 700, '2017-07-05', NULL),
(5, 'coffee', 8, 1300, '2017-07-08', '2017-08-31'),
(6, 'coffee', 10, 3000, '2017-07-03', '2017-09-30'),
(7, 'goodies', 1, 50000, '2017-08-09', NULL),
(8, 'goodies', 1, 50000, '2017-08-09', NULL),
(9, 'goodies', 1, 910, '2017-08-09', NULL),
(10, 'coffee', 7, 509, '2017-08-20', NULL),
(11, 'goodies', 1, 400, '2017-08-09', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `sizes`
--

CREATE TABLE `sizes` (
  `id` tinyint(3) UNSIGNED NOT NULL,
  `size` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `sizes`
--

INSERT INTO `sizes` (`id`, `size`) VALUES
(3, '1 lb.'),
(4, '2 lbs.'),
(1, '2 oz. Sample'),
(5, '5 lbs.'),
(2, 'Half Pound');

-- --------------------------------------------------------

--
-- Table structure for table `specific_coffees`
--

CREATE TABLE `specific_coffees` (
  `id` mediumint(8) UNSIGNED NOT NULL,
  `general_coffee_id` tinyint(3) UNSIGNED NOT NULL,
  `size_id` tinyint(3) UNSIGNED NOT NULL,
  `caf_decaf` enum('caf','decaf') DEFAULT NULL,
  `ground_whole` enum('ground','whole') DEFAULT NULL,
  `price` int(10) UNSIGNED NOT NULL,
  `stock` mediumint(8) UNSIGNED NOT NULL DEFAULT '0',
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `specific_coffees`
--

INSERT INTO `specific_coffees` (`id`, `general_coffee_id`, `size_id`, `caf_decaf`, `ground_whole`, `price`, `stock`, `date_created`) VALUES
(1, 3, 1, 'caf', 'ground', 200, 43, '2017-07-08 20:27:30'),
(2, 3, 2, 'caf', 'ground', 450, 54, '2017-07-08 20:27:30'),
(3, 3, 2, 'decaf', 'ground', 500, 35, '2017-07-08 20:27:30'),
(4, 3, 3, 'caf', 'ground', 800, 60, '2017-07-08 20:27:30'),
(5, 3, 3, 'decaf', 'ground', 850, 110, '2017-07-08 20:27:30'),
(6, 3, 3, 'caf', 'whole', 750, 140, '2017-07-08 20:27:30'),
(7, 3, 3, 'decaf', 'whole', 800, 90, '2017-07-08 20:27:30'),
(8, 3, 4, 'caf', 'whole', 1500, 86, '2017-07-08 20:27:30'),
(9, 3, 4, 'decaf', 'whole', 1550, 73, '2017-07-08 20:27:30'),
(10, 3, 5, 'caf', 'whole', 3250, 10, '2017-07-08 20:27:30'),
(11, 3, 1, 'caf', 'ground', 1000, 99, '2017-07-30 20:19:32'),
(12, 3, 1, 'caf', 'ground', 1000, 15, '2017-07-30 20:19:32'),
(13, 3, 1, 'caf', 'ground', 1000, 15, '2017-07-30 20:19:32'),
(14, 3, 1, 'caf', 'ground', 1000, 28, '2017-07-30 20:19:32'),
(15, 3, 1, 'caf', 'ground', 1000, 14, '2017-07-30 20:19:32'),
(16, 3, 1, 'caf', 'ground', 1000, 14, '2017-07-30 20:19:32'),
(17, 3, 1, 'caf', 'ground', 1000, 14, '2017-07-30 20:19:32'),
(18, 3, 1, 'caf', 'ground', 1000, 14, '2017-07-30 20:19:32'),
(19, 3, 1, 'caf', 'ground', 1000, 14, '2017-07-30 20:19:33'),
(20, 3, 1, 'caf', 'ground', 1000, 15, '2017-07-30 20:19:33');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` int(10) UNSIGNED NOT NULL,
  `order_id` int(10) UNSIGNED NOT NULL,
  `type` varchar(18) NOT NULL,
  `amount` int(10) UNSIGNED NOT NULL,
  `response_code` tinyint(1) UNSIGNED NOT NULL,
  `response_reason` tinytext,
  `transaction_id` bigint(20) UNSIGNED NOT NULL,
  `response` text NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `wish_lists`
--

CREATE TABLE `wish_lists` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_session_id` char(32) NOT NULL,
  `product_type` enum('coffee','goodies') DEFAULT NULL,
  `product_id` mediumint(8) UNSIGNED NOT NULL,
  `quantity` tinyint(3) UNSIGNED NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modified` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `carts`
--
ALTER TABLE `carts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_type` (`product_type`,`product_id`),
  ADD KEY `user_session_id` (`user_session_id`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `email` (`email`);

--
-- Indexes for table `general_coffees`
--
ALTER TABLE `general_coffees`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `type` (`category`);

--
-- Indexes for table `non_coffee_categories`
--
ALTER TABLE `non_coffee_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `category` (`category`);

--
-- Indexes for table `non_coffee_products`
--
ALTER TABLE `non_coffee_products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `non_coffee_category_id` (`non_coffee_category_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_date` (`order_date`),
  ADD KEY `customer_id` (`customer_id`);

--
-- Indexes for table `order_contents`
--
ALTER TABLE `order_contents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ship_date` (`ship_date`),
  ADD KEY `product_type` (`product_type`,`product_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `sales`
--
ALTER TABLE `sales`
  ADD PRIMARY KEY (`id`),
  ADD KEY `start_date` (`start_date`),
  ADD KEY `product_type` (`product_type`,`product_id`);

--
-- Indexes for table `sizes`
--
ALTER TABLE `sizes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `size` (`size`);

--
-- Indexes for table `specific_coffees`
--
ALTER TABLE `specific_coffees`
  ADD PRIMARY KEY (`id`),
  ADD KEY `general_coffee_id` (`general_coffee_id`),
  ADD KEY `size` (`size_id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `wish_lists`
--
ALTER TABLE `wish_lists`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_type` (`product_type`,`product_id`),
  ADD KEY `user_session_id` (`user_session_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `carts`
--
ALTER TABLE `carts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=66;
--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `general_coffees`
--
ALTER TABLE `general_coffees`
  MODIFY `id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `non_coffee_categories`
--
ALTER TABLE `non_coffee_categories`
  MODIFY `id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT for table `non_coffee_products`
--
ALTER TABLE `non_coffee_products`
  MODIFY `id` mediumint(8) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `order_contents`
--
ALTER TABLE `order_contents`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `sales`
--
ALTER TABLE `sales`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;
--
-- AUTO_INCREMENT for table `sizes`
--
ALTER TABLE `sizes`
  MODIFY `id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `specific_coffees`
--
ALTER TABLE `specific_coffees`
  MODIFY `id` mediumint(8) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;
--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `wish_lists`
--
ALTER TABLE `wish_lists`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
