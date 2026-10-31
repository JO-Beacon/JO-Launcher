#pragma once

namespace jol::platform {

/// Cross-process mutex guarding the account file.
class NamedMutex {
public:
    explicit NamedMutex(const char* name);
    ~NamedMutex();

    NamedMutex(const NamedMutex&) = delete;
    NamedMutex& operator=(const NamedMutex&) = delete;

    bool locked() const;

private:
    void* impl_ = nullptr;
};

}  // namespace jol::platform
