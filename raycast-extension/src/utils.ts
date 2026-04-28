import { Icon } from "@raycast/api";
import type { FormatItem, FormatItemIcon } from "./types";

export const LOSSLESS_SAMPLE_RATE = 192000;
export const LOSSLESS_BIT_DEPTH = 24;
export const HIGH_QUALITY_SAMPLE_RATE = 96000;
export const HIGH_QUALITY_BIT_DEPTH = 24;

export function getIcon(iconName: FormatItemIcon): Icon {
  switch (iconName) {
    case "checkmark.circle.fill":
    case "checkmark.circle":
      return Icon.CheckCircle;
    case "circle":
      return Icon.Circle;
    case "crown":
      return Icon.Crown;
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

export function errorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === "string") {
    return error;
  }
  try {
    return JSON.stringify(error);
  } catch {
    return String(error);
  }
}

export function formatBitrate(sampleRate?: number, bitDepth?: number): string {
  if (!sampleRate || !bitDepth) {
    return "N/A";
  }

  const rateKhz = sampleRate / 1000;
  return `${rateKhz >= 1000 ? `${rateKhz / 1000}M` : `${rateKhz}k`}/${bitDepth}`;
}

export function formatFullFormat(sampleRate?: number, bitDepth?: number, channels?: number): string {
  if (!sampleRate || !bitDepth) {
    return "Unknown format";
  }

  const channelSuffix = channels !== undefined && channels > 0 ? ` ${channels}ch` : "";
  return `${sampleRate / 1000}kHz ${bitDepth}-bit${channelSuffix}`;
}
