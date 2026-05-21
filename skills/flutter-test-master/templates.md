# Flutter Test Master Templates

---

## flutter-test-strategy.md 模板

```markdown
# Flutter 測試策略：[功能名稱]

## 功能概述
[簡要描述功能]

## 技術棧
- **Flutter 版本**: [例如 3.24.x]
- **Dart 版本**: [例如 3.5.x]
- **State Management**: [Riverpod / Provider / BLoC / GetX]
- **Mock 工具**: mocktail（優先）/ mockito / 純手寫 Fake
- **架構模式**: MVVM / Clean Architecture / Feature-based

## 測試目標
- 功能正確性：所有需求都正確實作
- UI 一致性：iOS + Android + Web（若適用）視覺一致
- 效能：widget rebuild 次數、動畫 60fps、啟動時間
- 並發穩定性：Isolate 通訊、async race condition
- **雙平台像素一致性**：Golden test 差異 ≤ 0.5%

## 測試範圍

### In Scope
- ✅ [功能點 1] — ViewModel + Repository + View 全層測試
- ✅ Platform Channel（若有使用原生 API）
- ✅ 錯誤狀態（載入失敗、空資料、網路錯誤）
- ✅ 邊界條件（空輸入、超長輸入、特殊字元）
- ✅ 生命週期（背景/前景、記憶體警告）

### Out of Scope
- ❌ 第三方 Flutter package 內部邏輯
- ❌ Firebase SDK 回應解析（由 SDK 保證）

## Flutter 架構層測試對應

| 層級 | 元件類型 | 測試類型 | Fake/Mock 策略 |
|------|---------|---------|---------------|
| Data | Repository | Unit Test | Mock HTTP Client / DB |
| Data | Service（platform channel）| Unit Test + Integration | Mock MethodChannel |
| Logic | ViewModel | Unit Test（純 Dart）| **Fake Repository** |
| UI | View / Screen | Widget Test | **Fake ViewModel** |
| UI | 複雜 widget | Golden Test | 無需 |
| App | 整體流程 | Integration Test | 真實依賴 or FakeApp |

## 測試金字塔分配

| 層級 | 比例 | Flutter 測試內容 |
|------|------|-----------------|
| Unit | 70% | ViewModel, Repository, UseCase, Utilities |
| Widget | 20% | Screens, 可重用 widgets, 自訂動畫 |
| Integration | 10% | 關鍵流程 E2E（登入、支付、核心功能）|

## 風險矩陣

| 風險 | 影響平台 | 影響 | 可能性 | 優先級 | 測試策略 |
|------|---------|------|--------|--------|---------|
| [Platform Channel 通訊失敗] | Both | High | Medium | P0 | Mock channel + Native unit + Integration |
| [iOS/Android 像素差異] | Both | Medium | High | P1 | Golden test 雙平台 baseline |
| [Isolate 記憶體洩漏] | Both | High | Low | P1 | Unit + DevTools profiling |

## 跨平台執行策略

| 測試類型 | iOS | Android | 備註 |
|---------|-----|---------|------|
| Unit | ✅ CI 一次執行 | - | Dart 跨平台 |
| Widget | ✅ CI 一次執行 | - | WidgetTester 跨平台 |
| Golden | ⚠️ 需分別 baseline | ⚠️ | 像素差異無法共用 |
| Integration | ✅ Simulator / Firebase | ✅ Emulator / Firebase | 關鍵流程雙平台都要跑 |
```

---

## coverage-gaps.md 模板

