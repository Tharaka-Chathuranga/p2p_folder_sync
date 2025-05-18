# Folder Sync

An Android application to synchronize folder contents between mobile devices over Wi-Fi without requiring an internet connection.

## Overview

Folder Sync enables peer-to-peer (P2P) folder synchronization over a wireless local area network (WLAN). The application ensures reliable, high-speed file synchronization between two or more smart mobile devices within the same network.

This application is particularly useful in scenarios where internet connectivity is limited or unavailable:
- Remote areas
- Classrooms
- Fieldwork operations
- Disaster recovery zones
- Secure workplaces

## Features

- **Device Discovery**: Automatically detect nearby devices on the same Wi-Fi network
- **Selective File Synchronization**: Choose specific files to sync instead of entire folders
- **Real-time Synchronization**: Changes in files are automatically detected and synced
- **Two-Way Sync**: Synchronize files in both directions between devices
- **Sync Control**: Start, pause, resume or cancel synchronization at any time
- **File Conflict Resolution**: Intelligently handle conflicts when the same file is modified on multiple devices
- **Offline Operation**: Works completely without internet connectivity

## Requirements

- Android 6.0 (API level 23) or higher
- Devices must be connected to the same Wi-Fi network
- Storage permission for accessing files
- Location permission for device discovery

## Getting Started

1. Install the app on both devices that need to sync files
2. Make sure both devices are connected to the same Wi-Fi network
3. On one device, tap "Advertise Device" to make it discoverable
4. On the other device, tap "Scan for Devices" to find available devices
5. Select a folder you want to synchronize
6. Connect to the discovered device
7. Choose which files to sync
8. Tap "Start Sync" to begin synchronization

## Development

This application is built using:
- Flutter for cross-platform development
- Provider for state management
- Nearby Connections API for P2P communication
- Platform-specific APIs for file operations

### Project Structure

- `lib/models/` - Data models
- `lib/services/` - Core services for device discovery, file operations, and sync
- `lib/providers/` - State management using the Provider pattern
- `lib/screens/` - UI screens
- `lib/widgets/` - Reusable UI components
- `lib/utils/` - Helper utilities

## Troubleshooting

- **Devices not finding each other**: Make sure both devices are on the same Wi-Fi network and have location services enabled
- **Sync stopping unexpectedly**: Check that both devices remain in close proximity during sync
- **Permission Issues**: Ensure all required permissions are granted in settings
- **Files not appearing**: Some system folders may be restricted; try using a different folder

## Team

This project was developed by the MobileX Team:
- ADIKARI A.M.S.S.H - 200012R
- KUMARA R.A.T.C - 200321M

## License

This project is licensed under the MIT License. See the LICENSE file for details.