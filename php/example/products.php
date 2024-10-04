<?php

error_reporting(E_ALL);
ini_set('display_errors', 'On');

$source = 'MySQL Server';
$database_name     = 'sample_db';
$database_user     = 'test_user';
$database_password = 'PASSWORD';
$mysql_host        = '10.24.28.17';

$pdo = new PDO('mysql:host=' . $mysql_host . '; dbname=' . $database_name, $database_user, $database_password);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$sql  = "SELECT * FROM products";
$stmt = $pdo->prepare($sql);
$stmt->execute();

while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
   $products[] = $row;
}

echo $_SERVER['SERVER_NAME']. ' <br>';
echo $source . ': <br>';
print_r($products);
?>
