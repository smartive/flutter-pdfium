

default: generate_bindings

clean:
    #!/usr/bin/env bash
    for type in ios macos; do
        just _clean $type
    done

_clean type:
    rm -rf {{type}}/Classes/*.*

generate_bindings: clean _dart_bindings _osx_bindings

_dart_bindings:
    @flutter pub run ffigen --config ffigen.yaml

_osx_bindings:
    #!/usr/bin/env bash
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    for $header in fpdfview fpdf_doc fpdf_text; do
        echo "generate ast for $header"
        clang -Xclang -ast-dump=json -fsyntax-only src/pdfium/$header.h > $temp_dir/$header.json
    done

    for $type in ios macos; do
        echo "generate bindings for $type"
        just _dart_osx_bindings $temp_dir/fpdfview.json $type/Classes/bindings/fpdfview.cpp $type_ FPDF
    done

_dart_osx_bindings def dest prefix +regex:
    #!/usr/bin/env dart
    import 'dart:convert';
    import 'dart:io';

    class NodeType {
        final String type;
        final String? desugaredType;

        NodeType.fromJson(Map<String, dynamic> json)
            : type = json['qualType'],
                desugaredType = json['desugaredQualType'];
    }

    class Node {
        final String id;
        final String kind;
        final String? name;
        final NodeType? type;
        final List<Node> children;

        Node.fromJson(Map<String, dynamic> json)
            : id = json['id'],
                kind = json['kind'],
                name = json['name'],
                type = json['type'] != null ? NodeType.fromJson(json['type']) : null,
                children = (json['inner'] as List<dynamic>?)?.map((e) => Node.fromJson(e)).toList() ?? [];
    }

    class CFunction {
        final String prefix;
        final Node functionNode;

        CFunction(this.functionNode, this.prefix);

        String get returnType => functionNode.type?.type.split('(').first.trim() ?? 'N/A';

        String get outerParams => functionNode.children
            .where((element) => element.kind == 'ParmVarDecl')
            .map((param) => '${param.type?.type} ${param.name}')
            .join(', ');

        String get innerParams =>
            functionNode.children.where((element) => element.kind == 'ParmVarDecl').map((param) => param.name).join(', ');

        @override
        String toString() => '''extern "C" __attribute__((visibility("default"))) __attribute__((used))
        $returnType $prefix${functionNode.name}($outerParams) {
        return ${functionNode.name}($innerParams);
        }
        ''';
    }

    Future<void> main() async {
        final definition = '{{def}}';
        final destination = '{{dest}}';
        final prefix = '{{prefix}}';
        final regex = '{{regex}}'.split(' ').map((s) => RegExp(s)).toList(growable: false);

        print('Load $definition and create bindings in $destination with prefix $prefix.');
        if (regex.isNotEmpty) {
            print('Use regex to filter functions: $regex');
        }

        final raw = await File.fromUri(Uri.file(definition)).readAsString();
        final rootNode = Node.fromJson(jsonDecode(raw));

        final functions = rootNode.children
            .where((element) =>
                element.kind == 'FunctionDecl' && regex.any((expression) => expression.hasMatch(element.name ?? '')))
            .map((func) => CFunction(func, prefix));

        final targetFile = File.fromUri(Uri.file(destination)).openWrite(mode: FileMode.write);

        targetFile.writeln('#import "../include/${File(destination).uri.pathSegments.last.split('.').first}.h"\n');
        targetFile.writeAll(functions, '\n');

        await targetFile.flush();
        await targetFile.close();
    }
