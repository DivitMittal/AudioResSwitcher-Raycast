import AudioToolbox
import CoreAudio
import Foundation
import RaycastSwiftMacros

// MARK: - Codable Types for Raycast Integration

struct FormatItem: Encodable {
  let title: String
  let subtitle: String
  let icon: String
  let type: String
  let sampleRate: Double?
  let bitDepth: Int?
  let channels: Int?
  let isCurrent: Bool?
}

struct AudioFormatsResult: Encodable {
  let items: [FormatItem]
}

struct FormatChangeResult: Encodable {
  let success: String
}

struct AudioBitrateData: Encodable {
  let outputSampleRate: Int?
  let outputBitDepth: Int?
  let outputChannels: Int?
  let outputDevice: String?
  let inputSampleRate: Int?
  let inputBitDepth: Int?
  let inputChannels: Int?
  let inputDevice: String?
}

// MARK: - Error Types

enum AudioFormatError: Error {
  case deviceNotFound(String)
  case deviceNameNotFound
  case formatSetFailed(String)
  case invalidParameters
}

// MARK: - Raycast Exported Functions

@raycast func getOutputFormats() throws -> AudioFormatsResult {
  guard let deviceID = getDefaultOutputDevice() else {
    throw AudioFormatError.deviceNotFound("Could not find default output device")
  }

  guard let deviceName = getDeviceName(deviceID: deviceID) else {
    throw AudioFormatError.deviceNameNotFound
  }

  let items = listFormats(deviceID: deviceID, deviceName: deviceName, isInput: false)
  return AudioFormatsResult(items: items)
}

@raycast func setOutputFormat(sampleRate: Double, bitDepth: Int, channels: Int) throws
  -> FormatChangeResult
{
  guard let deviceID = getDefaultOutputDevice() else {
    throw AudioFormatError.deviceNotFound("Could not find default output device")
  }

  guard
    let applied = setFormat(
      deviceID: deviceID, sampleRate: sampleRate, bitDepth: bitDepth, channels: channels,
      isInput: false)
  else {
    throw AudioFormatError.formatSetFailed("Failed to set output format")
  }

  return FormatChangeResult(success: "Output format set to \(describe(format: applied))")
}

@raycast func getInputFormats() throws -> AudioFormatsResult {
  guard let deviceID = getDefaultInputDevice() else {
    throw AudioFormatError.deviceNotFound("Could not find default input device")
  }

  guard let deviceName = getDeviceName(deviceID: deviceID) else {
    throw AudioFormatError.deviceNameNotFound
  }

  let items = listFormats(deviceID: deviceID, deviceName: deviceName, isInput: true)
  return AudioFormatsResult(items: items)
}

@raycast func setInputFormat(sampleRate: Double, bitDepth: Int, channels: Int) throws
  -> FormatChangeResult
{
  guard let deviceID = getDefaultInputDevice() else {
    throw AudioFormatError.deviceNotFound("Could not find default input device")
  }

  guard
    let applied = setFormat(
      deviceID: deviceID, sampleRate: sampleRate, bitDepth: bitDepth, channels: channels,
      isInput: true)
  else {
    throw AudioFormatError.formatSetFailed("Failed to set input format")
  }

  return FormatChangeResult(success: "Input format set to \(describe(format: applied))")
}

@raycast func getAudioBitrate() throws -> AudioBitrateData {
  var outputSampleRate: Int?
  var outputBitDepth: Int?
  var outputChannels: Int?
  var outputDevice: String?
  var inputSampleRate: Int?
  var inputBitDepth: Int?
  var inputChannels: Int?
  var inputDevice: String?

  // Get output device bitrate
  if let outputDeviceID = getDefaultOutputDevice() {
    if let format = getCurrentStreamFormat(deviceID: outputDeviceID, isInput: false) {
      outputSampleRate = Int(format.mSampleRate)
      outputBitDepth = Int(format.mBitsPerChannel)
      outputChannels = Int(format.mChannelsPerFrame)

      if let deviceName = getDeviceName(deviceID: outputDeviceID) {
        outputDevice = deviceName
      }
    }
  }

  // Get input device bitrate
  if let inputDeviceID = getDefaultInputDevice() {
    if let format = getCurrentStreamFormat(deviceID: inputDeviceID, isInput: true) {
      inputSampleRate = Int(format.mSampleRate)
      inputBitDepth = Int(format.mBitsPerChannel)
      inputChannels = Int(format.mChannelsPerFrame)

      if let deviceName = getDeviceName(deviceID: inputDeviceID) {
        inputDevice = deviceName
      }
    }
  }

  return AudioBitrateData(
    outputSampleRate: outputSampleRate,
    outputBitDepth: outputBitDepth,
    outputChannels: outputChannels,
    outputDevice: outputDevice,
    inputSampleRate: inputSampleRate,
    inputBitDepth: inputBitDepth,
    inputChannels: inputChannels,
    inputDevice: inputDevice
  )
}

