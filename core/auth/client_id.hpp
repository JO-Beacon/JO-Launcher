#pragma once

#include <string>

namespace jol::auth {

// OAuth client id used for Microsoft sign-in.
std::string resolve_client_id();
bool client_id_available();

}  // namespace jol::auth