```markdown
# Flutter 測試覆蓋缺口分析

## 現有 Unit Test
✅ 已有測試：
- `test/unit/view_models/home_view_model_test.dart`（HomeViewModel）

❌ 缺少測試：
- [ ] `UserRepository` — 缺少 API 錯誤處理測試
- [ ] `AuthService` — 缺少 token 過期重試測試

## 現有 Widget Test
✅ 已有測試：
- `test/widget/login_screen_test.dart`

❌ 缺少測試：
- [ ] `SettingsScreen` — 完全無 widget test
- [ ] `CustomSlider`（自訂 widget）— 無手勢測試

## 現有 Integration Test
✅ 已有測試：
- `integration_test/login_flow_test.dart`

❌ 缺少測試：
- [ ] 支付流程 E2E
- [ ] 深層連結 routing

## 現有 Golden Test
✅ 已有 baseline：
- `test/golden/goldens/home_screen.png`

❌ 缺少 baseline：
- [ ] 支付確認頁
- [ ] 錯誤狀態頁

## Platform Channel 測試
❌ 未測試的 channels：
- [ ] `com.example/payment` — 支付原生橋接
- [ ] `com.example/biometric` — 生物辨識

## 優先級建議
1. **P0**: 支付流程 Integration test（金流風險）
2. **P0**: Platform Channel 錯誤處理測試（native crash 風險）
3. **P1**: 缺失的 Widget test（UI 回歸風險）
4. **P2**: Golden test baseline 補齊
```

---

## automation-plan.md 模板

```markdown
# Flutter 自動化測試路線圖

## ROI 分析

| 測試案例 | 手動時間 | 自動化成本 | 執行頻率 | ROI | 建議 |
|---------|---------|-----------|---------|-----|------|
| 登入流程 Widget test | 3 min | 2 hours | 每次 commit | High | ✅ 優先 |
| 支付 E2E Integration | 10 min | 8 hours | 每次 release | High | ✅ 優先 |
| 動畫 Golden test | 5 min | 1 hour | 每次 UI 變更 | Medium | 🟡 評估 |
| 罕見錯誤狀態 | 2 min | 4 hours | 每月 | Low | ❌ 手動 |

## 自動化路線圖

### Phase 1: 立即實作（本 Sprint）
- Unit test: 所有新增 ViewModel / Repository
- Widget test: 所有新增 Screen

### Phase 2: 中期（下個 Sprint）
- Integration test: 登入 + 核心功能 E2E
- CI 整合：`flutter test --coverage` + lcov 報告

### Phase 3: 長期（Release 前）
- Firebase Test Lab 跨裝置執行
- Golden test baseline 建置

### 不建議自動化
- 一次性功能探索
- 需要真人判斷的 UX 測試

## CI 整合建議

```yaml
# .github/workflows/flutter-test.yml (範例)
- name: Unit + Widget Tests
  run: flutter test --coverage

- name: Integration Tests (Android)
  run: |
    flutter build apk --debug
    ./gradlew app:assembleAndroidTest
    # 上傳至 Firebase Test Lab

- name: Golden Tests
  run: flutter test --update-goldens  # 本地 / test
```
```

---

## flutter-exploratory-guide.md 模板

```markdown
# Flutter 探索性測試指引

## 測試章程
探索 [功能名] 在 [特定條件] 下的 [Flutter 特有風險]

## Flutter 特有探索區域

### 1. Hot Reload 殘留狀態
- [ ] 開發時 hot reload 後，畫面狀態是否正確？
- [ ] State 是否殘留舊值？
- [ ] Stream/StreamController 是否重複訂閱？

### 2. Isolate 通訊
- [ ] 背景 isolate 計算中切換前景/後景
- [ ] Isolate 異常時主 thread 是否凍結
- [ ] 大量訊息傳遞的效能（`compute()`）

### 3. Platform Channel 異常
- [ ] 原生回傳 null
- [ ] 原生拋出例外
- [ ] channel 名稱錯誤（典型 bug）
- [ ] 序列化失敗（不支援的型別）

### 4. 多平台像素差異
- [ ] iOS vs Android 相同 widget 的字型 baseline
- [ ] 陰影（BoxShadow）渲染差異
- [ ] 動畫時間一致性
- [ ] ScrollBar 顯示差異

### 5. 生命週期
- [ ] `AppLifecycleState.paused` 時的資源釋放
- [ ] 背景回前景時 state 恢復
- [ ] 低記憶體時 OS 殺 app 的重啟行為

### 6. 裝置覆蓋

**iOS（預設：iPhone 14 Plus, iOS 16.1.1）**:
- [ ] iPhone SE（最小螢幕）
- [ ] iPad（若支援）
- [ ] iOS 16（最低支援版本）
- [ ] Dynamic Island 裝置

**Android（預設：Pixel 8a, Android 16）**:
- [ ] 低階裝置（API 28 / Android 9）
- [ ] 大螢幕折疊手機（Galaxy Fold）
- [ ] Samsung One UI 特有行為

## 時間盒
- 預計時間：[X] 小時
- 重點領域：[按風險排序]
```

