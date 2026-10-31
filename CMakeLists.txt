cmake_minimum_required(VERSION 3.25)

project(jolauncher VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Product metadata used by the Windows version resource.
set(JOL_RC_PRODUCT "JO-Launcher")
set(JOL_RC_EXE "JO-Launcher.exe")
set(JOL_RC_VERSION "${PROJECT_VERSION}")


file(TO_CMAKE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/platform/win32" JOL_RES_DIR)
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/platform/win32/resources.rc.in"
    "${CMAKE_CURRENT_BINARY_DIR}/resources.rc"
    @ONLY)

include(FetchContent)
FetchContent_Declare(
    nlohmann_json
    URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz
    URL_HASH SHA256=d6c65aca6b1ed68e7a182f4757257b107ae403032760ed6ef121c9d55e81757d
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(nlohmann_json)

add_library(miniz STATIC
    third_party/miniz/miniz.c
    third_party/miniz/miniz_tdef.c
    third_party/miniz/miniz_tinfl.c
    third_party/miniz/miniz_zip.c
)
target_include_directories(miniz PUBLIC third_party/miniz)

if (MSVC)
    set_property(TARGET miniz PROPERTY
        MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
    )
endif()


set(JOL_IMPL_SOURCES
    core/auth/client_id.cpp)

if (WIN32)
    set(JOL_PLATFORM_SOURCES
        platform/win32/platform_win32.cpp
        platform/win32/process_win32.cpp
        platform/win32/http_winhttp.cpp)
else()
    set(JOL_PLATFORM_SOURCES
        platform/linux/platform_linux.cpp
        platform/linux/process_posix.cpp
        platform/linux/http_curl.cpp)
endif()


add_library(jolauncher_core STATIC
    core/game_dir.cpp
    core/log.cpp
    core/settings_store.cpp
    core/global_settings_store.cpp
    core/mc/version.cpp
    core/mc/version_config.cpp
    core/mc/version_manager.cpp
    ${JOL_IMPL_SOURCES}
    ${JOL_PLATFORM_SOURCES}
    core/auth/auth.cpp
    core/auth/account_store.cpp
    core/launch/launch.cpp
)

target_include_directories(jolauncher_core PUBLIC core third_party/miniz)
if (CLIENT_ID_GENERATED_DIR)
    target_include_directories(jolauncher_core PUBLIC
        "${CLIENT_ID_GENERATED_DIR}")
endif()
target_link_libraries(jolauncher_core PUBLIC
    nlohmann_json::nlohmann_json
    miniz
)
if (WIN32)
    target_link_libraries(jolauncher_core PUBLIC winhttp crypt32 shell32 ole32)
else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(CURL REQUIRED IMPORTED_TARGET libcurl)
    pkg_check_modules(SODIUM REQUIRED IMPORTED_TARGET libsodium)
    find_package(Threads REQUIRED)
    target_link_libraries(jolauncher_core PUBLIC
        PkgConfig::CURL PkgConfig::SODIUM Threads::Threads)
endif()

if (MSVC)
    target_compile_options(jolauncher_core PRIVATE /W4 /utf-8
        $<$<CONFIG:Release>:/O2 /GL /Gy /Gw /guard:cf>)
    set_property(TARGET jolauncher_core PROPERTY
        MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
    )
endif()

if (WIN32)
add_executable(JO-Launcher WIN32
    platform/win32/main.cpp
    platform/win32/app.cpp
    platform/win32/l10n.cpp
    "${CMAKE_CURRENT_BINARY_DIR}/resources.rc"
)

target_link_libraries(JO-Launcher PRIVATE
    jolauncher_core
    miniz
    user32
    gdi32
    d2d1
    dwrite
    dwmapi
    shell32
    ole32
    advapi32
)

target_compile_definitions(JO-Launcher PRIVATE UNICODE _UNICODE NOMINMAX)

if (MSVC)
    target_compile_options(JO-Launcher PRIVATE /W4 /utf-8
        $<$<CONFIG:Release>:/O2 /GL /Gy /Gw /guard:cf>)
    target_link_options(JO-Launcher PRIVATE
        $<$<CONFIG:Release>:/LTCG /OPT:REF /OPT:ICF /DYNAMICBASE /NXCOMPAT>)
    set_property(TARGET JO-Launcher PROPERTY
        MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
    )
endif()

set_target_properties(JO-Launcher PROPERTIES OUTPUT_NAME "JO-Launcher")

endif()  # WIN32

option(JO_BUILD_HARNESS "Build the launch/process test harness" OFF)
if (JO_BUILD_HARNESS)
    add_executable(launch_harness tools/launch_harness.cpp)
    target_link_libraries(launch_harness PRIVATE jolauncher_core)
    target_compile_definitions(launch_harness PRIVATE UNICODE _UNICODE NOMINMAX)

    if (MSVC)
        set_property(TARGET launch_harness PROPERTY
            MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    endif()
endif()

