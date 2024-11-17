#!/bin/bash

# Export PATH to ensure all commands are found
export PATH=$PATH:/usr/bin

# Define variables
MEMFLOW_DIR="/$HOME/$USER/apex_dma/memflow_lib"
MEMFLOW_FFI_DIR="$MEMFLOW_DIR/memflow-ffi"
MEMFLOW_KVM_DIR="$MEMFLOW_DIR/memflow-kvm"
MEMFLOW_QEMU_DIR="$MEMFLOW_DIR/memflow-qemu"
MEMFLOW_WIN32_DIR="$MEMFLOW_DIR/memflow-win32"
MEMFLOW_UP_DIR="$MEMFLOW_DIR/memflowup"

# Create directory for memflow
# mkdir -p "$MEMFLOW_DIR"

# Check for required tools
for cmd in git cargo curl; do
    cmd_path=$(which $cmd 2>/dev/null)
    if [ -z "$cmd_path" ]; then
        echo "$cmd could not be found. Please install it."
        exit 1
    fi
done

# Clone and build memflow
git clone --depth 1 --branch 0.2.X https://github.com/memflow/memflow.git "$MEMFLOW_DIR/memflow"
cd "$MEMFLOW_DIR/memflow"
cargo build --release --all-features --workspace

# Build memflow-ffi
git clone --depth 1 https://github.com/memflow/memflow-ffi.git "$MEMFLOW_FFI_DIR"
cd "$MEMFLOW_FFI_DIR"
cargo build --release --all-features

# Install memflow-up utility
git clone --depth 1 https://github.com/memflow/memflowup.git "$MEMFLOW_UP_DIR"
cd "$MEMFLOW_UP_DIR"
cargo build --release --all-features

# Ensure the memflow library directory exists
sudo mkdir -p /usr/lib/memflow

# Install connectors
sudo "$MEMFLOW_UP_DIR/target/release/memflowup" install memflow-kvm memflow-qemu memflow-win32 --system --dev --from-source
sudo modprobe memflow
echo "memflow" | sudo tee -a /etc/modules-load.d/modules.conf

# Build and install memflow-kvm
git clone --depth 1 https://github.com/memflow/memflow-kvm.git "$MEMFLOW_KVM_DIR"
cd "$MEMFLOW_KVM_DIR"
./install.sh
sudo cp target/release/libmemflow_kvm.so /usr/lib/memflow/

# Build and install memflow-qemu
git clone --depth 1 https://github.com/memflow/memflow-qemu.git "$MEMFLOW_QEMU_DIR"
cd "$MEMFLOW_QEMU_DIR"
cargo build --release --all-features
mkdir -p "$HOME/.local/lib/memflow"
sudo cp target/release/libmemflow_qemu.so "$HOME/.local/lib/memflow/"

# Build and install memflow-win32
git clone --depth 1 https://github.com/memflow/memflow-win32.git "$MEMFLOW_WIN32_DIR"
cd "$MEMFLOW_WIN32_DIR"
cargo build --release --all-features
sudo cp target/release/libmemflow_win32.so /usr/lib/memflow/

# Complete
echo "Memflow and its connectors have been installed successfully!"

# Copy or link the libraries to the target directory
TARGET_DIR="/$HOME/$USER/adkv/apex_dma/build"
mkdir -p "$TARGET_DIR"

# Copy the libraries to the target directory
sudo cp /usr/lib/memflow/libmemflow_ffi.so "$TARGET_DIR/"
sudo cp /usr/lib/memflow/libmemflow_kvm.so "$TARGET_DIR/"
sudo cp /usr/lib/memflow/libmemflow_qemu.so "$TARGET_DIR/"
sudo cp /usr/lib/memflow/libmemflow_win32.so "$TARGET_DIR/"

# Alternatively, to create symbolic links instead of copying, uncomment the following lines:
# ln -s /usr/lib/memflow/libmemflow_ffi.so "$TARGET_DIR/libmemflow_ffi.so"
# ln -s /usr/lib/memflow/libmemflow_kvm.so "$TARGET_DIR/libmemflow_kvm.so"
# ln -s /usr/lib/memflow/libmemflow_qemu.so "$TARGET_DIR/libmemflow_qemu.so"
# ln -s /usr/lib/memflow/libmemflow_win32.so "$TARGET_DIR/libmemflow_win32.so"

echo "Shared libraries have been copied/linked to $TARGET_DIR."

# (Optional) Verification
# You can uncomment the following lines if you want to check linked libraries
# echo "Verifying installation:"
# ldconfig -p | grep memflow

# Check for memflow-up version
echo "Checking memflow-up version:"
"$MEMFLOW_UP_DIR/target/release/memflowup" --version

echo "Setup complete."
