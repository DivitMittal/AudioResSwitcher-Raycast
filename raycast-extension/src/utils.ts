import { Icon } from "@raycast/api";
import type { FormatItem } from "./types";

export const LOSSLESS_SAMPLE_RATE = 192000;
export const LOSSLESS_BIT_DEPTH = 24;
export const HIGH_QUALITY_SAMPLE_RATE = 96000;
export const HIGH_QUALITY_BIT_DEPTH = 24;

export function getIcon(iconName: string): Icon {
  switch (iconName) {
    case "checkmark.circle.fill":
    case "checkmark.circle":
      return Icon.CheckCircle;
    case "circle":
      return Icon.Circle;
    case "crown":
      return Icon.Crown;
    default:
      return Icon.Circle;
  }
}

export function isLosslessQuality(item: FormatItem): boolean {
  return (
    item.sampleRate !== undefined &&
    item.sampleRate >= LOSSLESS_SAMPLE_RATE &&
    item.bitDepth !== undefined &&
    item.bitDepth >= LOSSLESS_BIT_DEPTH
  );
}

export function getQualityIcon(sampleRate?: number, bitDepth?: number): Icon {
  if (!sampleRate || !bitDepth) {
    return Icon.QuestionMark;
  }

  if (sampleRate >= LOSSLESS_SAMPLE_RATE && bitDepth >= LOSSLESS_BIT_DEPTH) {
    return Icon.Crown;
  }

  if (sampleRate >= HIGH_QUALITY_SAMPLE_RATE && bitDepth >= HIGH_QUALITY_BIT_DEPTH) {
    return Icon.Star;
  }

  return Icon.Circle;
}

export function formatBitrate(sampleRate?: number, bitDepth?: number): string {
  if (!sampleRate || !bitDepth) {
    return "N/A";
  }

  const rateKhz = sampleRate / 1000;
  return `${rateKhz >= 1000 ? `${rateKhz / 1000}M` : `${rateKhz}k`}/${bitDepth}`;
}
