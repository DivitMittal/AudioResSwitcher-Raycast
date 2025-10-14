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
└── assets/
    ├── output-formats.swift         # Swift: output format control
    ├── input-formats.swift          # Swift: input format control
    ├── audio-bitrate.swift          # Swift: bitrate info retrieval
    └── command-icon.png             # Extension icon
```

### Component Responsibilities
- **`output-formats.tsx` / `input-formats.tsx`**: React components providing Raycast UI for format selection
- **`audio-bitrate-menubar.tsx`**: MenuBar extra component displaying current audio bitrates
- **`output-formats.swift` / `input-formats.swift`**: Swift scripts querying CoreAudio and manipulating device properties
- **`audio-bitrate.swift`**: Swift script for retrieving current bitrate information
- **`assets/`**: Directory containing executable Swift scripts (with execute permissions set)

### Integration Architecture
1. **Swift Script Execution**: TypeScript uses `execa` to run Swift scripts for CoreAudio operations
2. **Swift Script Location**: Swift scripts are maintained directly in `assets/` directory with executable permissions
3. **Build Process**: Raycast CLI (`ray`) handles building TypeScript/React components; Swift scripts are pre-positioned in assets/

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
1. **Primary**: Swift scripts query CoreAudio API for exact supported formats per device
2. **Fallback**: Intelligent defaults based on device transport type:
   - **USB/Thunderbolt/Firewire**: Up to 192kHz 32-bit for pro interfaces
   - **Built-in**: Typically up to 48kHz 24-bit
   - **Bluetooth/AirPlay**: Limited to 48kHz 16-bit
3. **Format Data**: Sample rate (Hz), bit depth, channel count

### Format Switching
- Swift scripts directly manipulate CoreAudio device properties via AudioObjectSetPropertyData
- Raycast UI provides format selection with real-time feedback
- Changes take effect immediately without device restart

## Technical Implementation

### Error Handling
```
Swift Script (JSON) → execa → TypeScript → UI Toast
    ├─ Success: { items: [...] }
    └─ Error: { error: "message" } → Fallback formats
```

### Build System
- Swift scripts are stored directly in `assets/` directory (not copied from `src/`)
- Swift scripts must have executable permissions: `chmod +x assets/*.swift`
- Raycast CLI (`ray build` / `ray develop`) handles TypeScript/React compilation
- **Adding new Swift scripts**: Place in `assets/` and run `chmod +x assets/script-name.swift`

### Cross-Language Interface
- **Swift → TypeScript**: JSON output via stdout
- **TypeScript → Swift**: Command-line arguments (device type, sample rate, bit depth, channels)
- **Error Reporting**: stderr and exit codes

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
- **Swift script logs**: Emoji-prefixed verbose output (🎯 🔍 ✅ ❌)
- **Raycast console**: TypeScript console.log output in dev mode

## Platform Requirements
- **OS**: macOS only (CoreAudio framework)
- **Runtime**: Swift 5.0+, Node.js 22.14+
- **Raycast**: 1.26.0+
- **Build**: Nix with direnv (optional but recommended)
