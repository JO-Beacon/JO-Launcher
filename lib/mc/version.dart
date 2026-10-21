// A version = `versions/<folder>/` plus the version manifest inside it
// (`<name>.json`).
//
// A version is one game directory: jar, manifest, saves, mods and config all
// live there. Java, memory and JVM arguments are stored in `jolauncher.json`
// in the same directory (see `version_config.dart`).
//
// Manifests are produced by other launchers or Mojang. Missing fields and
// wrong types are treated as absent; one bad field must not discard the whole
// version.

import 'version_config.dart';

/// Version loader. `labelKey` is the localization-table key; loader names
/// themselves are not translated.
enum McLoader {
  vanilla('loader.vanilla'),
  fabric('loader.fabric'),
  quilt('loader.quilt'),
  forge('loader.forge'),
  neoforge('loader.neoforge');

  const McLoader(this.labelKey);

  final String labelKey;
}

/// One version.
class McVersion {
  const McVersion({
    required this.name,
    required this.gameVersion,
    required this.loader,
    required this.dir,
    this.loaderVersion,
    this.releaseTime,
    this.config = const VersionConfig(),
  });

  /// Folder name. This is what `--version` receives at launch.
  final String name;

  /// Game version, e.g. `1.21.1`. Snapshots keep the manifest id (`24w14a`).
  final String gameVersion;

  final McLoader loader;

  /// Loader version, e.g. `21.1.259`; null when it cannot be detected.
  final String? loaderVersion;

  /// Absolute path to the version folder.
  final String dir;

  /// `releaseTime` from the manifest. Null when unreadable; sorts last.
  final DateTime? releaseTime;

  /// This version's settings (`jolauncher.json`).
  final VersionConfig config;

  /// Parses a version manifest. [name] is the folder name; [dir] is its
  /// absolute path.
  factory McVersion.fromManifest(
    Map<String, Object?> json, {
    required String name,
    required String dir,
    VersionConfig config = const VersionConfig(),
  }) {
    final List<String> libs = _libraryNames(json['libraries']);
    final List<String> args = _gameArguments(json);
    final String? mainClass = _string(json['mainClass']);
    final String id = _string(json['id']) ?? name;

    final String? fabricVersion = _artifactVersion(
      libs,
      'net.fabricmc',
      'fabric-loader',
    );
    final String? quiltVersion = _artifactVersion(
      libs,
      'org.quiltmc',
      'quilt-loader',
    );
    final String? fmlNeo = _argValue(args, '--fml.neoForgeVersion');
    final String? fmlForge = _argValue(args, '--fml.forgeVersion');
    final String? neoArtifact = _artifactVersion(
      libs,
      'net.neoforged',
      'neoforge',
    );
    final String? neoFmlLoader = _artifactVersion(
      libs,
      'net.neoforged.fancymodloader',
      'loader',
    );
    final String? forgeArtifact = _artifactVersion(
      libs,
      'net.minecraftforge',
      'forge',
    );
    final String? forgeFmlLoader = _artifactVersion(
      libs,
      'net.minecraftforge',
      'fmlloader',
    );

    late final McLoader loader;
    String? loaderVersion;
    if (fabricVersion != null) {
      loader = McLoader.fabric;
      loaderVersion = fabricVersion;
    } else if (quiltVersion != null) {
      loader = McLoader.quilt;
      loaderVersion = quiltVersion;
    } else if (fmlNeo != null ||
        neoArtifact != null ||
        neoFmlLoader != null ||
        (mainClass?.startsWith('net.neoforged.') ?? false)) {
      loader = McLoader.neoforge;
      loaderVersion = fmlNeo ?? neoArtifact ?? neoFmlLoader;
    } else if (fmlForge != null ||
        forgeArtifact != null ||
        forgeFmlLoader != null ||
        (mainClass?.startsWith('net.minecraftforge.') ?? false) ||
        // Forge 1.17+ and NeoForge share this launcher class; NeoForge was
        // already recognized above by its own libraries and arguments, so
        // reaching here means Forge.
        mainClass == 'cpw.mods.bootstraplauncher.BootstrapLauncher') {
      loader = McLoader.forge;
      loaderVersion = fmlForge ?? forgeArtifact ?? forgeFmlLoader;
    } else {
      loader = _loaderFromName(id);
      if (loader == McLoader.vanilla) loaderVersion = null;
    }

    // Game version: trust the manifest first, then infer from the name.
    final String? inherited = _string(json['inheritsFrom']);
    final String? fmlMcVersion = _argValue(args, '--fml.mcVersion');
    final String gameVersion =
        inherited ??
        fmlMcVersion ??
        _versionFromName(id, loader, loaderVersion) ??
        id;

    return McVersion(
      name: name,
      gameVersion: gameVersion,
      loader: loader,
      loaderVersion: loaderVersion,
      dir: dir,
      releaseTime: DateTime.tryParse(_string(json['releaseTime']) ?? ''),
      config: config,
    );
  }

