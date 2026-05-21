# Flutter 自動化測試 Patterns

---

## 🧱 架構原則總覽

```
┌─────────────────────────────────────────────┐
│ Integration Test (E2E)          10%         │
│ integration_test package + 實機              │
├─────────────────────────────────────────────┤
│ Widget Test (Component)         20%         │
│ flutter_test + WidgetTester                 │
├─────────────────────────────────────────────┤
│ Unit Test (Logic)               70%         │
│ test / flutter_test + Fake                  │
└─────────────────────────────────────────────┘
```

核心原則：
1. **Fake > Mock**：優先建 Fake 實作（官方推薦）
2. **ValueKey locator**：UI test 用 `ValueKey` 而非 text / index
3. **Robot / Page Object Pattern**：封裝互動邏輯
4. **AAA 結構**：Arrange / Act / Assert
5. **不依賴真實 I/O**：Unit/Widget test 不碰網路、磁碟、平台

---

## 1️⃣ Unit Test Pattern

### ViewModel 測試（注入 Fake）

```dart
// test/unit/view_models/login_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../../fakes/fake_auth_repository.dart';

void main() {
  group('LoginViewModel', () {
    late FakeAuthRepository authRepo;
    late LoginViewModel viewModel;

    setUp(() {
      authRepo = FakeAuthRepository();
      viewModel = LoginViewModel(authRepository: authRepo);
    });

    // TC: BB-FLT-001 — 成功登入
    test('successful login sets authenticated state', () async {
      // Arrange
      authRepo.setUser(const User(id: '1', email: 'a@b.com'));

      // Act
      await viewModel.login('a@b.com', 'pwd');

      // Assert
      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.errorMessage, isNull);
    });

    // TC: BB-FLT-002 — 密碼錯誤
    test('wrong password shows error', () async {
      authRepo.throwOnNext = const AuthException('Invalid credentials');

      await viewModel.login('a@b.com', 'wrong');

      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.errorMessage, 'Invalid credentials');
    });
  });
}
```

### Repository 測試（Mock HTTP）

```dart
// test/unit/repositories/user_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('UserRepository', () {
    late MockHttpClient httpClient;
    late UserRepository repo;

    setUp(() {
      httpClient = MockHttpClient();
      repo = UserRepository(client: httpClient);
    });

    // TC: WB-FLT-010 — 500 錯誤降級
    test('fetchUser falls back to cache on 500', () async {
      when(() => httpClient.get(any()))
          .thenAnswer((_) async => http.Response('error', 500));

      final user = await repo.fetchUser('123');

      expect(user, isA<CachedUser>());
    });
  });
}
```

### Fake 實作（優先於 Mock）

```dart
// test/fakes/fake_auth_repository.dart
class FakeAuthRepository implements AuthRepository {
  User? _user;
  AuthException? throwOnNext;
  int loginCallCount = 0;

  void setUser(User user) => _user = user;

  @override
  Future<User?> login(String email, String password) async {
    loginCallCount++;
    if (throwOnNext != null) {
      final e = throwOnNext!;
      throwOnNext = null;
      throw e;
    }
    return _user;
  }

  @override
  Future<void> logout() async => _user = null;

  @override
  User? get currentUser => _user;
}
```

---

## 2️⃣ Widget Test Pattern

### 基本 Widget Test

```dart
// test/widget/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../fakes/fake_auth_repository.dart';

void main() {
  group('LoginScreen', () {
    late FakeAuthRepository authRepo;
    late LoginViewModel viewModel;

    setUp(() {
      authRepo = FakeAuthRepository()
          .setUser(const User(id: '1', email: 'a@b.com'));
      viewModel = LoginViewModel(authRepository: authRepo);
    });

    // TC: BB-FLT-020 — 表單驗證錯誤
    testWidgets('shows error when email is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(viewModel: viewModel)),
      );

      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    // TC: BB-FLT-021 — 成功登入跳轉
    testWidgets('navigates on successful login', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(viewModel: viewModel)),
      );

      await tester.enterText(
          find.byKey(const ValueKey('email_field')), 'a@b.com');
      await tester.enterText(
          find.byKey(const ValueKey('password_field')), 'pwd');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
```

