export interface AudioDevice {
  id: string;
  name: string;
  isDefault: boolean;
  isInput: boolean;
  isOutput: boolean;
}

export interface AudioFormat {
  sampleRate: number;
  bitDepth: number;
  channels: number;
  formatName: string;
  isCurrentFormat: boolean;
}

export interface AudioDeviceInfo {
  device: AudioDevice;
  supportedFormats: AudioFormat[];
  currentFormat: AudioFormat;
}
