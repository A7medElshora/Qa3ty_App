import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/core/services/firebase/firebase_remote_config/remote_config_service.dart';

void main() {
  group('force update build comparison', () {
    test('a zero config build does not require an update', () {
      expect(
        FRConfig.isBuildUpdateRequired(
          currentBuildNumber: 2,
          forceUpdateBuild: 0,
        ),
        isFalse,
      );
    });

    test('the current build does not require an update', () {
      expect(
        FRConfig.isBuildUpdateRequired(
          currentBuildNumber: 2,
          forceUpdateBuild: 2,
        ),
        isFalse,
      );
    });

    test('a higher configured build requires an update', () {
      expect(
        FRConfig.isBuildUpdateRequired(
          currentBuildNumber: 2,
          forceUpdateBuild: 3,
        ),
        isTrue,
      );
    });

    test('a missing config build defaults to no update', () {
      const int? missingConfigBuild = null;
      expect(
        FRConfig.isBuildUpdateRequired(
          currentBuildNumber: 2,
          forceUpdateBuild: missingConfigBuild ?? 0,
        ),
        isFalse,
      );
    });
  });
}
