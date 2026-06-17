# iot-thirtparty

第三方库构建脚本，用于下载和编译 IoT 项目常用的 C/C++ 库。

## 支持的库

| 库 | 默认版本 | 说明 |
|---|---|---|
| libuv | v1.48.0 | 跨平台异步 I/O 库 |
| zlib | 1.3.1 | 压缩库 |
| mbedtls | v3.6.0 | TLS/SSL 加密库 |

## 前置依赖

- Git
- CMake (>= 3.10)
- C/C++ 编译器 (gcc/clang)
- make

## 使用方法

```bash
# 赋予执行权限
chmod +x build.sh

# 构建所有库（使用默认版本）
./build.sh

# 只构建 libuv
./build.sh libuv

# 构建 libuv 和 zlib
./build.sh libuv zlib

# 构建 mbedtls
./build.sh mbedtls

# 清理后重新构建
./build.sh -c libuv

# 查看帮助
./build.sh -h
```

## 指定版本

可以通过命令行参数或环境变量指定库的版本：

### 命令行参数

```bash
# 指定 libuv 版本
./build.sh --libuv-version v1.44.2 libuv

# 指定 zlib 版本
./build.sh --zlib-version 1.2.13 zlib

# 指定 mbedtls 版本
./build.sh --mbedtls-version v2.28.5 mbedtls

# 同时指定多个库的版本
./build.sh --libuv-version v1.44.2 --zlib-version 1.2.13 libuv zlib

# 清理后重新构建指定版本
./build.sh -c --libuv-version v1.44.2 libuv
```

### 环境变量

```bash
# 使用环境变量指定版本
LIBUV_VERSION=v1.44.2 ./build.sh libuv

# 多个环境变量
LIBUV_VERSION=v1.44.2 ZLIB_VERSION=1.2.13 ./build.sh libuv zlib
```

**优先级**: 命令行参数 > 环境变量 > 默认值

## 参数说明

| 参数 | 说明 |
|---|---|
| `libuv` | 构建 libuv |
| `zlib` | 构建 zlib |
| `mbedtls` | 构建 mbedtls |
| `all` | 构建所有库（默认） |
| `-c, --clean` | 构建前清理 build 目录 |
| `--libuv-version <ver>` | 指定 libuv 版本 |
| `--zlib-version <ver>` | 指定 zlib 版本 |
| `--mbedtls-version <ver>` | 指定 mbedtls 版本 |
| `-h, --help` | 显示帮助信息 |

## 版本管理

脚本会自动检测版本变化：
- 当指定的版本与已下载的版本不同时，自动删除旧源码并重新下载
- 使用 `-c` 参数可强制清理所有构建产物后重新构建

## 目录结构

```
iot-thirtparty/
├── build.sh          # 构建脚本
├── build/            # 构建目录（下载源码和编译产物）
│   ├── libuv/
│   ├── libuv-build/
│   ├── zlib/
│   ├── zlib-build/
│   ├── mbedtls/
│   └── mbedtls-build/
├── install/          # 安装目录
│   ├── include/
│   └── lib/
└── README.md
```

## 在项目中使用

构建完成后，库文件和头文件会安装到 `install/` 目录。在 CMake 项目中引用：

```cmake
set(THIRDPARTY_DIR "/path/to/iot-thirtparty/install")

include_directories(${THIRDPARTY_DIR}/include)
link_directories(${THIRDPARTY_DIR}/lib)

target_link_libraries(your_target
    uv
    z
    mbedcrypto
    mbedtls
    mbedx509
)
```

或使用 `find_package`：

```cmake
list(APPEND CMAKE_PREFIX_PATH "/path/to/iot-thirtparty/install")

find_package(ZLIB REQUIRED)
find_package(MbedTLS REQUIRED)
```