  /// Names in `libraries` (`group:artifact:version[:classifier]`).
  static List<String> _libraryNames(Object? raw) {
    if (raw is! List) return const <String>[];
    final List<String> out = <String>[];
    for (final Object? item in raw) {
      if (item is Map) {
        final String? name = _string(item['name']);
        if (name != null) out.add(name);
      }
    }
    return out;
  }

  /// Entries in the game arguments. 1.13+ uses `arguments.game`; 1.12 and
  /// earlier use one `minecraftArguments` string.
  static List<String> _gameArguments(Map<String, Object?> json) {
    final List<String> out = <String>[];
    final Object? args = json['arguments'];
    if (args is Map) {
      final Object? game = args['game'];
      if (game is List) {
        for (final Object? item in game) {
          if (item is String) out.add(item);
        }
      }
    }
    final String? legacy = _string(json['minecraftArguments']);
    if (legacy != null) out.addAll(legacy.split(' '));
    return out;
  }

  /// Library version: `net.fabricmc:fabric-loader:0.16.9` → `0.16.9`.
  static String? _artifactVersion(
    List<String> libs,
    String group,
    String artifact,
  ) {
    for (final String lib in libs) {
      final List<String> parts = lib.split(':');
      if (parts.length >= 3 && parts[0] == group && parts[1] == artifact) {
        return parts[2];
      }
    }
    return null;
  }

  /// Value following `--flag` in the argument list.
  static String? _argValue(List<String> args, String flag) {
    final int i = args.indexOf(flag);
    if (i < 0 || i + 1 >= args.length) return null;
    final String value = args[i + 1];
    if (value.isEmpty || value.startsWith('--')) return null;
    return value;
  }

  /// Loader is not in the manifest but is present in the name (common for
  /// old Forge).
  static McLoader _loaderFromName(String name) {
    final String lower = name.toLowerCase();
    if (lower.contains('neoforge')) return McLoader.neoforge;
    if (lower.contains('forge')) return McLoader.forge;
    if (lower.contains('fabric')) return McLoader.fabric;
    if (lower.contains('quilt')) return McLoader.quilt;
    return McLoader.vanilla;
  }

  /// Infers the game version from the version id.
  ///
  /// `1.21.1-NeoForge_21.1.259` → `1.21.1`;
  /// `fabric-loader-0.16.9-1.21.1` → `1.21.1` (Fabric/Quilt put the loader
  /// version first, so take the last one; other loaders use the first).
  static String? _versionFromName(
    String id,
    McLoader loader,
    String? loaderVersion,
  ) {
    final List<String> versions = <String>[];
    for (final String part in id.split(RegExp(r'[-_+ ]'))) {
      if (part == loaderVersion) continue;
      if (RegExp(r'^\d+\.\d+(?:\.\d+)?$').hasMatch(part)) versions.add(part);
    }
    if (versions.isEmpty) return null;
    final bool loaderFirst =
        loader == McLoader.fabric || loader == McLoader.quilt;
    return loaderFirst ? versions.last : versions.first;
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
