const GEMINI_MODEL = 'gemini-3.1-flash-lite';
const MAX_SIZE_MB = 50;
const MASTER_SHEET_NAME = '고객마스터';

// https://youtu.be/hnByrAAHEAs?si=ndOKEI1Mb9ktxBQc

function getFolderId() {
  const folderId = PropertiesService.getScriptProperties().getProperty('DRIVE_FOLDER_ID');
  if (!folderId) throw new Error('DRIVE_FOLDER_ID가 설정되지 않았습니다. 상단 메뉴 [⚙️ 기본 설정]을 통해 폴더 ID를 먼저 등록해주세요.');
  return folderId;
}

function getApiKey() {
  const key = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  if (!key) throw new Error('GEMINI_API_KEY가 설정되지 않았습니다. 상단 메뉴 [⚙️ 기본 설정]을 통해 API 키를 먼저 등록해주세요.');
  return key;
}

function getTargetSheetName() {
  const props = PropertiesService.getScriptProperties();
  return props.getProperty('TARGET_SHEET_NAME') || '';
}

function getTargetSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const targetName = getTargetSheetName();
  if (targetName) {
    const s = ss.getSheetByName(targetName);
    if (s) return s;
  }
  const historySheet = ss.getSheetByName('상담이력');
  if (historySheet) return historySheet;
  return ss.getActiveSheet();
}

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🎙️ 통화 요약 자동화')
    .addItem('⚙️ 기본 설정 (폴더 ID / API 키)', 'showSetupDialog')
    .addSeparator()
    .addItem('🎯 [현재 시트]를 상담이력 시트로 지정', 'setCurrentSheetAsTarget')
    .addItem('📊 추천 기본 탭 자동 생성 (상담이력 + 고객마스터)', 'initDefaultSheets')
    .addItem('📋 현재 대상 시트 1행(헤더) 검사', 'checkHeaderColumns')
    .addSeparator()
    .addItem('▶️ 지금 즉시 녹음 파일 처리 (1회)', 'processNewRecordings')
    .addItem('🧪 Gemini API 연결 즉시 테스트 (1초 확인)', 'testGeminiConnection')
    .addItem('🧹 테스트 데이터 초기화 및 시작 기준점 설정', 'resetTestDataAndSetBaseline')
    .addItem('⏰ 5분 주기 자동 실행 시작', 'installTrigger')
    .addItem('⏹️ 자동 실행 중지', 'removeTriggers')
    .addSeparator()
    .addItem('🔍 연결 및 시스템 점검 (주소록 포함)', 'checkStatus')
    .addToUi();
}

function testGeminiConnection() {
  const apiKey = getApiKey();
  const testUrl = 'https://generativelanguage.googleapis.com/v1beta/models/' + GEMINI_MODEL + ':generateContent?key=' + apiKey;
  const resp = UrlFetchApp.fetch(testUrl, {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify({
      contents: [{ parts: [{ text: '핑 테스트. 안녕하세요!' }] }]
    }),
    muteHttpExceptions: true
  });

  const code = resp.getResponseCode();
  const body = resp.getContentText();
  console.log('응답 코드: ' + code);
  console.log('응답 본문: ' + body);

  if (code === 200) {
    try {
      const data = JSON.parse(body);
      const reply = data.candidates && data.candidates[0].content.parts[0].text ? data.candidates[0].content.parts[0].text : '응답 성공';
      SpreadsheetApp.getUi().alert('API 연결 성공 (200 OK)', '설정된 모델: ' + GEMINI_MODEL + '\n\nGemini 응답 내용:\n' + reply, SpreadsheetApp.getUi().ButtonSet.OK);
    } catch (e) {
      SpreadsheetApp.getUi().alert('API 연결 성공', 'HTTP 200 OK\n\n' + body.slice(0, 300), SpreadsheetApp.getUi().ButtonSet.OK);
    }
  } else {
    SpreadsheetApp.getUi().alert('API 연결 실패 (' + code + ')', '구글 서버 에러 상세 메시지:\n\n' + body, SpreadsheetApp.getUi().ButtonSet.OK);
  }
}