### Robot Pattern（封裝互動）

```dart
// test/widget/robots/login_robot.dart
class LoginRobot {
  final WidgetTester tester;

  LoginRobot(this.tester);

  Future<void> enterEmail(String email) async {
    await tester.enterText(find.byKey(const ValueKey('email_field')), email);
  }

  Future<void> enterPassword(String password) async {
    await tester.enterText(find.byKey(const ValueKey('password_field')), password);
  }

  Future<void> tapLogin() async {
    await tester.tap(find.byKey(const ValueKey('login_button')));
    await tester.pumpAndSettle();
  }

  void expectError(String message) {
    expect(find.text(message), findsOneWidget);
  }

  void expectNavigatedToHome() {
    expect(find.byType(HomeScreen), findsOneWidget);
  }
}
```

使用 Robot：

```dart
testWidgets('login flow via robot', (tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginScreen(viewModel: vm)));
  final robot = LoginRobot(tester);

  await robot.enterEmail('a@b.com');
  await robot.enterPassword('pwd');
  await robot.tapLogin();

  robot.expectNavigatedToHome();
});
```

---

## 3️⃣ Integration Test Pattern

### E2E 測試

```dart
// integration_test/login_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login → Home flow', () {
    // TC: BB-FLT-E2E-001 — 完整登入流程
    testWidgets('user can login and see home', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const ValueKey('password_field')), 'password123');
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Welcome, test@example.com'), findsOneWidget);
    });
  });
}
```

### Patrol（主力 E2E 工具，本套件 標準）

Patrol 是 `integration_test` 的進階版，特別擅長跨 Flutter + Native 的流程。

#### 安裝與設定

```yaml
# pubspec.yaml
dev_dependencies:
  patrol: ^3.x.x

patrol:
  app_name: uniopen
  android:
    package_name: com.example.app
  ios:
    bundle_id: com.example.app
```

```bash
dart pub global activate patrol_cli
patrol develop  # 本地開發
patrol test     # 跑測試
```

#### 基本語法（用 `$` 取代 `tester`）

```dart
// integration_test/patrol/login_flow_test.dart
import 'package:patrol/patrol.dart';
import 'package:uniopen/main.dart';

void main() {
  patrolTest('user can login', ($) async {
    await $.pumpWidgetAndSettle(const MyApp());

    // 用 text / type / key 找元素
    await $(#email_field).enterText('test@example.com');
    await $(#password_field).enterText('password');
    await $('Login').tap();

    await $.waitUntilVisible($('Welcome'));
    expect($('Welcome'), findsOneWidget);
  });
}
```

#### 🎯 Patrol 核心能力：原生互動

```dart
// 位置權限
patrolTest('grant location permission', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());
  await $(#enable_location).tap();

  // ⭐ 處理原生權限對話框
  await $.native.grantPermissionWhenInUse();

  expect($('Location enabled'), findsOneWidget);
});

// 推播通知
patrolTest('allow push notifications', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());
  await $(#enable_notifications).tap();
  await $.native.grantPermissionOnlyThisTime();
});

// Biometric (Face ID / 指紋)
patrolTest('login with biometric', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());
  await $(#biometric_login).tap();

  // iOS Face ID 模擬
  await $.native.enterTextByIndex('', index: 0);
  // Android 指紋驗證
  // 需要在模擬器上預先註冊指紋
});

// 系統設定（WiFi / 飛航模式）
patrolTest('handle offline mode', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());

  await $.native.disableCellular();
  await $.native.disableWifi();

  await $.pumpAndSettle();
  expect($('No internet connection'), findsOneWidget);

  await $.native.enableWifi();
});

// 跨 App（外部瀏覽器回跳）
patrolTest('OAuth flow via external browser', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());
  await $('Login with Google').tap();

  // Patrol 可以控制外部瀏覽器
  await $.native.pressHome();
  await $.native.openApp('com.example.app');

  // 驗證回到 app 後的狀態
  expect($('Welcome'), findsOneWidget);
});

// 剪貼簿操作
patrolTest('copy and paste verification code', ($) async {
  await $.native.setClipboardText('123456');
  // ...
});

// 鍵盤操作
patrolTest('hide keyboard', ($) async {
  await $(#input).enterText('test');
  await $.native.pressBack();  // 或 pressHome()
});
```

