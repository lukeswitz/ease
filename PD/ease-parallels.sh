#!/bin/bash
# ease-parallels.sh - EASE for Parallels Desktop on M1 Mac
# External Adapter Support Environment - Parallels Edition

set -e

# Configuration
VM_NAME="EASE-VM"
VM_MEMORY="2048"
VM_CPUS="2"
VM_DISK_SIZE="8192"
DEBIAN_ISO_URL="https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/debian-12.2.0-arm64-netinst.iso"
DEBIAN_ISO="debian-12.2.0-arm64-netinst.iso"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

show_help() {
    cat << EOF
EASE-Parallels: External Adapter Support Environment for M1 Macs

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    install         Install and setup EASE VM
    start           Start the EASE VM
    stop            Stop the EASE VM
    restart         Restart the EASE VM
    status          Show VM status
    provision       Run provisioning inside VM (run after OS install)
    usb             Configure USB device passthrough
    remove          Remove EASE VM completely
    update          Update EASE VM configuration
    logs            Show VM and sensor logs
    test            Test Wi-Fi adapter functionality

OPTIONS:
    --memory SIZE   Set VM memory in MB (default: 2048)
    --cpus COUNT    Set VM CPU count (default: 2)
    --disk SIZE     Set VM disk size in MB (default: 8192)
    --headless      Run VM in headless mode
    --gui           Run VM with GUI
    --force         Force operations without confirmation
    --verbose       Enable verbose output
    --help, -h      Show this help message

EXAMPLES:
    $0 install --memory 4096 --cpus 4
    $0 start --headless
    $0 usb --list
    $0 provision --verbose
    $0 remove --force

SUPPORTED ADAPTERS:
    - ASUS USB-N53
    - ALFA AWUS051NH, AWUS036NHA  
    - COMFAST CF-912AC
    - Edimax EW-7822UAC, EW-7833UAC
    - TP-Link compatible chipsets
    - MediaTek MT7612U
    - Realtek RTL8812AU/RTL8814AU

For more info: https://github.com/intuitibits/ease
EOF
}