function showSetupDialog() {
  const ui = SpreadsheetApp.getUi();
  const props = PropertiesService.getScriptProperties();

  const currentFolderId = props.getProperty('DRIVE_FOLDER_ID') || '';
  const currentKey = props.getProperty('GEMINI_API_KEY') || '';

  const folderResp = ui.prompt(
    '1/2. 구글 드라이브 폴더 ID 설정',
    '녹음 파일이 저장되는 구글 드라이브 폴더 ID를 입력하세요.\n(현재 설정: ' + (currentFolderId || '미설정') + ')',
    ui.ButtonSet.OK_CANCEL
  );
  if (folderResp.getSelectedButton() !== ui.Button.OK) return;
  const newFolderId = folderResp.getResponseText().trim();
  if (newFolderId) props.setProperty('DRIVE_FOLDER_ID', newFolderId);

  const keyResp = ui.prompt(
    '2/2. Gemini API 키 설정',
    'Google AI Studio에서 발급받은 Gemini API 키를 입력하세요.\n(현재 설정: ' + (currentKey ? '등록됨(' + currentKey.slice(0, 6) + '...)' : '미설정') + ')',
    ui.ButtonSet.OK_CANCEL
  );
  if (keyResp.getSelectedButton() !== ui.Button.OK) return;
  const newKey = keyResp.getResponseText().trim();
  if (newKey) props.setProperty('GEMINI_API_KEY', newKey);

  ui.alert(
    '기본 설정 완료',
    '드라이브 폴더 ID 및 API 키 설정이 성공적으로 저장되었습니다.\n\n• 커스텀 시트를 요약 저장 시트로 사용하시려면 해당 시트 탭을 열고 상단 메뉴의 [🎯 [현재 시트]를 상담이력 시트로 지정]을 클릭하세요.\n• 표준 기본 시트를 원하시면 [📊 추천 기본 탭 자동 생성]을 누르세요.',
    ui.ButtonSet.OK
  );
}

function setCurrentSheetAsTarget() {
  const ui = SpreadsheetApp.getUi();
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const activeSheet = ss.getActiveSheet();
  const sheetName = activeSheet.getName();

  if (sheetName === MASTER_SHEET_NAME) {
    const confirmResp = ui.alert(
      '확인 필요',
      '현재 활성 시트가 [' + MASTER_SHEET_NAME + ']입니다. 고객 정보 관리용 시트 대신 상담이력 요약 저장 시트로 지정하시겠습니까?',
      ui.ButtonSet.YES_NO
    );
    if (confirmResp !== ui.Button.YES) return;
  }

  PropertiesService.getScriptProperties().setProperty('TARGET_SHEET_NAME', sheetName);

  const headers = getHeaderList(activeSheet);
  if (headers.length > 0) {
    const names = headers.map(function(h) { return '• ' + h.name; }).join('\n');
    ui.alert(
      '상담이력 시트 지정 완료',
      '[' + sheetName + '] 시트가 통화 요약 저장 시트로 지정되었습니다.\n\n[감지된 1행 추출 항목 (' + headers.length + '개)]\n' + names + '\n\nAI가 녹음 분석 시 위 항목에 맞춰 자동으로 요약 및 데이터를 기록합니다.',
      ui.ButtonSet.OK
    );
  } else {
    ui.alert(
      '상담이력 시트 지정 완료 (헤더 필요)',
      '[' + sheetName + '] 시트가 통화 요약 저장 시트로 지정되었습니다.\n\n⚠️ 현재 시트 1행에 작성된 항목명(컬럼명)이 없습니다.\n1행에 추출하고 싶은 항목(예: 상담일시, 고객명, 연락처, 상담요약, 예산 등)을 자유롭게 적어두시면 AI가 맞춰 채워 넣습니다.',
      ui.ButtonSet.OK
    );
  }
}



