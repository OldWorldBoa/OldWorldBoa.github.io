## configure these for your environment
PKG="server"                                 # cargo package name
TARGET="aarch64-unknown-linux-gnu"            # remote target
ASSETS=("static" "templates")                # list of assets to bundle
BUILD_DIR="target/${TARGET}/release"         # cargo build directory

## ensure target toolchain is present
rustup target add $TARGET

## cross-compile
cargo zigbuild --target $TARGET --release

## bundle
tar -cvzf "${PKG}.tar.gz" -C "${BUILD_DIR}" "${PKG}"
