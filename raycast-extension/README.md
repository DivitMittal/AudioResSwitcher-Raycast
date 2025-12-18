# Audio Resolution Switcher - Raycast Extension

Control audio quality with precision. Switch sample rates, bit depth, and formats for input/output devices. Monitor current bitrate in menubar. Perfect for audiophiles and audio professionals.

## Features

- **Input Device Formats**: List and switch between all supported audio formats for your input device (microphone, audio interface)
- **Output Device Formats**: List and switch between all supported audio formats for your output device (speakers, headphones, DAC)
- **Format Switching**: Instantly set audio devices to specific sample rates, bit depths, and channel configurations
- **Menubar Monitor**: Real-time display of current audio bitrate and quality for both input and output devices
- **Lossless Quality Detection**: Visual indicators (crown, star icons) for high-quality formats (192kHz/24-bit+)
- **Swift + CoreAudio**: Native macOS audio control using CoreAudio framework for reliable format switching

## Commands

### 1. **Input Device Formats** (`input-formats.tsx`)
View and control microphone/input audio quality:
- Shows current input device name (USB audio interface, built-in mic, etc.)
- Lists all supported input formats with sample rate, bit depth, and channels
- Highlights the currently active format with a checkmark
- Switch to any supported format with one click
- Refresh device info with **Cmd+R**
- Quality indicators for lossless formats

### 2. **Output Device Formats** (`output-formats.tsx`)
View and control speaker/headphone audio quality:
- Shows current output device name (DAC, headphones, built-in speakers, etc.)
- Lists all supported output formats with sample rate, bit depth, and channels
- Highlights the currently active format with a checkmark
- Switch to any supported format with one click
- Crown icon 👑 for lossless quality formats (192kHz/24-bit+)
- Star icon ⭐ for high-quality formats (96kHz/24-bit+)
- Refresh device info with **Cmd+R**

### 3. **Audio Bitrate Monitor** (`audio-bitrate-menubar.tsx`)
Real-time menubar monitoring:
- **Compact display**: Shows `Out: 96k/24 | In: 48k/24` in menubar
- **Quality indicators**: Crown (192k/24+), Star (96k/24+), Circle (standard quality)
- **Auto-refresh**: Updates every 5 seconds to track format changes
- **Click to expand**: Dropdown shows device names and full format details
- **Quick actions**: Direct links to Input/Output Format commands for switching
- **Always visible**: Keep track of audio quality without opening any windows

## Format Information Displayed

For each audio format, you'll see:
- **Format Name**: Human-readable format description (e.g., "192kHz 24-bit Stereo")
- **Sample Rate**: In Hz (e.g., 44100, 48000, 96000, 192000)
- **Bit Depth**: In bits (e.g., 16, 24, 32)
- **Channels**: Mono, Stereo, or multi-channel configurations
- **Quality Indicator**: Shows "k" rating (e.g., "44.1k", "96k", "192k")
- **Current Status**: Checkmark indicates the currently active format
- **Quality Icons**:
  - 👑 Crown = Lossless/Hi-Res (192kHz/24-bit+)
  - ⭐ Star = High Quality (96kHz/24-bit+)
  - ⚪ Circle = Standard Quality

## Technical Architecture

The extension uses a hybrid TypeScript + Swift architecture:

### Swift Scripts (CoreAudio Integration)
- **`assets/output-formats.swift`**: Queries and sets output device formats via CoreAudio API
- **`assets/input-formats.swift`**: Queries and sets input device formats via CoreAudio API
- **`assets/audio-bitrate.swift`**: Retrieves current bitrate information for menubar display
- All scripts output JSON for TypeScript consumption
- Direct manipulation of AudioObjectSetPropertyData for reliable format switching

### TypeScript/React (Raycast UI)
- **`src/output-formats.tsx`**: Output device UI and format selection logic
- **`src/input-formats.tsx`**: Input device UI and format selection logic
- **`src/audio-bitrate-menubar.tsx`**: Menubar component with auto-refresh
- Uses `execa` package to execute Swift scripts and parse JSON responses
- Provides fallback format lists based on device transport type when Swift detection fails

## Installation & Setup

### Prerequisites
- **macOS**: Required (uses CoreAudio framework)
- **Node.js**: 22.14+ recommended
- **Raycast**: 1.26.0 or later
- **Nix + direnv** (optional): For reproducible development environment

### Development Setup

1. **Clone and navigate to extension directory**:
   ```bash
   cd raycast-extension
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Start development mode** (launches Raycast in dev mode):
   ```bash
   npm run dev
   ```

4. **Verify installation in Raycast**:
   - Search for "Input Device Formats"
   - Search for "Output Device Formats"
   - Search for "Audio Bitrate Monitor"

### Building for Production

```bash
npm run build     # Build extension
npm run lint      # Check code quality
npm run fix-lint  # Auto-fix linting issues
npm run publish   # Publish to Raycast Store
```

## Usage Guide

### Format Switching Commands

1. **View Current Format**:
   - Open either "Input Device Formats" or "Output Device Formats"
   - Current device name and active format appear at the top

2. **Browse Available Formats**:
   - Scroll through all formats supported by your device
   - Quality icons (crown/star) indicate high-quality formats
   - Current format is marked with a checkmark

3. **Switch Format**:
   - Select any format and press **Enter**
   - Format changes immediately (no device restart needed)
   - Confirmation toast appears on success

4. **Refresh Device Info**:
   - Press **Cmd+R** to refresh if you changed devices
   - Automatically detects new device and available formats

### Menubar Monitor

1. **Enable in Raycast**:
   - Search for "Audio Bitrate Monitor"
   - Toggle on in Raycast preferences

2. **View at a Glance**:
   - Menubar shows: `Out: 96k/24 | In: 48k/24`
   - Quality icons indicate audio quality level

3. **Access Details**:
   - Click menubar icon to see full device names
   - Use quick links to switch formats directly
