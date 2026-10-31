#include "net/http.hpp"

#include <windows.h>
#include <winhttp.h>

#include <fstream>
#include <stdexcept>
#include <string>
#include <vector>


namespace jol::net {
namespace {

std::runtime_error failure(const char* stage) {
    return std::runtime_error(std::string(stage) + " (WinHTTP error " +
                              std::to_string(GetLastError()) + ")");
}

struct WinHttpApi {
    HMODULE module = nullptr;
    decltype(&WinHttpOpen) open = nullptr;
    decltype(&WinHttpSetTimeouts) set_timeouts = nullptr;
    decltype(&WinHttpConnect) connect = nullptr;
    decltype(&WinHttpOpenRequest) open_request = nullptr;
    decltype(&WinHttpAddRequestHeaders) add_headers = nullptr;
    decltype(&WinHttpSendRequest) send_request = nullptr;
    decltype(&WinHttpReceiveResponse) receive_response = nullptr;
    decltype(&WinHttpQueryHeaders) query_headers = nullptr;
    decltype(&WinHttpQueryDataAvailable) query_available = nullptr;
    decltype(&WinHttpReadData) read_data = nullptr;
    decltype(&WinHttpCloseHandle) close_handle = nullptr;
};


const WinHttpApi* http_api() {
    static const WinHttpApi direct = [] {
        WinHttpApi value{};
        value.open = &WinHttpOpen;
        value.set_timeouts = &WinHttpSetTimeouts;
        value.connect = &WinHttpConnect;
        value.open_request = &WinHttpOpenRequest;
        value.add_headers = &WinHttpAddRequestHeaders;
        value.send_request = &WinHttpSendRequest;
        value.receive_response = &WinHttpReceiveResponse;
        value.query_headers = &WinHttpQueryHeaders;
        value.query_available = &WinHttpQueryDataAvailable;
        value.read_data = &WinHttpReadData;
        value.close_handle = &WinHttpCloseHandle;
        return value;
    }();
    return &direct;
}

}  // namespace

HttpResponse send(const HttpRequest& request) {
    const WinHttpApi* http = http_api();
    if (http == nullptr) throw std::runtime_error("WinHTTP is unavailable");

    HINTERNET session = http->open(
        L"JO-Launcher/0.1", WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
        WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
    if (session == nullptr) throw failure("WinHTTP");

    http->set_timeouts(session, 10000, 10000, 30000, 30000);

    HINTERNET connect = http->connect(
        session, request.host.c_str(), INTERNET_DEFAULT_HTTPS_PORT, 0);
    if (connect == nullptr) {
        http->close_handle(session);
        throw failure("WinHTTP");
    }

    HINTERNET handle = http->open_request(
        connect, request.method.c_str(), request.path.c_str(), nullptr,
        WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, WINHTTP_FLAG_SECURE);
    if (handle == nullptr) {
        http->close_handle(connect);
        http->close_handle(session);
        throw failure("WinHTTP");
    }

    for (const auto& header : request.headers) {
        const std::wstring value = header.first + L": " + header.second;
        http->add_headers(handle, value.c_str(),
                          static_cast<DWORD>(value.size()),
                          WINHTTP_ADDREQ_FLAG_ADD);
    }

    BOOL ok = http->send_request(
        handle, WINHTTP_NO_ADDITIONAL_HEADERS, 0,
        request.body.empty() ? WINHTTP_NO_REQUEST_DATA
                             : const_cast<char*>(request.body.data()),
        static_cast<DWORD>(request.body.size()),
        static_cast<DWORD>(request.body.size()), 0);
    if (!ok) {
        http->close_handle(handle);
        http->close_handle(connect);
        http->close_handle(session);
        throw failure("WinHTTP");
    }

    ok = http->receive_response(handle, nullptr);
    if (!ok) {
        http->close_handle(handle);
        http->close_handle(connect);
        http->close_handle(session);
        throw failure("WinHTTP");
    }

    DWORD status = 0;
    DWORD status_size = sizeof(status);
    http->query_headers(handle,
                        WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                        WINHTTP_HEADER_NAME_BY_INDEX, &status, &status_size,
                        WINHTTP_NO_HEADER_INDEX);

    constexpr std::size_t kMaxResponseBytes = 8ull * 1024 * 1024;
    std::string body;
    for (;;) {
        DWORD available = 0;
        if (!http->query_available(handle, &available)) break;
        if (available == 0) break;
        if (body.size() + available > kMaxResponseBytes) {
            http->close_handle(handle);
            http->close_handle(connect);
            http->close_handle(session);
            throw std::runtime_error("HTTP response is too large");
        }
        const size_t old_size = body.size();
        body.resize(old_size + available);
        DWORD read = 0;
        if (!http->read_data(handle, body.data() + old_size, available,
                             &read)) {
            break;
        }
        body.resize(old_size + read);
        if (read == 0) break;
    }

    http->close_handle(handle);
    http->close_handle(connect);
    http->close_handle(session);
    return HttpResponse{status, body};
}


}  // namespace jol::net
