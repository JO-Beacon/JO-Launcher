// The Microsoft Azure application id is read from the environment at runtime,
// so no id needs to be compiled into the binary.

#include "auth/client_id.hpp"
#include "platform/environment.hpp"

namespace jol::auth {
namespace {

}  // namespace

std::string resolve_client_id() {
    for (const char* name : {"JO_MS_CLIENT_ID", "JOL_MS_CLIENT_ID"}) {
        if (const auto value = platform::environment_string(name);
            value && !value->empty()) {
            return *value;
        }
    }
    return {};
}

bool client_id_available() { return !resolve_client_id().empty(); }


}  // namespace jol::auth
