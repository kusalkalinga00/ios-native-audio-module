# iOS Native Audio Module

A React Native application that exposes iOS native audio recording capabilities through a custom native module bridge. The app provides a simple UI with **Start Recording** and **Stop Recording** controls, backed by Swift-based native code on the iOS side.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [1. Install JavaScript dependencies](#1-install-javascript-dependencies)
  - [2. Install iOS native dependencies](#2-install-ios-native-dependencies)
  - [3. Start the Metro bundler](#3-start-the-metro-bundler)
  - [4. Run the iOS app](#4-run-the-ios-app)
- [Available Scripts](#available-scripts)
- [Key Dependencies](#key-dependencies)
- [iOS Configuration](#ios-configuration)
  - [New Architecture](#new-architecture)
  - [Privacy Manifest](#privacy-manifest)
  - [Permissions](#permissions)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project demonstrates how to build and integrate a **native iOS audio module** into a React Native application. The JavaScript layer calls into Swift native code via React Native's bridge (or the new JSI-based Turbo Module system), enabling direct access to iOS audio APIs such as `AVAudioEngine` or `AVAudioRecorder`.

The UI exposes two primary actions:

| Button | Description |
|---|---|
| **Start Recording** | Invokes the native iOS module to begin capturing audio from the device microphone. |
| **Stop Recording** | Signals the native module to stop the recording session and finalize the audio file. |

---

## Architecture

```
┌─────────────────────────────────────────┐
│           React Native (JS/TS)          │
│                                         │
│   App.tsx → screens/Home.tsx            │
│       ↓ NativeModule calls              │
│   Native Module Bridge (JS interface)   │
└──────────────┬──────────────────────────┘
               │ React Native Bridge / JSI
┌──────────────▼──────────────────────────┐
│           iOS Native Layer (Swift)      │
│                                         │
│   AppDelegate.swift                     │
│   AudioModule.swift (native module)     │
│       ↓                                 │
│   AVFoundation / AVAudioEngine          │
└─────────────────────────────────────────┘
```

- **JavaScript layer** (`App.tsx`, `screens/Home.tsx`): Renders the UI and dispatches recording commands through the native module interface.
- **Native bridge**: React Native's module registration system links JS calls to Swift implementations.
- **Swift native layer** (`ios/TestApp/`): Implements the recording logic using Apple's `AVFoundation` framework and registers the module with the React Native runtime via `AppDelegate.swift` and `RCTReactNativeFactory`.

---

## Prerequisites

Ensure the following tools are installed before proceeding:

| Tool | Required Version | Notes |
|---|---|---|
| **Node.js** | ≥ 20 | Use [nvm](https://github.com/nvm-sh/nvm) to manage versions |
| **npm** | Bundled with Node.js | Or use Yarn |
| **Ruby** | ≥ 2.7 (system or rbenv) | Required for CocoaPods via Bundler |
| **Bundler** | Latest | `gem install bundler` |
| **CocoaPods** | Latest | Installed via `bundle install` |
| **Xcode** | ≥ 15 | Required for iOS builds |
| **iOS Simulator** | via Xcode | Or a physical device |

> **Note**: Only iOS is supported as a target platform for the native audio module. Android support is not included.

---

## Project Structure

```
ios-native-audio-module/
├── ios/                         # iOS native project
│   ├── TestApp/
│   │   ├── AppDelegate.swift    # App entry point; sets up RCTReactNativeFactory
│   │   ├── Info.plist           # iOS app configuration and permissions
│   │   ├── PrivacyInfo.xcprivacy # Apple Privacy Manifest
│   │   └── LaunchScreen.storyboard
│   ├── Podfile                  # CocoaPods dependency manifest
│   └── Podfile.lock             # Locked CocoaPods versions
├── screens/
│   └── Home.tsx                 # Main screen with Start/Stop Recording UI
├── __tests__/
│   └── App.test.tsx             # Component render tests
├── App.tsx                      # Root component; sets up SafeAreaProvider
├── index.js                     # App entry point; registers component
├── app.json                     # App name config
├── package.json                 # JS dependencies and scripts
├── tsconfig.json                # TypeScript configuration
├── babel.config.js              # Babel configuration
├── metro.config.js              # Metro bundler configuration
└── jest.config.js               # Jest test configuration
```

---

## Getting Started

### 1. Install JavaScript dependencies

```sh
npm install
```

### 2. Install iOS native dependencies

Install CocoaPods itself via the Ruby Bundler (only needed once per machine or after modifying `Gemfile`):

```sh
bundle install
```

Install the iOS pod dependencies (run this on first clone and after any native dependency change):

```sh
bundle exec pod install
```

> For more information, see the [CocoaPods Getting Started guide](https://guides.cocoapods.org/using/getting-started.html).

### 3. Start the Metro bundler

Metro is the JavaScript build tool for React Native. Start it from the project root:

```sh
npm start
```

### 4. Run the iOS app

With Metro running, open a new terminal window and run:

```sh
npm run ios
```

This compiles the Swift native code, bundles the JavaScript, and launches the app in the iOS Simulator. To target a specific simulator, use:

```sh
npm run ios -- --simulator="iPhone 16 Pro"
```

To run on a connected physical device, open `ios/TestApp.xcworkspace` in Xcode and select your device as the build target.

---

## Available Scripts

| Script | Command | Description |
|---|---|---|
| `start` | `react-native start` | Start the Metro bundler |
| `ios` | `react-native run-ios` | Build and run on iOS Simulator |
| `android` | `react-native run-android` | Build and run on Android (not the primary target) |
| `test` | `jest` | Run the Jest test suite |
| `lint` | `eslint .` | Run ESLint on all JS/TS source files |

---

## Key Dependencies

### Runtime

| Package | Version | Purpose |
|---|---|---|
| `react` | 19.1.0 | UI rendering |
| `react-native` | 0.81.1 | Cross-platform native framework |
| `react-native-safe-area-context` | ^5.5.2 | Safe area insets for notched devices |
| `lucide-react-native` | ^0.542.0 | Icon library |

### Development

| Package | Version | Purpose |
|---|---|---|
| `typescript` | ^5.8.3 | Static type checking |
| `jest` | ^29.6.3 | Unit and component testing |
| `eslint` | ^8.19.0 | Code linting |
| `prettier` | 2.8.8 | Code formatting |
| `@react-native/metro-config` | 0.81.1 | Metro bundler configuration |
| `@react-native/babel-preset` | 0.81.1 | Babel preset for React Native |

---

## iOS Configuration

### New Architecture

This project has the **React Native New Architecture** enabled (`RCTNewArchEnabled: true` in `Info.plist`). The new architecture uses the JavaScript Interface (JSI) layer instead of the asynchronous bridge, providing:

- Synchronous native method calls via **Turbo Modules**
- Improved rendering with **Fabric**
- Lower latency for audio start/stop operations

### Privacy Manifest

`ios/TestApp/PrivacyInfo.xcprivacy` declares the following accessed API categories as required by Apple's App Store privacy policy:

| API Category | Reason Code | Purpose |
|---|---|---|
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `C617.1` | Accessing file timestamps (e.g., recorded audio files) |
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | Reading/writing app preferences |
| `NSPrivacyAccessedAPICategorySystemBootTime` | `35F9.1` | High-resolution timing for audio sessions |

### Permissions

To capture audio from the device microphone, add the following key to `ios/TestApp/Info.plist` before submitting to the App Store or running on a physical device:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to record audio.</string>
```

> Without this entry, the app will crash on iOS 10+ when attempting to start a recording session.

---

## Testing

Run the full test suite with:

```sh
npm test
```

Run tests in watch mode during development:

```sh
npm test -- --watch
```

Tests are located in the `__tests__/` directory. The current suite includes a smoke test verifying that the root `App` component renders without errors.

---

## Troubleshooting

### `pod install` fails with dependency errors

Ensure you have run `bundle install` first to install the correct CocoaPods version. Then re-run:

```sh
bundle exec pod install --repo-update
```

### App does not reflect JavaScript changes

Trigger a hard reload in the iOS Simulator by pressing <kbd>R</kbd>, or clear the Metro cache:

```sh
npm start -- --reset-cache
```

### Build errors after upgrading React Native

Clean the Xcode build folder (`Product → Clean Build Folder` in Xcode or `Cmd ⌘` + `Shift` + `K`), then re-run `bundle exec pod install`.

### Native module not found at runtime

Ensure the Swift native module is correctly exported using `@objc` annotations and that `RCT_EXTERN_MODULE` (for Objective-C bridging) or the Turbo Module spec is properly registered. Rebuild the app from Xcode after any changes to native files.

### General React Native issues

Refer to the official [React Native Troubleshooting](https://reactnative.dev/docs/troubleshooting) guide.
