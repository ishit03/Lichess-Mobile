import 'package:lichess_mobile/src/app_initialization.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'package_info.g.dart';

@Riverpod(keepAlive: true)
PackageInfo packageInfo(PackageInfoRef ref) {
  // requireValue is possible because appInitializationProvider is loaded before
  // anything. See: lib/src/app.dart
  return ref.read(appInitializationProvider).requireValue.packageInfo;
}
