import { MenuBarExtra, Icon, open } from "@raycast/api";
import { useCachedPromise } from "@raycast/utils";
import { getAudioBitrate } from "swift:../swift";

function formatBitrate(sampleRate?: number, bitDepth?: number): string {
  if (!sampleRate || !bitDepth) {
    return "N/A";
  }

  const rateKhz = sampleRate / 1000;
  return `${rateKhz >= 1000 ? `${rateKhz / 1000}M` : `${rateKhz}k`}/${bitDepth}`;
}

function getQualityIcon(sampleRate?: number, bitDepth?: number): Icon {
  if (!sampleRate || !bitDepth) {
    return Icon.QuestionMark;
  }

  // High quality: 192kHz+ with 24+ bit depth
  if (sampleRate >= 192000 && bitDepth >= 24) {
    return Icon.Crown;
  }

  // Good quality: 96kHz+ with 24+ bit depth
  if (sampleRate >= 96000 && bitDepth >= 24) {
    return Icon.Star;
  }

  // Standard quality
  return Icon.Circle;
}

export default function Command() {
  const { data, isLoading, revalidate } = useCachedPromise(getAudioBitrate, [], {
    initialData: {},
    keepPreviousData: true,
  });

  const outputBitrate = formatBitrate(data.outputSampleRate, data.outputBitDepth);
  const inputBitrate = formatBitrate(data.inputSampleRate, data.inputBitDepth);

  const title = `Out: ${outputBitrate} | In: ${inputBitrate}`;

  return (
    <MenuBarExtra
      title={title}
      isLoading={isLoading}
      tooltip="Audio Bitrate Monitor"
    >
      <MenuBarExtra.Section title="Output Device">
        {data.outputDevice && (
          <MenuBarExtra.Item
            title={data.outputDevice}
            icon={Icon.Speaker}
            onAction={() => open("raycast://extensions/divm/audio-res-switcher/output-formats")}
          />
        )}
        {data.outputSampleRate && data.outputBitDepth && (
          <MenuBarExtra.Item
            title={`${data.outputSampleRate / 1000}kHz ${data.outputBitDepth}-bit ${data.outputChannels || 2}ch`}
            icon={getQualityIcon(data.outputSampleRate, data.outputBitDepth)}
            subtitle="Current Format"
          />
        )}
        {!data.outputDevice && (
          <MenuBarExtra.Item title="No output device" icon={Icon.XMarkCircle} />
        )}
      </MenuBarExtra.Section>

      <MenuBarExtra.Section title="Input Device">
        {data.inputDevice && (
          <MenuBarExtra.Item
            title={data.inputDevice}
            icon={Icon.Microphone}
            onAction={() => open("raycast://extensions/divm/audio-res-switcher/input-formats")}
          />
        )}
        {data.inputSampleRate && data.inputBitDepth && (
          <MenuBarExtra.Item
            title={`${data.inputSampleRate / 1000}kHz ${data.inputBitDepth}-bit ${data.inputChannels || 2}ch`}
            icon={getQualityIcon(data.inputSampleRate, data.inputBitDepth)}
            subtitle="Current Format"
          />
        )}
        {!data.inputDevice && (
          <MenuBarExtra.Item title="No input device" icon={Icon.XMarkCircle} />
        )}
      </MenuBarExtra.Section>

      <MenuBarExtra.Section>
        <MenuBarExtra.Item
          title="Refresh"
          icon={Icon.ArrowClockwise}
          onAction={revalidate}
          shortcut={{ modifiers: ["cmd"], key: "r" }}
        />
        <MenuBarExtra.Item
          title="Configure Output"
          icon={Icon.Speaker}
          onAction={() => open("raycast://extensions/divm/audio-res-switcher/output-formats")}
        />
        <MenuBarExtra.Item
          title="Configure Input"
          icon={Icon.Microphone}
          onAction={() => open("raycast://extensions/divm/audio-res-switcher/input-formats")}
        />
      </MenuBarExtra.Section>

      <MenuBarExtra.Section>
        <MenuBarExtra.Item
          title="About Quality Indicators"
          subtitle="Crown = Lossless (192k/24+) | Star = High (96k/24+)"
          icon={Icon.Info}
        />
      </MenuBarExtra.Section>
    </MenuBarExtra>
  );
}
