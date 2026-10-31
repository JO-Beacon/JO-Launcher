#pragma once

#include <cstdint>
#include <filesystem>
#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace jol::platform {

struct ProcessSpawn {
    std::filesystem::path executable;
    /// UTF-8 arguments, unquoted.
    std::vector<std::string> arguments;
    std::filesystem::path working_directory;
};

/// Child process with captured stdout/stderr.
class ChildProcess {
public:
    ChildProcess();
    ~ChildProcess();
    ChildProcess(ChildProcess&&) noexcept;
    ChildProcess& operator=(ChildProcess&&) noexcept;
    ChildProcess(const ChildProcess&) = delete;
    ChildProcess& operator=(const ChildProcess&) = delete;

    bool valid() const;
    bool running() const;
    int pid() const;

    /// Terminates the child.
    void stop();

    /// Waits up to `timeout_ms` and returns the exit code, or -1.
    int wait(std::uint32_t timeout_ms = 0xFFFFFFFFu);

    /// True once the output pipe reached end-of-file.
    bool output_closed() const;

    /// Returns stdout/stderr collected since the previous call.
    std::string take_output();

    /// Waits briefly for the reader to finish, then returns the remaining
    /// output. Used after the child exited so the last lines are not lost.
    std::string take_output_after_exit(std::uint32_t timeout_ms = 500);

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;

    explicit ChildProcess(std::unique_ptr<Impl> impl);
    friend std::optional<ChildProcess> spawn_process(const ProcessSpawn&,
                                                     std::string& error);
};

/// Starts a child process. On failure returns nullopt and fills `error`.
std::optional<ChildProcess> spawn_process(const ProcessSpawn& request,
                                          std::string& error);

}  // namespace jol::platform
