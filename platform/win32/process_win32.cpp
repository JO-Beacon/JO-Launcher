#include "platform/process.hpp"

#include <windows.h>

#include <atomic>
#include <chrono>
#include <mutex>
#include <thread>

namespace jol::platform {
namespace {

std::wstring to_wide(const std::string& text) {
    if (text.empty()) return {};
    const int size = MultiByteToWideChar(CP_UTF8, 0, text.c_str(),
                                         static_cast<int>(text.size()),
                                         nullptr, 0);
    if (size <= 0) return {};
    std::wstring result(static_cast<std::size_t>(size), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, text.c_str(),
                        static_cast<int>(text.size()), result.data(), size);
    return result;
}

std::wstring quote_argument(const std::wstring& argument) {
    if (argument.empty()) return L"\"\"";
    if (argument.find_first_of(L" \t\n\v\"") == std::wstring::npos) {
        return argument;
    }
    std::wstring out = L"\"";
    for (auto it = argument.begin();; ++it) {
        std::size_t backslashes = 0;
        while (it != argument.end() && *it == L'\\') {
            ++it;
            ++backslashes;
        }
        if (it == argument.end()) {
            out.append(backslashes * 2, L'\\');
            break;
        }
        if (*it == L'"') {
            out.append(backslashes * 2 + 1, L'\\');
        } else {
            out.append(backslashes, L'\\');
        }
        out.push_back(*it);
    }
    out.push_back(L'"');
    return out;
}

}  // namespace

struct ChildProcess::Impl {
    HANDLE process = nullptr;
    HANDLE read_pipe = nullptr;
    DWORD process_id = 0;
    std::thread reader;
    std::mutex mutex;
    std::string output;
    std::atomic<bool> eof{false};

    ~Impl() {
        // Closing the launcher must not kill the child. If it is still
        // running, cancel the pending pipe read so the reader can exit, then
        // drop our handles and leave the process alone.
        // A grandchild may keep the write end open after the child exits, so
        // the reader can still be blocked on ReadFile. Always cancel it.
        if (read_pipe != nullptr) CancelIoEx(read_pipe, nullptr);
        if (reader.joinable()) reader.join();
        if (read_pipe != nullptr) CloseHandle(read_pipe);
        if (process != nullptr) CloseHandle(process);
    }
};

ChildProcess::ChildProcess() = default;
ChildProcess::~ChildProcess() = default;
ChildProcess::ChildProcess(ChildProcess&&) noexcept = default;
ChildProcess& ChildProcess::operator=(ChildProcess&&) noexcept = default;
ChildProcess::ChildProcess(std::unique_ptr<Impl> impl) : impl_(std::move(impl)) {}

bool ChildProcess::valid() const {
    return impl_ != nullptr && impl_->process != nullptr;
}

bool ChildProcess::running() const {
    return valid() && WaitForSingleObject(impl_->process, 0) == WAIT_TIMEOUT;
}

int ChildProcess::pid() const {
    return impl_ == nullptr ? 0 : static_cast<int>(impl_->process_id);
}

void ChildProcess::stop() {
    if (valid()) TerminateProcess(impl_->process, 1);
}

int ChildProcess::wait(std::uint32_t timeout_ms) {
    if (!valid()) return -1;
    if (WaitForSingleObject(impl_->process, timeout_ms) == WAIT_TIMEOUT) {
        return -1;
    }
    DWORD code = 0;
    if (!GetExitCodeProcess(impl_->process, &code)) return -1;
    return static_cast<int>(code);
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
    std::wstring command = quote_argument(request.executable.wstring());
    for (const auto& argument : request.arguments) {
        command += L" " + quote_argument(to_wide(argument));
    }

    SECURITY_ATTRIBUTES pipe_security{sizeof(pipe_security), nullptr, TRUE};
    HANDLE read_pipe = nullptr;
    HANDLE write_pipe = nullptr;
    if (!CreatePipe(&read_pipe, &write_pipe, &pipe_security, 0)) {
        error = "Could not create the output pipe (Win32 error " +
                std::to_string(GetLastError()) + ").";
        return std::nullopt;
    }
    SetHandleInformation(read_pipe, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    startup.dwFlags = STARTF_USESTDHANDLES;
    startup.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    startup.hStdOutput = write_pipe;
    startup.hStdError = write_pipe;

    std::vector<wchar_t> mutable_command(command.begin(), command.end());
    mutable_command.push_back(L'\0');
    PROCESS_INFORMATION process{};
    const wchar_t* working_directory =
        request.working_directory.empty() ? nullptr
                                          : request.working_directory.c_str();
    if (!CreateProcessW(request.executable.c_str(), mutable_command.data(),
                        nullptr, nullptr, TRUE, CREATE_NO_WINDOW, nullptr,
                        working_directory, &startup, &process)) {
        const DWORD code = GetLastError();
        CloseHandle(read_pipe);
        CloseHandle(write_pipe);
        error = "Could not start the game (Win32 error " +
                std::to_string(code) + ").";
        return std::nullopt;
    }
    CloseHandle(write_pipe);
    CloseHandle(process.hThread);

    auto impl = std::unique_ptr<ChildProcess::Impl>(new ChildProcess::Impl());
    impl->process = process.hProcess;
    impl->read_pipe = read_pipe;
    impl->process_id = process.dwProcessId;

    ChildProcess child(std::move(impl));
    auto* state = child.impl_.get();
    state->reader = std::thread([state] {
        char buffer[4096];
        DWORD read = 0;
        while (ReadFile(state->read_pipe, buffer, sizeof(buffer), &read,
                        nullptr) &&
               read > 0) {
            std::lock_guard<std::mutex> lock(state->mutex);
            state->output.append(buffer, read);
            if (state->output.size() > 1024 * 1024) {
                state->output.erase(0, state->output.size() - 1024 * 1024);
            }
        }
        state->eof.store(true);
    });
    return child;
}

}  // namespace jol::platform
