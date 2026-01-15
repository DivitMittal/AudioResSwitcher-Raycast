import { getInputFormats, setInputFormat } from "swift:../swift";
import { FormatList } from "./FormatList";

export default function Command() {
  return <FormatList deviceType="input" loadFormats={getInputFormats} setFormat={setInputFormat} />;
}
