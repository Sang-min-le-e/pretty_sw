import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/connected_device.dart';

abstract class DeviceRepository {
  /// `GET /children/:childId/devices`. `PENDING` 기기도 함께 내려온다.
  Future<List<ConnectedDevice>> getDevices(int childId);

  /// `GET /devices/:deviceId` — 페어링 폴링용.
  Future<ConnectedDevice> getDevice(int deviceId);

  /// `POST /devices/pairing` — 페어링 코드 발급.
  Future<PairingTicket> createPairing({required int childId, required String nickname});

  /// `PATCH /devices/:deviceId` — 별칭 변경.
  Future<void> renameDevice(int deviceId, String nickname);

  /// `DELETE /devices/:deviceId` — 연결 해제(서버는 soft delete).
  Future<void> deleteDevice(int deviceId);
}

class ApiDeviceRepository implements DeviceRepository {
  ApiDeviceRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<ConnectedDevice>> getDevices(int childId) async {
    try {
      final response = await _apiClient.dio.get('/children/$childId/devices');
      return (response.data['data'] as List)
          .map((raw) => ConnectedDevice.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<ConnectedDevice> getDevice(int deviceId) async {
    try {
      final response = await _apiClient.dio.get('/devices/$deviceId');
      return ConnectedDevice.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<PairingTicket> createPairing({
    required int childId,
    required String nickname,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/devices/pairing',
        data: {'childId': childId, 'nickname': nickname},
      );
      return PairingTicket.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> renameDevice(int deviceId, String nickname) async {
    try {
      await _apiClient.dio.patch('/devices/$deviceId', data: {'nickname': nickname});
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }

  @override
  Future<void> deleteDevice(int deviceId) async {
    try {
      await _apiClient.dio.delete('/devices/$deviceId');
    } on DioException catch (e) {
      throwAsApiException(e);
    }
  }
}
