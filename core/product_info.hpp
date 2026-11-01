#pragma once

// Product identity. The three values can be overridden with compile
// definitions; the defaults below are used when nothing is defined.
#ifndef JOL_APP_NAME
#define JOL_APP_NAME L"JO-Launcher"
#endif
#ifndef JOL_DATA_DIRECTORY
#define JOL_DATA_DIRECTORY L"JO-Launcher"
#endif
#ifndef JOL_LICENSE_NAME
#define JOL_LICENSE_NAME L"Apache License 2.0"
#endif
// CMake supplies the real project version. This fallback only keeps
// standalone syntax checks compiling.
#ifndef JOL_VERSION
#define JOL_VERSION "0.0.0"
#endif

namespace jol {

inline constexpr const wchar_t* kProductName = JOL_APP_NAME;
inline constexpr const char* kVersion = JOL_VERSION;
inline constexpr const wchar_t* kDataDirectoryName = JOL_DATA_DIRECTORY;
inline constexpr const wchar_t* kLicenseName = JOL_LICENSE_NAME;

}  // namespace jol
