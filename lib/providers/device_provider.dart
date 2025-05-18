import 'package:flutter/foundation.dart';
import '../models/device_info.dart';
import '../services/device_discovery_service.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceDiscoveryService _deviceService;
  
  DeviceProvider(this._deviceService) {
    _setupListeners();
  }
  
  // Get discovered devices
  List<DeviceInfo> get discoveredDevices => _deviceService.discoveredDevices;
  
  // Get connected device
  DeviceInfo? get connectedDevice => _deviceService.connectedDevice;
  
  // Get connection state
  ConnectionState get connectionState => _deviceService.connectionState;
  
  // Set up event listeners
  void _setupListeners() {
    _deviceService.onDeviceDiscovered = (device) {
      notifyListeners();
    };
    
    _deviceService.onDeviceDisconnected = (device) {
      notifyListeners();
    };
    
    _deviceService.onDeviceConnected = (device) {
      notifyListeners();
    };
    
    _deviceService.onConnectionStateChanged = (state) {
      notifyListeners();
    };
  }
  
  // Start advertising this device
  Future<bool> startAdvertising(String deviceName) async {
    final result = await _deviceService.startAdvertising(deviceName);
    notifyListeners();
    return result;
  }
  
  // Stop advertising
  Future<bool> stopAdvertising() async {
    final result = await _deviceService.stopAdvertising();
    notifyListeners();
    return result;
  }
  
  // Start discovering devices
  Future<bool> startDiscovery() async {
    final result = await _deviceService.startDiscovery();
    notifyListeners();
    return result;
  }
  
  // Stop discovering
  Future<bool> stopDiscovery() async {
    final result = await _deviceService.stopDiscovery();
    notifyListeners();
    return result;
  }
  
  // Connect to a device
  Future<bool> connectToDevice(String deviceId) async {
    return await _deviceService.connectToDevice(deviceId);
  }
  
  // Disconnect from current device
  Future<bool> disconnect() async {
    final result = await _deviceService.disconnect();
    notifyListeners();
    return result;
  }
  
  // Cleanup resources
  @override
  void dispose() {
    _deviceService.stopAllServices();
    super.dispose();
  }
} 