check_requirements() {
    log_info "Checking requirements..."
    
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Check if running on Apple Silicon
    if [[ "$(uname -m)" != "arm64" ]]; then
        log_warning "This script is optimized for Apple Silicon Macs"
    fi
    
    # Check if Parallels Desktop is installed
    if ! command -v prlctl &> /dev/null; then
        log_error "Parallels Desktop not found"
        echo "Please install Parallels Desktop from: https://www.parallels.com/products/desktop/"
        exit 1
    fi
    
    # Check Parallels version
    PARALLELS_VERSION=$(prlctl --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    log_info "Found Parallels Desktop version: $PARALLELS_VERSION"
    
    log_success "Requirements check passed"
}

download_debian_iso() {
    if [[ ! -f "$DEBIAN_ISO" ]]; then
        log_info "Downloading Debian ARM64 ISO..."
        if command -v curl &> /dev/null; then
            curl -L --progress-bar -o "$DEBIAN_ISO" "$DEBIAN_ISO_URL"
        elif command -v wget &> /dev/null; then
            wget -O "$DEBIAN_ISO" "$DEBIAN_ISO_URL"
        else
            log_error "Neither curl nor wget found. Please install one of them."
            exit 1
        fi
        log_success "Debian ISO downloaded"
    else
        log_info "Debian ISO already exists"
    fi
}

install_vm() {
    log_info "Installing EASE VM..."
    
    check_requirements
    download_debian_iso
    
    # Remove existing VM if it exists
    if prlctl list -a 2>/dev/null | grep -q "$VM_NAME"; then
        if [[ "$FORCE" != "true" ]]; then
            read -p "VM '$VM_NAME' already exists. Remove it? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_error "Installation cancelled"
                exit 1
            fi
        fi
        log_info "Removing existing VM..."
        prlctl delete "$VM_NAME" 2>/dev/null || true
    fi
    
    # Create new VM
    log_info "Creating VM: $VM_NAME"
    prlctl create "$VM_NAME" --distribution debian --no-hdd
    
    # Configure VM settings
    log_info "Configuring VM settings..."
    prlctl set "$VM_NAME" --memsize "$VM_MEMORY"
    prlctl set "$VM_NAME" --cpus "$VM_CPUS"
    prlctl set "$VM_NAME" --device-add hdd --type plain --size "$VM_DISK_SIZE"
    prlctl set "$VM_NAME" --device-set cdrom0 --image "$SCRIPT_DIR/$DEBIAN_ISO"
    prlctl set "$VM_NAME" --device-add net --type shared
    
    # Set startup mode
    if [[ "$HEADLESS" == "true" ]]; then
        prlctl set "$VM_NAME" --startup-view headless
    else
        prlctl set "$VM_NAME" --startup-view window
    fi
    
    prlctl set "$VM_NAME" --on-shutdown close
    prlctl set "$VM_NAME" --device-add usb --enable
    prlctl set "$VM_NAME" --auto-share-bluetooth off
    
    log_success "EASE VM created successfully!"
    
    echo
    log_info "Next steps:"
    echo "1. Start VM: $0 start"
    echo "2. Install Debian (follow the installer)"
    echo "3. After OS installation: $0 provision"
    echo "4. Configure USB adapters: $0 usb"
}

start_vm() {
    log_info "Starting EASE VM..."
    
    if ! prlctl list -a 2>/dev/null | grep -q "$VM_NAME"; then
        log_error "VM '$VM_NAME' not found. Run '$0 install' first."
        exit 1
    fi
    
    if prlctl status "$VM_NAME" 2>/dev/null | grep -q "running"; then
        log_warning "VM is already running"
        return 0
    fi
    
    prlctl start "$VM_NAME"
    sleep 3
    
    if prlctl status "$VM_NAME" 2>/dev/null | grep -q "running"; then
        log_success "EASE VM started"
        log_info "Wi-Fi adapters connected to this VM will appear in WiFi Explorer Pro"
    else
        log_error "Failed to start VM"
        exit 1
    fi
}

stop_vm() {
    log_info "Stopping EASE VM..."
    
    if ! prlctl list -a 2>/dev/null | grep -q "$VM_NAME"; then
        log_warning "VM '$VM_NAME' not found"
        return 0
    fi
    
    if ! prlctl status "$VM_NAME" 2>/dev/null | grep -q "running"; then
        log_warning "VM is not running"
        return 0
    fi
    
    prlctl stop "$VM_NAME"
    log_success "EASE VM stopped"
}

restart_vm() {
    log_info "Restarting EASE VM..."
    stop_vm
    sleep 2
    start_vm
}

show_status() {
    log_info "EASE VM Status:"
    
    if ! prlctl list -a 2>/dev/null | grep -q "$VM_NAME"; then
        echo "Status: Not installed"
        echo "Run '$0 install' to create the VM"
        return 0
    fi
    
    echo "VM Name: $VM_NAME"
    
    local status=$(prlctl status "$VM_NAME" 2>/dev/null | grep "Status:" | cut -d' ' -f2- || echo "unknown")
    echo "Status: $status"
    
    if [[ "$status" == *"running"* ]]; then
        echo "IP Address: $(prlctl list -f "$VM_NAME" 2>/dev/null | grep 'ip_configured' | cut -d'=' -f2 | tr -d ' ' || echo "N/A")"
        
        # Check if sensor is running
        if prlctl exec "$VM_NAME" systemctl is-active wifiexplorer-sensor 2>/dev/null | grep -q "active"; then
            echo "WiFi Explorer Sensor: Running ✅"
        else
            echo "WiFi Explorer Sensor: Not running ❌"
        fi
        
        # List connected USB devices
        echo "Connected USB devices:"
        prlctl list -i "$VM_NAME" 2>/dev/null | grep -A5 "USB devices" || echo "  None"
    fi
}

provision_vm() {
    log_info "Provisioning EASE environment..."
    
    if ! prlctl status "$VM_NAME" 2>/dev/null | grep -q "running"; then
        log_error "VM is not running. Start it first with: $0 start"
        exit 1
    fi
    
    # Wait for VM to be fully booted
    log_info "Waiting for VM to be ready..."
    sleep 10
    
    # Create provisioning script
    cat > /tmp/ease-provision.sh << 'EOF'
#!/bin/bash
set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing essential packages..."
sudo apt install -y \
    wireless-tools \
    wpasupplicant \
    iw \
    hostapd \
    dnsmasq \
    python3 \
    python3-pip \
    git \
    curl \
    build-essential \
    dkms \
    bc

echo "📡 Installing wireless drivers..."

# Install firmware packages
sudo apt install -y \
    firmware-realtek \
    firmware-atheros \
    firmware-ralink \
    firmware-misc-nonfree || true

# RTL8812AU driver (common chipset)
if [ ! -d "/usr/src/rtl8812au-5.6.4.2" ]; then
    git clone https://github.com/morrownr/8812au-20210629.git /tmp/8812au
    cd /tmp/8812au
    sudo ./install-driver.sh || echo "Driver installation failed, continuing..."
fi

echo "🔌 Installing WiFi Explorer sensor..."
curl -L -o /tmp/wifiexplorer-sensor.py "https://raw.githubusercontent.com/intuitibits/wifiexplorer-sensor/master/wifiexplorer-sensor.py"
sudo cp /tmp/wifiexplorer-sensor.py /usr/local/bin/
sudo chmod +x /usr/local/bin/wifiexplorer-sensor.py

# Create systemd service
sudo tee /etc/systemd/system/wifiexplorer-sensor.service > /dev/null << 'EOFSERVICE'
[Unit]
Description=WiFi Explorer Sensor
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/wifiexplorer-sensor.py --interface=auto
Restart=always
RestartSec=5
User=root
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable wifiexplorer-sensor
sudo systemctl start wifiexplorer-sensor

echo "✅ EASE provisioning complete!"
echo "📋 WiFi Explorer sensor status:"
sudo systemctl status wifiexplorer-sensor --no-pager
EOF
    
    # Copy and execute provisioning script
    prlctl exec "$VM_NAME" "cat > /tmp/ease-provision.sh" < /tmp/ease-provision.sh
    prlctl exec "$VM_NAME" "chmod +x /tmp/ease-provision.sh"
    prlctl exec "$VM_NAME" "/tmp/ease-provision.sh"
    
    rm /tmp/ease-provision.sh
    log_success "Provisioning completed successfully!"
}

configure_usb() {
    case "$1" in
        --list)
            log_info "Connected USB devices:"
            system_profiler SPUSBDataType | grep -E "(Product ID|Vendor ID|Manufacturer|Product)" | head -20
            echo
            log_info "To connect a device to EASE VM:"
            echo "1. In Parallels Desktop, go to Devices > USB & Bluetooth"
            echo "2. Select your Wi-Fi adapter"
            echo "3. The adapter will appear as wlan0, wlan1, etc. in the VM"
            ;;
        --auto)
            log_info "Enabling automatic USB device connection..."
            prlctl set "$VM_NAME" --auto-share-bluetooth off
            prlctl set "$VM_NAME" --auto-share-camera off
            log_success "USB auto-connect configured"
            ;;
        *)
            log_info "USB Configuration for EASE VM"
            echo
            echo "🔌 To use Wi-Fi adapters with EASE:"
            echo "1. Plug in your USB Wi-Fi adapter"
            echo "2. In Parallels Desktop menu: Devices > USB & Bluetooth"
            echo "3. Click on your Wi-Fi adapter to connect it to the VM"
            echo "4. The adapter will be available as wlan0, wlan1, etc."
            echo
            echo "📱 Supported adapters:"
            echo "  • ASUS USB-N53"
            echo "  • ALFA AWUS051NH, AWUS036NHA"
            echo "  • COMFAST CF-912AC"
            echo "  • Edimax EW-7822UAC, EW-7833UAC"
            echo "  • TP-Link compatible chipsets"
            echo
            echo "Use '$0 usb --list' to see connected USB devices"
            echo "Use '$0 usb --auto' to enable automatic USB sharing"
            ;;
    esac
}