// MARK: - Internal Helper Functions

private func listFormats(deviceID: AudioDeviceID, deviceName: String, isInput: Bool) -> [FormatItem]
{
  let currentFormat = getCurrentStreamFormat(deviceID: deviceID, isInput: isInput)
  let availableRates = getAvailableSampleRates(deviceID: deviceID)

  var items: [FormatItem] = []
  var seenFormats = Set<String>()

  // Add current device info
  items.append(
    FormatItem(
      title: "Current Device: \(deviceName)",
      subtitle: currentFormat != nil
        ? "\(Int(currentFormat!.mSampleRate)) Hz \(currentFormat!.mBitsPerChannel)-bit \(currentFormat!.mChannelsPerFrame)-channel"
        : "Format unknown",
      icon: "checkmark.circle.fill",
      type: "info",
      sampleRate: nil,
      bitDepth: nil,
      channels: nil,
      isCurrent: nil
    ))

  // Add available hardware formats
  for rate in availableRates {
    let streamFormats = getAvailableStreamFormats(
      deviceID: deviceID, sampleRate: rate, isInput: isInput)

    for format in streamFormats {
      let formatType = format.mFormatFlags & kAudioFormatFlagIsFloat != 0 ? "Float" : "Integer"

      let isCurrent: Bool = {
        guard let current = currentFormat else { return false }
        let currentIsFloat = current.mFormatFlags & kAudioFormatFlagIsFloat != 0
        let formatIsFloat = format.mFormatFlags & kAudioFormatFlagIsFloat != 0
        return abs(current.mSampleRate - format.mSampleRate) < 0.1
          && current.mBitsPerChannel == format.mBitsPerChannel
          && current.mChannelsPerFrame == format.mChannelsPerFrame
          && currentIsFloat == formatIsFloat
      }()

      // Create unique key for deduplication
      let formatKey =
        "\(Int(format.mSampleRate))_\(format.mBitsPerChannel)_\(format.mChannelsPerFrame)_\(formatType)"

      // Skip if we've already added this format
      if seenFormats.contains(formatKey) {
        continue
      }
      seenFormats.insert(formatKey)

      let title =
        "\(Int(format.mSampleRate)) Hz \(format.mBitsPerChannel)-bit \(format.mChannelsPerFrame)-channel"
      let subtitle = formatType + (isCurrent ? " (Current)" : "")
      let isHighQuality = format.mSampleRate >= 192000 && format.mBitsPerChannel >= 24

      items.append(
        FormatItem(
          title: title,
          subtitle: subtitle,
          icon: isCurrent ? "checkmark.circle" : (isHighQuality ? "crown" : "circle"),
          type: "format",
          sampleRate: format.mSampleRate,
          bitDepth: Int(format.mBitsPerChannel),
          channels: Int(format.mChannelsPerFrame),
          isCurrent: isCurrent
        ))
    }
  }

  // Sort formats
  let sortedItems = items.sorted { item1, item2 in
    // Keep device info first
    if item1.type == "info" { return true }
    if item2.type == "info" { return false }

    guard let rate1 = item1.sampleRate,
      let rate2 = item2.sampleRate,
      let bits1 = item1.bitDepth,
      let bits2 = item2.bitDepth
    else {
      return false
    }

    // Sort by sample rate ascending, then bit depth ascending
    if rate1 != rate2 {
      return rate1 < rate2
    }
    return bits1 < bits2
  }

  return sortedItems
}

