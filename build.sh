#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
INSTALL_DIR="${SCRIPT_DIR}/install"

LIBUV_VERSION="${LIBUV_VERSION:-v1.48.0}"
ZLIB_VERSION="${ZLIB_VERSION:-1.3.1}"
MBEDTLS_VERSION="${MBEDTLS_VERSION:-v3.6.0}"

print_usage() {
    echo "Usage: $0 [OPTIONS] [LIBRARIES...]"
    echo ""
    echo "Libraries:"
    echo "  libuv      - Build libuv library"
    echo "  zlib       - Build zlib library"
    echo "  mbedtls    - Build mbedtls library"
    echo "  all        - Build all libraries (default if no library specified)"
    echo ""
    echo "Options:"
    echo "  -c, --clean               Clean build directory before building"
    echo "  --libuv-version <ver>     Specify libuv version (default: ${LIBUV_VERSION})"
    echo "  --zlib-version <ver>      Specify zlib version (default: ${ZLIB_VERSION})"
    echo "  --mbedtls-version <ver>   Specify mbedtls version (default: ${MBEDTLS_VERSION})"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  LIBUV_VERSION             libuv version (overridden by --libuv-version)"
    echo "  ZLIB_VERSION              zlib version (overridden by --zlib-version)"
    echo "  MBEDTLS_VERSION           mbedtls version (overridden by --mbedtls-version)"
    echo ""
    echo "Examples:"
    echo "  $0                                        # Build all libraries with default versions"
    echo "  $0 libuv                                  # Build only libuv"
    echo "  $0 libuv zlib                             # Build libuv and zlib"
    echo "  $0 --libuv-version v1.44.2 libuv          # Build libuv v1.44.2"
    echo "  $0 --zlib-version 1.2.13 zlib             # Build zlib 1.2.13"
    echo "  $0 --mbedtls-version v2.28.5 mbedtls      # Build mbedtls v2.28.5"
    echo "  $0 -c --libuv-version v1.44.2 libuv       # Clean and rebuild libuv v1.44.2"
    echo "  LIBUV_VERSION=v1.44.2 $0 libuv            # Using environment variable"
}

CLEAN=0
LIBRARIES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--clean)
            CLEAN=1
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        --libuv-version)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --libuv-version requires a version argument"
                exit 1
            fi
            LIBUV_VERSION="$2"
            shift 2
            ;;
        --zlib-version)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --zlib-version requires a version argument"
                exit 1
            fi
            ZLIB_VERSION="$2"
            shift 2
            ;;
        --mbedtls-version)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --mbedtls-version requires a version argument"
                exit 1
            fi
            MBEDTLS_VERSION="$2"
            shift 2
            ;;
        libuv|zlib|mbedtls|all)
            LIBRARIES+=("$1")
            shift
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

if [ ${#LIBRARIES[@]} -eq 0 ]; then
    LIBRARIES=("all")
fi

if [[ " ${LIBRARIES[*]} " =~ " all " ]]; then
    LIBRARIES=("libuv" "zlib" "mbedtls")
fi

mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}"

if [ "$CLEAN" -eq 1 ]; then
    echo "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"/*
fi

check_version() {
    local lib_name="$1"
    local version="$2"
    local version_file="${BUILD_DIR}/${lib_name}/.version"

    if [ -f "$version_file" ]; then
        local saved_version
        saved_version=$(cat "$version_file")
        if [ "$saved_version" != "$version" ]; then
            echo "Version changed for ${lib_name}: ${saved_version} -> ${version}"
            echo "Removing old source..."
            rm -rf "${BUILD_DIR}/${lib_name}" "${BUILD_DIR}/${lib_name}-build"
        fi
    fi
}

save_version() {
    local lib_name="$1"
    local version="$2"
    echo "$version" > "${BUILD_DIR}/${lib_name}/.version"
}

build_libuv() {
    echo "=========================================="
    echo "Building libuv ${LIBUV_VERSION}"
    echo "=========================================="

    check_version "libuv" "${LIBUV_VERSION}"

    local src_dir="${BUILD_DIR}/libuv"
    local build_dir="${BUILD_DIR}/libuv-build"

    if [ ! -d "$src_dir" ]; then
        echo "Downloading libuv ${LIBUV_VERSION}..."
        git clone --depth 1 --branch "${LIBUV_VERSION}" https://github.com/libuv/libuv.git "$src_dir"
        save_version "libuv" "${LIBUV_VERSION}"
    fi

    mkdir -p "$build_dir"
    cmake -S "$src_dir" -B "$build_dir" \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
        -DBUILD_TESTING=OFF \
        -DLIBUV_BUILD_TESTS=OFF

    cmake --build "$build_dir" --config Release -j$(nproc)
    cmake --install "$build_dir"

    echo "libuv ${LIBUV_VERSION} installed to ${INSTALL_DIR}"
}

build_zlib() {
    echo "=========================================="
    echo "Building zlib ${ZLIB_VERSION}"
    echo "=========================================="

    check_version "zlib" "${ZLIB_VERSION}"

    local src_dir="${BUILD_DIR}/zlib"
    local build_dir="${BUILD_DIR}/zlib-build"

    if [ ! -d "$src_dir" ]; then
        echo "Downloading zlib ${ZLIB_VERSION}..."
        git clone --depth 1 --branch "v${ZLIB_VERSION}" https://github.com/madler/zlib.git "$src_dir"
        save_version "zlib" "${ZLIB_VERSION}"
    fi

    mkdir -p "$build_dir"
    cmake -S "$src_dir" -B "$build_dir" \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"

    cmake --build "$build_dir" --config Release -j$(nproc)
    cmake --install "$build_dir"

    echo "zlib ${ZLIB_VERSION} installed to ${INSTALL_DIR}"
}

build_mbedtls() {
    echo "=========================================="
    echo "Building mbedtls ${MBEDTLS_VERSION}"
    echo "=========================================="

    check_version "mbedtls" "${MBEDTLS_VERSION}"

    local src_dir="${BUILD_DIR}/mbedtls"
    local build_dir="${BUILD_DIR}/mbedtls-build"

    if [ ! -d "$src_dir" ]; then
        echo "Downloading mbedtls ${MBEDTLS_VERSION}..."
        git clone --depth 1 --branch "${MBEDTLS_VERSION}" --recurse-submodules https://github.com/Mbed-TLS/mbedtls.git "$src_dir"
        save_version "mbedtls" "${MBEDTLS_VERSION}"
    fi

    mkdir -p "$build_dir"
    cmake -S "$src_dir" -B "$build_dir" \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
        -DENABLE_TESTING=OFF \
        -DENABLE_PROGRAMS=OFF \
        -DINSTALL_MBEDTLS_HEADERS=ON

    cmake --build "$build_dir" --config Release -j$(nproc)
    cmake --install "$build_dir"

    echo "mbedtls ${MBEDTLS_VERSION} installed to ${INSTALL_DIR}"
}

echo "Library versions:"
echo "  libuv:   ${LIBUV_VERSION}"
echo "  zlib:    ${ZLIB_VERSION}"
echo "  mbedtls: ${MBEDTLS_VERSION}"
echo ""

for lib in "${LIBRARIES[@]}"; do
    case $lib in
        libuv)
            build_libuv
            ;;
        zlib)
            build_zlib
            ;;
        mbedtls)
            build_mbedtls
            ;;
    esac
done

echo ""
echo "=========================================="
echo "Build completed!"
echo "Libraries installed to: ${INSTALL_DIR}"
echo "=========================================="
