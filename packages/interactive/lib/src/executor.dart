import 'dart:io';

import 'package:interactive/src/main.dart';
import 'package:interactive/src/parser.dart';
import 'package:interactive/src/utils.dart';
import 'package:interactive/src/vm_service_wrapper.dart';
import 'package:interactive/src/workspace_code.dart';
import 'package:interactive/src/workspace_file_tree.dart';
import 'package:interactive/src/workspace_isolate.dart';
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

class Executor {
  static final log = Logger('Executor');

  static const _evaluateCode = 'interactiveRuntimeContext.generatedMethod()';

  final WorkspaceFileTree workspaceFileTree;
  final Writer writer;
  final VmServiceWrapper vm;
  final WorkspaceIsolate workspaceIsolate;
  var workspaceCode = const WorkspaceCode.empty();
  final inputParser = InputParser();

  Executor._(
      this.vm, this.workspaceIsolate, this.writer, this.workspaceFileTree);

  static Future<Executor> create(Writer writer,
      {required WorkspaceFileTree workspaceFileTree}) async {
    // reset to avoid syntax error etc
    _writeWorkspaceCode(const WorkspaceCode.empty(), workspaceFileTree);

    final vm = await VmServiceWrapper.create();
    final workspaceIsolate =
        await WorkspaceIsolate.create(vm, workspaceFileTree);

    return Executor._(vm, workspaceIsolate, writer, workspaceFileTree);
  }

  void dispose() {
    workspaceIsolate.dispose();
    vm.dispose();
  }

  Future<void> execute(String rawInput) async {
    if (rawInput.startsWith(_kExecuteShellPrefix)) {
      return _executeShell(rawInput);
    }
    return _executeCode(rawInput);
  }

  static const _kExecuteShellPrefix = '!';

  Future<void> _executeShell(String rawInput) async {
    await executeProcess(
      rawInput.substring(_kExecuteShellPrefix.length),
      workingDirectory: workspaceFileTree.directory,
      writer: writer,
    );
  }

  Future<void> _executeCode(String rawInput) async {
    log.info('=== Execute rawInput=$rawInput ===');

    if (rawInput.trim().isEmpty) return;

    log.info('Phase: Parse');
    final parsedInput = inputParser.parse(rawInput);
    if (parsedInput == null) return;
    workspaceCode = workspaceCode.merge(parsedInput);

    log.info('Phase: Write');
    _writeWorkspaceCode(workspaceCode, workspaceFileTree);

    log.info('Phase: ReloadSources');
    final report = await vm.vmService.reloadSources(workspaceIsolate.isolateId);
    if (report.success != true) {
      log.warning(
          'Error: Hot reload failed, maybe because code has syntax error?');
      return;
    }

    log.info('Phase: Evaluate');
    final isolateInfo = await workspaceIsolate.isolateInfo;
    final targetId = isolateInfo.rootLib!.id!;
    final response = await vm.vmService
        .evaluate(workspaceIsolate.isolateId, targetId, _evaluateCode);
    await _handleEvaluateResponse(response);
  }

  Future<void> _handleEvaluateResponse(Response response) async {
    final responseString = response is ObjRef
        ? await _objRefToString(response)
        : response.toString();
    if (response is InstanceRef) {
      if (responseString != null && responseString != 'null') {
        writer(responseString);
      }
    } else if (response is ErrorRef) {
      log.warning('Error: $responseString');
    } else {
      log.warning('Unknown error (response: $response)');
    }
  }

  Future<String?> _objRefToString(ObjRef object) async {
    // InstanceRef.valueAsString only works on primitive values like String,
    // int, double, etc. so for anything else we have to ask the VM to get the toString value
    final response = await vm.vmService
        .evaluate(workspaceIsolate.isolateId, object.id!, 'this.toString()');

    if (response is InstanceRef) {
      return response.valueAsString;
    }

    // fail to call toString(), so fallback
    return object.toString();
  }

  static void _writeWorkspaceCode(
      WorkspaceCode workspaceCode, WorkspaceFileTree workspaceFileTree) {
    final generatedCode = workspaceCode.generate();
    File(workspaceFileTree.pathAutoGeneratedDart)
        .writeAsStringSync(generatedCode);
    log.info('generatedCode: $generatedCode');
  }
}
