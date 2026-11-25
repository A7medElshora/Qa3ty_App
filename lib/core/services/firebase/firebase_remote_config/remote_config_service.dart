import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qa3ty_app/core/config/env.dart';

/// [FRConfig] is stands for Firebase Remote Config.
class FRConfig {
  static final FRConfig instance = FRConfig._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  Future<void>? _configuration;
  Future<void>? _fetchInProgress;
  DateTime? _lastFetchAttempt;

  FRConfig._();

  bool get _isIos => Platform.isIOS;

  String get contactUsLink {
    return _remoteConfig
        .getString(_isIos ? 'contact_us_link_ios' : 'contact_us_link');
  }

  String get storeAppLink => _remoteConfig.getString('update_link');

  String get latestVersionName =>
      _remoteConfig.getString('latest_version_name');

  bool get isAppUnderMaintenance =>
      _remoteConfig.getBool('is_under_maintenance');

  static bool isBuildUpdateRequired({
    required int currentBuildNumber,
    required int forceUpdateBuild,
  }) {
    return forceUpdateBuild > 0 && currentBuildNumber < forceUpdateBuild;
  }

  Future<void> refreshRemoteConfig({bool forceFetch = false}) async {
    await _ensureConfigured();

    final minimumFetchInterval = AppConfig.current.isDevelopment
        ? Duration.zero
        : const Duration(hours: 1);
    final inProgress = _fetchInProgress;
    if (inProgress != null) {
      await inProgress;
      return;
    }

    final now = DateTime.now();
    final lastAttempt = _lastFetchAttempt;
    if (!forceFetch &&
        !AppConfig.current.isDevelopment &&
        lastAttempt != null &&
        now.difference(lastAttempt) < minimumFetchInterval) {
      return;
    }

    _lastFetchAttempt = now;
    final fetch = _fetchAndActivate();
    _fetchInProgress = fetch;
    try {
      await fetch;
    } finally {
      if (identical(_fetchInProgress, fetch)) _fetchInProgress = null;
    }
  }

  Future<void> _fetchAndActivate() async {
    try {
      final activated = await _remoteConfig.fetchAndActivate().timeout(
            const Duration(seconds: 10),
          );
      debugPrint(
        'Remote Config fetch completed: activated=$activated, '
        'force_update_build=${_remoteConfig.getInt('force_update_build')}, '
        'update_link_configured=${_remoteConfig.getString('update_link').isNotEmpty}',
      );
    } on Exception catch (error) {
      debugPrint('Remote Config fetch failed; using cached values: $error');
    }
  }

  Future<bool> isNeedForceUpdate() async {
    await _ensureConfigured();

    final int? currentBuildNumber;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentBuildNumber = int.tryParse(packageInfo.buildNumber);
    } on Exception catch (error) {
      debugPrint('Could not read the current build number: $error');
      return false;
    }
    if (currentBuildNumber == null) return false;

    final forceUpdateBuild = _remoteConfig.getInt('force_update_build');
    debugPrint(
      'Force update check: current build=$currentBuildNumber, '
      'force_update_build=$forceUpdateBuild',
    );
    return isBuildUpdateRequired(
      currentBuildNumber: currentBuildNumber,
      forceUpdateBuild: forceUpdateBuild,
    );
  }

  Future<void> _ensureConfigured() async {
    final existingConfiguration = _configuration;
    if (existingConfiguration != null) {
      await existingConfiguration;
      return;
    }

    final configuration = _configure();
    _configuration = configuration;
    try {
      await configuration;
    } on Exception catch (error) {
      _configuration = null;
      debugPrint('Remote Config setup failed; using cached values: $error');
    }
  }

  Future<void> _configure() async {
    final minimumFetchInterval = AppConfig.current.isDevelopment
        ? Duration.zero
        : const Duration(hours: 1);

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: minimumFetchInterval,
      ),
    );
    await _remoteConfig.setDefaults({
      'force_update_build': 0,
      'update_link': '',
      'latest_version_name': '',
      'is_under_maintenance': false,
    });
    await _remoteConfig.activate();
  }

  String appLink() => storeAppLink;
}
