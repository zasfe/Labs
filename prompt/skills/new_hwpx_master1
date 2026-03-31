---
name: new_hwpx_master
description: hwpx 공문/기안문 양식을 첨부하면 주제에 맞춰 공문 내용을 자동 작성
---

# HWPX 공문/기안문 자동 채우기 스킬

## 1단계: HWPX 파일 해제

```bash
mkdir -p hwpx_work && cd hwpx_work
cp 원본.hwpx 원본.zip
unzip -o 원본.zip -d original
```

해제 후 핵심 파일:
- Contents/section0.xml: 본문 (수정 대상)
- Contents/header.xml: 서식 정의
- mimetype, META-INF/, BinData/, Preview/: 수정하지 않음

## 2단계: section XML 분석

Contents/section0.xml을 파싱하여 공문 필드를 식별한다.

## 3단계: XML 수정

### ★★★ 가장 중요한 규칙: linesegarray 삭제 ★★★

텍스트를 수정한 <hp:p> 에서 반드시 <linesegarray> 자식 요소를 삭제해야 한다.

linesegarray는 원본 편집기가 저장한 "줄 배치 캐시"이다.
텍스트를 변경하면 이 캐시가 무효화되어 글자가 겹쳐 보이는 현상이 발생한다.
삭제하면 한컴오피스가 파일을 열 때 자동으로 줄 배치를 재계산한다.

```python
from lxml import etree
import copy

with open('original/Contents/section0.xml', 'rb') as f:
    tree = etree.parse(f)
root = tree.getroot()

# 텍스트를 수정한 모든 <hp:p>에서 linesegarray를 반드시 삭제
def remove_linesegarray(p_element):
    """수정된 문단에서 linesegarray를 삭제한다. 필수!"""
    for child in list(p_element):
        if etree.QName(child.tag).localname == 'linesegarray':
            p_element.remove(child)

# 텍스트 교체 예시
for elem in root.iter():
    local = etree.QName(elem.tag).localname
    if local == 't' and elem.text:
        if elem.text.strip() == '기존텍스트':
            elem.text = '새 텍스트'
            # ★ 반드시 해당 <hp:p>의 linesegarray를 삭제
            p = elem.getparent().getparent()
            remove_linesegarray(p)
```

### 안전하게 모든 수정된 문단 처리하는 방법

```python
# 수정 대상 <hp:p>를 추적
modified_paragraphs = set()

# 텍스트 수정 시마다 기록
def safe_set_text(t_element, new_text):
    """텍스트를 안전하게 변경하는 함수"""
    t_element.text = new_text
    # run -> p 순서로 올라가서 <hp:p> 찾기
    run = t_element.getparent()
    p = run.getparent()
    modified_paragraphs.add(id(p))
    # 즉시 linesegarray 삭제
    remove_linesegarray(p)

# 모든 수정이 끝난 후 최종 확인 (안전장치)
for elem in root.iter():
    local = etree.QName(elem.tag).localname
    if local == 'p':
        if id(elem) in modified_paragraphs:
            remove_linesegarray(elem)  # 이중 확인
```

### 절대 금지 사항
- 절대로 XML을 문자열(f-string, concat, replace)로 조합하지 않는다.
- 절대로 XML 선언(<?xml ...?>)을 수동으로 추가하지 않는다.
- 절대로 section0.xml 전체를 새로 작성하지 않는다.
- 절대로 .replace()나 re.sub()로 XML을 조작하지 않는다.

### 긴 텍스트 삽입 시 문단 분할

```python
def insert_multiline(parent, ref_p, texts):
    """ref_p를 복제하여 여러 문단으로 삽입. 각 문단의 linesegarray도 삭제."""
    p_index = list(parent).index(ref_p)

    # 첫 번째 텍스트: 원본 <hp:p>에 넣기
    for t in ref_p.iter():
        if etree.QName(t.tag).localname == 't':
            t.text = texts[0]
            break
    remove_linesegarray(ref_p)  # ★ 필수

    # 나머지: <hp:p> 복제 후 삽입
    for i, txt in enumerate(texts[1:], 1):
        new_p = copy.deepcopy(ref_p)
        for t in new_p.iter():
            if etree.QName(t.tag).localname == 't':
                t.text = txt
                break
        remove_linesegarray(new_p)  # ★ 필수
        parent.insert(p_index + i, new_p)
```

### XML 저장

```python
tree.write('original/Contents/section0.xml',
           xml_declaration=True,
           encoding=tree.docinfo.encoding or 'UTF-8',
           standalone=tree.docinfo.standalone)
```

## 4단계: HWPX 재패키징

```python
import zipfile, os

output_path = '결과물.hwpx'
with zipfile.ZipFile(output_path, 'w') as zf:
    # mimetype은 반드시 첫 번째, 비압축으로
    mimetype_path = os.path.join('original', 'mimetype')
    if os.path.exists(mimetype_path):
        zf.write(mimetype_path, 'mimetype', compress_type=zipfile.ZIP_STORED)
    for dirpath, dirnames, filenames in os.walk('original'):
        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            arcname = os.path.relpath(filepath, 'original')
            if arcname == 'mimetype':
                continue
            zf.write(filepath, arcname, compress_type=zipfile.ZIP_DEFLATED)
```

## 5단계: 검증

```python
from lxml import etree
import zipfile

with zipfile.ZipFile(output_path, 'r') as zf:
    assert zf.testzip() is None, "ZIP 손상"
    with zf.open('Contents/section0.xml') as f:
        tree = etree.parse(f)
    print("검증 완료")
```

## 6단계: 공문 작성 원칙

- 경어체 (합니다/습니다체)
- 두괄식 서술 (결론 → 배경 → 세부내용)
- 본문 순서: 목적/배경 → 세부 내용 → 요청/협조 사항 → 붙임
- 관용 표현: "~와 관련하여", "아래와 같이", "~하여 주시기 바랍니다"
