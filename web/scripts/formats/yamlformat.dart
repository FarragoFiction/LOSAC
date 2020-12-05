import "package:LoaderLib/Loader.dart";
import "package:yaml/yaml.dart" as YAML;

class YAMLFormat extends StringFileFormat<YAML.YamlDocument> {

    @override
    String mimeType() => "application/yaml";

    @override
    Future<YAML.YamlDocument> read(String input) async => YAML.loadYamlDocument(input);

    @override
    Future<String> write(YAML.YamlDocument input) => throw UnimplementedError("YAML write not supported");

    @override
    String header() => "";
}