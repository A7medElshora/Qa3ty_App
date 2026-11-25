part of 'intro_app_cubit.dart';

@immutable
abstract class IntroAppState {}

class IntroAppInitial extends IntroAppState {}

class ForceUpdate extends IntroAppState {
  final String appLink;
  final String latestVersionName;

  ForceUpdate({required this.appLink, this.latestVersionName = ''});
}

class NoRestriction extends IntroAppState {}

class AppUnderMaintenance extends IntroAppState {}
