#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <string>
#include <utility>
#include <vector>

namespace jol::net {

struct HttpRequest {
    std::wstring host;
    std::wstring path;
    std::wstring method = L"POST";
    std::string body;
    std::vector<std::pair<std::wstring, std::wstring>> headers;
};

struct HttpResponse {
    unsigned long status = 0;
    std::string body;
};

HttpResponse send(const HttpRequest& request);


}  // namespace jol::net
