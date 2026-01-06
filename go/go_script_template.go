/*usr/local/go/bin/go run "$0" "$@"; exit; */
// [설명 1] 위 라인은 '가짜 쉬뱅'입니다. 셸은 이를 실행 명령으로 인식하지만, 
// Go 포맷터(go fmt)와의 충돌을 피하기 위해 // 대신 /* */를 사용합니다 [1, 2].
// 마지막에 exit;를 붙여야 셸이 아래의 Go 코드를 셸 스크립트로 오해하여 읽는 것을 방지합니다 [3].
//
// https://lorentz.app/blog-item.html?id=go-shebang

package main

import (
    "fmt"
    "os"
)

func main() {
    // [설명 2] 작동 원리: 셸이 이 파일을 직접 실행하려다 ELF 형식이 아니고 
    // 표준 쉬뱅(#!)도 없어서 ENOEXEC(실행 형식 오류)을 내뱉으면, 
    // 셸은 이 파일을 셸 스크립트로 간주하고 한 줄씩 읽기 시작합니다 [4, 5].

    // [설명 3] 매개변수 활용:
    // "$0": 현재 실행 중인 파일의 경로를 Go 바이너리에 전달합니다 [6, 7].
    // "$@": 스크립트에 전달된 모든 인자(flags 등)를 Go 프로그램으로 넘깁니다 [3].

    fmt.Println("Hello, Go Scripting!")
    
    // 전달된 인자 확인 예시
    if len(os.Args) > 1 {
        fmt.Printf("전달된 인자: %v\n", os.Args[1:])
    }
}