function initDefaultSheets() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  let master = ss.getSheetByName(MASTER_SHEET_NAME);
  if (!master) {
    master = ss.insertSheet(MASTER_SHEET_NAME);
    master.appendRow(['전화번호', '이름', '최초상담일', '최근상담일', '상담횟수', '메모']);
    master.getRange(1, 1, 1, 6).setFontWeight('bold').setBackground('#4F46E5').setFontColor('#FFFFFF');
    master.setFrozenRows(1);
  }

  let history = ss.getSheetByName('상담이력');
  if (!history) {
    history = ss.insertSheet('상담이력');
    history.appendRow(['상담일시', '전화번호', '이름', '거래유형', '입주시기', '예산', '희망지역', '추가요청', '요약', '녹음링크', '전사내용', '처리일시']);
    history.getRange(1, 1, 1, 12).setFontWeight('bold').setBackground('#4F46E5').setFontColor('#FFFFFF');
    history.setFrozenRows(1);
  }

  SpreadsheetApp.getUi().alert(
    '시트 자동 생성 완료',
    '[상담이력] 및 [고객마스터] 탭이 생성되었습니다.\n\n• 상담이력 탭의 1행 컬럼명을 본인 업종에 맞게 자유롭게 수정하셔도 AI가 자동 인식합니다.',
    SpreadsheetApp.getUi().ButtonSet.OK
  );
}

function getHeaderList(sheet) {
  const lastCol = sheet.getLastColumn();
  if (lastCol < 1) return [];
  const rawHeaders = sheet.getRange(1, 1, 1, lastCol).getValues()[0];
  const headers = [];
  for (var i = 0; i < rawHeaders.length; i++) {
    const h = String(rawHeaders[i] || '').trim();
    if (h) headers.push({ colIndex: i + 1, name: h });
  }
  return headers;
}

function checkHeaderColumns() {
  const ui = SpreadsheetApp.getUi();
  const sheet = getTargetSheet();
  const headers = getHeaderList(sheet);

  if (headers.length === 0) {
    ui.alert(
      '헤더(1행) 없음',
      '[' + sheet.getName() + '] 시트의 1행에 추출하고 싶은 항목명(예: 상담일시, 고객명, 연락처, 상담요약 등)을 작성해주세요.\n또는 메뉴의 [추천 기본 탭 자동 생성]을 누르셔도 됩니다.',
      ui.ButtonSet.OK
    );
    return;
  }

  const names = headers.map(function(h) { return '• ' + h.name; }).join('\n');
  ui.alert(
    '감지된 추출 항목 (' + headers.length + '개)',
    '[' + sheet.getName() + '] 시트의 1행에서 다음 항목들을 감지했습니다:\n\n' + names + '\n\nAI가 녹음 분석 시 위 항목들에 맞춰 데이터를 자동으로 추출하여 채워 넣습니다.',
    ui.ButtonSet.OK
  );
}

function formatPhone(raw) {
  const d = String(raw).replace(/\D/g, '');
  if (d.length === 11) return d.slice(0, 3) + '-' + d.slice(3, 7) + '-' + d.slice(7);
  if (d.length === 10) return d.slice(0, 3) + '-' + d.slice(3, 6) + '-' + d.slice(6);
  return d;
}

function parseFileName(name) {
  const meta = { phone: '', date: '', contactName: '' };
  const baseName = name.replace(/\.[^.]+$/, '');

  const phoneMatch = baseName.match(/(\d{9,11})/);
  if (phoneMatch) {
    meta.phone = formatPhone(phoneMatch[1]);
  }

  const dateMatches = baseName.match(/(\d{6,8})[_-]?(\d{4,6})?/g);
  if (dateMatches) {
    for (const m of dateMatches) {
      const digits = m.replace(/\D/g, '');
      if (digits.length >= 10) {
        var year, month, day, hour, minute;
        if (digits.length >= 12) {
          var testYear = parseInt(digits.slice(0, 4));
          var testMonth = parseInt(digits.slice(4, 6));
          if (testYear > 2100 || testMonth > 12) {
            year = '20' + digits.slice(0, 2);
            month = digits.slice(2, 4);
            day = digits.slice(4, 6);
            hour = digits.slice(6, 8);
            minute = digits.slice(8, 10);
          } else {
            year = digits.slice(0, 4);
            month = digits.slice(4, 6);
            day = digits.slice(6, 8);
            hour = digits.slice(8, 10);
            minute = digits.slice(10, 12);
          }
        } else {
          year = '20' + digits.slice(0, 2);
          month = digits.slice(2, 4);
          day = digits.slice(4, 6);
          hour = digits.slice(6, 8);
          minute = digits.slice(8, 10);
        }
        meta.date = year + '-' + month + '-' + day;
        break;
      } else if (digits.length >= 6) {
        meta.date = '20' + digits.slice(0, 2) + '-' + digits.slice(2, 4) + '-' + digits.slice(4, 6);
      }
    }
  }

  if (!meta.phone) {
    const parts = baseName.split(/[_\-\s]+/);
    for (const part of parts) {
      if (!/^\d+$/.test(part) && part.length >= 2) {
        meta.contactName = part.trim();
        break;
      }
    }
  }

  return meta;
}

