class WorkspaceCode {
  final Map<DeclarationKey, String> declarationMap;
  final String generatedMethodCodeBlock;

  const WorkspaceCode({
    required this.declarationMap,
    required this.generatedMethodCodeBlock,
  });

  const WorkspaceCode.empty()
      : declarationMap = const {},
        generatedMethodCodeBlock = '';

  WorkspaceCode merge(WorkspaceCode other) => WorkspaceCode(
        declarationMap: {...declarationMap, ...other.declarationMap},
        generatedMethodCodeBlock: other.generatedMethodCodeBlock,
      );

  String generate() {
    return '''
// AUTO-GENERATED, PLEASE DO NOT MODIFY BY HAND

import 'workspace.dart'; // ignore: unused_import
export 'workspace.dart';

${declarationMap.values.join('\n\n')}

extension ExtDynamic on dynamic {
  Object? generatedMethod() {
    $generatedMethodCodeBlock
  }
}
''';
  }
}

class DeclarationKey {
  final Type type;
  final String identifier;

  DeclarationKey(this.type, this.identifier);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeclarationKey &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          identifier == other.identifier;

  @override
  int get hashCode => type.hashCode ^ identifier.hashCode;

  @override
  String toString() => 'DeclarationKey($type, $identifier)';
}
