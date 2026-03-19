# 아기 일기장 - 영아 분유 수유 관리 앱

**AI-DLC 방법론**으로 단계적 개발 중인 iOS + AWS 백엔드 프로젝트입니다.

---

## 개발 진행 현황

### ✅ 완료된 단계

| 단계 | 파일 | 상태 |
|------|------|------|
| 0. 기획 | `0.plan.md` | ✅ 완료 |
| 1. 요구사항 (Inception) | `1.inception.md` | ✅ 완료 |
| 2. 도메인 설계 | `2.domain.md` | ✅ 완료 |
| 3. 논리적 설계 | `3.logical.md` | ✅ 완료 |
| 4. 소스 코드 (iOS 앱) | `BabyDiary/` | ✅ 완료 + UI 개선 완료 |
| 4. 소스 코드 (AWS 백엔드) | `backend/lambda/` | ✅ Lambda 코드 작성 완료 |
| 5. AWS 인프라 배포 (Terraform) | `backend/terraform/` | ✅ 배포 완료 (98 리소스) |
| iOS ↔ AWS 연동 | Auth 흐름, APIService, AppConfig | ✅ 코드 연동 완료 |

### ⏳ 남은 단계

| 단계 | 내용 | 상태 |
|------|------|------|
| 실기기 통합 테스트 | Cognito 회원가입 → 수유기록 → AI 추천 확인 | ✅ 완료 |
| APNs 알람 | Apple Developer Program($99/년) 등록 후 진행 | ⏳ 추후 |
| 5. 유닛 테스트 | `6.test.md` | ⏳ 미시작 |
| 6. CI/CD | `7.cicd.md` | ⏳ 미시작 |
| 7. E2E 테스트 | `8.e2e.md` | ⏳ 미시작 |
| 8. App Store 배포 | `9.release.md` | ⏳ 미시작 |

---

## 프로젝트 구조

```
Baby_Care_App/
├── 0.plan.md              # 앱 기획서 + 교훈 기록
├── 1.inception.md         # User Stories & 체크리스트
├── 2.domain.md            # 도메인 설계
├── 3.logical.md           # 논리적 설계 (API, DB, 아키텍처)
├── 4.source.md            # 소스 코드 체크리스트
├── 5.deploy.md            # AWS 배포 계획서 (Terraform, dev 환경)
│
├── BabyDiary.xcodeproj    # Xcode 프로젝트
│
├── BabyDiary/             # iOS 앱 소스
│   ├── Config/
│   │   └── AppConfig.swift       # ⚠️ .gitignore 포함 — API URL, Cognito ID (절대 커밋 금지)
│   ├── App/
│   │   ├── BabyDiaryApp.swift    # @main, AppDelegate (APNs 토큰 등록)
│   │   └── RootView.swift        # 온보딩 ↔ 메인탭 라우팅
│   ├── Models/
│   │   ├── UserProfile.swift     # SwiftData 모델 (아이이름/생년월일/어머니이름)
│   │   ├── FeedingRecord.swift   # SwiftData 모델 (수유 시간/분유량/syncedAt)
│   │   └── BowelRecord.swift     # SwiftData 모델 (배변 시간/상태/syncedAt)
│   ├── Services/
│   │   ├── AgeCalculatorService.swift  # 월령 자동 계산, 권장 기준
│   │   ├── AlarmService.swift          # 로컬 알람 + APNs 토큰 등록
│   │   ├── APIService.swift            # API Gateway 연동 (actor)
│   │   ├── AuthManager.swift           # 로그인 상태 관리 (@MainActor ObservableObject)
│   │   ├── CognitoService.swift        # Cognito 회원가입/로그인/인증 (REST 직접 호출)
│   │   └── FeedingService.swift        # 평균 수유 간격/분유량 계산
│   ├── Views/
│   │   ├── MainTabView.swift           # 4탭 구성 (홈/기록/어드바이저/인사이트)
│   │   ├── Auth/AuthView.swift         # 로그인·회원가입·이메일인증 화면
│   │   ├── Onboarding/OnboardingView.swift
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   ├── FeedingInputModal.swift
│   │   │   ├── BowelInputModal.swift
│   │   │   └── AdvisorCardView.swift
│   │   ├── Record/RecordView.swift
│   │   ├── Advisor/AdvisorView.swift
│   │   └── Insights/InsightsView.swift
│   └── Resources/
│       └── Info.plist
│
└── backend/
    ├── terraform/
    │   ├── bootstrap/              # 1회 실행: S3 + DynamoDB 상태 관리 리소스
    │   └── environments/dev/       # 앱 인프라 (VPC, Lambda, API GW 등)
    └── lambda/                     # Python Lambda 함수 코드
        ├── feedings/               # GET/POST /feedings, DELETE /feedings/{id}
        ├── bowels/                 # GET/POST /bowels, DELETE /bowels/{id}
        ├── profile/                # GET/PUT /profile
        ├── advisor/                # POST /advisor/advice (Bedrock Claude 3.5 Sonnet)
        ├── insights/               # GET /insights (Bedrock Claude 3.5 Sonnet)
        ├── alarm/                  # POST /alarm/schedule (EventBridge Scheduler 예약)
        ├── alarm_delivery/         # SNS → APNs 발송 (EventBridge Scheduler가 호출)
        └── device/                 # POST /device/token (SNS Endpoint 생성)
```

