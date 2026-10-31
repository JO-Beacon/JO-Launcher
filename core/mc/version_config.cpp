#include "json_io.hpp"
#include "platform/paths.hpp"
#include "version_config.hpp"

#include <fstream>
#include <stdexcept>
#include <system_error>

#include <nlohmann/json.hpp>

namespace jol {
namespace {

using json = nlohmann::json;

std::string trim(std::string value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) return {};
    const auto last = value.find_last_not_of(" \t\r\n");
    return value.substr(first, last - first + 1);
}

int memory_value(const json& root, const char* key) {
    const auto it = root.find(key);
    if (it == root.end() || !it->is_number_integer()) return 0;
    const int value = it->get<int>();
    return value > 0 ? value : 0;
}

std::string joined_jvm_args(const json& root) {
    const auto it = root.find("jvmArgs");
    if (it == root.end()) return {};
    if (it->is_string()) return trim(it->get<std::string>());
    if (it->is_array()) {
        std::string result;
        for (const auto& part : *it) {
            if (!part.is_string()) continue;
            if (!result.empty()) result += ' ';
            result += part.get<std::string>();
        }
        return trim(result);
    }
    return {};
}

}  // namespace

VersionConfig readVersionConfig(const std::filesystem::path& version_dir) {
    VersionConfig config;
    if (platform::is_reparse_point(version_dir)) return config;
    const auto file = version_dir / L"jolauncher.json";
    std::error_code file_ec;
    if (!std::filesystem::is_regular_file(file, file_ec)) return config;

    try {
        json root = jsonio::read(file, 1024 * 1024);
        if (!root.is_object()) return config;

        const auto java = root.find("javaPath");
        if (java != root.end() && java->is_string()) {
            config.java_path = trim(java->get<std::string>());
        }
        config.min_memory_mb = memory_value(root, "minMemoryMb");
        config.max_memory_mb = memory_value(root, "maxMemoryMb");
        config.jvm_args = joined_jvm_args(root);
    } catch (...) {
        // A broken config must not block the version from being listed.
    }
    return config;
}

void writeVersionConfig(const std::filesystem::path& version_dir,
                        const VersionConfig& config) {
    if (platform::is_reparse_point(version_dir)) {
        throw std::runtime_error("Version directory is a link.");
    }
    json root = json::object();
    const auto file = version_dir / L"jolauncher.json";
    try {
        std::ifstream stream(file);
        if (stream) {
            json existing;
            stream >> existing;
            if (existing.is_object()) root = std::move(existing);
        }
    } catch (...) {
        // Keep the object if the old file was broken.
    }

    root["schema"] = 1;
    if (config.java_path.empty()) {
        root["javaPath"] = nullptr;
    } else {
        root["javaPath"] = config.java_path;
    }
    if (config.min_memory_mb > 0) {
        root["minMemoryMb"] = config.min_memory_mb;
    } else {
        root["minMemoryMb"] = nullptr;
    }
    if (config.max_memory_mb > 0) {
        root["maxMemoryMb"] = config.max_memory_mb;
    } else {
        root["maxMemoryMb"] = nullptr;
    }
    root["jvmArgs"] = config.jvm_args;

    const auto temp = version_dir / L"jolauncher.json.tmp";
    {
        std::ofstream out(temp, std::ios::binary | std::ios::trunc);
        if (!out) {
            throw std::runtime_error("Could not open settings file for writing.");
        }
        out << root.dump(2, ' ', false, nlohmann::json::error_handler_t::replace) << '\n';
        if (!out) {
            throw std::runtime_error("Could not write settings file.");
        }
    }

    std::error_code ec;
    if (!platform::atomic_replace(temp, file)) {
        std::filesystem::remove(temp, ec);
        throw std::runtime_error("Could not replace settings file.");
    }
    if (ec) {
        throw std::runtime_error("Could not replace settings file.");
    }
}

}  // namespace jol