/// Sets the device format and returns the format actually applied to the hardware,
/// or nil if the change failed. Reads back the physical format after setting so the
/// caller can report the truth (driver may have substituted a different format, or
/// the call may have only changed the nominal sample rate).
private func setFormat(
  deviceID: AudioDeviceID, sampleRate: Double, bitDepth: Int, channels: Int, isInput: Bool
) -> AudioStreamBasicDescription? {
  let streamFormats = getAvailableStreamFormats(
    deviceID: deviceID, sampleRate: sampleRate, isInput: isInput)

  let exactMatch = streamFormats.first { format in
    format.mBitsPerChannel == bitDepth && format.mChannelsPerFrame == channels
  }

  let targetFormat = exactMatch ?? (streamFormats.isEmpty ? nil : findBestFormat(formats: streamFormats))

  let applied: Bool
  if let format = targetFormat {
    applied = setStreamFormat(deviceID: deviceID, format: format, isInput: isInput)
  } else {
    // No matching physical format — fall back to the nominal sample rate.
    // Bit depth and channels are left as the device's current setting.
    applied = setSampleRate(deviceID: deviceID, sampleRate: sampleRate)
  }

  guard applied else { return nil }
  return getCurrentStreamFormat(deviceID: deviceID, isInput: isInput)
}

private func describe(format: AudioStreamBasicDescription) -> String {
  let channels = format.mChannelsPerFrame
  return "\(Int(format.mSampleRate)) Hz \(format.mBitsPerChannel)-bit \(channels)-channel"
}

// MARK: - CoreAudio Helper Functions

private func getDefaultOutputDevice() -> AudioDeviceID? {
  var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultOutputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
  )

  var deviceID: AudioDeviceID = 0
  var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

  guard
    AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject),
      &propertyAddress, 0, nil, &propertySize, &deviceID) == noErr
  else {
    return nil
  }

  return deviceID != kAudioObjectUnknown ? deviceID : nil
}

private func getDefaultInputDevice() -> AudioDeviceID? {
  var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultInputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
  )

  var deviceID: AudioDeviceID = 0
  var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

  guard
    AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject),
      &propertyAddress, 0, nil, &propertySize, &deviceID) == noErr
  else {
    return nil
  }

  return deviceID != kAudioObjectUnknown ? deviceID : nil
}

private func getDeviceName(deviceID: AudioDeviceID) -> String? {
  var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioDevicePropertyDeviceNameCFString,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
  )

  var deviceName: Unmanaged<CFString>?
  var propertySize = UInt32(MemoryLayout<Unmanaged<CFString>>.size)

  // kAudioDevicePropertyDeviceNameCFString returns a +1 retained CFString;
  // the caller owns it and must release it. takeRetainedValue() does that.
  guard
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &deviceName)
      == noErr,
    let name = deviceName?.takeRetainedValue()
  else {
    return nil
  }

  return name as String
}

private func getCurrentStreamFormat(deviceID: AudioDeviceID, isInput: Bool)
  -> AudioStreamBasicDescription?
{
  let scope = isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput

  // Get physical format (actual hardware format) instead of virtual format

  // First, get the audio streams
  var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioDevicePropertyStreams,
    mScope: scope,
    mElement: kAudioObjectPropertyElementMain
  )

  var propertySize: UInt32 = 0
  guard AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize) == noErr
  else {
    return nil
  }

  let streamCount = Int(propertySize) / MemoryLayout<AudioStreamID>.size
  var streams = [AudioStreamID](repeating: 0, count: streamCount)

  guard
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &streams)
      == noErr
  else {
    return nil
  }

  guard let streamID = streams.first else {
    return nil
  }

  // Get the physical format from the stream
  var streamPropertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioStreamPropertyPhysicalFormat,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
  )

  var format = AudioStreamBasicDescription()
  var streamPropertySize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)

  guard
    AudioObjectGetPropertyData(
      streamID, &streamPropertyAddress, 0, nil, &streamPropertySize, &format) == noErr
  else {
    return nil
  }

  return format
}

private func getAvailableSampleRates(deviceID: AudioDeviceID) -> [Double] {
  var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioDevicePropertyAvailableNominalSampleRates,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
  )

  var propertySize: UInt32 = 0
  guard AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize) == noErr
  else {
    return []
  }

  let rangeCount = Int(propertySize) / MemoryLayout<AudioValueRange>.size
  var ranges = [AudioValueRange](repeating: AudioValueRange(), count: rangeCount)

  guard
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &ranges)
      == noErr
  else {
    return []
  }

  var sampleRates: [Double] = []
  for range in ranges {
    if range.mMinimum == range.mMaximum {
      sampleRates.append(range.mMinimum)
    } else {
      let standardRates = [
        8000.0, 16000.0, 22050.0, 44100.0, 48000.0, 88200.0, 96000.0, 176400.0, 192000.0,
        352800.0, 384000.0,
      ]
      for rate in standardRates {
        if rate >= range.mMinimum && rate <= range.mMaximum {
          sampleRates.append(rate)
        }
      }
    }
  }

  return Array(Set(sampleRates)).sorted()
}

