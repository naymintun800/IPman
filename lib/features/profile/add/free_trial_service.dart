import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

part 'free_trial_service.g.dart';

class FreeTrialFailure implements Exception {
  final String message;
  const FreeTrialFailure(this.message);

  @override
  String toString() => message;
}

@riverpod
class FreeTrialService extends _$FreeTrialService with InfraLogger {
  final _secureStorage = const FlutterSecureStorage();
  static const String _deviceIdKey = 'free_trial_device_id';
  static const String _hasClaimedKey = 'has_claimed_free_trial';
  static const String _subscriptionUrlKey = 'free_trial_subscription_url';

  // NocoDB configuration from .env
  String get _apiUrl => dotenv.env['NOCO_API_URL'] ?? '';
  String get _apiKey => dotenv.env['NOCO_API_KEY'] ?? '';
  String get _tableId => 'my82k2q7trs0he1'; // Your NocoDB table ID

  // VPN API configuration from .env
  String get _vpnApiUrl => dotenv.env['VPN_API_URL'] ?? '';
  String get _vpnApiKey => dotenv.env['HIDDIFY_API_KEY'] ?? '';
  String get _userPath => dotenv.env['USER_PATH'] ?? '';
  String get _proxyPath => dotenv.env['PROXY_PATH'] ?? '';

  @override
  Future<bool> build() async {
    // Check if free trial has been claimed locally
    final hasClaimed = await _secureStorage.read(key: _hasClaimedKey);
    return hasClaimed == 'true';
  }

  Future<String?> getStoredSubscriptionUrl() async {
    return await _secureStorage.read(key: _subscriptionUrlKey);
  }

  Future<String> claimFreeTrial() async {
    try {
      // Get or generate device fingerprint
      final deviceId = await _getOrCreateDeviceId();

      // Check local storage first
      final hasClaimed = await _secureStorage.read(key: _hasClaimedKey);
      final storedUrl = await _secureStorage.read(key: _subscriptionUrlKey);

      if (hasClaimed == 'true' && storedUrl != null && storedUrl.isNotEmpty) {
        return storedUrl;
      }

      // Check NocoDB to see if this device already claimed
      final existingClaim = await _checkExistingClaim(deviceId);
      if (existingClaim != null) {
        // Already claimed, update local storage
        await _secureStorage.write(key: _hasClaimedKey, value: 'true');
        await _secureStorage.write(key: _subscriptionUrlKey, value: existingClaim);
        state = const AsyncData(true);
        return existingClaim;
      }

      // Create new 1GB profile
      final subscriptionUrl = await _createFreeTrialProfile(deviceId);

      // Save to NocoDB
      await _saveClaimToNocoDB(deviceId, subscriptionUrl);

      // Update local storage
      await _secureStorage.write(key: _hasClaimedKey, value: 'true');
      await _secureStorage.write(key: _subscriptionUrlKey, value: subscriptionUrl);
      state = const AsyncData(true);

      return subscriptionUrl;
    } catch (e, stack) {
      loggy.error('Error claiming free trial', e, stack);
      throw FreeTrialFailure('Failed to claim free trial: $e');
    }
  }

