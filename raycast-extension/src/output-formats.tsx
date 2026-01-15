import { getOutputFormats, setOutputFormat } from "swift:../swift";
import { FormatList } from "./FormatList";

export default function Command() {
  return <FormatList deviceType="output" loadFormats={getOutputFormats} setFormat={setOutputFormat} />;
}
