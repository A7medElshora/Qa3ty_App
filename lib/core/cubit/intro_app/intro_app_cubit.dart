import 'package:qa3ty_app/core/services/firebase/firebase_remote_config/remote_config_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'intro_app_state.dart';

class IntroAppCubit extends Cubit<IntroAppState> {
  IntroAppCubit() : super(IntroAppInitial());

  Future<void> initApp() => refreshRemoteConfig();

  Future<void> refreshRemoteConfig({bool forceFetch = false}) async {
    try {
      await FRConfig.instance.refreshRemoteConfig(forceFetch: forceFetch);
      final isUserForcedToUpdate = await FRConfig.instance.isNeedForceUpdate();
      if (isUserForcedToUpdate) {
        emit(
          ForceUpdate(
            appLink: FRConfig.instance.appLink(),
            latestVersionName: FRConfig.instance.latestVersionName,
          ),
        );
        return;
      }

      if (FRConfig.instance.isAppUnderMaintenance) {
        emit(AppUnderMaintenance());
      } else {
        emit(NoRestriction());
      }
    } on Exception catch (error) {
      debugPrint('Intro app Remote Config check failed: $error');
      if (state is! ForceUpdate) emit(NoRestriction());
    }
  }
}
