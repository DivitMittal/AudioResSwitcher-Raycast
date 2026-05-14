import { describe, expect, it, vi } from "vitest";

vi.mock("@raycast/api", () => ({
  Icon: {
    CheckCircle: "check-circle",
    Circle: "circle",
    Crown: "crown",
    Star: "star",
    QuestionMark: "question-mark",
  },
}));

import { errorMessage, formatBitrate, formatFullFormat, getQualityIcon, isLosslessQuality } from "./utils";
import type { FormatItem } from "./types";

function makeFormatItem(overrides: Partial<FormatItem> = {}): FormatItem {
  return {
    title: "test",
    subtitle: "test",
    icon: "circle",
    type: "format",
    ...overrides,
  };
}

describe("formatBitrate", () => {
  it("returns N/A when sample rate is missing", () => {
    expect(formatBitrate(undefined, 24)).toBe("N/A");
  });

  it("returns N/A when bit depth is missing", () => {
    expect(formatBitrate(48000, undefined)).toBe("N/A");
  });

  it("returns N/A when both inputs are missing", () => {
    expect(formatBitrate()).toBe("N/A");
  });

  it("treats zero sample rate as missing", () => {
    expect(formatBitrate(0, 24)).toBe("N/A");
  });

  it("treats zero bit depth as missing", () => {
    expect(formatBitrate(48000, 0)).toBe("N/A");
  });

  it("formats CD quality as 44.1k/16", () => {
    expect(formatBitrate(44100, 16)).toBe("44.1k/16");
  });

  it("formats DAT quality as 48k/16", () => {
    expect(formatBitrate(48000, 16)).toBe("48k/16");
  });

  it("formats high-res 96kHz/24-bit as 96k/24", () => {
    expect(formatBitrate(96000, 24)).toBe("96k/24");
  });

  it("formats lossless 192kHz/24-bit as 192k/24", () => {
    expect(formatBitrate(192000, 24)).toBe("192k/24");
  });

  it("switches to MHz notation at 1 MHz and above", () => {
    expect(formatBitrate(1000000, 32)).toBe("1M/32");
  });

  it("formats 2.8224 MHz DSD-style rate in MHz", () => {
    expect(formatBitrate(2822400, 1)).toBe("2.8224M/1");
  });
});

describe("formatFullFormat", () => {
  it("returns Unknown format when sample rate is missing", () => {
    expect(formatFullFormat(undefined, 24, 2)).toBe("Unknown format");
  });

  it("returns Unknown format when bit depth is missing", () => {
    expect(formatFullFormat(48000, undefined, 2)).toBe("Unknown format");
  });

  it("treats zero sample rate as missing", () => {
    expect(formatFullFormat(0, 24, 2)).toBe("Unknown format");
  });

  it("renders the channel suffix when channels is provided", () => {
    expect(formatFullFormat(96000, 24, 2)).toBe("96kHz 24-bit 2ch");
  });

  it("renders a mono channel suffix", () => {
    expect(formatFullFormat(48000, 16, 1)).toBe("48kHz 16-bit 1ch");
  });

  it("omits the channel suffix when channels is undefined", () => {
    expect(formatFullFormat(48000, 16, undefined)).toBe("48kHz 16-bit");
  });

  it("omits the channel suffix when channels is zero (was the `|| 2` bug)", () => {
    expect(formatFullFormat(48000, 16, 0)).toBe("48kHz 16-bit");
  });

  it("renders multi-channel surround configs", () => {
    expect(formatFullFormat(48000, 24, 8)).toBe("48kHz 24-bit 8ch");
  });
});

