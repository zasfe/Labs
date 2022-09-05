<?php

// 이미지 데이터를 가져와서 base64 인코딩으로 변환 후 반환
function getImageData($imgLink){
    $curl = curl_init();
//    curl_setopt($curl, CURLOPT_PROXY, "proxy사용할경우:포트");
    curl_setopt($curl, CURLOPT_URL, $imgLink);
    curl_setopt($curl, CURLOPT_REFERER, '');
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
    $img = curl_exec($curl);
    curl_close($curl);
    return base64_encode($img);
}


// 이미지 링크에서 이미지의 확장자를 읽어  mime type 형태로 반환
function getHeader($img){

    $extArr = array(
        'jpg' => 'image/jpg',
        'gif' => 'image/gif',
        'bmp' => 'image/bmp',
        'png' => 'image/png'
    );

    $ext = strtolower(substr($img, strrpos($img, '.')+1));
    return $extArr[$ext];
}



// 이미지 링크
$img = 'https://www.aaa.com/image.png';

// base64 데이터 가져오기
$imgBase64 = getImageData($img);

// mime type 가져오기
$imgData = getHeader($img);


//    ip
echo "$_SERVER['SERVER_ADDR'] <br>";

echo "$imgBase64 <br>";

// 이미지 출력
echo '<img src="data:'.$imgData.';base64,'.$imgBase64.'" />';

?>

