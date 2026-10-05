# Git 작업 방식 (feature 브랜치 → PR → main)

2026-10-05부터 이 저장소는 **`main`에 직접 push하지 않고**, `feature` 브랜치 하나에서 작업한 뒤 PR로 `main`에 합친다.
사람(본인)이 무엇을 할지 정하고 PR을 확인해서 merge하며, AI 에이전트(Claude Code, Copilot)도 같은 규칙을 따른다.
배경은 KHU "AI Developer Blueprint"의 원칙이다. AI가 만든 코드는 리뷰나 테스트라는 필터를 거친 뒤에 `main`에 들어간다.

## GitHub 쪽 설정 (2026-10-05 적용됨)

`main` 브랜치 보호 규칙 (Settings → Branches → `main`):

| 설정 | 값 | 효과 |
|---|---|---|
| Require a pull request before merging | 켜짐 | PR을 거쳐야만 `main`에 들어감 |
| Require approvals | 꺼짐 (승인 0명) | 혼자서도 자기 PR을 merge할 수 있음 |
| Do not allow bypassing the above settings | 켜짐 | 저장소 주인도 `main` 직접 push 불가 |
| Force push / 삭제 | 막힘 | — |

그래서 `main` 위에서 `git push`하면 아래처럼 **거절된다** (정상 동작):
```
! [remote rejected] main -> main (protected branch hook declined)
```

## 처음 한 번 (새 컴퓨터에서)

```bash
git clone https://github.com/Sang-min-le-e/pretty_sw.git
cd pretty_sw
git switch feature          # GitHub에 있는 feature 브랜치를 받아서 이동
flutter pub get
```

## 매번 작업할 때

```bash
# 1) 시작 전: 이전 PR이 merge됐다면 feature를 최신 main과 맞춘다
git switch feature
git fetch origin
git reset --hard origin/main      # ⚠ 커밋 안 한 수정과 merge 안 된 커밋이 사라짐. PR merge 직후에만 실행
git push --force-with-lease       # GitHub의 feature도 같게 맞춤

# 2) 작업
git status                        # 첫 줄이 "On branch feature"인지 확인
git add .
git commit -m "fix: 무엇을 왜 바꿨는지"
git push                          # 처음이면 git push -u origin feature

# 3) PR 만들고 확인 후 merge
gh pr create --base main --head feature --fill
gh pr view --web                  # Files changed 탭에서 바뀐 내용 확인
gh pr merge --squash              # --delete-branch는 붙이지 않는다 (feature를 계속 쓰니까)

# 4) 마무리
git switch main
git pull
```

**1)을 하는 이유:** squash merge를 하면 `main`에는 새 커밋 하나가 생기고 `feature`에는 원래 커밋들이 남는다. 이 상태로 다음 작업을 하면 이미 반영된 변경이 다음 PR에 또 섞여 보인다. 그래서 새 작업을 시작할 때마다 `feature`를 `main`과 똑같이 맞춘다.

**한 번에 PR 하나만 진행한다.** 브랜치가 하나라서 PR이 열린 동안 다른 작업을 시작하면 그 변경이 열린 PR에 섞인다. 동시에 여러 작업이 필요해지면 `feature/작업명` 브랜치를 따로 만든다.

## 실수로 main에서 커밋했을 때

```bash
git switch -c feature-tmp          # 방금 커밋을 들고 임시 브랜치로
git switch main
git reset --hard origin/main       # 내 PC의 main을 GitHub과 같게 되돌림
git switch feature
git cherry-pick main..feature-tmp  # 커밋을 feature로 옮김
git branch -D feature-tmp
```

## AI 에이전트(Claude Code, Copilot)가 지킬 규칙

`CLAUDE.md`는 로컬 전용(`.gitignore`)이라 다른 컴퓨터에는 없다. 그래서 같은 규칙을 여기에도 적어 둔다.

- `main`에 커밋하거나 push하지 않는다. 작업은 `feature` 브랜치에서만 한다.
- 새 작업을 시작하기 전에 `git log origin/main..feature`로 merge 안 된 커밋이 없는지 확인한다. 없을 때만 `feature`를 `origin/main`에 맞춘다.
- 간단하지 않은 작업은 먼저 계획을 보여주고 승인을 받는다.
- push 전에 `flutter analyze`(테스트가 생기면 `flutter test`까지)를 통과시킨다.
- PR은 `gh pr create --base main --head feature`로 만든다. **merge는 하지 않는다.** 사람이 확인하고 merge한다.
- 코드에 주석을 넉넉히 단다(사용자가 코드를 읽으며 공부한다). 화면 파일에는 Figma 노드 id를 문서 주석으로 남긴다.

## 자주 쓰는 확인 명령

```bash
git status            # 현재 브랜치 + 바뀐 파일
git branch -a         # 브랜치 목록 (* = 현재)
git log --oneline -5  # 최근 커밋 5개
gh pr list            # 열려 있는 PR
gh pr status          # 내 PR 상태
```
VS Code 왼쪽 아래 상태바에도 현재 브랜치 이름이 항상 보인다. 커밋 전에 `main`이 아닌지 확인하는 습관을 들인다.
