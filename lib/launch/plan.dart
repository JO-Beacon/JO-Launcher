// Computes the final command line from the version manifest, account, Java and
// version settings.
//
// Computation only; it does not start a process. This makes it testable with
// fixtures when there is no token or version directory. The actual spawn lives
// in launch_service.dart.

import 'dart:io';

import 'package:archive/archive.dart';

import '../auth/account.dart';
import '../mc/paths.dart';
import '../mc/version.dart';
import '../mc/version_config.dart';
import 'java.dart';
import 'launch_error.dart';
import 'manifest.dart';

class LaunchPlan {
  const LaunchPlan({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  });

  final String executable;
  final List<String> arguments;
  final String workingDirectory;

  /// Human-readable command line (paths with spaces are quoted; not guaranteed
  /// to be shell-copyable).
  String get commandLine => <String>[
    executable,
    ...arguments,
  ].map((String part) => part.contains(' ') ? '"$part"' : part).join(' ');
}

Future<LaunchPlan> buildLaunchPlan({
  required String gameDir,
  required McVersion version,
  required MinecraftAccount account,
  required VersionConfig config,
  required VersionManifest manifest,
  required JavaRuntime java,
  LaunchContext? context,
  String launcherVersion = '0.0.1',
  String clientId = '',
}) async {
  final LaunchContext ctx = context ?? LaunchContext.host();
  final int? requiredMajor = manifest.javaMajor;
  if (requiredMajor != null && java.major < requiredMajor) {
    throw LaunchException('launch.error.javaTooOld', <String, Object>{
      'required': requiredMajor,
      'found': java.major,
    });
  }

  final String versionDir = version.dir;
  final String librariesDir = joinPath(gameDir, 'libraries');
  final String assetsDir = joinPath(gameDir, 'assets');
  final String nativesDir = joinPath(versionDir, 'natives');
  await Directory(nativesDir).create(recursive: true);

  final String jarId = manifest.clientJarId ?? version.name;
  File clientJar = File(joinPath(versionDir, '$jarId.jar'));
  if (!await clientJar.exists()) {
    final Directory jarDir = Directory(
      joinPath(joinPath(gameDir, 'versions'), jarId),
    );
    final File inherited = File(joinPath(jarDir.path, '$jarId.jar'));
    if (await inherited.exists()) clientJar = inherited;
  }
  if (!await clientJar.exists()) {
    throw LaunchException('launch.error.missingClient', <String, Object>{
      'path': clientJar.path,
    });
  }

  final List<String> classpath = <String>[];
  for (final Library library in manifest.libraries) {
    if (!library.allows(ctx)) continue;
    final Download? artifact = library.artifact;
    if (artifact == null) continue;
    final File file = File(joinPath(librariesDir, artifact.path));
    if (!await file.exists()) {
      throw LaunchException('launch.error.missingLibrary', <String, Object>{
        'path': file.path,
      });
    }
    if (!classpath.contains(file.path)) classpath.add(file.path);
  }
  if (!classpath.contains(clientJar.path)) classpath.add(clientJar.path);
  final String separator = ctx.osName == 'windows' ? ';' : ':';
  final String classpathString = classpath.join(separator);

  await _extractNatives(manifest, ctx, librariesDir, nativesDir);

  final String? indexId = manifest.assetIndex ?? manifest.assets;
  if (indexId == null) {
    throw const LaunchException('launch.error.missingAssetsIndex');
  }
  final File indexFile = File(
    joinPath(joinPath(assetsDir, 'indexes'), '$indexId.json'),
  );
  if (!await indexFile.exists()) {
    throw LaunchException('launch.error.missingAssets', <String, Object>{
      'path': indexFile.path,
    });
  }

  final String? mainClass = manifest.mainClass;
  if (mainClass == null) {
    throw const LaunchException('launch.error.noMainClass');
  }

  final Map<String, String> variables = <String, String>{
    'auth_player_name': account.name,
    'version_name': version.name,
    'game_directory': versionDir,
    'assets_root': assetsDir,
    'assets_index_name': indexId,
    'auth_uuid': account.uuid,
    'auth_access_token': account.accessToken,
    'auth_session': 'token:${account.accessToken}:${account.uuid}',
    'clientid': clientId,
    'auth_xuid': '',
    'user_type': 'msa',
    'version_type': manifest.type ?? 'release',
    'user_properties': '{}',
    'natives_directory': nativesDir,
    'classpath': classpathString,
    'classpath_separator': separator,
    'library_directory': librariesDir,
    'game_assets': joinPath(assetsDir, 'virtual/legacy'),
    'launcher_name': 'JO-Launcher',
    'launcher_version': launcherVersion,
    'resolution_width': '854',
    'resolution_height': '480',
  };

  List<String> gameArguments = _expand(manifest.gameArguments, ctx, variables);
  if (gameArguments.isEmpty && manifest.minecraftArguments != null) {
    gameArguments = _substituteAll(
      manifest.minecraftArguments!.split(RegExp(r'\s+')),
      variables,
    );
  }

  final List<String> jvmArguments = _expand(
    manifest.jvmArguments,
    ctx,
    variables,
  );
  if (jvmArguments.isEmpty) {
    jvmArguments.addAll(<String>[
      '-Djava.library.path=$nativesDir',
      '-cp',
      classpathString,
    ]);
  } else if (!_hasClasspathFlag(jvmArguments)) {
    jvmArguments.addAll(<String>['-cp', classpathString]);
  }

  if (config.minMemoryMb != null) {
    jvmArguments.add('-Xms${config.minMemoryMb}M');
  }
  if (config.maxMemoryMb != null) {
    jvmArguments.add('-Xmx${config.maxMemoryMb}M');
  }
  final String custom = config.jvmArgs.trim();
  if (custom.isNotEmpty) {
    jvmArguments.addAll(custom.split(RegExp(r'\s+')));
  }

  return LaunchPlan(
    executable: java.path,
    arguments: <String>[...jvmArguments, mainClass, ...gameArguments],
    workingDirectory: versionDir,
  );
}