function lookupContactByName(name) {
  try {
    if (typeof People === 'undefined' || !People.People) return [];
    const resp = People.People.Connections.list('people/me', {
      personFields: 'names,phoneNumbers',
      pageSize: 1000
    });
    if (!resp.connections) return [];
    return resp.connections
      .filter(function(c) {
        return (c.names || []).some(function(n) {
          return n.displayName && n.displayName.includes(name);
        });
      })
      .map(function(c) {
        return {
          name: c.names[0].displayName,
          phones: (c.phoneNumbers || []).map(function(p) { return formatPhone(p.value.replace(/\D/g, '')); })
        };
      });
  } catch (e) {
    return [];
  }
}

function lookupContactByPhone(phone) {
  try {
    if (typeof People === 'undefined' || !People.People) return '';
    const clean = phone.replace(/\D/g, '');
    if (!clean) return '';
    const resp = People.People.Connections.list('people/me', {
      personFields: 'names,phoneNumbers',
      pageSize: 1000
    });
    if (!resp.connections) return '';
    for (var i = 0; i < resp.connections.length; i++) {
      const c = resp.connections[i];
      const numbers = (c.phoneNumbers || []).map(function(p) { return p.value.replace(/\D/g, ''); });
      if (numbers.includes(clean)) {
        return c.names && c.names[0] ? c.names[0].displayName : '';
      }
    }
    return '';
  } catch (e) {
    return '';
  }
}

function resolveContactInfo(fileMeta, analysis) {
  let phone = analysis.phone || fileMeta.phone || '';
  let name = analysis.customerName || analysis.name || analysis.고객명 || analysis.이름 || fileMeta.contactName || '';

  if (!phone && fileMeta.contactName) {
    const matched = lookupContactByName(fileMeta.contactName);
    if (matched.length > 0 && matched[0].phones.length > 0) {
      phone = matched[0].phones[0];
    }
  }

  if (!name && phone) {
    const contactName = lookupContactByPhone(phone);
    if (contactName) {
      name = contactName;
    } else {
      const ss = SpreadsheetApp.getActiveSpreadsheet();
      const master = ss.getSheetByName(MASTER_SHEET_NAME);
      if (master) {
        const data = master.getDataRange().getValues();
        const strPhone = String(phone);
        for (var i = 1; i < data.length; i++) {
          if (String(data[i][0]) === strPhone && data[i][1]) {
            name = String(data[i][1]);
            break;
          }
        }
      }
    }
  }

  return { phone: phone, name: name };
}

function findCustomerRow(masterSheet, phone) {
  const data = masterSheet.getDataRange().getValues();
  const strPhone = String(phone);
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === strPhone) return i + 1;
  }
  return -1;
}

function upsertCustomerMaster(phone, name, dateStr) {
  if (!phone) return;
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const master = ss.getSheetByName(MASTER_SHEET_NAME);
  if (!master) return;

  const row = findCustomerRow(master, phone);
  if (row > 0) {
    const cur = master.getRange(row, 1, 1, 6).getValues()[0];
    if (name && (!cur[1] || cur[1] === '미확인')) master.getRange(row, 2).setValue(name);
    master.getRange(row, 4).setValue(dateStr);
    master.getRange(row, 5).setValue((Number(cur[4]) || 0) + 1);
  } else {
    master.appendRow([phone, name || '', dateStr, dateStr, 1, '']);
  }
}

