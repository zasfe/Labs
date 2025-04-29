<?php
// 모든 POST, GET, COOKIE, SERVER 변수를 출력하는 PHP 코드

echo "<h1>POST 데이터</h1>";
echo "<pre>";
print_r($_POST);
echo "</pre>";

echo "<h1>GET 데이터</h1>";
echo "<pre>";
print_r($_GET);
echo "</pre>";

echo "<h1>COOKIE 데이터</h1>";
echo "<pre>";
print_r($_COOKIE);
echo "</pre>";

echo "<h1>SERVER 데이터</h1>";
echo "<pre>";
print_r($_SERVER);
echo "</pre>";
?>