Future<void> _extractNatives(
  VersionManifest manifest,
  LaunchContext context,
  String librariesDir,
  String nativesDir,
) async {
  Directory? directory;
  for (final Library library in manifest.libraries) {
    if (!library.allows(context)) continue;
    final String? classifier = library.nativesClassifier(context);
    if (classifier == null) continue;
    final Download? download = library.classifiers[classifier];
    if (download == null) continue;

    final File jar = File(joinPath(librariesDir, download.path));
    if (!await jar.exists()) {
      throw LaunchException('launch.error.missingLibrary', <String, Object>{
        'path': jar.path,
      });
    }

    directory ??= Directory(nativesDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    try {
      final Archive archive = ZipDecoder().decodeBytes(await jar.readAsBytes());
      for (final ArchiveFile file in archive) {
        if (!file.isFile) continue;
        final String name = file.name.replaceAll('\\', '/');
        if (name.startsWith('META-INF/') || name.contains('..')) continue;
        final File out = File(joinPath(nativesDir, name));
        await out.parent.create(recursive: true);
        await out.writeAsBytes(file.content);
      }
    } catch (error) {
      throw LaunchException('launch.error.natives', <String, Object>{
        'error': '$error',
      });
    }
  }
}

List<String> _expand(
  List<Argument> arguments,
  LaunchContext context,
  Map<String, String> variables,
) {
  final List<String> out = <String>[];
  for (final Argument argument in arguments) {
    if (!argument.applies(context)) continue;
    out.addAll(_substituteAll(argument.values, variables));
  }
  return out;
}

List<String> _substituteAll(
  List<String> values,
  Map<String, String> variables,
) {
  final RegExp pattern = RegExp(r'\$\{([a-zA-Z0-9_]+)\}');
  return values
      .map(
        (String value) => value.replaceAllMapped(
          pattern,
          (Match match) => variables[match.group(1)] ?? match.group(0)!,
        ),
      )
      .toList();
}

bool _hasClasspathFlag(List<String> args) {
  return args.contains('-cp') || args.contains('-classpath');
}
