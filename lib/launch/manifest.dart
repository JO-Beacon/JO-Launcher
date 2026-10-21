// Version manifest: inheritance chain, rules, libraries and arguments.
//
// Only the parts needed for launching are parsed: mainClass, libraries,
// arguments, assetIndex and javaVersion. Download URLs are parsed too, ready
// for the downloader when it is connected.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import '../mc/paths.dart';
import '../mc/version_json.dart';
import 'launch_error.dart';

/// Current system environment, used to evaluate rules.
class LaunchContext {
  const LaunchContext({
    required this.osName,
    required this.osArch,
    Map<String, bool>? features,
  }) : features = features ?? const <String, bool>{};

  /// `windows` / `linux` / `osx`。
  final String osName;

  /// `x86` / `x86_64` / `arm64`。
  final String osArch;

  /// Manifest features (demo mode, custom resolution, etc.). All false by default.
  final Map<String, bool> features;

  factory LaunchContext.host({Map<String, bool>? features}) {
    final String os = Platform.isWindows
        ? 'windows'
        : (Platform.isMacOS ? 'osx' : 'linux');
    return LaunchContext(osName: os, osArch: _hostArch(), features: features);
  }

  static String _hostArch() {
    final Abi abi = Abi.current();
    if (abi == Abi.windowsIA32 || abi == Abi.linuxIA32) return 'x86';
    if (abi == Abi.windowsArm64 ||
        abi == Abi.linuxArm64 ||
        abi == Abi.macosArm64) {
      return 'arm64';
    }
    return 'x86_64';
  }
}

/// One allow / disallow rule.
class Rule {
  const Rule({
    this.action = 'allow',
    this.osName,
    this.osArch,
    this.features = const <String, bool>{},
  });

  final String action;
  final String? osName;
  final String? osArch;
  final Map<String, bool> features;

  bool get isAllow => action == 'allow';

  bool applies(LaunchContext context) {
    if (osName != null && osName != context.osName) return false;
    if (osArch != null && osArch != context.osArch) return false;
    for (final MapEntry<String, bool> e in features.entries) {
      if ((context.features[e.key] ?? false) != e.value) return false;
    }
    return true;
  }
}

/// “Allow first, then override” semantics for a rule list.
bool rulesAllow(List<Rule> rules, LaunchContext context) {
  if (rules.isEmpty) return true;
  bool allow = false;
  for (final Rule rule in rules) {
    if (rule.applies(context)) allow = rule.isAllow;
  }
  return allow;
}

/// One item in the argument table: value + rules that control it.
class Argument {
  const Argument(this.values, {this.rules = const <Rule>[]});

  final List<String> values;
  final List<Rule> rules;

  bool applies(LaunchContext context) => rulesAllow(rules, context);
}

/// A library file to be downloaded.
class Download {
  const Download({required this.path, this.url, this.sha1, this.size});

  /// Path relative to `libraries/`.
  final String path;
  final String? url;
  final String? sha1;
  final int? size;
}

/// A library.
class Library {
  const Library({
    required this.name,
    this.rules = const <Rule>[],
    this.artifact,
    this.classifiers = const <String, Download>{},
    this.natives = const <String, String>{},
  });

  /// `group:artifact:version[:classifier]`。
  final String name;
  final List<Rule> rules;
  final Download? artifact;

  /// Classifier -> file (legacy natives).
  final Map<String, Download> classifiers;

  /// System name -> classifier (`windows` -> `natives-windows`).
  final Map<String, String> natives;

  bool allows(LaunchContext context) => rulesAllow(rules, context);

  /// Natives classifier to extract for this system.
  String? nativesClassifier(LaunchContext context) {
    final String? raw = natives[context.osName];
    if (raw == null) return null;
    return raw.replaceAll(r'${arch}', context.osArch == 'x86' ? '32' : '64');
  }
}

