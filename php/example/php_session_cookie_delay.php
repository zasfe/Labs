<?php
session_start();

// 세션 설정
if (!isset($_SESSION['visit_count'])) {
    $_SESSION['visit_count'] = 1;
} else {
    $_SESSION['visit_count']++;
}

// 쿠키 설정
$cookie_name = "user_session";
$cookie_value = session_id();
setcookie($cookie_name, $cookie_value, time() + (86400 * 30), "/"); // 30일간 유지

// 파라미터로 숫자 입력받기
$delay = 0;
if (isset($_GET['delay'])) {
    $delay = intval($_GET['delay']);
    if ($delay < 0) {
        $delay = 0;
    }
}

// 지연 실행
if ($delay > 0) {
    sleep($delay);
}

// 서버 정보
$server_ip = $_SERVER['SERVER_ADDR'] ?? '알 수 없음';
$server_name = gethostname();
?>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>PHP 세션 및 쿠키 테스트</title>
</head>
<body>
    <h1>PHP 세션 및 쿠키 테스트 페이지</h1>
    <p>세션 방문 횟수: <?php echo $_SESSION['visit_count']; ?></p>
    <h2>쿠키 목록:</h2>
    <ul>
        <?php
        if (!empty($_COOKIE)) {
            foreach ($_COOKIE as $name => $value) {
                echo '<li>' . htmlspecialchars($name, ENT_QUOTES, 'UTF-8') . ': ' . htmlspecialchars($value, ENT_QUOTES, 'UTF-8') . '</li>';
            }
        } else {
            echo '<li>설정된 쿠키가 없습니다.</li>';
        }
        ?>
    </ul>
    <p>서버 이름: <?php echo htmlspecialchars($server_name, ENT_QUOTES, 'UTF-8'); ?></p>
    <p>서버 IP: <?php echo htmlspecialchars($server_ip, ENT_QUOTES, 'UTF-8'); ?></p>
    <form method="get" action="">
        <label for="delay">지연 시간 (초):</label>
        <input type="number" name="delay" id="delay" min="0">
        <button type="submit">전송</button>
    </form>
</body>
</html>