remove_vm() {
    if [[ "$FORCE" != "true" ]]; then
        read -p "Are you sure you want to remove EASE VM completely? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Removal cancelled"
            exit 0
        fi
    fi
    
    log_info "Removing EASE VM..."
    
    if prlctl list -a 2>/dev/null | grep -q "$VM_NAME"; then
        prlctl delete "$VM_NAME"
        log_success "EASE VM removed"
    else
        log_warning "VM not found"
    fi
    
    # Optionally remove ISO
    if [[ -f "$DEBIAN_ISO" ]]; then
        read -p "Remove downloaded Debian ISO? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$DEBIAN_ISO"
            log_success "Debian ISO removed"
        fi
    fi
}

update_vm() {
    log_info "Updating EASE VM configuration..."
    
    if ! prlctl list -a 2>/dev/null | grep -q "$VM_NAME"; then
        log_error "VM not found. Run '$0 install' first."
        exit 1
    fi
    
    # Update VM settings
    prlctl set "$VM_NAME" --memsize "$VM_MEMORY"
    prlctl set "$VM_NAME" --cpus "$VM_CPUS"
    
    log_success "VM configuration updated"
    log_info "Memory: ${VM_MEMORY}MB, CPUs: $VM_CPUS"
}

show_logs() {
    log_info "EASE VM Logs:"
    
    if ! prlctl status "$VM_NAME" 2>/dev/null | grep -q "running"; then
        log_error "VM is not running"
        exit 1
    fi
    
    echo "=== WiFi Explorer Sensor Status ==="
    prlctl exec "$VM_NAME" "systemctl status wifiexplorer-sensor --no-pager" || true
    
    echo
    echo "=== WiFi Explorer Sensor Logs (last 20 lines) ==="
    prlctl exec "$VM_NAME" "journalctl -u wifiexplorer-sensor -n 20 --no-pager" || true
    
    echo
    echo "=== Available Network Interfaces ==="
    prlctl exec "$VM_NAME" "ip link show" || true
}