private func getAvailableStreamFormats(deviceID: AudioDeviceID, sampleRate: Double, isInput: Bool)
  -> [AudioStreamBasicDescription]
{
  let scope = isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput

  // Get audio streams for the device
  var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioDevicePropertyStreams,
    mScope: scope,
    mElement: kAudioObjectPropertyElementMain
  )

  var propertySize: UInt32 = 0
  guard AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize) == noErr
  else {
    return []
  }

  let streamCount = Int(propertySize) / MemoryLayout<AudioStreamID>.size
  var streams = [AudioStreamID](repeating: 0, count: streamCount)

  guard
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &streams)
      == noErr
  else {
    return []
  }

  var physicalFormats: [AudioStreamBasicDescription] = []

  // Get physical formats from each stream
  for streamID in streams {
    var streamPropertyAddress = AudioObjectPropertyAddress(
      mSelector: kAudioStreamPropertyAvailablePhysicalFormats,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )

    var streamPropertySize: UInt32 = 0
    guard
      AudioObjectGetPropertyDataSize(
        streamID, &streamPropertyAddress, 0, nil, &streamPropertySize) == noErr
    else {
      continue
    }

    let formatCount = Int(streamPropertySize) / MemoryLayout<AudioStreamRangedDescription>.size
    var rangedFormats = [AudioStreamRangedDescription](
      repeating: AudioStreamRangedDescription(), count: formatCount)

    guard
      AudioObjectGetPropertyData(
        streamID, &streamPropertyAddress, 0, nil, &streamPropertySize, &rangedFormats) == noErr
    else {
      continue
    }

    // Extract formats that match the sample rate
    for rangedFormat in rangedFormats {
      let format = rangedFormat.mFormat
      // Check if this format's sample rate range includes our target rate
      if rangedFormat.mSampleRateRange.mMinimum <= sampleRate
        && rangedFormat.mSampleRateRange.mMaximum >= sampleRate
      {
        // Only include valid formats
        if format.mBitsPerChannel > 0 && format.mBitsPerChannel <= 64 {
          physicalFormats.append(format)
        }
      }
    }
  }

  return physicalFormats
}

private func findBestFormat(formats: [AudioStreamBasicDescription]) -> AudioStreamBasicDescription {
  return formats.max { a, b in
    if a.mBitsPerChannel != b.mBitsPerChannel {
      return a.mBitsPerChannel < b.mBitsPerChannel
    }
    if a.mChannelsPerFrame != b.mChannelsPerFrame {
      return a.mChannelsPerFrame < b.mChannelsPerFrame
    }
    let aIsFloat = a.mFormatFlags & kAudioFormatFlagIsFloat != 0
    let bIsFloat = b.mFormatFlags & kAudioFormatFlagIsFloat != 0
    return !aIsFloat && bIsFloat
  } ?? formats.first!
}

private func setStreamFormat(
  deviceID: AudioDeviceID, format: AudioStreamBasicDescription, isInput: Bool
) -> Bool {
  let scope = isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput

  // Get the audio streams
  var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioDevicePropertyStreams,
    mScope: scope,
    mElement: kAudioObjectPropertyElementMain
  )

  var propertySize: UInt32 = 0
  guard AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize) == noErr
  else {
    return false
  }

  let streamCount = Int(propertySize) / MemoryLayout<AudioStreamID>.size
  var streams = [AudioStreamID](repeating: 0, count: streamCount)

  guard
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &streams)
      == noErr
  else {
    return false
  }

  guard let streamID = streams.first else {
    return false
  }

  // Set the physical format (actual hardware format)
  var streamPropertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioStreamPropertyPhysicalFormat,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
  )

  var formatCopy = format
  let streamPropertySize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)

  let result = AudioObjectSetPropertyData(
    streamID, &streamPropertyAddress, 0, nil, streamPropertySize, &formatCopy)
  return result == noErr
}

private func setSampleRate(deviceID: AudioDeviceID, sampleRate: Double) -> Bool {
  var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioDevicePropertyNominalSampleRate,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
  )

  var rate = sampleRate
  let propertySize = UInt32(MemoryLayout<Double>.size)

  return AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, propertySize, &rate)
    == noErr
}
