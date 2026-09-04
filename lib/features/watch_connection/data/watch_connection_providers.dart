import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ble/ble_service.dart';

final bleServiceProvider = Provider((ref) => BleService());

final watchScanProvider = StreamProvider((ref) {
  return ref.watch(bleServiceProvider).scanForWatch();
});
