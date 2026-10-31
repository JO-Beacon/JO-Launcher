#pragma once

#include <filesystem>
#include <string>

namespace jol {

/// Per-version settings stored in `<version dir>/jolauncher.json`.
struct VersionConfig {
    std::string java_path;
    int min_memory_mb = 0;
    int max_memory_mb = 0;
    std::string jvm_args;
};

VersionConfig readVersionConfig(const std::filesystem::path& version_dir);

/// Writes the four managed fields and preserves unknown fields already in the
/// file, matching the launcher's existing configuration format.
void writeVersionConfig(const std::filesystem::path& version_dir,
                        const VersionConfig& config);

}  // namespace jol