describe("errorMessage", () => {
  it("returns the message of a real Error", () => {
    expect(errorMessage(new Error("boom"))).toBe("boom");
  });

  it("returns the message of an Error subclass", () => {
    class CustomError extends Error {}
    expect(errorMessage(new CustomError("custom boom"))).toBe("custom boom");
  });

  it("returns string inputs as-is", () => {
    expect(errorMessage("something went wrong")).toBe("something went wrong");
  });

  it("stringifies plain objects via JSON", () => {
    expect(errorMessage({ code: 42, reason: "nope" })).toBe('{"code":42,"reason":"nope"}');
  });

  it("returns String(value) when JSON.stringify fails (circular refs)", () => {
    const circular: Record<string, unknown> = {};
    circular.self = circular;
    expect(errorMessage(circular)).toBe("[object Object]");
  });

  it("handles undefined without returning undefined", () => {
    // JSON.stringify(undefined) is undefined, so the function must fall back
    // to String(undefined) rather than returning a non-string from a
    // declared `string` return type.
    expect(errorMessage(undefined)).toBe("undefined");
  });

  it("handles null", () => {
    expect(errorMessage(null)).toBe("null");
  });

  it("handles numbers", () => {
    expect(errorMessage(404)).toBe("404");
  });
});

describe("getQualityIcon", () => {
  it("returns the question-mark icon when sample rate is missing", () => {
    expect(getQualityIcon(undefined, 24)).toBe("question-mark");
  });

  it("returns the question-mark icon when bit depth is missing", () => {
    expect(getQualityIcon(96000, undefined)).toBe("question-mark");
  });

  it("returns the question-mark icon when both inputs are missing", () => {
    expect(getQualityIcon()).toBe("question-mark");
  });

  it("returns the crown icon for lossless rates (>=192k/24)", () => {
    expect(getQualityIcon(192000, 24)).toBe("crown");
  });

  it("returns the crown icon for above-lossless rates", () => {
    expect(getQualityIcon(384000, 32)).toBe("crown");
  });

  it("does not award the crown when bit depth is below 24, even at lossless sample rates", () => {
    // 192k/16 satisfies the rate part of the lossless and high-quality
    // thresholds but fails both bit-depth gates (24), so it falls to circle.
    expect(getQualityIcon(192000, 16)).toBe("circle");
  });

  it("returns the star icon for high-quality (96k/24) formats", () => {
    expect(getQualityIcon(96000, 24)).toBe("star");
  });

  it("returns the star icon at 96k/24 exactly (boundary)", () => {
    expect(getQualityIcon(96000, 24)).toBe("star");
  });

  it("returns the circle icon for CD-quality formats", () => {
    expect(getQualityIcon(44100, 16)).toBe("circle");
  });

  it("returns the circle icon for DAT-quality formats", () => {
    expect(getQualityIcon(48000, 16)).toBe("circle");
  });

  it("returns the circle icon just below the high-quality threshold", () => {
    expect(getQualityIcon(88200, 24)).toBe("circle");
  });
});

describe("isLosslessQuality", () => {
  it("returns true at exactly 192k/24", () => {
    expect(isLosslessQuality(makeFormatItem({ sampleRate: 192000, bitDepth: 24 }))).toBe(true);
  });

  it("returns true above the threshold on both axes", () => {
    expect(isLosslessQuality(makeFormatItem({ sampleRate: 384000, bitDepth: 32 }))).toBe(true);
  });

  it("returns false when sample rate is below threshold", () => {
    expect(isLosslessQuality(makeFormatItem({ sampleRate: 96000, bitDepth: 24 }))).toBe(false);
  });

  it("returns false when bit depth is below threshold", () => {
    expect(isLosslessQuality(makeFormatItem({ sampleRate: 192000, bitDepth: 16 }))).toBe(false);
  });

  it("returns false when sample rate is undefined", () => {
    expect(isLosslessQuality(makeFormatItem({ bitDepth: 24 }))).toBe(false);
  });

  it("returns false when bit depth is undefined", () => {
    expect(isLosslessQuality(makeFormatItem({ sampleRate: 192000 }))).toBe(false);
  });

  it("returns false for an info item with no rate or depth", () => {
    expect(isLosslessQuality(makeFormatItem({ type: "info" }))).toBe(false);
  });
});
