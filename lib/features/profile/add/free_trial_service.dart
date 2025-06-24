import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
      // Check if this is an emulator
      final isDeviceEmulator = await isEmulator();
      if (isDeviceEmulator) {
        loggy.info('Emulator detected - using special handling for testing');
      }

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

      // We're not limiting by IP address anymore to avoid blocking legitimate users behind shared IPs
      // Instead, we rely on our enhanced device fingerprinting for abuse prevention
      // We still collect IP for analytics in _saveClaimToNocoDB

      // For emulators, add a special note to the device ID to track testing claims
      final effectiveDeviceId = isDeviceEmulator ? "$deviceId-EMULATOR-TEST" : deviceId;

      // Create new 1GB profile
      final subscriptionUrl = await _createFreeTrialProfile(effectiveDeviceId);

      // Save to NocoDB
      await _saveClaimToNocoDB(effectiveDeviceId, subscriptionUrl);

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

  // Note: We've removed IP-based rate limiting to avoid blocking legitimate users
  // who might share the same IP address (e.g., through VPNs, NAT networks, etc.)
  // We still collect IP addresses for analytics purposes in _saveClaimToNocoDB
  // This comment is selected by the user in the code editor

  Future<String?> _checkExistingClaim(String deviceId) async {
    try {
      final dio = Dio();
      dio.options.headers['xc-token'] = _apiKey;

      // First, try to find by exact device ID
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

      if (list != null && list.isNotEmpty) {
        // Found by exact device ID
        final record = list[0] as Map<String, dynamic>;
        return record['subscription_url'] as String?;
      }

      // If not found by device ID, try to find by device info
      final deviceInfo = await _collectDeviceInfo();

      // Check for Android devices using more reliable identifiers
      if (Platform.isAndroid) {
        // Try to match by fingerprint, model, and manufacturer
        final fingerprint = deviceInfo['fingerprint'];
        final model = deviceInfo['model'];
        final manufacturer = deviceInfo['manufacturer'];

        if (fingerprint != null && model != null && manufacturer != null) {
          // Search for records with similar device info
          final secondResponse = await dio.get(
            '$_apiUrl/api/v2/tables/$_tableId/records',
          );

          if (secondResponse.statusCode == 200) {
            final allData = secondResponse.data as Map<String, dynamic>;
            final allRecords = allData['list'] as List?;

            if (allRecords != null) {
              // Look for matching device info in all records
              for (final record in allRecords) {
                final recordMap = record as Map<String, dynamic>;
                final deviceInfoStr = recordMap['device_info'] as String?;

                if (deviceInfoStr != null) {
                  try {
                    final recordDeviceInfo = json.decode(deviceInfoStr) as Map<String, dynamic>;

                    // Check if critical hardware identifiers match
                    if (recordDeviceInfo['fingerprint'] == fingerprint && recordDeviceInfo['model'] == model && recordDeviceInfo['manufacturer'] == manufacturer) {
                      loggy.info('Found matching device by hardware identifiers');
                      return recordMap['subscription_url'] as String?;
                    }
                  } catch (e) {
                    // Continue to next record if parsing fails
                    continue;
                  }
                }
              }
            }
          }
        }
      }

      return null; // No existing claim found
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

      // Generate a unique profile name with a short 4-character unique ID
      // This ensures each profile has a unique name while keeping it concise

      // Create a 4-character unique ID
      // We'll use a combination of device ID and timestamp to ensure uniqueness
      String uniqueId;

      // Get the last 4 digits of the current timestamp
      final timestampStr = DateTime.now().millisecondsSinceEpoch.toString();
      final timestampPart = timestampStr.substring(timestampStr.length - 4);

      // If the device ID is at least 2 characters, use first 2 chars + timestamp digits
      if (deviceId.length >= 2) {
        uniqueId = deviceId.substring(0, 2) + timestampPart.substring(0, 2);
      } else {
        // Otherwise just use the 4 timestamp digits
        uniqueId = timestampPart;
      }

      // Combine to create a unique profile name
      final profileName = '${uniqueId}_FREE-1GB';

      // Create request to your VPN API
      final response = await dio.post(
        '$_vpnApiUrl/api/user',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': _vpnApiKey,
          },
        ),
        data: {
          'data_limit': 1073741824, // 1GB in bytes
          'data_limit_reset_strategy': 'no_reset',
          'expire': 0,
          'inbounds': {
            'vless': ['VLESS TCP REALITY']
          },
          'proxies': {
            'vless': {'flow': 'xtls-rprx-vision'}
          },
          'status': 'active',
          'username': profileName,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw FreeTrialFailure('Failed to create VPN profile: ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final subscriptionUrl = data['subscription_url'] as String?;

      if (subscriptionUrl == null || subscriptionUrl.isEmpty) {
        throw const FreeTrialFailure('Invalid subscription_url received from VPN API');
      }

      return subscriptionUrl;
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

    // Create a more stable fingerprint by only using hardware identifiers
    // that don't change between installations
    final stableIdentifiers = <String, dynamic>{};

    if (Platform.isAndroid) {
      // Use the most stable identifiers for Android
      if (deviceInfo['fingerprint'] != null) stableIdentifiers['fingerprint'] = deviceInfo['fingerprint'];
      if (deviceInfo['model'] != null) stableIdentifiers['model'] = deviceInfo['model'];
      if (deviceInfo['manufacturer'] != null) stableIdentifiers['manufacturer'] = deviceInfo['manufacturer'];
      if (deviceInfo['brand'] != null) stableIdentifiers['brand'] = deviceInfo['brand'];
      if (deviceInfo['device'] != null) stableIdentifiers['device'] = deviceInfo['device'];
      if (deviceInfo['product'] != null) stableIdentifiers['product'] = deviceInfo['product'];
      if (deviceInfo['hardware'] != null) stableIdentifiers['hardware'] = deviceInfo['hardware'];

      // Add a flag to indicate if this is an emulator
      stableIdentifiers['isEmulator'] = !(deviceInfo['isPhysicalDevice'] as bool? ?? true);
    } else if (Platform.isIOS) {
      // Use stable identifiers for iOS
      if (deviceInfo['model'] != null) stableIdentifiers['model'] = deviceInfo['model'];
      if (deviceInfo['systemName'] != null) stableIdentifiers['systemName'] = deviceInfo['systemName'];
      if (deviceInfo['utsname'] != null) stableIdentifiers['utsname'] = deviceInfo['utsname'];
      if (deviceInfo['isPhysicalDevice'] != null) stableIdentifiers['isPhysicalDevice'] = deviceInfo['isPhysicalDevice'];
    } else {
      // For other platforms, use what we have
      stableIdentifiers.addAll(deviceInfo);
    }

    // Add a salt to make it harder to spoof
    stableIdentifiers['salt'] = 'ipman-app-fingerprint-$_apiKey';

    // Add a version number to the fingerprinting method
    // This allows you to update the algorithm in the future if needed
    stableIdentifiers['version'] = 'v1.1';

    // Generate a hash from the stable data
    final dataStr = json.encode(stableIdentifiers);
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
        // Collect more identifiers for better fingerprinting
        data['id'] = info.id;
        data['brand'] = info.brand;
        data['model'] = info.model;
        data['fingerprint'] = info.fingerprint;
        data['board'] = info.board;
        data['bootloader'] = info.bootloader;
        data['device'] = info.device;
        data['display'] = info.display;
        data['hardware'] = info.hardware;
        data['host'] = info.host;
        data['manufacturer'] = info.manufacturer;
        data['product'] = info.product;
        data['serialNumber'] = info.serialNumber;
        data['supportedAbis'] = info.supportedAbis.join(',');
        data['tags'] = info.tags;
        data['type'] = info.type;
        data['isPhysicalDevice'] = info.isPhysicalDevice;
        // Note: androidId is not directly available in newer versions of device_info_plus
        // Use a combination of other identifiers instead
        data['systemFeatures'] = info.systemFeatures.join(',');
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        data['id'] = info.identifierForVendor;
        data['model'] = info.model;
        data['name'] = info.name;
        data['systemName'] = info.systemName;
        data['systemVersion'] = info.systemVersion;
        data['localizedModel'] = info.localizedModel;
        data['utsname'] = '${info.utsname.sysname}-${info.utsname.nodename}-${info.utsname.machine}';
        data['isPhysicalDevice'] = info.isPhysicalDevice;
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        data['id'] = info.computerName;
        data['machineId'] = info.deviceId;
        data['numberOfCores'] = info.numberOfCores;
        data['systemMemoryInMegabytes'] = info.systemMemoryInMegabytes;
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        data['id'] = info.machineId;
        data['version'] = info.version;
        data['name'] = info.name;
        data['buildId'] = info.buildId;
        data['variant'] = info.variant;
        data['variantId'] = info.variantId;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        data['id'] = info.systemGUID;
        data['model'] = info.model;
        data['kernelVersion'] = info.kernelVersion;
        data['osRelease'] = info.osRelease;
        data['activeCPUs'] = info.activeCPUs;
        data['memorySize'] = info.memorySize;
        data['cpuFrequency'] = info.cpuFrequency;
      }

      // Don't include installation timestamp as it changes with each install
      // Instead, use more hardware-specific identifiers

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

  // Check if the current device is likely an emulator
  Future<bool> isEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        // Check multiple indicators that suggest an emulator
        final isEmulator = !info.isPhysicalDevice || info.brand.toLowerCase().contains('google') || info.model.toLowerCase().contains('sdk') || info.fingerprint.toLowerCase().contains('generic') || info.product.toLowerCase().contains('sdk');
        return isEmulator;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return !info.isPhysicalDevice;
      }

      // For other platforms, assume not an emulator
      return false;
    } catch (e) {
      // If we can't determine, assume it's not an emulator
      return false;
    }
  }
}