function analyzeCallWithDynamicHeaders(file, fileMeta, headerNames) {
  const blob = file.getBlob();
  const sizeMB = blob.getBytes().length / (1024 * 1024);
  if (sizeMB > MAX_SIZE_MB) throw new Error('파일 크기 ' + sizeMB.toFixed(1) + 'MB 초과');

  const mimeType = blob.getContentType();
  const apiKey = getApiKey();

  const uploadResp = UrlFetchApp.fetch(
    'https://generativelanguage.googleapis.com/upload/v1beta/files?uploadType=media&key=' + apiKey,
    { method: 'post', contentType: mimeType, payload: blob.getBytes(), muteHttpExceptions: true }
  );
  if (uploadResp.getResponseCode() !== 200) throw new Error('오디오 업로드 실패: ' + uploadResp.getContentText().slice(0, 300));

  let fileInfo = JSON.parse(uploadResp.getContentText()).file;

  var checkCount = 0;
  while (fileInfo && fileInfo.state === 'PROCESSING' && checkCount < 10) {
    Utilities.sleep(3000);
    checkCount++;
    try {
      const checkResp = UrlFetchApp.fetch('https://generativelanguage.googleapis.com/v1beta/' + fileInfo.name + '?key=' + apiKey, { muteHttpExceptions: true });
      if (checkResp.getResponseCode() === 200) {
        fileInfo = JSON.parse(checkResp.getContentText());
      }
    } catch (e) {}
  }
  if (fileInfo && fileInfo.state === 'FAILED') throw new Error('오디오 파일 처리 실패');

  const sttPrompt = '이 오디오의 대화 내용을 화자를 구분하여(예: 상담사/고객 또는 참석자별) 처음부터 끝까지 빠짐없이 전사해줘.';
  const sttResp = UrlFetchApp.fetch(
    'https://generativelanguage.googleapis.com/v1beta/models/' + GEMINI_MODEL + ':generateContent?key=' + apiKey,
    {
      method: 'post', contentType: 'application/json',
      payload: JSON.stringify({
        contents: [{ parts: [{ file_data: { mime_type: mimeType, file_uri: fileInfo.uri } }, { text: sttPrompt }] }],
        generationConfig: { temperature: 0.1, maxOutputTokens: 8192 }
      }),
      muteHttpExceptions: true
    }
  );

  try {
    UrlFetchApp.fetch('https://generativelanguage.googleapis.com/v1beta/' + fileInfo.name + '?key=' + apiKey, { method: 'delete', muteHttpExceptions: true });
  } catch (e) {}

  if (sttResp.getResponseCode() !== 200) throw new Error('Gemini 1단계(전사) 실패: ' + sttResp.getResponseCode() + ' ' + sttResp.getContentText().slice(0, 200));
  const sttData = JSON.parse(sttResp.getContentText());
  var transcript = sttData.candidates && sttData.candidates[0].content.parts[0].text ? sttData.candidates[0].content.parts[0].text : '';
  if (!transcript) throw new Error('전사 텍스트를 생성하지 못했습니다.');

  const fieldListStr = headerNames.map(function(h) { return '- ' + h; }).join('\n');
  const prompt = '다음 통화 녹음 전사본을 분석하여, 아래 요청된 항목별로 정보를 추출해 JSON 객체로 반환해주세요.\n\n'
    + '[전사 내용]\n' + transcript + '\n\n'
    + '[추출할 항목 목록]\n' + fieldListStr + '\n\n'
    + '## 추출 및 작성 규칙\n'
    + '1. 위에 나열된 각 항목명을 정확히 JSON의 Key로 사용하세요.\n'
    + '2. 통화 내용에서 파악된 정보를 각 항목에 맞게 충실히 채워넣으세요.\n'
    + '3. 통화에서 언급되지 않았거나 불확실한 항목은 빈 문자열("")로 반환하세요.\n'
    + '4. 요약/핵심내용 관련 항목은 1~2문장으로 명확히 요약하세요.\n'
    + '5. 날짜/시간 관련 항목은 식별 가능한 경우 YYYY-MM-DD HH:mm 형식으로 작성하세요.\n'
    + '6. 오직 단일 JSON 객체({ ... }) 형식으로만 응답하세요.';

  const jsonResp = UrlFetchApp.fetch(
    'https://generativelanguage.googleapis.com/v1beta/models/' + GEMINI_MODEL + ':generateContent?key=' + apiKey,
    {
      method: 'post', contentType: 'application/json',
      payload: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { response_mime_type: 'application/json', temperature: 0.1, maxOutputTokens: 8192 }
      }),
      muteHttpExceptions: true
    }
  );

  if (jsonResp.getResponseCode() !== 200) throw new Error('Gemini 2단계(정보추출) 실패: ' + jsonResp.getResponseCode() + ' ' + jsonResp.getContentText().slice(0, 200));
  var text = JSON.parse(jsonResp.getContentText()).candidates[0].content.parts[0].text;
  if (!text) throw new Error('정보 추출 응답이 비어있습니다.');

  try {
    var result = JSON.parse(text);
    result.__transcript = transcript;
    return result;
  } catch (e) {
    var fixed = text.replace(/[\x00-\x1F]/g, ' ');
    if (!fixed.endsWith('}')) {
      var lastQuote = fixed.lastIndexOf('"');
      if (lastQuote > 0) fixed = fixed.slice(0, lastQuote + 1) + '}';
    }
    try {
      var result = JSON.parse(fixed);
      result.__transcript = transcript;
      return result;
    } catch (e2) {
      throw new Error('JSON 파싱 실패: ' + text.slice(0, 300));
    }
  }
}

