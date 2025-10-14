import { useState, useEffect } from "react";
import {
  ActionPanel,
  Action,
  List,
  Icon,
  showToast,
  Toast,
} from "@raycast/api";
import { execa } from "execa";
import { environment } from "@raycast/api";
import path from "path";

interface ListItem {
  title: string;
  subtitle: string;
  icon: string;
  type: string;
  sampleRate?: number;
  bitDepth?: number;
  channels?: number;
  isCurrent?: boolean;
  action?: string;
}

export default function Command() {
  const [items, setItems] = useState<ListItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const loadFormats = async () => {
    try {
      setIsLoading(true);
      const scriptPath = path.join(
        environment.assetsPath,
        "output-formats.swift",
      );
      const { stdout } = await execa("swift", [scriptPath]);
      const result = JSON.parse(stdout);

      if (result.error) {
        throw new Error(result.error);
      }

      setItems(result.items || []);
    } catch (error) {
      console.error("Error loading output formats:", error);
      await showToast({
        style: Toast.Style.Failure,
        title: "Error Loading Formats",
        message: String(error),
      });
    } finally {
      setIsLoading(false);
    }
  };

  const setFormat = async (item: ListItem) => {
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
        title: "Setting Output Format",
        message: `Configuring to ${item.title}...`,
      });

      const scriptPath = path.join(
        environment.assetsPath,
        "output-formats.swift",
      );
      console.log(
        `Executing: swift ${scriptPath} set ${item.sampleRate} ${item.bitDepth} ${item.channels}`,
      );

      const { stdout, stderr } = await execa("swift", [
        scriptPath,
        "set",
        item.sampleRate.toString(),
        item.bitDepth.toString(),
        item.channels.toString(),
      ]);

      console.log("Swift stdout:", stdout);
      console.log("Swift stderr:", stderr);

      if (stderr) {
        throw new Error(`Swift execution error: ${stderr}`);
      }

      let result;
      try {
        result = JSON.parse(stdout);
      } catch (parseError) {
        console.error("JSON parse error:", parseError);
        console.error("Raw stdout:", stdout);
        throw new Error(`Failed to parse Swift response: ${stdout}`);
      }

      if (result.error) {
        throw new Error(result.error);
      }

      await showToast({
        style: Toast.Style.Success,
        title: "Output Format Updated",
        message: result.success || `Set to ${item.title}`,
      });

      // Refresh the list after a short delay to allow the change to take effect
      setTimeout(() => loadFormats(), 500);
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

  const isHighQuality = (item: ListItem) => {
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