---

## a11y-checklist 模板（Flutter 版）

每個 Flutter UI 功能 TC 生成時，自動附加此 checklist：

```markdown
# Flutter a11y 測試檢查清單

## 1. MediaQuery.textScaler（字級縮放，Flutter 核心）

### 觸發路徑
**iOS**（Flutter 會跟隨 Dynamic Type）:
- [ ] 設定 → 顯示與亮度 → 文字大小 → **最大**
- [ ] 設定 → 輔助使用 → 顯示與文字大小 → **較大字體 → 最大**（AX5）

**Android**（Flutter 會跟隨 fontScale）:
- [ ] 設定 → 顯示 → 字型大小 → **最大**
- [ ] 設定 → 顯示 → 顯示大小 → **最大**

### 驗證項目
- [ ] `Text` 元件跟隨放大且版面不破版
- [ ] **裝飾性數字**（計數/徽章）**不應**放大
- [ ] 按鈕文字放大後仍在範圍內
- [ ] 主 Tab Bar / BottomNavigationBar 高度不跳動
- [ ] ListView 可正常滾動看完內容

### 測試寫法（Widget Test）
```dart
testWidgets('reaction count ignores text scaling', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
        child: ReactionCountWidget(count: 12),
      ),
    ),
  );
  // 驗證計數字體大小固定（不受 scaler 影響）
  final text = tester.widget<Text>(find.text('12'));
  expect(text.style?.fontSize, 12);  // 固定 12
});
```

## 2. Semantics / ExcludeSemantics

- [ ] 互動元件有 `Semantics(label: ..., button: true)`
- [ ] 圖示按鈕：`IconButton(tooltip: ...)` 自動生成 label
- [ ] 裝飾性元件用 `ExcludeSemantics` 或 `Semantics(excludeSemantics: true)`
- [ ] 群組資訊用 `MergeSemantics`

### 測試寫法
```dart
testWidgets('button has correct semantics', (tester) async {
  await tester.pumpWidget(MaterialApp(home: MyButton()));
  expect(tester.getSemantics(find.byType(MyButton)).label, 'Submit');
});
```

## 3. VoiceOver / TalkBack 手動驗證

- [ ] iOS: 開啟 VoiceOver，讀取順序與 label 正確
- [ ] Android: 開啟 TalkBack，讀取順序與 contentDescription 正確
- [ ] 自動化：integration_test + `SemanticsBinding` 檢查

## 4. 觸控目標
- [ ] 可點擊區域 ≥ `kMinInteractiveDimension`（48dp）
- [ ] 若 widget 視覺小於 48dp，用 `SizedBox` 或 `Material(InkWell)` 包大熱區

## 5. 對比度與深色模式
- [ ] `ThemeData.light` + `ThemeData.dark` 都驗證
- [ ] 文字 vs 背景 ≥ 4.5:1
- [ ] 可用 Flutter DevTools → Accessibility inspector

## 6. Reduce Motion
- [ ] 聽從 `MediaQuery.disableAnimations`
- [ ] 動畫元件提供 fallback（直接顯示終態）

```dart
final disableAnim = MediaQuery.of(context).disableAnimations;
final duration = disableAnim ? Duration.zero : const Duration(milliseconds: 300);
```

## 7. Root Cause 快速對照（Flutter 跑版）

| 問題 | 原因 | 修正 |
|------|------|------|
| 文字放大破版 | 未限制 textScaler | wrap `MediaQuery(data: ...copyWith(textScaler: TextScaler.linear(maxScale)))` |
| 裝飾數字被放大 | 預設跟 textScaler | `Text('12', textScaler: TextScaler.noScaling)` |
| 元件沒被讀出 | 缺 Semantics | 加 `Semantics(label: ...)` |
| 觸控區太小 | size < 48dp | 用 `SizedBox(width: 48, height: 48)` 包裝 |

## 8. 跨平台配對原則

- Flutter 一份程式碼跑雙平台，但**字級觸發機制不同**（iOS Dynamic Type / Android fontScale）
- a11y bug/優化單**預設開一對**（iOS + Android），用 Relates 連結
- 範例：APP-395（Android）↔ APP-399（iOS）Social 地圖表情計數
```