function processNewRecordings() {
  const folderId = getFolderId();
  if (!folderId) {
    console.error('❌ 폴더 ID가 설정되지 않았습니다.');
    return;
  }

  const sheet = getTargetSheet();
  const headerObjs = getHeaderList(sheet);
  if (headerObjs.length === 0) {
    console.error('❌ 시트 1행에 헤더(항목명)가 없습니다.');
    return;
  }

  const resetTimeStr = PropertiesService.getScriptProperties().getProperty('RESET_TIMESTAMP');
  const resetTime = resetTimeStr ? new Date(resetTimeStr).getTime() : 0;

  const headerNames = headerObjs.map(function(h) { return h.name; });
  const folder = DriveApp.getFolderById(folderId);
  const files = folder.getFiles();
  var processed = 0, skipped = 0, failed = 0;

  while (files.hasNext()) {
    const file = files.next();
    if ((file.getDescription() || '').includes('[PROCESSED]')) { skipped++; continue; }
    if (resetTime > 0 && file.getDateCreated().getTime() < resetTime) {
      file.setDescription((file.getDescription() || '') + '\n[PROCESSED] ' + new Date().toISOString());
      skipped++;
      continue;
    }

    const mimeType = file.getBlob().getContentType();
    if (!mimeType.startsWith('audio/')) { skipped++; continue; }

    const fileName = file.getName();
    console.log('▶️ 분석 시작: ' + fileName);

    try {
      const fileMeta = parseFileName(fileName);
      const analysis = analyzeCallWithDynamicHeaders(file, fileMeta, headerNames);
      const transcript = analysis.__transcript || '';

      const contact = resolveContactInfo(fileMeta, analysis);
      const phone = contact.phone;
      const customerName = contact.name;
      const dateStr = analysis.date || analysis.상담일시 || analysis.통화일시 || fileMeta.date || Utilities.formatDate(new Date(), 'Asia/Seoul', 'yyyy-MM-dd HH:mm');

      if (phone) {
        upsertCustomerMaster(phone, customerName, dateStr);
      }

      const rowData = [];
      for (var i = 0; i < headerNames.length; i++) {
        const h = headerNames[i];
        let val = '';

        if (/녹음.*링크|오디오.*링크|녹음.*URL|오디오.*URL|파일.*링크/i.test(h)) {
          val = file.getUrl();
        } else if (/전사.*내용|대화.*전문|전체.*대화|STT/i.test(h)) {
          val = transcript;
        } else if (/처리.*일시|분석.*일시|등록.*일시/i.test(h)) {
          val = Utilities.formatDate(new Date(), 'Asia/Seoul', 'yyyy-MM-dd HH:mm:ss');
        } else if (/파일.*명|녹음.*파일명/i.test(h)) {
          val = fileName;
        } else if (/전화.*번호|연락처|휴대폰/i.test(h)) {
          val = phone || analysis[h] || '';
        } else if (/고객.*명|이름/i.test(h)) {
          val = customerName || analysis[h] || '';
        } else if (/상담.*일시|통화.*일시|통화.*날짜/i.test(h)) {
          val = dateStr || analysis[h] || '';
        } else if (analysis[h] !== undefined && analysis[h] !== null) {
          val = analysis[h];
        } else {
          for (var key in analysis) {
            if (key.trim().toLowerCase() === h.toLowerCase()) {
              val = analysis[key];
              break;
            }
          }
        }
        rowData.push(val);
      }

      sheet.appendRow(rowData);
      file.setDescription((file.getDescription() || '') + '\n[PROCESSED] ' + new Date().toISOString());
      processed++;
      console.log('✅ 완료: ' + fileName);
    } catch (err) {
      failed++;
      console.error('❌ 실패 [' + fileName + ']: ' + err.message);
    }
  }

  console.log('=== 처리 결과: 성공 ' + processed + '건 / 스킵 ' + skipped + '건 / 실패 ' + failed + '건 ===');
}

