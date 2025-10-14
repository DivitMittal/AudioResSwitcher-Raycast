# Audio Format Inspector - Raycast Extension

A Raycast extension for inspecting supported audio formats on the current input and output devices, with the ability to switch between formats.

## Features

- **Input Device Formats**: List all supported audio formats for the current input device
- **Output Device Formats**: List all supported audio formats for the current output device
- **Format Switching**: Set audio devices to specific sample rates and bit depths
- **Lossless Quality Detection**: Highlights high-quality formats (192kHz/24-bit+)

## Commands

1. **Input Device Formats** (`input-formats.tsx`)
   - Shows current input device name
   - Lists all supported input formats with sample rate, bit depth, and channels
   - Highlights the currently active format
   - Allows switching to any supported format
   - Refresh device info with Cmd+R

2. **Output Device Formats** (`output-formats.tsx`)
   - Shows current output device name
   - Lists all supported output formats with sample rate, bit depth, and channels
   - Highlights the currently active format
   - Allows switching to any supported format
   - Special integration with Swift scripts for highest quality formats
   - Crown icon for lossless quality formats (192kHz/24-bit+)
   - Refresh device info with Cmd+R

## Format Information Displayed

For each audio format, you'll see:
- **Format Name**: Human-readable format description
- **Sample Rate**: In Hz (e.g., 44100, 48000, 96000, 192000)
- **Bit Depth**: In bits (e.g., 16, 24, 32)
- **Channels**: Mono, Stereo, or multi-channel
- **Quality Indicator**: Shows "k" rating (e.g., "44.1k", "192k")
- **Current Status**: Indicates which format is currently active

## Integration with Existing Scripts

The extension integrates with your existing Swift audio control scripts:
- Uses `../set_highest_format.swift` for setting optimal output formats
- Falls back to AppleScript automation when Swift scripts aren't available
- Maintains compatibility with your current audio switching workflow

## Installation

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start development:
   ```bash
   npm run dev
   ```

3. The extension will appear in Raycast with two commands:
   - "Input Device Formats"
   - "Output Device Formats"

## Usage

1. **View Current Formats**: Launch either command to see the current device and its active format
2. **Browse Supported Formats**: Scroll through all formats supported by the device
3. **Switch Formats**: Press Enter on any non-current format to switch to it
4. **Copy Format Info**: Use the copy action to copy format names to clipboard
5. **Refresh**: Use Cmd+R to refresh device information

## Technical Details

- Uses Audio MIDI Setup automation to detect formats
- Parses format strings to extract sample rate, bit depth, and channel information
- Provides fallback format lists when detection fails
- Integrates with existing Swift scripts for advanced format control

## Requirements

- macOS (Raycast extension)
- Node.js 22.14+
- Raycast 1.26.0+
- Audio MIDI Setup (built into macOS)

## Keyboard Shortcuts

- **Cmd+R**: Refresh device information
- **Cmd+H**: Set to highest quality format (output formats only)
- **Enter**: Set selected format
- **Cmd+C**: Copy format name to clipboard