/// Decoded version manifest.
class VersionManifest {
  const VersionManifest({
    required this.id,
    this.inheritsFrom,
    this.mainClass,
    this.minecraftArguments,
    this.gameArguments = const <Argument>[],
    this.jvmArguments = const <Argument>[],
    this.libraries = const <Library>[],
    this.assetIndex,
    this.assets,
    this.jar,
    this.clientJarId,
    this.javaMajor,
    this.type,
  });

  final String id;
  final String? inheritsFrom;
  final String? mainClass;

  /// Legacy single argument string for 1.12 and earlier.
  final String? minecraftArguments;

  final List<Argument> gameArguments;
  final List<Argument> jvmArguments;
  final List<Library> libraries;

  /// Asset index id (usually something like `17`). Falls back to [assets]
  /// when `assetIndex` is absent.
  final String? assetIndex;
  final String? assets;

  /// Client jar name (defaults to the version name).
  final String? jar;

  /// Version id that actually provides the client jar.
  ///
  /// Child manifests such as Fabric / Forge have no jar of their own, so they
  /// inherit the parent version's jar.
  final String? clientJarId;

  /// Required Java major version.
  final int? javaMajor;

  final String? type;

  factory VersionManifest.fromJson(Map<String, Object?> json) {
    final Object? arguments = json['arguments'];
    List<Argument> game = const <Argument>[];
    List<Argument> jvm = const <Argument>[];
    if (arguments is Map) {
      game = _parseArguments(arguments['game']);
      jvm = _parseArguments(arguments['jvm']);
    }

    final Object? assetIndex = json['assetIndex'];
    final String? indexId = assetIndex is Map
        ? _string(assetIndex['id'])
        : _string(json['assets']);

    final Object? javaVersion = json['javaVersion'];
    final Object? major = javaVersion is Map
        ? javaVersion['majorVersion']
        : null;

    final String id = _string(json['id']) ?? '';
    final String? jar = _string(json['jar']);
    return VersionManifest(
      id: id,
      inheritsFrom: _string(json['inheritsFrom']),
      mainClass: _string(json['mainClass']),
      minecraftArguments: _string(json['minecraftArguments']),
      gameArguments: game,
      jvmArguments: jvm,
      libraries: _parseLibraries(json['libraries']),
      assetIndex: indexId,
      assets: _string(json['assets']),
      jar: jar,
      clientJarId: jar ?? id,
      javaMajor: major is num ? major.toInt() : null,
      type: _string(json['type']),
    );
  }

  /// Child manifests override the parent; libraries and arguments are
  /// concatenated parent-first, child-last.
  static VersionManifest merge(VersionManifest parent, VersionManifest child) {
    return VersionManifest(
      id: child.id,
      mainClass: child.mainClass ?? parent.mainClass,
      minecraftArguments: child.minecraftArguments ?? parent.minecraftArguments,
      gameArguments: <Argument>[
        ...parent.gameArguments,
        ...child.gameArguments,
      ],
      jvmArguments: <Argument>[...parent.jvmArguments, ...child.jvmArguments],
      libraries: <Library>[...parent.libraries, ...child.libraries],
      assetIndex: child.assetIndex ?? parent.assetIndex,
      assets: child.assets ?? parent.assets,
      jar: child.jar ?? parent.jar,
      clientJarId: child.jar ?? parent.clientJarId,
      javaMajor: child.javaMajor ?? parent.javaMajor,
      type: child.type ?? parent.type,
    );
  }
}

