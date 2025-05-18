import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../providers/device_provider.dart';
import '../providers/sync_provider.dart';
import '../models/device_info.dart';
import 'sync_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScanning = false;
  bool _isAdvertising = false;
  String? _selectedDirectory;
  DeviceInfo? _selectedDevice;
  final TextEditingController _deviceNameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _deviceNameController.text = 'My Device';
    _initializePermissions();
  }
  
  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }
  
  // Initialize required permissions
  Future<void> _initializePermissions() async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    await syncProvider.requestPermissions();
  }
  
  // Select a folder to sync
  Future<void> _selectDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null) {
      setState(() {
        _selectedDirectory = selectedDirectory;
      });
    }
  }
  
  // Start scanning for devices
  Future<void> _startScan() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    
    setState(() {
      _isScanning = true;
    });
    
    final success = await deviceProvider.startDiscovery();
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start scanning')),
      );
      
      setState(() {
        _isScanning = false;
      });
    }
  }
  
  // Stop scanning for devices
  Future<void> _stopScan() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    
    await deviceProvider.stopDiscovery();
    
    setState(() {
      _isScanning = false;
    });
  }
  
  // Start advertising this device
  Future<void> _startAdvertising() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    
    setState(() {
      _isAdvertising = true;
    });
    
    final success = await deviceProvider.startAdvertising(_deviceNameController.text);
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start advertising')),
      );
      
      setState(() {
        _isAdvertising = false;
      });
    }
  }
  
  // Stop advertising this device
  Future<void> _stopAdvertising() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    
    await deviceProvider.stopAdvertising();
    
    setState(() {
      _isAdvertising = false;
    });
  }
  
  // Connect to a device
  Future<void> _connectToDevice(DeviceInfo device) async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    
    setState(() {
      _selectedDevice = device;
    });
    
    final success = await deviceProvider.connectToDevice(device.id);
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${device.name}')),
      );
      
      setState(() {
        _selectedDevice = null;
      });
    } else {
      // Connection successful, navigate to sync screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SyncScreen(
              deviceInfo: device,
              sourcePath: _selectedDirectory!,
            ),
          ),
        ).then((_) {
          // Disconnect when returning from sync screen
          deviceProvider.disconnect();
          setState(() {
            _selectedDevice = null;
          });
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show about dialog
              showAboutDialog(
                context: context,
                applicationName: 'Folder Sync',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 MobileX Team',
                children: [
                  const Text(
                    'Synchronize folder contents between mobile devices over Wi-Fi.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Device name input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _deviceNameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          // Advertise button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isAdvertising ? Icons.stop : Icons.broadcast_on_personal),
                    label: Text(_isAdvertising ? 'Stop Advertising' : 'Advertise Device'),
                    onPressed: _isAdvertising ? _stopAdvertising : _startAdvertising,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Directory selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Select Folder to Sync'),
                    onPressed: _selectDirectory,
                  ),
                ),
              ],
            ),
          ),
          
          if (_selectedDirectory != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedDirectory!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          // Scan controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isScanning ? Icons.stop : Icons.search),
                    label: Text(_isScanning ? 'Stop Scanning' : 'Scan for Devices'),
                    onPressed: _isScanning ? _stopScan : _startScan,
                  ),
                ),
              ],
            ),
          ),
          
          // Available devices list
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.devices, size: 20),
                SizedBox(width: 8),
                Text(
                  'Available Devices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Consumer<DeviceProvider>(
              builder: (context, deviceProvider, child) {
                final devices = deviceProvider.discoveredDevices;
                
                if (devices.isEmpty) {
                  return const Center(
                    child: Text('No devices found'),
                  );
                }
                
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    
                    return ListTile(
                      leading: const Icon(Icons.smartphone),
                      title: Text(device.name),
                      subtitle: Text(device.id),
                      trailing: _selectedDevice?.id == device.id
                          ? const CircularProgressIndicator()
                          : IconButton(
                              icon: const Icon(Icons.link),
                              onPressed: _selectedDirectory == null
                                  ? null
                                  : () => _connectToDevice(device),
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 