#pragma once

#include <atomic>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include "auth/auth.hpp"

namespace jol::launch {

struct LaunchRequest {
    std::filesystem::path game_dir;
    std::string version_name;
    jol::auth::Account account;
    std::filesystem::path java_path;
    std::int64_t min_memory_mb = 0;
    std::int64_t max_memory_mb = 0;
    std::string jvm_args;
    std::string client_id;
};

struct JavaRuntime {
    std::filesystem::path path;
    int major = 0;
    std::string version;
};

/// Thrown when no Java runtime that satisfies a version can be found, or when
/// the configured one is missing or too old.
class JavaError : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

std::optional<int> required_java_major(const std::filesystem::path& game_dir,
                                       const std::string& version_name);
std::vector<JavaRuntime> detect_java_runtimes(
    const std::atomic_bool* cancelled = nullptr);


/// Reads `java -version` for a single executable. Returns nullopt when the
/// file is not a usable Java runtime.
std::optional<JavaRuntime> inspect_java(
    const std::filesystem::path& executable);

/// Builds the command line, extracts natives and starts the game.
/// Throws std::runtime_error with a readable reason on failure.
class GameProcess {
public:
    GameProcess();
    ~GameProcess();

    GameProcess(const GameProcess&) = delete;
    GameProcess& operator=(const GameProcess&) = delete;
    GameProcess(GameProcess&& other) noexcept;
    GameProcess& operator=(GameProcess&& other) noexcept;

    bool valid() const;
    bool running() const;
    int pid() const;

    void stop();
    int wait();

    /// Returns stdout/stderr collected since the previous call.
    std::string take_output();

    /// Waits briefly for the reader, then returns the remaining output.
    std::string take_output_after_exit(std::uint32_t timeout_ms = 500);

private:
    struct Impl;
    explicit GameProcess(std::unique_ptr<Impl> impl);
    std::unique_ptr<Impl> impl_;

    friend GameProcess start(const LaunchRequest& request);
};

GameProcess start(const LaunchRequest& request);

}  // namespace jol::launch
