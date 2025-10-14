#!/usr/bin/env swift

import AudioToolbox
import CoreAudio
import Foundation

class AudioBitrateCommand {
  func run() {
    var result: [String: Any] = [:]

    // Get output device bitrate
    if let outputDeviceID = getDefaultOutputDevice() {
      if let format = getCurrentStreamFormat(deviceID: outputDeviceID, isInput: false) {
        result["outputSampleRate"] = Int(format.mSampleRate)
        result["outputBitDepth"] = Int(format.mBitsPerChannel)
        result["outputChannels"] = Int(format.mChannelsPerFrame)

        if let deviceName = getDeviceName(deviceID: outputDeviceID) {
          result["outputDevice"] = deviceName
        }
      }
    }

    // Get input device bitrate
    if let inputDeviceID = getDefaultInputDevice() {
      if let format = getCurrentStreamFormat(deviceID: inputDeviceID, isInput: true) {
        result["inputSampleRate"] = Int(format.mSampleRate)
        result["inputBitDepth"] = Int(format.mBitsPerChannel)
        result["inputChannels"] = Int(format.mChannelsPerFrame)

        if let deviceName = getDeviceName(deviceID: inputDeviceID) {
          result["inputDevice"] = deviceName
        }
      }
    }

    outputJSON(result)
  }

  // MARK: - Audio Core Functions

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

  // MARK: - Utility Functions

  private func outputJSON(_ object: Any) {
    guard
      let jsonData = try? JSONSerialization.data(withJSONObject: object, options: []),
      let jsonString = String(data: jsonData, encoding: .utf8)
    else {
      print("{}")
      return
    }
    print(jsonString)
  }
}

let command = AudioBitrateCommand()
command.run()
