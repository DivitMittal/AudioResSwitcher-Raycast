#!/usr/bin/env swift

import AudioToolbox
import CoreAudio
import Foundation

class InputFormatsCommand {
  func run() {
    // Check if we have command line arguments for setting format
    if CommandLine.arguments.count > 1 && CommandLine.arguments[1] == "set" {
      handleSetFormat()
      return
    }

    // Default: list formats
    listFormats()
  }

  private func handleSetFormat() {
    guard CommandLine.arguments.count >= 4 else {
      outputError("Usage: input-formats.swift set <sampleRate> <bitDepth> [channels]")
      return
    }

    guard let sampleRate = Double(CommandLine.arguments[2]),
      let bitDepth = Int(CommandLine.arguments[3])
    else {
      outputError("Invalid sample rate or bit depth")
      return
    }

    let channels = CommandLine.arguments.count > 4 ? Int(CommandLine.arguments[4]) ?? 2 : 2

    guard let deviceID = getDefaultInputDevice() else {
      outputError("Could not find default input device")
      return
    }

    if setFormat(deviceID: deviceID, sampleRate: sampleRate, bitDepth: bitDepth, channels: channels)
    {
      outputSuccess(
        "Successfully set input format to \(Int(sampleRate)) Hz \(bitDepth)-bit \(channels)-channel"
      )
    } else {
      outputError("Failed to set input format")
    }
  }

  private func listFormats() {
    guard let deviceID = getDefaultInputDevice() else {
      outputError("Could not find default input device")
      return
    }

    guard let deviceName = getDeviceName(deviceID: deviceID) else {
      outputError("Could not get device name")
      return
    }

    let currentFormat = getCurrentStreamFormat(deviceID: deviceID, isInput: true)
    let availableRates = getAvailableSampleRates(deviceID: deviceID)

    var listItems: [[String: Any]] = []

    // Track seen formats to avoid duplicates (by rate, bit depth, channels, and type)
    var seenFormats = Set<String>()

    // Add current device info
    listItems.append([
      "title": "Current Device: \(deviceName)",
      "subtitle": currentFormat != nil
        ? "\(Int(currentFormat!.mSampleRate)) Hz \(currentFormat!.mBitsPerChannel)-bit \(currentFormat!.mChannelsPerFrame)-channel"
        : "Format unknown",
      "icon": "checkmark.circle.fill",
      "type": "info",
    ])

    // Add available hardware formats only (no virtual/software formats)
    for rate in availableRates {
      let streamFormats = getAvailableStreamFormats(
        deviceID: deviceID, sampleRate: rate, isInput: true)

      for format in streamFormats {
        let isCurrent =
          currentFormat != nil && abs(currentFormat!.mSampleRate - format.mSampleRate) < 0.1
          && currentFormat!.mBitsPerChannel == format.mBitsPerChannel
          && currentFormat!.mChannelsPerFrame == format.mChannelsPerFrame

        let formatType = format.mFormatFlags & kAudioFormatFlagIsFloat != 0 ? "Float" : "Integer"

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

        listItems.append([
          "title": title,
          "subtitle": subtitle,
          "icon": isCurrent ? "checkmark.circle" : (isHighQuality ? "crown" : "circle"),
          "type": "format",
          "sampleRate": format.mSampleRate,
          "bitDepth": Int(format.mBitsPerChannel),
          "channels": Int(format.mChannelsPerFrame),
          "isCurrent": isCurrent,
        ])
      }
    }

    // Sort formats: first by sample rate (ascending), then by bit depth (descending for quality)
    let sortedListItems = listItems.sorted { item1, item2 in
      // Keep device info first
      if let type1 = item1["type"] as? String, type1 == "info" { return true }
      if let type2 = item2["type"] as? String, type2 == "info" { return false }

      guard let rate1 = item1["sampleRate"] as? Double,
        let rate2 = item2["sampleRate"] as? Double,
        let bits1 = item1["bitDepth"] as? Int,
        let bits2 = item2["bitDepth"] as? Int
      else {
        return false
      }

      // Sort by sample rate ascending, then bit depth ascending
      if rate1 != rate2 {
        return rate1 < rate2
      }
      return bits1 < bits2
    }

    let result = [
      "items": sortedListItems
    ]

    outputJSON(result)
  }

  // MARK: - Audio Core Functions

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

    guard
      AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &deviceName)
        == noErr,
      let name = deviceName?.takeUnretainedValue()
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
    // This ensures we show the real format, not the macOS conversion layer

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

  // MARK: - Utility Functions

  private func outputJSON(_ object: Any) {
    guard
      let jsonData = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
      let jsonString = String(data: jsonData, encoding: .utf8)
    else {
      outputError("Failed to serialize JSON")
      return
    }
    print(jsonString)
  }

  private func setFormat(deviceID: AudioDeviceID, sampleRate: Double, bitDepth: Int, channels: Int)
    -> Bool
  {
    // Try to find matching format
    let streamFormats = getAvailableStreamFormats(
      deviceID: deviceID, sampleRate: sampleRate, isInput: true)

    var targetFormat: AudioStreamBasicDescription?

    // Find exact match
    targetFormat = streamFormats.first { format in
      format.mBitsPerChannel == bitDepth && format.mChannelsPerFrame == channels
    }

    if targetFormat == nil && !streamFormats.isEmpty {
      // Find best available format at this sample rate
      targetFormat = findBestFormat(formats: streamFormats)
    }

    if let format = targetFormat {
      return setStreamFormat(deviceID: deviceID, format: format, isInput: true)
    } else {
      // Fall back to setting just sample rate
      return setSampleRate(deviceID: deviceID, sampleRate: sampleRate)
    }
  }

  private func findBestFormat(formats: [AudioStreamBasicDescription]) -> AudioStreamBasicDescription
  {
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

    // Set the physical format (actual hardware format) instead of virtual format
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

  private func outputError(_ message: String) {
    let error = ["error": message]
    if let jsonData = try? JSONSerialization.data(withJSONObject: error, options: []),
      let jsonString = String(data: jsonData, encoding: .utf8)
    {
      print(jsonString)
    } else {
      print("{\"error\": \"Unknown error\"}")
    }
  }

  private func outputSuccess(_ message: String) {
    let success = ["success": message]
    if let jsonData = try? JSONSerialization.data(withJSONObject: success, options: []),
      let jsonString = String(data: jsonData, encoding: .utf8)
    {
      print(jsonString)
    }
  }
}

let command = InputFormatsCommand()
command.run()
