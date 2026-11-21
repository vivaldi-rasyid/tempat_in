import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempat_in/controllers/auth_controller.dart';
import 'package:tempat_in/core/constants.dart';
import 'package:tempat_in/repositories/mock/mock_repositories.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('rejects non-student email and accepts demo account', () async {
    final auth = AuthController(MockAuthRepository());

    final bad = await auth.login('user@gmail.com', 'password123');
    expect(bad, isFalse);
    expect(auth.errorMessage, isNotNull);

    final ok = await auth.login(
      AppConstants.demoEmail,
      AppConstants.demoPassword,
    );
    expect(ok, isTrue);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentUser?.email, AppConstants.demoEmail);
  });

  test('MockRoomRepository emits live room updates', () async {
    final repo = MockRoomRepository(
      tickInterval: const Duration(milliseconds: 20),
    );
    addTearDown(repo.dispose);

    final updated = await repo.watchRooms().first;
    expect(updated.length, greaterThanOrEqualTo(15));
  });
}