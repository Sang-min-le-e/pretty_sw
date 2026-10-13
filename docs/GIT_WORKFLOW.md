# Git 작업 방식 (main에 바로 작업)

**2026-10-13부터 `main` 보호를 껐다.** 이제 PR 없이 `main`에서 바로 커밋하고 push한다.
(2026-10-05~10-13에는 `feature` 브랜치 → PR → merge 방식이었다. 그때 만든 `feature` 브랜치는 `main`과 같은 커밋이라 더 쓰지 않는다.)

## GitHub 쪽 설정

`main` 브랜치 보호 규칙은 없다(Settings → Branches). `main`에 직접 push할 수 있다.
다시 보호를 켜면 push가 아래처럼 거절되고, 그때는 브랜치 → PR 방식으로 돌아가야 한다.
```
! [remote rejected] main -> main (protected branch hook declined)
```

## 처음 한 번 (새 컴퓨터에서)

```bash
git clone https://github.com/Sang-min-le-e/pretty_sw.git
cd pretty_sw
flutter pub get
```

## 매번 작업할 때

```bash
git switch main
git pull                          # 시작 전: 다른 컴퓨터에서 올린 걸 받는다

# 작업
git status                        # 바뀐 파일 확인
flutter analyze                   # 오류 없는지 (테스트가 있으면 flutter test까지)
git add <파일들>                  # 가능하면 `git add .`보다 파일을 골라서
git commit -m "feat(범위): 무엇을 왜 바꿨는지"
git push
```

커밋 메시지는 `feat(...)`, `fix(...)`, `docs(...)`, `chore(...)` 같은 접두어를 쓴다.

## 두 컴퓨터(리눅스·맥북)를 같이 쓸 때

같은 `main`을 쓰므로 어긋나지 않게 **작업 전 `git pull`, 끝나면 `git push`**를 습관으로 한다.
push가 `non-fast-forward`로 거절되면 다른 컴퓨터에서 올린 커밋이 있다는 뜻이다.

```bash
git pull --rebase     # 내 커밋을 최신 main 위로 옮긴다
git push
```

## 위험한 작업은 브랜치로

큰 리팩터링처럼 도중에 앱이 깨질 수 있는 작업은 `main`을 보호하려고 브랜치를 따로 판다.

```bash
git switch -c feature/작업명
# 작업·커밋·push
git switch main
git merge --ff-only feature/작업명   # 끝나면 main에 합친다 (충돌이 있으면 --ff-only가 막아 준다)
git push
git branch -d feature/작업명
```

## 되돌리기

```bash
git revert <커밋>          # push한 커밋을 취소하는 새 커밋을 만든다 (안전)
git restore <파일>         # 아직 커밋 안 한 변경을 버린다 (⚠ 되돌릴 수 없음)
```
`git push --force`와 `git reset --hard`는 다른 컴퓨터의 작업을 날릴 수 있어서, 무슨 일이 일어나는지 알 때만 쓴다.

## AI 에이전트(Claude Code, Copilot)가 지킬 규칙

`CLAUDE.md`는 로컬 전용(`.gitignore`)이라 다른 컴퓨터에는 없다. 그래서 같은 규칙을 여기에도 적어 둔다.

- **사용자가 커밋·푸시를 시키기 전에는 커밋하거나 push하지 않는다.** 시키면 `main`에 바로 해도 된다.
- 작업 시작 전 `git pull`로 최신 상태인지 확인한다.
- push 전에 `flutter analyze`(테스트가 생기면 `flutter test`까지)를 통과시킨다.
- `--force` push, `reset --hard`, 브랜치·태그 삭제는 사용자가 명시적으로 시킬 때만 한다.
- 간단하지 않은 작업은 먼저 계획을 보여주고 승인을 받는다.
- 코드에 주석을 넉넉히 단다(사용자가 코드를 읽으며 공부한다). 화면 파일에는 Figma 노드 id를 문서 주석으로 남긴다.

## 자주 쓰는 확인 명령

```bash
git status            # 현재 브랜치 + 바뀐 파일
git branch -a         # 브랜치 목록 (* = 현재)
git log --oneline -5  # 최근 커밋 5개
git diff              # 아직 add 안 한 변경 내용
```
VS Code 왼쪽 아래 상태바에도 현재 브랜치 이름이 항상 보인다.
