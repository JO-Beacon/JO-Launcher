#include "log.hpp"

#include <chrono>
#include <ctime>
#include <fstream>
#include <mutex>
#include <system_error>

namespace jol::log {
namespace {

constexpr std::uintmax_t kMaxBytes = 2ull * 1024 * 1024;

struct State {
    std::mutex mutex;
    std::ofstream stream;
    std::filesystem::path path;
    std::uintmax_t size = 0;
    bool ready = false;
};

State& state() {
    static State instance;
    return instance;
}

const char* level_name(Level level) {
    switch (level) {
        case Level::debug: return "DEBUG";
        case Level::info: return "INFO";
        case Level::warn: return "WARN";
        case Level::error: return "ERROR";
    }
    return "INFO";
}

std::string timestamp() {
    const auto now = std::chrono::system_clock::now();
    const std::time_t time = std::chrono::system_clock::to_time_t(now);
    std::tm local{};
#if defined(_WIN32)
    localtime_s(&local, &time);
#else
    localtime_r(&time, &local);
#endif
    char buffer[32]{};
    std::strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", &local);
    return buffer;
}

void rotate_locked(State& s) {
    if (s.stream.is_open()) s.stream.close();
    std::error_code ec;
    const auto previous =
        s.path.parent_path() /
        (s.path.stem().wstring() + L".1" + s.path.extension().wstring());
    std::filesystem::remove(previous, ec);
    std::filesystem::rename(s.path, previous, ec);
    s.stream.open(s.path, std::ios::binary | std::ios::trunc);
    s.size = 0;
}

}  // namespace

void init(const std::filesystem::path& directory) {
    std::lock_guard<std::mutex> lock(state().mutex);
    State& s = state();
    if (s.ready) return;

    std::error_code ec;
    std::filesystem::create_directories(directory, ec);
    if (ec) return;

    s.path = directory / "launcher.log";
    s.stream.open(s.path, std::ios::binary | std::ios::app);
    if (!s.stream) return;

    s.size = std::filesystem::file_size(s.path, ec);
    if (ec) s.size = 0;
    s.ready = true;

    s.stream << timestamp() << " INFO  launcher: log opened ("
             << s.path.string() << ")\n";
    s.stream.flush();
}

void shutdown() {
    std::lock_guard<std::mutex> lock(state().mutex);
    State& s = state();
    if (s.stream.is_open()) {
        s.stream << timestamp() << " INFO  launcher: log closed\n";
        s.stream.flush();
        s.stream.close();
    }
    s.ready = false;
}

void write(Level level, std::string_view module,
           std::string_view message) noexcept {
    try {
    std::lock_guard<std::mutex> lock(state().mutex);
    State& s = state();
    if (!s.ready) return;

    const std::string line = timestamp() + " " + level_name(level) + " " +
                             std::string(module) + ": " + std::string(message) +
                             "\n";
    if (s.size + line.size() > kMaxBytes) {
        rotate_locked(s);
        if (!s.stream) {
            s.ready = false;
            return;
        }
    }
    s.stream << line;
    s.stream.flush();
    s.size += line.size();
    } catch (...) {
        state().ready = false;
    }
}

std::filesystem::path file() {
    std::lock_guard<std::mutex> lock(state().mutex);
    return state().path;
}

}  // namespace jol::log
