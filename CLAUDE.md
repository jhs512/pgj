LLM이 코딩할 때 흔히 저지르는 실수를 줄이기 위한 행동 지침. 프로젝트별 규칙과 병행하여 사용할 것.

**트레이드오프:** 이 지침은 속도보다 신중함에 무게를 둔다. 사소한 작업에는 상식적으로 판단할 것.

## 1. 코딩 전에 생각하라

**추측하지 마라. 혼란을 숨기지 마라. 트레이드오프를 드러내라.**

구현에 들어가기 전:

- 가정을 명시적으로 밝혀라. 확신이 없으면 물어라.
- 해석이 여러 가지라면 전부 제시하라 - 임의로 하나를 골라 진행하지 마라.
- 더 단순한 방법이 있다면 말하라. 필요하면 반론을 제기하라.
- 뭔가 불분명하면 멈춰라. 뭐가 헷갈리는지 짚고, 물어라.

## 2. 단순함이 우선이다

**문제를 해결하는 최소한의 코드만 작성하라. 추측성 코드는 금지.**

- 요청받지 않은 기능을 넣지 마라.
- 한 번만 쓸 코드에 추상화를 만들지 마라.
- 요청하지 않은 "유연성"이나 "설정 가능성"을 넣지 마라.
- 일어날 수 없는 상황에 대한 에러 처리를 하지 마라.
- 200줄로 썼는데 50줄로 될 수 있다면 다시 써라.

스스로에게 물어라: "시니어 엔지니어가 이거 보고 과하다고 할까?" 그렇다면 단순화하라.

## 3. 수술하듯 변경하라

**건드려야 할 것만 건드려라. 자기가 만든 찌꺼기만 치워라.**

기존 코드를 수정할 때:

- 주변 코드, 주석, 포매팅을 "개선"하지 마라.
- 망가지지 않은 코드를 리팩터링하지 마라.
- 기존 스타일에 맞춰라. 네 취향과 달라도.
- 관련 없는 죽은 코드를 발견하면 언급만 하라 - 삭제하지 마라.

네 변경으로 고아가 된 코드가 있을 때:

- 네 변경으로 안 쓰게 된 import/변수/함수는 제거하라.
- 원래부터 있던 죽은 코드는 요청받지 않는 한 건드리지 마라.

검증 기준: 변경된 모든 줄은 사용자의 요청과 직접적으로 연결되어야 한다.

## 4. 목표 기반 실행

**완료 조건을 정의하라. 검증될 때까지 반복하라.**

작업을 검증 가능한 목표로 변환하라:

- "검증 추가" → "잘못된 입력에 대한 테스트를 작성하고, 통과시켜라"
- "버그 수정" → "버그를 재현하는 테스트를 작성하고, 통과시켜라"
- "X 리팩터링" → "리팩터링 전후로 테스트가 통과하는지 확인하라"

여러 단계의 작업이라면 간단한 계획을 세워라:

```
1. [단계] → 검증: [확인 사항]
2. [단계] → 검증: [확인 사항]
3. [단계] → 검증: [확인 사항]
```

명확한 완료 조건이 있으면 스스로 반복할 수 있다. 모호한 조건("되게 해줘")은 끊임없이 확인이 필요하다.

---

**이 지침이 잘 작동하고 있다면:** diff에 불필요한 변경이 줄고, 과도한 복잡성으로 인한 재작성이 줄고, 실수 후가 아니라 구현 전에 질문이 나온다.

# PGJ - PostgreSQL + Groonga + Vector + PostGIS

PostgreSQL 18 기반 Docker 이미지. 전문 검색(PGroonga), 공간 데이터(PostGIS), 벡터 유사도 검색(pgvector)을 하나의 컨테이너에 통합.

**Docker Hub**: `jangka512/pgj`
**Registry**: https://hub.docker.com/repository/docker/jangka512/pgj

## 프로젝트 구조

```
pgj/
├── Dockerfile                    # 멀티스테이지 빌드
├── entrypoint.sh                 # PostgreSQL 기동 + DB 자동 생성
├── initdb.d/
│   └── 10-extensions.sql         # 컨테이너 초기화 시 익스텐션 자동 생성
├── .github/workflows/
│   └── sync-readme.yml           # README.md → Docker Hub 설명 자동 동기화
├── README.md
└── CLAUDE.md
```

## 베이스 이미지 및 익스텐션

| 레이어 | 소스 | 버전 |
|--------|------|------|
| PostgreSQL + PGroonga | `groonga/pgroonga:latest-debian-18` | PostgreSQL 18 |
| PostGIS | PGDG APT 저장소 | 3.x |
| pgvector | 소스 빌드 (GitHub) | 0.8.1 |

## 포트

| 포트 | 서비스 | 설명 |
|------|--------|------|
| 5432 | PostgreSQL | 직접 접속 |

## 태그 규칙

| 태그 | 용도 |
|------|------|
| `latest` | 최신 빌드, 항상 함께 푸시 |
| `v1`, `v2`, ... | 버전 릴리스, 숫자 순 증가 |

## 빌드 및 배포

- Docker 빌드는 로컬에서 수행 (GitHub Actions에서는 빌드하지 않음)
- main에 README.md 변경을 push하면 GitHub Actions가 Docker Hub README 자동 동기화
- 워크플로우: `.github/workflows/docker-push.yml`
- 필요한 시크릿: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (GitHub repo Settings > Secrets)

```bash
# 로컬 빌드 (latest + 버전 태그)
docker buildx build -t jangka512/pgj:latest -t jangka512/pgj:v1 .

# 실행
docker run -d --name pgj -e POSTGRES_PASSWORD=secret -p 5432:5432 jangka512/pgj:latest

# Docker Hub에 푸시 (latest + 버전 태그 함께)
docker push jangka512/pgj:latest
docker push jangka512/pgj:v1
```

## 개발 가이드라인

- Dockerfile 수정 후 반드시 `docker buildx build`로 빌드 검증
- pgvector 버전 업데이트 시 `ARG PGVECTOR_VERSION` 값 변경
- 새 익스텐션 추가 시: Dockerfile에 설치 단계 추가 + `initdb.d/10-extensions.sql`에 `CREATE EXTENSION` 추가
- initdb.d 스크립트는 파일명 순서대로 실행됨 (숫자 프리픽스로 순서 제어)
- 헬스체크: `pg_isready -U postgres` (30초 간격, 5초 타임아웃, 3회 재시도)