test_adapters() {
    log_info "Testing Wi-Fi adapter functionality..."
    
    if ! prlctl status "$VM_NAME" 2>/dev/null | grep -q "running"; then
        log_error "VM is not running. Start it first with: $0 start"
        exit 1
    fi
    
    echo "=== Available Network Interfaces ==="
    prlctl exec "$VM_NAME" "ip link show | grep -E '^[0-9]+: (wlan|wifi)'"
    
    echo
    echo "=== Wireless Interface Capabilities ==="
    prlctl exec "$VM_NAME" "iw list | grep -A 20 'Supported interface modes'" || true
    
    echo
    echo "=== WiFi Explorer Sensor Status ==="
    if prlctl exec "$VM_NAME" "systemctl is-active wifiexplorer-sensor" | grep -q "active"; then
        log_success "WiFi Explorer sensor is running"
    else
        log_error "WiFi Explorer sensor is not running"
        echo "Try: $0 provision"
    fi
}

# Parse command line arguments
COMMAND=""
FORCE=false
VERBOSE=false
HEADLESS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        install|start|stop|restart|status|provision|usb|remove|update|logs|test)
            COMMAND="$1"
            shift
            ;;
        --memory)
            VM_MEMORY="$2"
            shift 2
            ;;
        --cpus)
            VM_CPUS="$2"
            shift 2
            ;;
        --disk)
            VM_DISK_SIZE="$2"
            shift 2
            ;;
        --headless)
            HEADLESS=true
            shift
            ;;
        --gui)
            HEADLESS=false
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            set -x
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        --list|--auto)
            # USB subcommands
            configure_usb "$1"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute command
case "$COMMAND" in
    install)
        install_vm
        ;;
    start)
        start_vm
        ;;
    stop)
        stop_vm
        ;;
    restart)
        restart_vm
        ;;
    status)
        show_status
        ;;
    provision)
        provision_vm
        ;;
    usb)
        configure_usb
        ;;
    remove)
        remove_vm
        ;;
    update)
        update_vm
        ;;
    logs)
        show_logs
        ;;
    test)
        test_adapters
        ;;
    "")
        log_error "No command specified"
        show_help
        exit 1
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
