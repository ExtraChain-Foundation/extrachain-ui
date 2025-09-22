./vcpkg install \
    libsodium:arm64-osx \
    sqlite3:arm64-osx \
    boost-system:arm64-osx \
    boost-thread:arm64-osx \
    boost-variant:arm64-osx \
    boost-interprocess:arm64-osx \
    boost-multiprecision:arm64-osx \
    boost-asio:arm64-osx \
    boost-filesystem:arm64-osx \
    boost-mp11:arm64-osx \
    boost-describe:arm64-osx \
    boost-json:arm64-osx \
    msgpack:arm64-osx \
    fmt:arm64-osx \
    magic-enum:arm64-osx \
    hash-library:arm64-osx \
    cpp-base64:arm64-osx \
    blake3:arm64-osx \
    --triplet=arm64-custom-osx14 \
    --overlay-triplets=.
    
    ./vcpkg install \
    libsodium:x64-osx \
    sqlite3:x64-osx \
    boost-system:x64-osx \
    boost-thread:x64-osx \
    boost-variant:x64-osx \
    boost-interprocess:x64-osx \
    boost-multiprecision:x64-osx \
    boost-asio:x64-osx \
    boost-filesystem:x64-osx \
    boost-mp11:x64-osx \
    boost-describe:x64-osx \
    boost-json:x64-osx \
    msgpack:x64-osx \
    fmt:x64-osx \
    magic-enum:x64-osx \
    hash-library:x64-osx \
    cpp-base64:x64-osx \
    blake3:x64-osx \
    --triplet=x64-custom-osx14 \
    --overlay-triplets=.
