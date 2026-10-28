# LANDERAI — Infrastructure

LANDERAI는 랜딩페이지를 생성하고 수정한 뒤 사용자별 주소로 게시할 수 있는 서비스입니다. 이 저장소에서는 서비스 기능보다는 이를 운영하기 위해 구성한 AWS 인프라와 Terraform 코드를 다룹니다.

- [서비스](https://landerai.un-box.click)
- [Backend](https://github.com/nacgyun/LANDERAI-BE)
- [Frontend](https://github.com/nacgyun/LANDERAI-FE)

## 1. 인프라 구성

| 구분 | 사용 기술 |
| --- | --- |
| Infrastructure as Code | Terraform, AWS Provider |
| API / Compute | API Gateway (HTTP API), Lambda (Python 3.12, arm64) |
| Workflow / Messaging | Step Functions (Standard), SQS, DLQ |
| Data / Storage | DynamoDB, S3, S3 Vectors 연동 |
| Hosting / DNS | CloudFront, CloudFront Functions, Route 53, ACM |
| Deployment / Access | GitHub Actions, IAM, OIDC, SSM Parameter Store |
| Observability | CloudWatch Logs / Dashboard / Alarms, SNS |

## 2. 전체 아키텍처

<img width="1353" height="1020" alt="LANDERAI 찐최종본 drawio" src="https://github.com/user-attachments/assets/7727b2ff-3197-4710-9071-772dc1ecc8b5" />


위 그림은 생성·수정 요청을 처리하는 주요 구성요소를 보여줍니다. 실제 Terraform에서는 프론트엔드 CloudFront가 S3를 원본으로 사용하며, 브라우저는 API Gateway의 별도 HTTP API를 호출합니다. 생성된 페이지를 제공하는 사용자 호스팅용 CloudFront 배포도 별도로 구성되어 있습니다.

인프라의 주요 처리 경로는 다음과 같이 나뉩니다.

| 경로 | AWS 구성 | 역할 |
| --- | --- | --- |
| API 요청 | API Gateway → API Lambda | 요청 수신 및 후속 작업 시작 |
| 생성 워크플로 | Step Functions → Lambda | 단계별 실행, A/B 생성 병렬화 및 오류 처리 |
| 수정 요청 | API Lambda → SQS → Revision Worker | 시간이 걸리는 수정 작업을 비동기로 처리 |
| 프론트엔드 호스팅 | Route 53 → CloudFront → S3 | 정적 프론트엔드 제공 |
| 사용자 페이지 호스팅 | Wildcard DNS → CloudFront Function → S3 | 서브도메인별 게시 페이지 제공 |

## 3. 주요 설계 내용

<img width="2990" height="2158" alt="mermaid-diagram" src="https://github.com/user-attachments/assets/a16b20db-1517-4041-8204-9c3a0a6ecb56" />
### 3.1 Step Functions로 생성 단계 관리

생성 작업을 하나의 Lambda에서 모두 실행하는 방식도 검토했습니다. 하지만 단계별 실행 결과를 확인하고, 실패한 작업을 어디에서 처리해야 하는지 구분하기 위해 Lambda를 분리하고 Step Functions로 연결했습니다.

- `Embedding → Design Plan → Generate Landing Page Variants → Persist Result` 순서로 실행합니다.
- A/B 시안 생성은 `Map` 상태로 구성했습니다. `variant_max_concurrency` 값으로 순차 또는 병렬 실행을 조정할 수 있습니다.
- Lambda 서비스 오류는 2초 간격으로 시작하는 지수 백오프로 최대 3회 재시도합니다.
- 재시도 후에도 오류가 발생하면 `Catch`에서 `WorkflowFailed` 상태로 이동합니다.

단일 Lambda와 비교했을 때 약 1초의 실행 오버헤드가 있었지만, 실행 흐름을 확인하고 재시도 정책을 단계별로 관리할 수 있다는 점을 고려해 이 구조를 선택했습니다.

관련 코드: [`modules/step_function/main.tf`](modules/step_function/main.tf)

### 3.2 SQS를 이용한 수정 요청 비동기 처리

페이지 수정 작업은 실행 시간이 길어질 수 있어 API 요청과 분리했습니다. API Lambda는 작업을 SQS에 전달하고 Revision Worker Lambda가 메시지를 소비하도록 구성했습니다.

| 항목 | 설정 |
| --- | --- |
| Long Polling | 20초 |
| Visibility Timeout | 1,800초 |
| DLQ 이동 기준 | 최대 수신 횟수 3회 |
| Revision Worker | Reserved Concurrency 3, Batch Size 1 |
| 메시지 보관 기간 | 기본 큐 4일 / DLQ 14일 |
| 큐 암호화 | SQS 관리형 서버 측 암호화 |

반복해서 실패한 메시지는 DLQ에 남도록 했습니다. 다만 SQS는 중복 전달이 가능하므로, 작업의 멱등성은 애플리케이션에서도 고려해야 합니다.

관련 코드: [`modules/revision_queue/main.tf`](modules/revision_queue/main.tf), [`environments/prod/main.tf`](environments/prod/main.tf)

### 3.3 CloudFront Function 기반 사용자별 페이지 호스팅

사용자가 페이지를 게시할 때마다 CloudFront Distribution을 만드는 대신, 하나의 배포에서 여러 사용자 페이지를 제공하도록 구성했습니다.

1. 사용자가 `{slug}.landerai.un-box.click`에 접속합니다.
2. Wildcard Route 53 레코드가 사용자 호스팅 CloudFront로 요청을 전달합니다.
3. CloudFront Function에서 Host 헤더의 slug를 확인하고 요청 경로를 `/published/{slug}/...`로 바꿉니다.
4. CloudFront가 비공개 S3 버킷에서 해당 객체를 가져옵니다.

S3 버킷에는 Public Access Block을 설정하고 CloudFront OAC를 통해 객체를 읽도록 했습니다. 게시한 내용의 변경 사항을 바로 확인할 수 있도록 사용자 호스팅에는 캐시 비활성화 정책을 사용했습니다. 503 오류 페이지는 별도 S3 원본에 보관합니다.

라우팅 코드는 유효하지 않은 slug, 요청 경로, 오류 응답, CloudFront Function 코드 크기를 테스트하도록 작성했습니다.

```bash
node --test modules/user_hosting/host_router.test.cjs
```

관련 코드: [`modules/user_hosting/main.tf`](modules/user_hosting/main.tf), [`modules/user_hosting/error_origin.tf`](modules/user_hosting/error_origin.tf)

### 3.4 DynamoDB와 S3 관리

DynamoDB는 요청, 생성 결과, 디자인 계획 등 용도에 따라 네 개의 테이블로 분리했습니다.

생성 HTML은 별도 S3 버킷에 저장하며 Public Access Block과 기본 서버 측 암호화(SSE-S3)를 설정했습니다. S3 Vectors의 버킷 및 인덱스는 현재 이 저장소에서 생성하지 않고, Lambda가 접근할 수 있도록 이름과 IAM 권한을 연결합니다.

관련 코드: [`modules/dynamodb/main.tf`](modules/dynamodb/main.tf), [`environments/prod/main.tf`](environments/prod/main.tf)

## 4. Terraform 환경 분리

```text
LANDERAI-INFRA/
├── environments/
│   ├── shared/                  # 공통 Route 53 Hosted Zone
│   ├── dev/                     # 개발 환경
│   └── prod/                    # 운영 환경 및 알람
├── modules/
│   ├── api_gateway/
│   ├── dynamodb/
│   ├── frontend_hosting/
│   ├── lambda/
│   ├── revision_queue/
│   ├── step_function/
│   └── user_hosting/
├── src/                         # Lambda 리소스 생성용 초기 핸들러
└── .gitignore
```

개발 환경과 운영 환경은 각각 독립된 Terraform 루트 모듈로 관리합니다. 공통으로 사용하는 리소스 정의는 `modules/`에 두고, 환경별 파일에서 필요한 모듈을 호출합니다.

- `shared`: Route 53 Hosted Zone. 실수로 삭제하지 않도록 `prevent_destroy` 적용
- `dev` / `prod`: 동일한 모듈 기반으로 환경별 리소스 생성
- `prod`: CloudWatch Dashboard, Metric Alarm, SNS Topic, Clerk DNS 설정 추가
- 기본 리전은 `ap-northeast-2`, CloudFront용 ACM 인증서는 `us-east-1`에서 관리

환경마다 `.terraform.lock.hcl`을 커밋하고, 실제 `terraform.tfvars`와 State 파일은 Git 추적에서 제외했습니다.

## 5. GitHub Actions와 IAM

Terraform은 인프라 리소스를 관리하고, 서비스 코드 배포는 BE·FE 저장소의 GitHub Actions에서 수행합니다.

| 저장소 | 배포 방식 |
| --- | --- |
| [LANDERAI-BE](https://github.com/nacgyun/LANDERAI-BE) | Python 의존성을 Lambda arm64 환경에 맞게 패키징한 뒤 6개 Lambda의 코드 업데이트 |
| [LANDERAI-FE](https://github.com/nacgyun/LANDERAI-FE) | 타입 검사·Lint·빌드 후 S3 업로드, CloudFront 캐시 무효화 |

두 워크플로는 `develop` 브랜치를 `dev`, `main` 브랜치를 `prod` 환경에 연결합니다. 장기 AWS 액세스 키 대신 GitHub OIDC를 이용해 배포용 IAM Role을 수임합니다. Trust Policy에는 `aud`와 `sub` 조건을 설정했고, BE 역할에는 Lambda 코드 업데이트, FE 역할에는 S3 객체 관리와 CloudFront 무효화에 필요한 권한을 부여했습니다.

`src/`의 핸들러는 Terraform으로 Lambda 리소스를 처음 만들기 위한 초기 코드입니다. 실제 애플리케이션 코드는 BE 저장소에서 별도로 배포합니다.

관련 코드: [`environments/prod/github_actions.tf`](environments/prod/github_actions.tf), [`environments/prod/frontend_github_actions.tf`](environments/prod/frontend_github_actions.tf)

## 6. 모니터링 및 운영 설정

운영 환경의 CloudWatch Dashboard에서 API, Step Functions, Lambda의 요청·실행·오류 지표를 확인하도록 구성했습니다. Metric Alarm은 다음 상황을 감지하도록 설정했습니다.

| 대상 | 알람 조건 |
| --- | --- |
| API Gateway | 5xx 오류 발생 |
| Step Functions | 실행 실패 또는 타임아웃 |
| Lambda | Throttling 발생 |
| SQS | DLQ에 메시지 유입 |
| DynamoDB | 읽기·쓰기 Throttling 발생 |

현재 Terraform 코드 기준으로는 SNS Topic의 구독 대상이 정의 되어있지 않기 때문에 실제 apply 시 관련 추가 설정이 필요합니다.

관련 코드: [`environments/prod/monitoring.tf`](environments/prod/monitoring.tf), [`environments/prod/alarms.tf`](environments/prod/alarms.tf)
