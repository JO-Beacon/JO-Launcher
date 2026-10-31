#include "net/http.hpp"

#include "platform/text.hpp"

#include <curl/curl.h>

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <mutex>
#include <stdexcept>
#include <string>

namespace jol::net {
namespace {

constexpr std::size_t kMaxResponseBytes = 8ull * 1024 * 1024;

void ensure_curl() {
    static std::once_flag once;
    std::call_once(once, [] { curl_global_init(CURL_GLOBAL_DEFAULT); });
}

std::string url_for(const HttpRequest& request) {
    std::string host = platform::narrow(request.host);
    if (host.rfind("https://", 0) == 0) {
        host = host.substr(8);
    } else if (host.rfind("http://", 0) == 0) {
        throw std::runtime_error("Only https URLs are supported");
    }
    if (host.empty()) throw std::runtime_error("Empty HTTP host");
    return "https://" + host + platform::narrow(request.path);
}

struct BodySink {
    std::string* body = nullptr;
    bool overflow = false;
};

std::size_t write_body(char* data, std::size_t size, std::size_t count,
                       void* user) {
    auto* sink = static_cast<BodySink*>(user);
    const std::size_t bytes = size * count;
    if (sink->body->size() + bytes > kMaxResponseBytes) {
        sink->overflow = true;
        return 0;
    }
    sink->body->append(data, bytes);
    return bytes;
}


struct CurlHandle {
    CURL* handle = nullptr;
    curl_slist* headers = nullptr;

    ~CurlHandle() {
        if (headers != nullptr) curl_slist_free_all(headers);
        if (handle != nullptr) curl_easy_cleanup(handle);
    }
};

}  // namespace

HttpResponse send(const HttpRequest& request) {
    ensure_curl();
    CurlHandle curl;
    curl.handle = curl_easy_init();
    if (curl.handle == nullptr) {
        throw std::runtime_error("Could not create a libcurl handle");
    }

    const std::string url = url_for(request);
    const std::string method = platform::narrow(request.method);
    std::string body;
    BodySink sink{&body};

    for (const auto& [name, value] : request.headers) {
        const std::string line =
            platform::narrow(name) + ": " + platform::narrow(value);
        curl.headers = curl_slist_append(curl.headers, line.c_str());
    }

    curl_easy_setopt(curl.handle, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl.handle, CURLOPT_USERAGENT, "JO-Launcher/0.1");
    curl_easy_setopt(curl.handle, CURLOPT_CONNECTTIMEOUT, 15L);
    curl_easy_setopt(curl.handle, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(curl.handle, CURLOPT_LOW_SPEED_LIMIT, 1L);
    curl_easy_setopt(curl.handle, CURLOPT_LOW_SPEED_TIME, 60L);
    curl_easy_setopt(curl.handle, CURLOPT_FOLLOWLOCATION, 0L);
    curl_easy_setopt(curl.handle, CURLOPT_WRITEFUNCTION, write_body);
    curl_easy_setopt(curl.handle, CURLOPT_WRITEDATA, &sink);
    if (curl.headers != nullptr) {
        curl_easy_setopt(curl.handle, CURLOPT_HTTPHEADER, curl.headers);
    }

    if (method == "POST") {
        curl_easy_setopt(curl.handle, CURLOPT_POST, 1L);
        curl_easy_setopt(curl.handle, CURLOPT_POSTFIELDS, request.body.data());
        curl_easy_setopt(curl.handle, CURLOPT_POSTFIELDSIZE,
                         static_cast<long>(request.body.size()));
    } else if (method != "GET") {
        curl_easy_setopt(curl.handle, CURLOPT_CUSTOMREQUEST, method.c_str());
        if (!request.body.empty()) {
            curl_easy_setopt(curl.handle, CURLOPT_POSTFIELDS,
                             request.body.data());
            curl_easy_setopt(curl.handle, CURLOPT_POSTFIELDSIZE,
                             static_cast<long>(request.body.size()));
        }
    }

    const CURLcode result = curl_easy_perform(curl.handle);
    if (sink.overflow) {
        throw std::runtime_error("HTTP response is too large");
    }
    if (result != CURLE_OK) {
        throw std::runtime_error(std::string("HTTP request failed: ") +
                                 curl_easy_strerror(result));
    }

    long status = 0;
    curl_easy_getinfo(curl.handle, CURLINFO_RESPONSE_CODE, &status);
    HttpResponse response;
    response.status = static_cast<unsigned long>(status);
    response.body = std::move(body);
    return response;
}


}  // namespace jol::net
