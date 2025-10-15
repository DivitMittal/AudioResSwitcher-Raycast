import { useState, useEffect } from "react";
import {
  ActionPanel,
  Action,
  List,
  Icon,
  showToast,
  Toast,
} from "@raycast/api";
import { getInputFormats, setInputFormat } from "swift:../swift";
import type { FormatItem } from "./types";

export default function Command() {
  const [items, setItems] = useState<FormatItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const loadFormats = async () => {
    try {
      setIsLoading(true);
      const result = await getInputFormats();
      setItems(result.items);
    } catch (error) {
      console.error("Error loading input formats:", error);
      await showToast({
        style: Toast.Style.Failure,
        title: "Error Loading Formats",
        message: String(error),
      });
    } finally {
      setIsLoading(false);
    }
  };

  const setFormat = async (item: FormatItem) => {
    if (!item.sampleRate || !item.bitDepth || !item.channels) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Invalid Format",
        message: "Missing format parameters",
      });
      return;
    }

    try {
      await showToast({
        style: Toast.Style.Animated,
        title: "Setting Input Format",
        message: `Configuring to ${item.title}...`,
      });

      const result = await setInputFormat(
        item.sampleRate,
        item.bitDepth,
        item.channels,
      );

      await showToast({
        style: Toast.Style.Success,
        title: "Input Format Updated",
        message: result.success,
      });

      // Refresh the list
      await loadFormats();
    } catch (error) {
      console.error("Error setting format:", error);
      await showToast({
        style: Toast.Style.Failure,
        title: "Failed to Set Format",
        message: String(error),
      });
    }
  };

  const setToHighestQuality = async () => {
    // Find the highest quality format (192kHz+ with 24+ bit depth)
    const highestQualityFormat = items.find(
      (item) =>
        item.type === "format" &&
        item.sampleRate &&
        item.sampleRate >= 192000 &&
        item.bitDepth &&
        item.bitDepth >= 24,
    );

    if (highestQualityFormat) {
      await setFormat(highestQualityFormat);
    } else {
      await showToast({
        style: Toast.Style.Failure,
        title: "No High Quality Format Found",
        message: "No 192kHz/24-bit+ format available",
      });
    }
  };

  useEffect(() => {
    loadFormats();
  }, []);

  const getIcon = (iconName: string) => {
    switch (iconName) {
      case "checkmark.circle.fill":
        return Icon.CheckCircle;
      case "checkmark.circle":
        return Icon.CheckCircle;
      case "circle":
        return Icon.Circle;
      case "crown":
        return Icon.Crown;
      default:
        return Icon.Circle;
    }
  };

  const isHighQuality = (item: FormatItem) => {
    return (
      item.sampleRate &&
      item.sampleRate >= 192000 &&
      item.bitDepth &&
      item.bitDepth >= 24
    );
  };

  // Filter to show only format items, not info items
  const formatItems = items.filter((item) => item.type === "format");
  const deviceInfo = items.find((item) => item.type === "info");

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search audio formats...">
      {formatItems.map((item, index) => (
        <List.Item
          key={index}
          title={item.title}
          subtitle={item.subtitle}
          icon={getIcon(item.icon)}
          accessories={[
            ...(isHighQuality(item)
              ? [{ icon: Icon.Crown, tooltip: "Lossless Quality" }]
              : []),
          ]}
          actions={
            <ActionPanel>
              {!item.isCurrent && (
                <Action
                  title="Set This Format"
                  icon={Icon.Gear}
                  onAction={() => setFormat(item)}
                />
              )}
              {isHighQuality(item) && (
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
                onAction={loadFormats}
                shortcut={{ modifiers: ["cmd"], key: "r" }}
              />
              <Action.CopyToClipboard
                content={item.title}
                title="Copy Format Name"
              />
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
