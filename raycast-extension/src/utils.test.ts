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

import { formatBitrate } from "./utils";

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