#### Patrol + Robot Pattern

```dart
// integration_test/patrol/robots/login_patrol_robot.dart
import 'package:patrol/patrol.dart';

class LoginPatrolRobot {
  final PatrolTester $;
  LoginPatrolRobot(this.$);

  Future<void> enterEmail(String email) async {
    await $(#email_field).enterText(email);
  }

  Future<void> enterPassword(String password) async {
    await $(#password_field).enterText(password);
  }

  Future<void> tapLogin() async {
    await $('Login').tap();
  }

  Future<void> grantLocationIfPrompted() async {
    await $.native.grantPermissionWhenInUse();
  }

  void expectOnHome() {
    expect($('Welcome'), findsOneWidget);
  }
}
```

使用：

```dart
patrolTest('full login with permissions', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());
  final robot = LoginPatrolRobot($);

  await robot.enterEmail('test@example.com');
  await robot.enterPassword('pwd');
  await robot.tapLogin();
  await robot.grantLocationIfPrompted();
  robot.expectOnHome();
});
```

#### integration_test vs Patrol 的選擇

| 情境 | 用 `integration_test` | 用 Patrol |
|------|---------------------|-----------|
| 純 Flutter 畫面內流程 | ✅ 較輕量 | 也可，但殺雞用牛刀 |
| 原生權限對話框 | ❌ 做不到 | ✅ |
| 系統設定（網路/通知） | ❌ | ✅ |
| 跨 App 流程（OAuth 等） | ❌ | ✅ |
| 生物辨識 | ⚠️ 需 workaround | ✅ |
| CI 執行 | ✅ | ✅（patrol_cli） |
| 學習成本 | 低 | 中 |

#### 執行指令

```bash
# 純 integration_test
flutter test integration_test/login_flow_test.dart

# Patrol
patrol test --target integration_test/patrol/login_flow_test.dart

# Patrol on Android
patrol test --target integration_test/patrol/ \
  --device-id emulator-5554

# Patrol on iOS Simulator
patrol test --target integration_test/patrol/ \
  --device 'iPhone 14 Plus'

# Patrol on Firebase Test Lab
patrol build android --target integration_test/patrol/login_flow_test.dart
gcloud firebase test android run \
  --type instrumentation \
  --use-orchestrator \
  --app build/app/outputs/apk/dev/debug/app-dev-debug.apk \
  --test build/app/outputs/apk/androidTest/dev/debug/app-dev-debug-androidTest.apk
```

---

## 4️⃣ Golden Test Pattern

### 基本 Golden

```dart
// test/golden/home_screen_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeScreen golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(viewModel: _fakeVm())),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen.png'),
    );
  });
}
```

### 使用 alchemist（雙平台 baseline）

```dart
import 'package:alchemist/alchemist.dart';

void main() {
  goldenTest(
    'HomeScreen renders correctly',
    fileName: 'home_screen',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'default',
          child: HomeScreen(viewModel: _fakeVm()),
        ),
        GoldenTestScenario(
          name: 'empty',
          child: HomeScreen(viewModel: _emptyVm()),
        ),
      ],
    ),
  );
}
```

**執行指令**：
- 建立 baseline: `flutter test --update-goldens test/golden/`
- 驗證: `flutter test test/golden/`
- 差異容忍度: 預設 0，可透過 `Alchemist.runWithConfig` 調整

---

## 5️⃣ Platform Channel Test Pattern

### Dart 側 Mock Channel

