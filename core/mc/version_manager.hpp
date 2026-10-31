#pragma once

#include <filesystem>
#include <string>

namespace jol {

/// Renames a version folder, renames its manifest and updates the manifest id.
void renameVersion(const std::filesystem::path& game_dir,
                   const std::string& old_name,
                   const std::string& new_name);

/// Deletes a version folder recursively.
void deleteVersion(const std::filesystem::path& game_dir,
                   const std::string& name);

/// Imports a version folder into `<game dir>/versions/<name>`.
void importVersionFolder(const std::filesystem::path& game_dir,
                         const std::filesystem::path& source_dir,
                         const std::string& name);

/// Imports a version folder from a local zip archive. The archive may contain
/// the version folder at its root, under `versions/<name>/`, or as the only
/// version subfolder.
std::string importVersionZip(const std::filesystem::path& game_dir,
                             const std::filesystem::path& zip_path);

}  // namespace jol