/// Parses a version manifest from disk, merging along `inheritsFrom` when needed.
Future<VersionManifest> resolveManifest(
  String gameDir,
  String versionName, {
  Set<String>? seen,
}) async {
  final Set<String> visited = seen ?? <String>{};
  if (!visited.add(versionName)) {
    throw LaunchException('launch.error.inheritCycle', <String, Object>{
      'name': versionName,
    });
  }

  final Directory folder = Directory(
    joinPath(joinPath(gameDir, 'versions'), versionName),
  );
  final File? file = await findVersionJson(folder, versionName);
  if (file == null) {
    throw LaunchException('launch.error.manifestMissing', <String, Object>{
      'name': versionName,
    });
  }

  try {
    final Object? raw = jsonDecode(await file.readAsString());
    if (raw is! Map<String, Object?>) {
      throw LaunchException('launch.error.manifestRead', <String, Object>{
        'name': versionName,
        'error': 'not a JSON object',
      });
    }
    final VersionManifest child = VersionManifest.fromJson(raw);
    final String? parentName = child.inheritsFrom;
    if (parentName == null || parentName.isEmpty) return child;
    final VersionManifest parent = await resolveManifest(
      gameDir,
      parentName,
      seen: visited,
    );
    return VersionManifest.merge(parent, child);
  } on LaunchException {
    rethrow;
  } catch (error) {
    throw LaunchException('launch.error.manifestRead', <String, Object>{
      'name': versionName,
      'error': '$error',
    });
  }
}

List<Argument> _parseArguments(Object? raw) {
  if (raw is! List) return const <Argument>[];
  final List<Argument> out = <Argument>[];
  for (final Object? item in raw) {
    if (item is String) {
      out.add(Argument(<String>[item]));
    } else if (item is Map) {
      final Object? value = item['value'];
      final List<String> values = value is String
          ? <String>[value]
          : value is List
          ? value.whereType<String>().toList()
          : const <String>[];
      if (values.isEmpty) continue;
      out.add(Argument(values, rules: _parseRules(item['rules'])));
    }
  }
  return out;
}

List<Rule> _parseRules(Object? raw) {
  if (raw is! List) return const <Rule>[];
  final List<Rule> out = <Rule>[];
  for (final Object? item in raw) {
    if (item is! Map) continue;
    final Object? os = item['os'];
    String? osName;
    String? osArch;
    if (os is Map) {
      osName = _string(os['name']);
      osArch = _string(os['arch']);
    }
    final Map<String, bool> features = <String, bool>{};
    final Object? rawFeatures = item['features'];
    if (rawFeatures is Map) {
      rawFeatures.forEach((Object? key, Object? value) {
        if (key is String && value is bool) features[key] = value;
      });
    }
    out.add(
      Rule(
        action: _string(item['action']) ?? 'allow',
        osName: osName,
        osArch: osArch,
        features: features,
      ),
    );
  }
  return out;
}

List<Library> _parseLibraries(Object? raw) {
  if (raw is! List) return const <Library>[];
  final List<Library> out = <Library>[];
  for (final Object? item in raw) {
    if (item is! Map) continue;
    final String? name = _string(item['name']);
    if (name == null) continue;

    final Object? downloads = item['downloads'];
    Download? artifact;
    final Map<String, Download> classifiers = <String, Download>{};
    if (downloads is Map) {
      artifact = _download(downloads['artifact']);
      final Object? rawClassifiers = downloads['classifiers'];
      if (rawClassifiers is Map) {
        rawClassifiers.forEach((Object? key, Object? value) {
          if (key is String) {
            final Download? download = _download(value);
            if (download != null) classifiers[key] = download;
          }
        });
      }
    }

    final Map<String, String> natives = <String, String>{};
    final Object? rawNatives = item['natives'];
    if (rawNatives is Map) {
      rawNatives.forEach((Object? key, Object? value) {
        if (key is String && value is String) natives[key] = value;
      });
    }

    out.add(
      Library(
        name: name,
        rules: _parseRules(item['rules']),
        artifact: artifact,
        classifiers: classifiers,
        natives: natives,
      ),
    );
  }
  return out;
}

Download? _download(Object? raw) {
  if (raw is! Map) return null;
  final String? path = _string(raw['path']);
  if (path == null) return null;
  final Object? size = raw['size'];
  return Download(
    path: path,
    url: _string(raw['url']),
    sha1: _string(raw['sha1']),
    size: size is num ? size.toInt() : null,
  );
}

String? _string(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
