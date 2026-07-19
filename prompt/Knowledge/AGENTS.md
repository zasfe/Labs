## Case 생성 원칙

운영지식은 원본 입력 단위를 기준으로 관리한다.

- 메일 1건 → Case 1개
- 회의록 1건 → Case 1개
- Mattermost 스레드 1개 → Case 1개
- 작업보고서 1건 → Case 1개
- 장애보고서 1건 → Case 1개

여러 입력을 하나의 Case로 병합하지 않는다.

Case는 시간순으로 발생한 사실과 근거를 보존하는 기록이다.

기존 Case를 수정하여 새로운 사건을 추가하지 말고, 새로운 입력은 항상 새로운 Case로 작성한다.

관련 사건은 Case를 병합하는 대신 `related_cases` 등 참조 관계로 연결한다.

Pattern, Workflow, Rule, Memory는 여러 Case를 검토하여 생성한다. 하나의 Case만으로 일반화하거나 기준 정의를 변경하지 않는다.

원본은 가능한 한 그대로 유지하고, 구조화된 정보는 Case에 기록한다. Object, Relationship, Action, Workflow, Rule의 신규 정의는 후보(Candidate)로 제안하며, 승인 전에는 기준 정의를 직접 변경하지 않는다.
