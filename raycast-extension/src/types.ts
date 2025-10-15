export interface FormatItem {
  title: string;
  subtitle: string;
  icon: string;
  type: string;
  sampleRate?: number;
  bitDepth?: number;
  channels?: number;
  isCurrent?: boolean;
}

export interface AudioFormatsResult {
  items: FormatItem[];
}

export interface FormatChangeResult {
  success: string;
}

export interface AudioBitrateData {
  outputSampleRate?: number;
  outputBitDepth?: number;
  outputChannels?: number;
  outputDevice?: string;
  inputSampleRate?: number;
  inputBitDepth?: number;
  inputChannels?: number;
  inputDevice?: string;
}
