#include <chrono>
#include <filesystem>
#include <iostream>
#include <string>
#include <thread>

#include "launch/launch.hpp"

int main(int argc, char** argv) {
    const std::filesystem::path game_dir =
        argc > 1 ? std::filesystem::path(argv[1])
                 : std::filesystem::path("C:/JO-Launcher-Test/.minecraft");
    const bool stop_after_start = argc > 2 && std::string(argv[2]) == "stop";

    jol::launch::LaunchRequest request;
    request.game_dir = game_dir;
    request.version_name = "harness";
    request.client_id = "harness";
    request.account.name = "Harness";
    request.account.uuid = "00000000000000000000000000000000";
    request.account.access_token = "harness-token";

    try {
        jol::launch::GameProcess process = jol::launch::start(request);
        std::cout << "pid=" << process.pid() << std::endl;
        for (int i = 0; i < 300; ++i) {
            const std::string output = process.take_output();
            if (!output.empty()) {
                std::cout << output;
                std::cout.flush();
            }
            if (stop_after_start && i == 10) {
                std::cout << "stopping" << std::endl;
                process.stop();
            }
            if (!process.running()) break;
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
        std::cout << "exit=" << process.wait() << std::endl;
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "launch failed: " << error.what() << std::endl;
        return 1;
    }
}
