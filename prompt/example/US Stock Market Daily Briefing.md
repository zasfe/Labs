[웹(네이버/구글) 검색 예시 프롬프트]
1분후에 24시간 내 미국 시장의 공개 데이터와 공개 보도를 바탕으로,
미국 증시 일일 브리핑을 작성한 뒤 하이웍스 메일로 발송하세요. (메일 발송 자동 승인)

실행 원칙:
- 추측, 전망, 과장된 해석은 배제하고 공개적으로 확인 가능한 수치와 사실만 사용하세요.
- 확인되지 않은 정보, 루머, 익명 발언은 사용하지 마세요.
- 데이터 및 기사 기준 시점은 "실행 시점 기준 최근 24시간"으로 제한하세요.

출처 규칙:
- 출처는 Reuters, CNBC, MarketWatch 중 1~2개만 사용하세요.
- 기사/보도 내용을 인용할 때는 핵심 사실만 간단히 반영하세요.
- 수치 데이터는 공개 시장지표와 기사 내 명시 수치만 사용하세요.

메일 발송 조건:
- 수신자: {id}@gmail.com
- 메일 제목: 미국 증시 일일 브리핑
- 본문 언어: 한국어
- 본문 형식: HTML

작성 규칙:
- 아래 HTML 템플릿의 구조와 인라인 스타일은 절대 변경하지 마세요.
- 스타일을 삭제, 축약, 재배치하지 말고 데이터 부분만 실제 값으로 치환하세요.
- 작성일자, 출처, 3문장 핵심 요약, 주요 지수 3개, 주요 종목 3개, 거시 이슈 2개를 채우세요.
- 주요 지수는 S&P 500, Nasdaq, Dow Jones의 종가와 등락률을 작성하세요.
- 등락률 색상은 상승 시 #16a34a, 하락 시 #dc2626 을 사용하세요.
- 주요 종목 3개는 최근 24시간 내 시장에서 의미 있게 언급된 종목만 선정하고, 각 종목별 등락 사유를 1문장으로 작성하세요.
- 거시 이슈는 시장에 실제 영향을 준 공개 이슈 2개만 간단명료하게 정리하세요.
- 숫자, 회사명, 지수명, 등락률 표기는 일관되게 작성하세요.
- 정보를 확인할 수 없는 칸은 임의 추정으로 채우지 말고, 확인 가능한 다른 항목으로 대체하세요.

작업 순서:
- 최근 24시간 기준으로 미국 증시 관련 공개 보도와 시장지표를 확인합니다.
- Reuters, CNBC, MarketWatch 중 1~2개 출처를 선정합니다.
- 핵심 사실만 요약합니다.
- 아래 HTML 템플릿의 플레이스홀더를 실제 데이터로 치환합니다.
- 완성된 HTML 본문으로 하이웍스 메일을 발송합니다.

HTML 템플릿:
<div style="max-width:680px;margin:0 auto;padding:24px;font-family:-apple-system,'Apple SD Gothic Neo','Malgun Gothic',sans-serif;color:#1f2937;background:#ffffff;"> <div style="border-bottom:3px solid #3b82f6;padding-bottom:12px;margin-bottom:20px;"> <h1 style="margin:0;font-size:22px;color:#0f172a;">미국 증시 일일 브리핑</h1> <p style="margin:6px 0 0;font-size:13px;color:#64748b;">{작성일자} · 출처: {출처}</p> </div> <div style="background:#f8fafc;border-left:4px solid #3b82f6;padding:14px 16px;margin-bottom:20px;border-radius:4px;"> <h2 style="margin:0 0 8px;font-size:15px;color:#0f172a;">핵심 요약</h2> <p style="margin:0;font-size:14px;line-height:1.6;">{3문장 요약}</p> </div> <h2 style="font-size:15px;color:#0f172a;border-bottom:1px solid #e2e8f0;padding-bottom:6px;margin:24px 0 10px;">주요 지수</h2> <table style="width:100%;border-collapse:collapse;font-size:13px;"> <thead> <tr style="background:#f1f5f9;"> <th style="text-align:left;padding:8px;border:1px solid #e2e8f0;">지수</th> <th style="text-align:right;padding:8px;border:1px solid #e2e8f0;">종가</th> <th style="text-align:right;padding:8px;border:1px solid #e2e8f0;">등락률</th> </tr> </thead> <tbody> <tr><td style="padding:8px;border:1px solid #e2e8f0;">S&P 500</td><td style="padding:8px;border:1px solid #e2e8f0;text-align:right;">{종가}</td><td style="padding:8px;border:1px solid #e2e8f0;text-align:right;color:{상승은 #16a34a, 하락은 #dc2626};font-weight:600;">{등락률}</td></tr> <tr><td style="padding:8px;border:1px solid #e2e8f0;">Nasdaq</td><td style="padding:8px;border:1px solid #e2e8f0;text-align:right;">{종가}</td><td style="padding:8px;border:1px solid #e2e8f0;text-align:right;color:{색};font-weight:600;">{등락률}</td></tr> <tr><td style="padding:8px;border:1px solid #e2e8f0;">Dow Jones</td><td style="padding:8px;border:1px solid #e2e8f0;text-align:right;">{종가}</td><td style="padding:8px;border:1px solid #e2e8f0;text-align:right;color:{색};font-weight:600;">{등락률}</td></tr> </tbody> </table> <h2 style="font-size:15px;color:#0f172a;border-bottom:1px solid #e2e8f0;padding-bottom:6px;margin:24px 0 10px;">주요 종목 3개</h2> <ul style="margin:0;padding-left:20px;font-size:14px;line-height:1.7;"> <li><strong style="color:#0f172a;">{종목명}</strong> ({티커}): {등락 사유 1줄}</li> <li><strong style="color:#0f172a;">{종목명}</strong> ({티커}): {등락 사유 1줄}</li> <li><strong style="color:#0f172a;">{종목명}</strong> ({티커}): {등락 사유 1줄}</li> </ul> <h2 style="font-size:15px;color:#0f172a;border-bottom:1px solid #e2e8f0;padding-bottom:6px;margin:24px 0 10px;">거시 이슈</h2> <ul style="margin:0;padding-left:20px;font-size:14px;line-height:1.7;"> <li>{이슈 1}</li> <li>{이슈 2}</li> </ul> <div style="margin-top:28px;padding-top:12px;border-top:1px dashed #cbd5e1;font-size:11px;color:#94a3b8;"> 본 메일은 최근 24시간 내 공개 보도만을 근거로 자동 작성되었습니다. </div> </div>
