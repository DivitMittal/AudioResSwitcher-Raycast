# CLAUDE.md

## Project Overview

AudioResSwitcher-Raycast is a Raycast extension for macOS that enables users to inspect and switch between audio formats on input/output devices with lossless quality control.

## Development Commands

```bash
# Navigate to extension directory
cd raycast-extension

# Install dependencies
npm install

# Development mode (launches Raycast dev)
npm run dev

# Build for production
npm run build

# Lint code
npm run lint

# Fix lint issues automatically
npm run fix-lint

# Publish to Raycast Store
npm run publish
```

## Development Environment

The project uses a Nix-based development environment:
- **Nix flake** provides reproducible environment with all dependencies
- **direnv** automatically loads the environment when entering the directory
- Run `direnv allow` after first clone to enable automatic environment setup

## Architecture

### Project Structure
```
raycast-extension/
├── src/
│   ├── output-formats.tsx           # Output device UI & logic
│   ├── input-formats.tsx            # Input device UI & logic
│   ├── audio-bitrate-menubar.tsx    # Menubar bitrate monitor
│   └── types.ts                     # TypeScript type definitions
├── swift/
│   ├── Package.swift                # Swift Package Manager manifest
│   └── Sources/
│       └── AudioFormats.swift       # CoreAudio integration (@raycast functions)
└── assets/
    └── command-icon.png             # Extension icon
```

### Component Responsibilities
- **`output-formats.tsx` / `input-formats.tsx`**: React components providing Raycast UI for format selection
- **`audio-bitrate-menubar.tsx`**: MenuBar extra component displaying current audio bitrates
- **`types.ts`**: Shared TypeScript type definitions matching Swift Codable structs
- **`swift/Sources/AudioFormats.swift`**: Swift Package with @raycast-exported functions for CoreAudio operations
  - `getOutputFormats()` / `setOutputFormat()`: Output device format management
  - `getInputFormats()` / `setInputFormat()`: Input device format management
  - `getAudioBitrate()`: Real-time bitrate information retrieval
- **`swift/Package.swift`**: Swift Package Manager manifest with Raycast Swift tools dependencies

### Integration Architecture
1. **Raycast Swift Tools**: Uses official `@raycast` macros for type-safe Swift ↔ TypeScript communication
2. **Build Plugins**: Raycast build plugins auto-generate TypeScript bindings from `@raycast` functions
3. **Import Pattern**: TypeScript imports Swift functions via `import { functionName } from "swift:../swift"`
4. **Type Safety**: Swift `Encodable` structs automatically serialize to TypeScript types
5. **Error Handling**: Swift `throws` errors map to Promise rejections in TypeScript
6. **Build Process**:
   - Raycast CLI (`ray build` / `ray develop`) compiles both TypeScript and Swift
   - Swift Package Manager resolves dependencies and builds Swift code
   - Build plugins generate TypeScript bindings automatically

## Features

### Audio Format Selection Commands
Standard Raycast commands that provide a list interface for switching audio formats:
- **Output Device Formats**: View and switch output device audio formats
- **Input Device Formats**: View and switch input device audio formats
- Both commands display available sample rates, bit depths, and channel configurations
- Quality indicators (crown icon) for lossless formats (192kHz/24-bit+)

### Menubar Bitrate Monitor
Real-time menubar display showing current audio bitrate for both input and output devices:
- **Compact display**: Shows format as `Out: 96k/24 | In: 48k/24` in menubar
- **Quality indicators**: Crown (192k/24+), Star (96k/24+), Circle (standard)
- **Dropdown menu**: Click to see device names, full format details, and quick actions
- **Quick navigation**: Links to Output/Input Format commands for switching
- **Auto-refresh**: Automatically updates when audio device formats change

## Audio Format Management

### Format Detection Strategy
1. **Primary**: Swift CoreAudio API queries for exact supported formats per device
2. **Physical Formats**: Queries `kAudioStreamPropertyAvailablePhysicalFormats` for real hardware capabilities
3. **Format Data**: Sample rate (Hz), bit depth, channel count, format type (Float/Integer)
4. **Deduplication**: Filters duplicate formats to show only unique configurations

### Format Switching
- Swift code directly manipulates CoreAudio device properties via `AudioObjectSetPropertyData`
- Targets `kAudioStreamPropertyPhysicalFormat` for actual hardware format (not virtual/software layer)
- Raycast UI provides format selection with real-time feedback
- Changes take effect immediately without device restart

## Technical Implementation

### Error Handling
```
Swift @raycast Function → Promise → TypeScript → UI Toast
    ├─ Success: Typed result object (e.g., AudioFormatsResult)
    └─ Error: Swift throws → Promise rejection → Error toast
```

### Build System
- **Swift Package Manager**: Manages Swift dependencies and compilation
- **Raycast Swift Tools**: Build plugins generate TypeScript bindings at compile time
- **Type Generation**: `@raycast` macros automatically create TypeScript interfaces
- **Raycast CLI**: `ray build` / `ray develop` orchestrates full build pipeline
- **Adding new Swift functions**:
  1. Add `@raycast func` to `swift/Sources/AudioFormats.swift`
  2. Ensure return types conform to `Encodable`
  3. Import in TypeScript via `import { functionName } from "swift:../swift"`

### Cross-Language Interface
- **Swift → TypeScript**: Automatic serialization via `Encodable` protocol
- **TypeScript → Swift**: Direct function calls with typed parameters
- **Type Safety**: Compile-time type checking on both sides
- **Error Propagation**: Swift `throws` → TypeScript `Promise.reject()`

## Testing & Debugging

### Development Testing
```bash
npm run dev             # Launch in Raycast development mode
# Verify in Raycast:
#   - Output Device Formats command
#   - Input Device Formats command
#   - Audio Bitrate Monitor (menubar item)
```

### System Verification
- **Audio MIDI Setup.app**: Verify actual device format changes
- **Raycast console**: TypeScript console.log and Swift error output in dev mode
- **Swift Package Build**: Check `.build/` directory for compilation artifacts

## Platform Requirements
- **OS**: macOS 12+ (CoreAudio framework)
- **Runtime**: Swift 5.9+, Node.js 22.14+
- **Raycast**: 1.26.0+
- **Xcode**: Required for Swift Package Manager build tools
- **Build**: Nix with direnv (optional but recommended)

## Swift Integration Details

### Dependencies
The project uses Raycast's official Swift tools for type-safe integration:
- **extensions-swift-tools** (v1.0.4+): Provides `@raycast` macros and build plugins
- **RaycastSwiftMacros**: Macro annotations for exported functions
- **RaycastSwiftPlugin**: Swift code generation plugin
- **RaycastTypeScriptPlugin**: TypeScript binding generation plugin

### Exported Functions
All functions in `AudioFormats.swift` marked with `@raycast` are automatically available in TypeScript:

```swift
@raycast func getOutputFormats() throws -> AudioFormatsResult
@raycast func setOutputFormat(sampleRate: Double, bitDepth: Int, channels: Int) throws -> FormatChangeResult
@raycast func getInputFormats() throws -> AudioFormatsResult
@raycast func setInputFormat(sampleRate: Double, bitDepth: Int, channels: Int) throws -> FormatChangeResult
@raycast func getAudioBitrate() throws -> AudioBitrateData
```

### TypeScript Usage
```typescript
import { getOutputFormats, setOutputFormat } from "swift:../swift";
import type { AudioFormatsResult, FormatChangeResult } from "./types";

// Direct async/await usage
const formats = await getOutputFormats();
const result = await setOutputFormat(192000, 24, 2);
```
