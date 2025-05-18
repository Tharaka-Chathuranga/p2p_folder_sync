import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/device_info.dart';

enum ConnectionState {
  disconnected,
  connecting,
  connected,
}

class DeviceDiscoveryService {
  final Nearby _nearby = Nearby();
  final String _serviceId = 'com.mobilex.p2pfolderSync';
  
  // Maps device ID to DeviceInfo
  final Map<String, DeviceInfo> _discoveredDevices = {};
  
  // Connection state tracking
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _connectedDeviceId;
  
  // Callbacks
  Function(DeviceInfo)? onDeviceDiscovered;
  Function(DeviceInfo)? onDeviceDisconnected;
  Function(DeviceInfo)? onDeviceConnected;
  Function(DeviceInfo, String)? onConnectionFailed;
  Function(DeviceInfo, Uint8List, bool)? onDataReceived;
  Function(ConnectionState)? onConnectionStateChanged;

  // Getters
  List<DeviceInfo> get discoveredDevices => _discoveredDevices.values.toList();
  ConnectionState get connectionState => _connectionState;
  DeviceInfo? get connectedDevice => 
      _connectedDeviceId != null ? _discoveredDevices[_connectedDeviceId] : null;

  // Set connection state and notify listeners
  void _setConnectionState(ConnectionState state) {
    _connectionState = state;
    if (onConnectionStateChanged != null) {
      onConnectionStateChanged!(state);
    }
  }

