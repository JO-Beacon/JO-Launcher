#include "platform/process.hpp"

#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <cerrno>
#include <chrono>
#include <cstring>
#include <atomic>
#include <mutex>
#include <thread>
#include <vector>

namespace jol::platform {

struct ChildProcess::Impl {
    pid_t pid = -1;
    int read_fd = -1;
    std::thread reader;
    std::mutex mutex;
    std::string output;
    std::atomic<bool> eof{false};
    std::atomic<bool> stop{false};
    bool reaped = false;
    int exit_code = -1;

    ~Impl() {
        // Leave a running child alone: closing the launcher must not stop the
        // game. The reader polls with a timeout, so it notices `stop` and can
        // be joined before the descriptor is closed.
        stop.store(true);
        if (reader.joinable()) reader.join();
        if (read_fd >= 0) {
            ::close(read_fd);
            read_fd = -1;
        }
        if (pid > 0 && !reaped) {
            ::waitpid(pid, nullptr, WNOHANG);
        }
    }
};

ChildProcess::ChildProcess() = default;
ChildProcess::~ChildProcess() = default;
ChildProcess::ChildProcess(ChildProcess&&) noexcept = default;
ChildProcess& ChildProcess::operator=(ChildProcess&&) noexcept = default;
ChildProcess::ChildProcess(std::unique_ptr<Impl> impl) : impl_(std::move(impl)) {}

bool ChildProcess::valid() const {
    return impl_ != nullptr && impl_->pid > 0;
}

bool ChildProcess::running() const {
    if (!valid() || impl_->reaped) return false;
    int status = 0;
    const pid_t result = ::waitpid(impl_->pid, &status, WNOHANG);
    if (result == 0) return true;
    if (result == impl_->pid) {
        impl_->reaped = true;
        impl_->exit_code = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
    }
    return false;
}

int ChildProcess::pid() const {
    return impl_ == nullptr ? 0 : static_cast<int>(impl_->pid);
}

void ChildProcess::stop() {
    if (valid() && !impl_->reaped) {
        if (::kill(-impl_->pid, SIGTERM) != 0) {
            ::kill(impl_->pid, SIGTERM);
        }
    }
}

int ChildProcess::wait(std::uint32_t timeout_ms) {
    if (!valid()) return -1;
    if (impl_->reaped) return impl_->exit_code;
    const auto deadline = std::chrono::steady_clock::now() +
                          std::chrono::milliseconds(timeout_ms);
    for (;;) {
        int status = 0;
        const pid_t result = ::waitpid(impl_->pid, &status, WNOHANG);
        if (result == impl_->pid) {
            impl_->reaped = true;
            impl_->exit_code = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
            return impl_->exit_code;
        }
        if (result < 0 && errno != EINTR) return -1;
        if (std::chrono::steady_clock::now() >= deadline) return -1;
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
}

bool ChildProcess::output_closed() const {
    return impl_ == nullptr || impl_->eof.load();
}

std::string ChildProcess::take_output_after_exit(std::uint32_t timeout_ms) {
    for (std::uint32_t waited = 0;
         impl_ != nullptr && !impl_->eof.load() && waited < timeout_ms;
         waited += 5) {
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    return take_output();
}

std::string ChildProcess::take_output() {
    if (impl_ == nullptr) return {};
    std::lock_guard<std::mutex> lock(impl_->mutex);
    std::string result = std::move(impl_->output);
    impl_->output.clear();
    return result;
}

std::optional<ChildProcess> spawn_process(const ProcessSpawn& request,
                                          std::string& error) {
    int pipes[2] = {-1, -1};
    if (::pipe(pipes) != 0) {
        error = "Could not create the output pipe.";
        return std::nullopt;
    }

    std::vector<std::string> argv_storage;
    argv_storage.push_back(request.executable.string());
    for (const auto& argument : request.arguments) {
        argv_storage.push_back(argument);
    }
    std::vector<char*> argv;
    argv.reserve(argv_storage.size() + 1);
    for (auto& item : argv_storage) argv.push_back(item.data());
    argv.push_back(nullptr);

    const pid_t pid = ::fork();
    if (pid < 0) {
        ::close(pipes[0]);
        ::close(pipes[1]);
        error = "Could not fork the game process.";
        return std::nullopt;
    }
    if (pid == 0) {
        // Own process group so the launcher can stop the game and its
        // children together.
        ::setpgid(0, 0);
        ::dup2(pipes[1], STDOUT_FILENO);
        ::dup2(pipes[1], STDERR_FILENO);
        ::close(pipes[0]);
        ::close(pipes[1]);
        if (!request.working_directory.empty()) {
            ::chdir(request.working_directory.c_str());
        }
        ::execv(request.executable.c_str(), argv.data());
        _exit(127);
    }

    ::close(pipes[1]);
    auto impl = std::unique_ptr<ChildProcess::Impl>(new ChildProcess::Impl());
    impl->pid = pid;
    impl->read_fd = pipes[0];

    ChildProcess child(std::move(impl));
    auto* state = child.impl_.get();
    state->reader = std::thread([state] {
        char buffer[4096];
        while (!state->stop.load()) {
            pollfd descriptor{state->read_fd, POLLIN, 0};
            const int ready = ::poll(&descriptor, 1, 100);
            if (ready < 0) {
                if (errno == EINTR) continue;
                break;
            }
            if (ready == 0) continue;
            const ssize_t read = ::read(state->read_fd, buffer, sizeof(buffer));
            if (read <= 0) break;
            std::lock_guard<std::mutex> lock(state->mutex);
            state->output.append(buffer, static_cast<std::size_t>(read));
            if (state->output.size() > 1024 * 1024) {
                state->output.erase(0, state->output.size() - 1024 * 1024);
            }
        }
        state->eof.store(true);
    });
    return child;
}

}  // namespace jol::platform