---

## flutter-test-code 模板

### ViewModel Unit Test

```dart
// test/unit/view_models/home_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../fakes/fake_booking_repository.dart';
import '../fakes/fake_user_repository.dart';

void main() {
  group('HomeViewModel', () {
    late FakeBookingRepository bookingRepo;
    late FakeUserRepository userRepo;
    late HomeViewModel viewModel;

    setUp(() {
      bookingRepo = FakeBookingRepository();
      userRepo = FakeUserRepository();
      viewModel = HomeViewModel(
        bookingRepository: bookingRepo,
        userRepository: userRepo,
      );
    });

    test('Load bookings successfully', () async {
      bookingRepo.createBooking(kBooking);
      await viewModel.loadBookings();
      expect(viewModel.bookings, isNotEmpty);
      expect(viewModel.isLoading, isFalse);
    });

    test('Handle load error gracefully', () async {
      bookingRepo.throwOnNext = true;
      await viewModel.loadBookings();
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.bookings, isEmpty);
    });
  });
}
```

### Widget Test

```dart
// test/widget/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreen', () {
    late HomeViewModel viewModel;
    late FakeBookingRepository bookingRepo;

    setUp(() {
      bookingRepo = FakeBookingRepository()..createBooking(kBooking);
      viewModel = HomeViewModel(
        bookingRepository: bookingRepo,
        userRepository: FakeUserRepository(),
      );
    });

    testWidgets('renders bookings list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(viewModel: viewModel)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Booking 1'), findsOneWidget);
    });

    testWidgets('shows empty state when no bookings', (tester) async {
      final emptyVm = HomeViewModel(
        bookingRepository: FakeBookingRepository(),
        userRepository: FakeUserRepository(),
      );
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(viewModel: emptyVm)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No bookings yet'), findsOneWidget);
    });
  });
}
```

### Fake Repository（優先於 Mock）

```dart
// test/fakes/fake_booking_repository.dart
class FakeBookingRepository implements BookingRepository {
  final List<Booking> _bookings = [];
  bool throwOnNext = false;

  void createBooking(Booking booking) => _bookings.add(booking);

  @override
  Future<List<Booking>> fetchBookings() async {
    if (throwOnNext) {
      throwOnNext = false;
      throw Exception('Simulated network error');
    }
    return List.unmodifiable(_bookings);
  }

  @override
  Future<void> cancelBooking(String id) async {
    _bookings.removeWhere((b) => b.id == id);
  }
}
```

### Integration Test

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login → Home flow', () {
    testWidgets('login and see bookings', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Fill login form
      await tester.enterText(find.byKey(const ValueKey('email')), 'test@example.com');
      await tester.enterText(find.byKey(const ValueKey('password')), 'password123');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      // Verify landed on home
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

### Golden Test

```dart
// test/golden/home_screen_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeScreen matches golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(viewModel: _buildFakeViewModel())),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen.png'),
    );
  });
}
```

### Platform Channel Test

```dart
// test/unit/services/payment_service_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example/payment');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'pay') return {'status': 'success', 'txId': 'TX123'};
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('pay returns success', () async {
    final service = PaymentService();
    final result = await service.pay(amount: 100);
    expect(result.status, 'success');
    expect(result.txId, 'TX123');
  });
}
```
