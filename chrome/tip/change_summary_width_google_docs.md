# 구글 문서내 개요 너비 변경용 즐겨찾기 생성 방법

1. 크롬을 실행합니다.
2. 사용할 즐겨찾기를 만듭니다.(나중에 수정할거라 대충만듭니다.)
3. 2번에 만든 "즐겨찾기" 마우스 우측 버튼을 누르고 "수정" 메뉴를 선택합니다.
4. URL 부분에 아래 문구를 입력합니다.

```
javascript:function unify(w){w.document.querySelector('.left-sidebar-container.docs-ui-unprintable.left-sidebar-container-animation').style.width='400px';w.document.querySelector('.navigation-widget.navigation-widget-unified-styling.docs-material.navigation-widget-floating-navigation-button.navigation-location-indicator.outline-refresh.navigation-widget-hoverable.left-sidebar-container-content-child').style.width='400px';}; unify(self);
```

5. 구글 문서 파일을 열고, 2번에 만든 "즐겨찾기"를 클릭합니다.(가로 길이 400으로 변경)
- 다른 길이로 변경하려는 경우 4번 자바스크립트 문구 중 400px 부분을 수정합니다.
