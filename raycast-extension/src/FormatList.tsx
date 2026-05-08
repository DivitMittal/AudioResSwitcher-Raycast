import { ActionPanel, Action, List, Icon, LaunchType, launchCommand, showToast, Toast } from "@raycast/api";
import { useCachedPromise } from "@raycast/utils";
import type { FormatItem } from "./types";
import { errorMessage, getIcon, isLosslessQuality } from "./utils";

const MENUBAR_COMMAND_NAME = "audio-bitrate-menubar";

async function refreshMenubar(): Promise<void> {
  try {
    await launchCommand({ name: MENUBAR_COMMAND_NAME, type: LaunchType.Background });
  } catch (error) {
    // Menubar may be disabled by the user, or the command may not be installed
    // yet during dev. Either way, failing to refresh it shouldn't surface as a
    // user-visible error from the format change.
    console.warn("Could not push menubar refresh:", error);
  }
}

interface FormatListProps {
  deviceType: "input" | "output";
  loadFormats: () => Promise<{ items: FormatItem[] }>;
  setFormat: (sampleRate: number, bitDepth: number, channels: number) => Promise<{ success: string }>;
}

const EMPTY_RESULT = { items: [] as FormatItem[] };

export function FormatList({ deviceType, loadFormats, setFormat }: FormatListProps) {
  const directionLabel = deviceType === "input" ? "Input" : "Output";

  const { data, isLoading, revalidate } = useCachedPromise(loadFormats, [], {
    initialData: EMPTY_RESULT,
    keepPreviousData: true,
    onError: async (error) => {
      console.error(`Error loading ${deviceType} formats:`, error);
      await showToast({
        style: Toast.Style.Failure,
        title: "Error Loading Formats",
        message: errorMessage(error),
      });
    },
  });

  const items = data?.items ?? [];

  const setDeviceFormat = async (item: FormatItem) => {
    if (!item.sampleRate || !item.bitDepth || !item.channels) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Invalid Format",
        message: "Missing format parameters",
      });
      return;
    }

    const toast = await showToast({
      style: Toast.Style.Animated,
      title: `Setting ${directionLabel} Format`,
      message: `Configuring to ${item.title}...`,
    });

    try {
      const result = await setFormat(item.sampleRate, item.bitDepth, item.channels);
      toast.style = Toast.Style.Success;
      toast.title = `${directionLabel} Format Updated`;
      toast.message = result.success;
      revalidate();
      await refreshMenubar();
    } catch (error) {
      console.error("Error setting format:", error);
      toast.style = Toast.Style.Failure;
      toast.title = "Failed to Set Format";
      toast.message = errorMessage(error);
    }
  };

  const pickHighestQualityFormat = (): FormatItem | undefined => {
    const losslessFormats = items.filter((item) => item.type === "format" && isLosslessQuality(item));
    if (losslessFormats.length === 0) {
      return undefined;
    }
    return losslessFormats.reduce((best, candidate) => {
      const bestScore = (best.sampleRate ?? 0) * (best.bitDepth ?? 0);
      const candidateScore = (candidate.sampleRate ?? 0) * (candidate.bitDepth ?? 0);
      return candidateScore > bestScore ? candidate : best;
    });
  };

  const setToHighestQuality = async () => {
    const highestQualityFormat = pickHighestQualityFormat();

    if (highestQualityFormat) {
      await setDeviceFormat(highestQualityFormat);
    } else {
      await showToast({
        style: Toast.Style.Failure,
        title: "No High Quality Format Found",
        message: "No 192kHz/24-bit+ format available",
      });
    }
  };

  const hasHighestQualityFormat = pickHighestQualityFormat() !== undefined;

  const formatItems = items.filter((item) => item.type === "format");
  const deviceInfo = items.find((item) => item.type === "info");

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search audio formats...">
      {formatItems.map((item) => (
        <List.Item
          key={`${item.sampleRate}-${item.bitDepth}-${item.channels}-${item.subtitle}`}
          title={item.title}
          subtitle={item.subtitle}
          icon={getIcon(item.icon)}
          accessories={isLosslessQuality(item) ? [{ icon: Icon.Crown, tooltip: "Lossless Quality" }] : []}
          actions={
            <ActionPanel>
              {!item.isCurrent && (
                <Action title="Set This Format" icon={Icon.Gear} onAction={() => setDeviceFormat(item)} />
              )}
              {hasHighestQualityFormat && (
                <Action
                  title="Set to Highest Quality"
                  icon={Icon.Crown}
                  onAction={setToHighestQuality}
                  shortcut={{ modifiers: ["cmd"], key: "h" }}
                />
              )}
              <Action
                title="Refresh Formats"
                icon={Icon.ArrowClockwise}
                onAction={revalidate}
                shortcut={{ modifiers: ["cmd"], key: "r" }}
              />
              <Action.CopyToClipboard content={item.title} title="Copy Format Name" />
              {deviceInfo && (
                <Action.CopyToClipboard
                  content={deviceInfo.title}
                  title="Copy Device Name"
                  shortcut={{ modifiers: ["cmd"], key: "d" }}
                />
              )}
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
