<h1 align='center'>AudioResSwitcher-Raycast</h1>
<div align='center'>
    <p><em>Professional audio format control for macOS through Raycast</em></p>
    <div align='center'>
        <a href='https://github.com/DivitMittal/AudioResSwitcher-Raycast'>
            <img src='https://img.shields.io/github/repo-size/DivitMittal/AudioResSwitcher-Raycast?&style=for-the-badge&logo=github'>
        </a>
        <a href='https://github.com/DivitMittal/AudioResSwitcher-Raycast/blob/main/LICENSE'>
            <img src='https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&logo=unlicense'/>
        </a>
        <a href='https://raycast.com'>
            <img src='https://img.shields.io/badge/Raycast-Extension-orange?style=for-the-badge&logo=raycast'/>
        </a>
    </div>
    <br>
</div>

---

<div align='center'>
    <a href="https://github.com/DivitMittal/AudioResSwitcher-Raycast/actions/workflows/flake-check.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/DivitMittal/AudioResSwitcher-Raycast/flake-check.yml?style=flat-square&label=flake%20check" alt="Flake Check"/>
    </a>
    <a href="https://github.com/DivitMittal/AudioResSwitcher-Raycast/actions/workflows/flake-lock-update.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/DivitMittal/AudioResSwitcher-Raycast/flake-lock-update.yml?style=flat-square&label=flake%20update" alt="Flake Lock Update"/>
    </a>
    <a href="https://www.raycast.com/divm/audio-res-switcher">
        <img src="https://img.shields.io/badge/Raycast-Store-blue?style=flat-square" alt="Raycast Store"/>
    </a>
    <img src="https://img.shields.io/badge/macOS-12+-lightgrey?style=flat-square&logo=apple" alt="macOS Support"/>
</div>

---

A Raycast extension for macOS that enables precision audio format control with real-time monitoring. Switch sample rates, bit depths, and formats for input/output devices through native CoreAudio integration, with menubar bitrate monitoring for audiophiles and audio professionals.

## ✨ Features

### 🎛️ Audio Format Control
- **Precision Switching**: Change sample rate, bit depth, and channel configuration
- **Device Support**: All macOS audio devices (built-in, USB, Thunderbolt, Bluetooth)
- **Real-time Changes**: Instant format switching without device restart
- **Visual Quality Indicators**: Crown 👑 for lossless (192kHz/24+), Star ⭐ for high-quality (96kHz/24+)

### 📊 Menubar Monitoring
- **Live Display**: Real-time audio format monitoring (`Out: 96k/24 | In: 48k/24`)
- **Quick Access**: Dropdown with device details and format switching shortcuts
- **Auto-refresh**: 5-second interval updates for format changes

### 🔧 Professional Features
- **CoreAudio Integration**: Native Swift implementation for reliable format detection
- **Format Validation**: Shows only formats actually supported by hardware
- **Lossless Detection**: Automatic identification of high-fidelity audio formats
- **Multi-device**: Separate control for input (microphone) and output (speakers/headphones)

## 📦 Installation

### Using Raycast Store
1. Open Raycast
2. Search for "Audio Resolution Switcher"
3. Install and configure commands

### Development Setup

#### Prerequisites
- macOS 12+ (CoreAudio framework)
- Raycast 1.26.0+
- Node.js 22.14+
- Xcode (for Swift Package Manager)

#### Quick Start with Nix (Recommended)
```bash
# Clone repository
git clone https://github.com/DivitMittal/AudioResSwitcher-Raycast
cd AudioResSwitcher-Raycast

# Nix environment auto-loads with direnv
direnv allow

# Install and start development
cd raycast-extension
npm install
npm run dev
```

#### Manual Setup
```bash
# Clone and navigate
git clone https://github.com/DivitMittal/AudioResSwitcher-Raycast
cd AudioResSwitcher-Raycast/raycast-extension

# Install dependencies
npm install

# Start development
npm run dev
```

## 🚀 Usage

### Commands

| Command | Description | Mode |
|---------|-------------|------|
| **Input Device Formats** | Control microphone/input audio quality | View |
| **Output Device Formats** | Control speaker/headphone audio quality | View |
| **Audio Bitrate Monitor** | Real-time menubar monitoring | MenuBar |

### Format Selection
1. **Open Command**: Search "Input" or "Output Device Formats" in Raycast
2. **View Formats**: Browse all device-supported formats with quality indicators
3. **Switch Format**: Select and press Enter for instant format change
4. **Refresh**: Use Cmd+R to update device information

### Menubar Monitor
1. **Enable**: Search "Audio Bitrate Monitor" and enable in Raycast
2. **View**: Compact display shows current format in menubar
3. **Expand**: Click for device details and quick switching options

## 🏗️ Architecture

### Hybrid TypeScript + Swift Design
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Raycast UI    │    │  Swift Package   │    │   CoreAudio     │
│  (TypeScript)   │◄──►│  (@raycast)      │◄──►│   Framework     │
│                 │    │                  │    │                 │
│ • React Views   │    │ • Format Query   │    │ • Device Access │
│ • User Actions  │    │ • Format Switch  │    │ • Format Control│
│ • Menubar       │    │ • Type Safety    │    │ • Hardware API  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Project Structure
```
AudioResSwitcher-Raycast/
├── raycast-extension/           # Main extension
│   ├── src/
│   │   ├── output-formats.tsx   # Output device UI
│   │   ├── input-formats.tsx    # Input device UI
│   │   ├── audio-bitrate-menubar.tsx  # Menubar component
│   │   └── types.ts             # TypeScript definitions
│   ├── swift/
│   │   ├── Package.swift        # Swift Package Manager
│   │   └── Sources/
│   │       └── AudioFormats.swift    # CoreAudio integration
│   └── package.json
├── flake.nix                    # Nix development environment
├── flake.lock                   # Lock file for reproducible builds
└── README.md                    # This file
```
