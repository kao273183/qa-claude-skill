# flaky-test-hunter 範例

## 範例 1: 從 GitHub Actions 撈 30 天紀錄

```
User: /flaky-test-hunter --days=30
```

執行：
1. 用 `gh run list --workflow=ci.yml` 撈 842 個 run
2. 解析 JUnit XML（artifact 內）
3. 算每個測試的 flakiness
4. 找到 42 條 flaky / 19 條 stable-fail
5. 寫報告 `~/.local/share/qa-flaky/my-app/report-2026-05-22.md`

## 範例 2: High flaky 自動 Quarantine

```
Bot: 找到 8 條 High flaky (>30%):
  1. LoginUITests.testRetryAfterFailure (47%)
  2. WebSocketTest.testReconnect (35%)
  ...

要 quarantine 嗎? (y/n/select)
User: y

→ 自動加 @QuarantineFlaky annotation
→ 建 8 個 JIRA ticket (via bug-report skill)
→ 產 PR feature/quarantine-flaky-2026-05-22
```

## 範例 3: 找 flaky 根因 pattern

```
LoginUITests.testRetryAfterFailure 分析:

Pattern 偵測:
✗ Hard-coded sleep at line 42: Thread.sleep(2000)
✗ Depends on token expiry timing (external)

建議修法:
1. 改 `expect(element).toExist()` 等待條件
2. 注入 fake clock 控制 token expiry
3. 將 retry 邏輯抽到獨立 unit test

→ 寫到 ticket description，PM/Dev 可直接看
```

## 範例 4: Sprint Review 用

```
User: /flaky-test-hunter --days=14 --since-last-sprint
```

→ 對比這個 sprint vs 上個 sprint flakiness
→ 「上 sprint 5.1%，這 sprint 3.4% (-1.7%)」
→ 可直接放 Sprint Review demo