  Future<String?> _checkExistingClaim(String deviceId) async {
    try {
      final dio = Dio();
      dio.options.headers['xc-token'] = _apiKey;

      // Query NocoDB for this device ID
      final response = await dio.get(
        '$_apiUrl/api/v2/tables/$_tableId/records',
        queryParameters: {
          'where': '(device_id,eq,$deviceId)',
        },
      );

      if (response.statusCode != 200) {
        loggy.error('Failed to check NocoDB: ${response.statusCode}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final list = data['list'] as List?;

      if (list == null || list.isEmpty) {
        return null; // No existing claim
      }

      // Return the subscription URL from the existing claim
      final record = list[0] as Map<String, dynamic>;
      return record['subscription_url'] as String?;
    } catch (e) {
      loggy.error('Error checking existing claim', e);
      return null; // Assume no claim if error
    }
  }

  Future<void> _saveClaimToNocoDB(String deviceId, String subscriptionUrl) async {
    try {
      final dio = Dio();
      dio.options.headers['xc-token'] = _apiKey;

      // Get device info for additional data
      final deviceInfo = await _collectDeviceInfo();

      // Save to NocoDB
      await dio.post(
        '$_apiUrl/api/v2/tables/$_tableId/records',
        data: {
          'device_id': deviceId,
          'subscription_url': subscriptionUrl,
          'claimed_at': DateTime.now().toIso8601String(),
          'device_info': jsonEncode(deviceInfo),
          'ip_address': await _getIpAddress(),
        },
      );
    } catch (e) {
      loggy.error('Error saving claim to NocoDB', e);
      // Continue anyway, since we have the subscription URL
    }
  }

  Future<String> _createFreeTrialProfile(String deviceId) async {
    try {
      final dio = Dio();

      // Create request to your VPN API
      final response = await dio.post(
        '$_vpnApiUrl/$_proxyPath/api/v2/admin/user/',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Hiddify-API-Key': _vpnApiKey,
          },
        ),
        data: {
          'enable': true,
          'is_active': true,
          'lang': 'en',
          'mode': 'no_reset',
          'name': 'IPman Free 1 GB',
          'package_days': 3650,
          'usage_limit_GB': 1,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw FreeTrialFailure('Failed to create VPN profile: ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final uuid = data['uuid'] as String?;

      if (uuid == null || uuid.isEmpty) {
        throw const FreeTrialFailure('Invalid UUID received from VPN API');
      }

      // Construct subscription URL
      return '$_vpnApiUrl/$_userPath/$uuid/';
    } catch (e) {
      loggy.error('Error creating free trial profile', e);
      throw FreeTrialFailure('Failed to create VPN profile: $e');
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    // Try to get existing device ID
    final storedId = await _secureStorage.read(key: _deviceIdKey);
    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }

    // Generate new device fingerprint
    final deviceId = await _generateDeviceFingerprint();
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    return deviceId;
  }

  Future<String> _generateDeviceFingerprint() async {
    // Get device info
    final deviceInfo = await _collectDeviceInfo();

    // Add a salt to make it harder to spoof
    deviceInfo['salt'] = 'ipman-app-fingerprint-$_apiKey';

    // Generate a hash from the collected data
    final dataStr = json.encode(deviceInfo);
    final bytes = utf8.encode(dataStr);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final data = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        data['id'] = info.id;
        data['brand'] = info.brand;
        data['model'] = info.model;
        data['fingerprint'] = info.fingerprint;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        data['id'] = info.identifierForVendor;
        data['model'] = info.model;
        data['name'] = info.name;
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        data['id'] = info.computerName;
        data['machineId'] = info.deviceId;
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        data['id'] = info.machineId;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        data['id'] = info.systemGUID;
        data['model'] = info.model;
      }

      // Add installation timestamp as additional identifier
      data['installTime'] = DateTime.now().toIso8601String();

      return data;
    } catch (e) {
      // Fallback if device info collection fails
      return {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'fallback': true,
      };
    }
  }

  Future<String> _getIpAddress() async {
    try {
      final response = await Dio().get('https://api.ipify.org');
      return response.data.toString();
    } catch (e) {
      return 'unknown';
    }
  }

// For testing only - completely resets both claim status and device ID
  Future<void> resetEverythingForTesting() async {
    // Delete all storage keys
    await _secureStorage.delete(key: _hasClaimedKey);
    await _secureStorage.delete(key: _subscriptionUrlKey);
    await _secureStorage.delete(key: _deviceIdKey); // Also delete the device ID

    // Reset state
    state = const AsyncData(false);

    // Log for debugging
    loggy.info('Free trial completely reset for testing');
  }
}