  // Check if platform is supported
  bool _isPlatformSupported() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  // Request location permission (required for Nearby Connections)
  Future<bool> requestLocationPermission() async {
    try {
      if (!_isPlatformSupported()) {
        print('Nearby Connections is only supported on Android and iOS');
        return false;
      }
      
      // For newer versions of the package, permissions are handled during
      // startAdvertising/startDiscovery or using permission_handler
      return true;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }
  
  // Start advertising this device to be discovered by others
  Future<bool> startAdvertising(String deviceName) async {
    if (!_isPlatformSupported()) {
      print('Nearby Connections is only supported on Android and iOS');
      return false;
    }
    
    try {
      bool permissionGranted = await requestLocationPermission();
      if (!permissionGranted) {
        return false;
      }
      
      // Get the device info to advertise
      final deviceInfo = DeviceInfo(
        id: await _getDeviceId(),
        name: deviceName,
        deviceType: 'android',
        isAvailable: true,
      );
      
      final Strategy strategy = Strategy.P2P_CLUSTER;
      
      return await _nearby.startAdvertising(
        deviceInfo.name,
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
    } catch (e) {
      print('Error starting advertising: $e');
      return false;
    }
  }
  
  // Stop advertising
  Future<bool> stopAdvertising() async {
    if (!_isPlatformSupported()) {
      return true;
    }
    
    try {
      await _nearby.stopAdvertising();
      return true;
    } catch (e) {
      print('Error stopping advertising: $e');
      return false;
    }
  }
  
  // Start discovering nearby devices
  Future<bool> startDiscovery() async {
    if (!_isPlatformSupported()) {
      print('Nearby Connections is only supported on Android and iOS');
      return false;
    }
    
    try {
      bool permissionGranted = await requestLocationPermission();
      if (!permissionGranted) {
        return false;
      }
      
      final Strategy strategy = Strategy.P2P_CLUSTER;
      
      // Clear previous devices
      _discoveredDevices.clear();
      
      return await _nearby.startDiscovery(
        await _getDeviceId(),
        strategy,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _serviceId,
      );
    } catch (e) {
      print('Error starting discovery: $e');
      return false;
    }
  }
  
  // Stop discovering devices
  Future<bool> stopDiscovery() async {
    if (!_isPlatformSupported()) {
      return true;
    }
    
    try {
      await _nearby.stopDiscovery();
      return true;
    } catch (e) {
      print('Error stopping discovery: $e');
      return false;
    }
  }
  
  // Connect to a specific device
  Future<bool> connectToDevice(String deviceId) async {
    if (!_isPlatformSupported()) {
      print('Nearby Connections is only supported on Android and iOS');
      return false;
    }
    
    if (!_discoveredDevices.containsKey(deviceId)) {
      return false;
    }
    
    _setConnectionState(ConnectionState.connecting);
    
    final device = _discoveredDevices[deviceId]!;
    device.isConnecting = true;
    
    try {
      final res = await _nearby.requestConnection(
        await _getDeviceId(),
        deviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      
      return res;
    } catch (e) {
      print('Error connecting to device: $e');
      device.isConnecting = false;
      _setConnectionState(ConnectionState.disconnected);
      return false;
    }
  }
  
  // Disconnect from connected device
  Future<bool> disconnect() async {
    if (!_isPlatformSupported() || _connectedDeviceId == null) {
      return true;
    }
    
    try {
      await _nearby.disconnectFromEndpoint(_connectedDeviceId!);
      _connectedDeviceId = null;
      _setConnectionState(ConnectionState.disconnected);
      return true;
    } catch (e) {
      print('Error disconnecting: $e');
      return false;
    }
  }
  
  // Send data to connected device
  Future<bool> sendData(String deviceId, Uint8List data) async {
    if (!_isPlatformSupported() || _connectionState != ConnectionState.connected) {
      return false;
    }
    
    try {
      final success = _nearby.sendBytesPayload(deviceId, data);
      return true; // Consider it successful if no exception is thrown
    } catch (e) {
      print('Error sending data: $e');
      return false;
    }
  }
  
  // Send a file to connected device
  Future<bool> sendFile(String deviceId, String filePath) async {
    if (!_isPlatformSupported() || _connectionState != ConnectionState.connected) {
      return false;
    }
    
    try {
      final payloadId = await _nearby.sendFilePayload(deviceId, filePath);
      return payloadId > 0; // Consider successful if we get a valid payload ID
    } catch (e) {
      print('Error sending file: $e');
      return false;
    }
  }
  
  // Send message to connected device
  Future<bool> sendMessage(String deviceId, Map<String, dynamic> message) async {
    final data = Uint8List.fromList(utf8.encode(jsonEncode(message)));
    return sendData(deviceId, data);
  }
  
  // Stop all services
  Future<void> stopAllServices() async {
    if (!_isPlatformSupported()) {
      return;
    }
    
    await stopAdvertising();
    await stopDiscovery();
    await disconnect();
    
    try {
      await _nearby.stopAllEndpoints();
    } catch (e) {
      print('Error stopping all endpoints: $e');
    }
  }
  
  // Handlers for Nearby Connections callbacks
  void _onEndpointFound(String id, String name, String serviceId) {
    final deviceInfo = DeviceInfo(
      id: id,
      name: name,
      deviceType: 'android', // Assuming Android for now
      isAvailable: true,
    );
    
    _discoveredDevices[id] = deviceInfo;
    
    if (onDeviceDiscovered != null) {
      onDeviceDiscovered!(deviceInfo);
    }
  }
  
  // Update the callback type for onEndpointLost
  void _onEndpointLost(String? id) {
    if (id == null) return;
    
    final deviceInfo = _discoveredDevices.remove(id);
    if (deviceInfo != null && onDeviceDisconnected != null) {
      onDeviceDisconnected!(deviceInfo);
    }
  }
  
  void _onConnectionInitiated(String id, ConnectionInfo info) {
    // Auto-accept connections
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: (String endpointId, Payload payload) {
        _handlePayloadReceived(endpointId, payload);
      },
      onPayloadTransferUpdate: (String endpointId, PayloadTransferUpdate update) {
        _handlePayloadTransferUpdate(endpointId, update);
      },
    );
  }
  
  void _onConnectionResult(String id, Status status) {
    final deviceInfo = _discoveredDevices[id];
    if (deviceInfo == null) return;
    
    deviceInfo.isConnecting = false;
    
    if (status == Status.CONNECTED) {
      _connectedDeviceId = id;
      deviceInfo.isConnected = true;
      _setConnectionState(ConnectionState.connected);
      
      if (onDeviceConnected != null) {
        onDeviceConnected!(deviceInfo);
      }
    } else {
      deviceInfo.isConnected = false;
      _setConnectionState(ConnectionState.disconnected);
      
      if (onConnectionFailed != null) {
        onConnectionFailed!(deviceInfo, status.toString());
      }
    }
  }
  
  void _onDisconnected(String id) {
    final deviceInfo = _discoveredDevices[id];
    if (deviceInfo == null) return;
    
    deviceInfo.isConnected = false;
    deviceInfo.isConnecting = false;
    
    if (_connectedDeviceId == id) {
      _connectedDeviceId = null;
      _setConnectionState(ConnectionState.disconnected);
    }
    
    if (onDeviceDisconnected != null) {
      onDeviceDisconnected!(deviceInfo);
    }
  }
  
  // Handle received data payload
  void _handlePayloadReceived(String endpointId, Payload payload) async {
    final deviceInfo = _discoveredDevices[endpointId];
    if (deviceInfo == null) return;
    
    if (payload.type == PayloadType.BYTES) {
      final bytes = payload.bytes!;
      if (onDataReceived != null) {
        onDataReceived!(deviceInfo, bytes, false);
      }
    } else if (payload.type == PayloadType.FILE) {
      final filePath = payload.filePath!;
      final fileBytes = await File(filePath).readAsBytes();
      
      if (onDataReceived != null) {
        onDataReceived!(deviceInfo, fileBytes, true);
      }
    }
  }
  
  // Handle updates on file transfer progress
  void _handlePayloadTransferUpdate(String endpointId, PayloadTransferUpdate update) {
    // Track progress, could be used for UI updates
    if (update.totalBytes > 0) {
      final progress = update.bytesTransferred / update.totalBytes;
      print('Transfer progress: ${(progress * 100).toStringAsFixed(2)}%');
    }
  }
  
  // Get a unique device ID
  Future<String> _getDeviceId() async {
    if (!_isPlatformSupported()) {
      return 'desktop-${DateTime.now().millisecondsSinceEpoch}';
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final deviceIdFile = File(path.join(directory.path, 'device_id.txt'));
      
      if (await deviceIdFile.exists()) {
        return await deviceIdFile.readAsString();
      } else {
        final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        await deviceIdFile.writeAsString(deviceId);
        return deviceId;
      }
    } catch (e) {
      print('Error getting device ID: $e');
      return 'fallback-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
} 