```dart
// test/unit/services/payment_service_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example/payment');
  final messenger = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'pay':
          return {'status': 'success', 'txId': 'TX123'};
        case 'refund':
          return {'status': 'success'};
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  // TC: WB-FLT-PC-001 — pay 成功回傳
  test('pay returns success result', () async {
    final service = PaymentService();
    final result = await service.pay(amount: 100);
    expect(result.status, 'success');
    expect(result.txId, 'TX123');
  });

  // TC: WB-FLT-PC-002 — pay 異常
  test('pay throws on native error', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'PAY_FAIL', message: 'declined');
    });

    final service = PaymentService();
    expect(() => service.pay(amount: 100), throwsA(isA<PlatformException>()));
  });
}
```

### 原生側（iOS XCTest 範例）

```swift
// ios/RunnerTests/PaymentPluginTests.swift
import XCTest
@testable import Runner

class PaymentPluginTests: XCTestCase {
    func testPayMethodChannel() {
        let plugin = PaymentPlugin()
        let call = FlutterMethodCall(methodName: "pay", arguments: ["amount": 100])
        let expectation = self.expectation(description: "pay returns")

        plugin.handle(call) { result in
            XCTAssertEqual((result as? [String: Any])?["status"] as? String, "success")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }
}
```

### 原生側（Android JUnit 範例）

```kotlin
// android/app/src/test/kotlin/.../PaymentPluginTest.kt
class PaymentPluginTest {
    @Test
    fun `pay method returns success`() {
        val plugin = PaymentPlugin()
        val call = MethodCall("pay", mapOf("amount" to 100))
        val result = mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, result)

        verify(result).success(argThat {
            (this as Map<*, *>)["status"] == "success"
        })
    }
}
```

---

## 6️⃣ 命名慣例

### 測試檔案

| 類型 | 檔名模式 |
|------|---------|
| Unit (ViewModel) | `[name]_view_model_test.dart` |
| Unit (Repository) | `[name]_repository_test.dart` |
| Widget | `[screen_name]_test.dart` |
| Golden | `[name]_golden_test.dart` |
| Integration | `[flow_name]_test.dart` |

### 測試方法

- 描述**行為**，非實作：
  - ❌ `test('testLogin', ...)`
  - ✅ `test('successful login sets authenticated state', ...)`
- Widget test 用 `testWidgets(description, ...)`
- Golden test 用 `testWidgets('[ComponentName] golden', ...)`

### TC ID 註釋

每個測試方法上方加：
```dart
// TC: BB-FLT-001
test('successful login sets authenticated state', () async { ... });
```

---

## 7️⃣ 常見陷阱

| 問題 | 解方 |
|------|------|
| Widget 不 rebuild | 改用 `tester.pumpAndSettle()` 或 `pump(Duration)` |
| StreamController 沒關閉 | `tearDown()` 中呼叫 `close()` |
| Timer pending 錯誤 | 使用 `fakeAsync` 或 `tester.pumpAndSettle(timeout)` |
| Golden 跨平台失敗 | 用 `alchemist` 或按平台分開 baseline |
| Mock HTTP 未重置 | 每個 test 都 `setUp` 重建 mock |
| Integration test 超時 | 增加 `pumpAndSettle(Duration(seconds: N))` |

---

## 8️⃣ 執行指令

```bash
# Unit + Widget
flutter test

# 含覆蓋率
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Golden（首次建立 baseline）
flutter test --update-goldens test/golden/

# Integration（本機）
flutter test integration_test/login_flow_test.dart

# Integration（Web）
chromedriver --port=4444 &
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/login_flow_test.dart \
  -d chrome

# Firebase Test Lab（Android）
flutter build apk --debug
cd android && ./gradlew app:assembleAndroidTest
gcloud firebase test android run --type instrumentation \
  --app ../build/app/outputs/apk/debug/app-debug.apk \
  --test app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk

# Patrol
patrol test --target integration_test/permissions_flow_test.dart
```