function resetTestDataAndSetBaseline() {
  const ui = SpreadsheetApp.getUi();
  const confirmResp = ui.alert(
    '⚠️ 테스트 데이터 초기화 및 시작 기준점 설정',
    '다음 작업이 수행됩니다:\n\n'
    + '1. 현재 상담이력 시트 및 고객마스터 시트의 2행 이하 테스트 데이터 모두 삭제 (1행 헤더는 유지)\n'
    + '2. 구글 드라이브 폴더의 기존 녹음 파일들을 모두 [처리 완료] 상태로 마킹\n'
    + '3. 지금 시각을 [시작 기준점]으로 등록하여, 이후 새로 업로드되는 파일만 자동 분석하도록 설정\n\n'
    + '정말 초기화하시겠습니까?',
    ui.ButtonSet.YES_NO
  );
  if (confirmResp !== ui.Button.YES) return;

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const targetSheet = getTargetSheet();
  let targetDeletedRows = 0;
  if (targetSheet.getLastRow() > 1) {
    targetDeletedRows = targetSheet.getLastRow() - 1;
    targetSheet.deleteRows(2, targetDeletedRows);
  }

  const masterSheet = ss.getSheetByName(MASTER_SHEET_NAME);
  let masterDeletedRows = 0;
  if (masterSheet && masterSheet.getLastRow() > 1) {
    masterDeletedRows = masterSheet.getLastRow() - 1;
    masterSheet.deleteRows(2, masterDeletedRows);
  }

  let driveFileCount = 0;
  try {
    const folderId = getFolderId();
    const folder = DriveApp.getFolderById(folderId);
    const files = folder.getFiles();
    const nowIso = new Date().toISOString();
    while (files.hasNext()) {
      const f = files.next();
      const desc = f.getDescription() || '';
      if (!desc.includes('[PROCESSED]')) {
        f.setDescription(desc + '\n[PROCESSED] ' + nowIso);
      }
      driveFileCount++;
    }
  } catch (e) {
    console.error('드라이브 파일 마킹 중 오류: ' + e.message);
  }

  const nowIso = new Date().toISOString();
  PropertiesService.getScriptProperties().setProperty('RESET_TIMESTAMP', nowIso);

  const formattedDate = Utilities.formatDate(new Date(), 'Asia/Seoul', 'yyyy-MM-dd HH:mm:ss');
  ui.alert(
    '초기화 완료 (시작 기준점 등록됨)',
    '테스트 데이터가 정리되고 시작 기준점이 설정되었습니다.\n\n'
    + '• [' + targetSheet.getName() + '] 데이터 삭제: ' + targetDeletedRows + '건\n'
    + (masterSheet ? '• [' + MASTER_SHEET_NAME + '] 데이터 삭제: ' + masterDeletedRows + '건\n' : '')
    + '• 드라이브 기존 녹음 파일 정리: ' + driveFileCount + '개 제외 완료\n'
    + '• 수집 시작 기준 시각: ' + formattedDate + '\n\n'
    + '이제 [⏰ 5분 주기 자동 실행 시작]을 켜두시면, 지금(' + formattedDate + ') 이후 드라이브로 들어오는 새 녹음 파일부터 자동으로 분석되어 시트에 기록됩니다.',
    ui.ButtonSet.OK
  );
}

