import 'dart:io';

Future<void> main(List<String> arguments) async {
  // Add this part
  final useFvm = !arguments.contains('--no-fvm');
  final command = useFvm
      ? 'fvm dart run dart_pre_commit' // or "fmv flutter pub run dart_pre_commit" for flutter projects
      : 'dart run dart_pre_commit'; // or "flutter pub run dart_pre_commit" for flutter projects

  final preCommitHook = File('.git/hooks/pre-commit');
  await preCommitHook.parent.create();
  await preCommitHook.writeAsString('''
#!/bin/sh
exec $command # use the previously selected command here
''');

  if (!Platform.isWindows) {
    final result = await Process.run('chmod', ['a+x', preCommitHook.path]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    exitCode = result.exitCode;
  }
}