---

## 앱 개요

- **앱 이름**: 아기 일기장
- **번들 ID**: com.youngbaby.app
- **플랫폼**: iOS 17+ (SwiftUI + SwiftData)
- **언어**: Swift 6.0 (strict concurrency)
- **UI**: 파스텔 톤 + 귀여운 아이콘
- **테마**: 라이트 모드 고정 (`.preferredColorScheme(.light)`)
- **색상**: Assets.xcassets Named Colors (PastelBackground/Pink/Mint/Purple)

### 주요 기능

| 탭 | 기능 |
|----|------|
| 홈 | 오늘 요약, 수유/배변 기록 버튼, AI 추천 카드 |
| 기록 | 수유·배변 기록 목록, 통계 |
| 어드바이저 | AI 수유 추천 (Bedrock Claude 3.5 Sonnet) |
| 인사이트 | 주간 데이터 인사이트 카드 피드 |

### AWS 아키텍처

```
[iPhone]
  ↓ HTTPS
[AWS WAF]              ← Rate 30req/min, OWASP, IP Reputation
  ↓
[API Gateway]          ← Cognito JWT Authorizer
  ↓ VPC 내부 (IGW/NAT 없음)
[Lambda - Private Subnet (us-east-1a, us-east-1b)]
  ├── DynamoDB ──── Gateway Endpoint  (무료)
  ├── S3 ────────── Gateway Endpoint  (무료)
  ├── Bedrock ───── Interface Endpoint (Claude 3.5 Sonnet)
  ├── SNS ────────── Interface Endpoint (APNs 알람)
  ├── CloudWatch ── Interface Endpoint (로그)
  └── EventBridge ─ Interface Endpoint (알람 스케줄)

리전: us-east-1 (버지니아 북부)
VPC: 10.100.0.0/16
인증: Cognito (이메일+비밀번호, 가족 공유 계정)
```

---

## AWS 배포 실제 값 (dev 환경)

| 항목 | 값 |
|------|-----|
| API URL | `https://fpnfjmdedb.execute-api.us-east-1.amazonaws.com/dev` |
| Cognito User Pool ID | `us-east-1_2qNTl06xv` |
| Cognito Client ID | `3ios0cmngi01lb94p208gvkd3d` |
| Cognito Region | `us-east-1` |
| VPC ID | `vpc-0583574e9710d71d1` |
| Account ID | `912542578074` |
| State Bucket | `youngbaby-terraform-state-912542578074` |

---

## 앱 화면 흐름 (현재)

```
앱 실행
  ↓
[AuthView] 로그인 / 회원가입  ← Cognito REST API 직접 호출
  ↓ 로그인 성공
[OnboardingView] 아이 이름·생년월일·어머니이름 입력  ← 최초 1회
  ↓
[MainTabView] 홈·기록·어드바이저·인사이트
```

## 다음 작업 순서

### ~~Step 1. 실기기 통합 테스트~~ ✅ 완료
- [x] Xcode Build Settings에 `AppConfig.swift` 값 확인 (Config.xcconfig 불필요 — AppConfig.swift 방식)
- [x] Cognito 회원가입 (이메일 + 비밀번호 8자 이상, 대문자·소문자·숫자·특수문자 포함)
- [x] 이메일 인증 코드 확인
- [x] 로그인 → 온보딩 → 홈 화면 진입
- [x] 수유 기록 → API → DynamoDB 저장 확인
- [x] 어드바이저 탭 → Bedrock Claude AI 추천 확인
- [x] 인사이트 탭 → 데이터 분석 확인

### Step 2. APNs 알람 (추후)
> Apple Developer Program($99/년) 등록 후 진행
> `5.deploy.md` Phase 9 참조

### Step 3. 테스트 & 출시
- [ ] 유닛 테스트 (`FeedingService`, `AgeCalculatorService`)
- [ ] E2E 테스트 (수유 기록 → 동기화 → AI 추천 전체 흐름)
- [ ] TestFlight 내부 테스트
- [ ] App Store Connect 제출

---

## 보안 주의사항

- `AppConfig.swift` → `.gitignore`에 포함 (절대 커밋 금지) — API URL, Cognito ID/Region 하드코딩, xcconfig 방식 대신 Swift 파일 방식 채택
- Lambda 함수에 API 키, 시크릿 하드코딩 없음
- DynamoDB `prevent_destroy = true` (terraform destroy 시 데이터 보존)
- Cognito 토큰 유효기간: AccessToken 1시간, RefreshToken 30일
- VPC Private Subnet: IGW/NAT 없음, 인터넷 직접 접근 차단