function installTrigger() {
  removeTriggers();
  ScriptApp.newTrigger('processNewRecordings').timeBased().everyMinutes(5).create();
  try {
    SpreadsheetApp.getUi().alert('트리거 설치 완료', '5분마다 구글 드라이브 폴더의 새 녹음 파일을 감지하여 시트 항목에 맞춰 자동 요약합니다.', SpreadsheetApp.getUi().ButtonSet.OK);
  } catch (e) {
    console.log('트리거 설치 완료');
  }
}

function removeTriggers() {
  ScriptApp.getProjectTriggers().forEach(function(t) {
    if (t.getHandlerFunction() === 'processNewRecordings') ScriptApp.deleteTrigger(t);
  });
  try {
    SpreadsheetApp.getUi().alert('트리거 중지 완료', '자동 실행 트리거가 모두 제거되었습니다.', SpreadsheetApp.getUi().ButtonSet.OK);
  } catch (e) {
    console.log('트리거 제거 완료');
  }
}

function checkStatus() {
  const ui = SpreadsheetApp.getUi();
  const sheet = getTargetSheet();
  const headers = getHeaderList(sheet);

  let folderStatus = '';
  let keyStatus = '';
  let peopleStatus = '';

  try {
    const folderId = getFolderId();
    const folder = DriveApp.getFolderById(folderId);
    const files = folder.getFiles();
    var count = 0, audio = 0;
    while (files.hasNext()) { count++; if (files.next().getBlob().getContentType().startsWith('audio/')) audio++; }
    folderStatus = '✅ 정상 (' + folder.getName() + ' / 파일 ' + count + '개, 오디오 ' + audio + '개)';
  } catch (e) {
    folderStatus = '❌ 접근 실패: ' + e.message;
  }

  try {
    const key = getApiKey();
    keyStatus = '✅ 등록됨 (' + key.slice(0, 6) + '...)';
  } catch (e) {
    keyStatus = '❌ 미등록 (' + e.message + ')';
  }

  try {
    if (typeof People !== 'undefined' && People.People) {
      const resp = People.People.Connections.list('people/me', { pageSize: 1, personFields: 'names' });
      peopleStatus = '✅ 연동됨 (Google People API 활성화)';
    } else {
      peopleStatus = 'ℹ️ 비활성화 (선택 사항: [서비스]에서 People API 추가 시 활성화)';
    }
  } catch (e) {
    peopleStatus = '⚠️ 권한 필요 또는 오류: ' + e.message;
  }

  const headerStatus = headers.length > 0 
    ? '✅ ' + headers.length + '개 컬럼 감지됨 (' + headers.map(function(h) { return h.name; }).join(', ') + ')' 
    : '❌ 1행에 헤더가 작성되지 않음';

  const triggers = ScriptApp.getProjectTriggers().filter(function(t) { return t.getHandlerFunction() === 'processNewRecordings'; });
  const triggerStatus = triggers.length > 0 ? '✅ 5분 주기 동작 중 (' + triggers.length + '개)' : '⏹️ 미동작';

  const resetTimeStr = PropertiesService.getScriptProperties().getProperty('RESET_TIMESTAMP');
  const resetStatus = resetTimeStr 
    ? Utilities.formatDate(new Date(resetTimeStr), 'Asia/Seoul', 'yyyy-MM-dd HH:mm:ss') + ' 이후 새 파일만 분석'
    : '전체 (기준점 미설정)';

  ui.alert(
    '🔍 시스템 상태 점검',
    '• 대상 시트: [' + sheet.getName() + ']\n'
    + '• 헤더 설정: ' + headerStatus + '\n'
    + '• 드라이브 폴더: ' + folderStatus + '\n'
    + '• Gemini API 키: ' + keyStatus + '\n'
    + '• 구글 주소록 연동: ' + peopleStatus + '\n'
    + '• 수집 시작 기준: ' + resetStatus + '\n'
    + '• 자동 실행 트리거: ' + triggerStatus,
    ui.ButtonSet.OK
  );
}
