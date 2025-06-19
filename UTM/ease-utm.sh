#!/bin/bash
# ease-utm.sh - EASE for UTM on M1 Mac
# External Adapter Support Environment - UTM Edition

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
EASE-UTM: External Adapter Support Environment for M1 Macs using UTM

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    install         Install and setup EASE VM in UTM
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
    backup          Backup VM to file
    restore         Restore VM from backup
    ssh             SSH into the running VM
    optimize        Optimize VM performance settings

OPTIONS:
    --memory SIZE   Set VM memory in MB (default: 2048)
    --cpus COUNT    Set VM CPU count (default: 2)
    --disk SIZE     Set VM disk size in MB (default: 8192)
    --headless      Run VM in headless mode
    --acceleration  Enable hardware acceleration
    --force         Force operations without confirmation
    --verbose       Enable verbose output
    --help, -h      Show this help message

EXAMPLES:
    $0 install --memory 4096 --cpus 4
    $0 start --headless
    $0 usb --list
    $0 provision --verbose
    $0 backup my-ease-backup.utm
    $0 remove --force

UTM-SPECIFIC FEATURES:
    - Free and open source
    - Good Apple Silicon performance  
    - USB passthrough support
    - VM backup/restore functionality
    - SSH access to VM

SUPPORTED ADAPTERS:
    - ASUS USB-N53
    - ALFA AWUS051NH, AWUS036NHA  
    - COMFAST CF-912AC
    - Edimax EW-7822UAC, EW-7833UAC
    - TP-Link compatible chipsets
    - MediaTek MT7612U
    - Realtek RTL8812AU/RTL8814AU

For more info: https://github.com/yourusername/ease-utm
EOF
}

check_requirements() {
    log_info "Checking requirements..."
    
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Check if running on Apple Silicon (recommended)
    if [[ "$(uname -m)" != "arm64" ]]; then
        log_warning "This script is optimized for Apple Silicon Macs"
    fi
    
    # Check if UTM is installed
    if [[ ! -d "/Applications/UTM.app" ]]; then
        log_error "UTM not found in /Applications/"
        echo "Please install UTM from: https://mac.getutm.app/"
        exit 1
    fi
    
    # Check UTM version
    UTM_VERSION=$(defaults read /Applications/UTM.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "unknown")
    log_info "Found UTM version: $UTM_VERSION"
    
    log_success "Requirements check passed"
}

# UTM Helper Functions
utm_list_vms() {
    osascript -e 'tell application "UTM" to get name of every virtual machine' 2>/dev/null | tr ',' '\n' | sed 's/^[[:space:]]*//' || echo ""
}

utm_vm_exists() {
    utm_list_vms | grep -q "^$VM_NAME$"
}

utm_vm_running() {
    osascript -e "tell application \"UTM\" to get started of virtual machine \"$VM_NAME\"" 2>/dev/null | grep -q "true"
}

utm_start_vm() {
    osascript -e "tell application \"UTM\" to start virtual machine \"$VM_NAME\""
}

utm_stop_vm() {
    osascript -e "tell application \"UTM\" to stop virtual machine \"$VM_NAME\""
}

utm_delete_vm() {
    osascript -e "tell application \"UTM\" to delete virtual machine \"$VM_NAME\""
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

create_utm_vm() {
    log_info "Creating UTM VM configuration..."
    
    # Create a temporary UTM configuration
    local temp_config=$(mktemp -d)
    local utm_file="${temp_config}/${VM_NAME}.utm"
    
    # Create the UTM bundle structure
    mkdir -p "$utm_file"
    
    # Create config.plist for UTM
    cat > "$utm_file/config.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Backend</key>
    <string>qemu</string>
    <key>ConfigurationVersion</key>
    <integer>4</integer>
    <key>Information</key>
    <dict>
        <key>Architecture</key>
        <string>aarch64</string>
        <key>Name</key>
        <string>$VM_NAME</string>
        <key>Notes</key>
        <string>EASE - External Adapter Support Environment for WiFi Explorer Pro</string>
        <key>UUID</key>
        <string>$(uuidgen)</string>
    </dict>
    <key>System</key>
    <dict>
        <key>Architecture</key>
        <string>aarch64</string>
        <key>Boot</key>
        <dict>
            <key>BootOrder</key>
            <array>
                <string>cd</string>
                <string>hd</string>
            </array>
        </dict>
        <key>CPU</key>
        <dict>
            <key>Cores</key>
            <integer>$VM_CPUS</integer>
            <key>Flags</key>
            <array/>
        </dict>
        <key>Memory</key>
        <dict>
            <key>Size</key>
            <integer>$VM_MEMORY</integer>
        </dict>
        <key>Target</key>
        <string>virt</string>
    </dict>
    <key>Drives</key>
    <array>
        <dict>
            <key>Identifier</key>
            <string>drive0</string>
            <key>ImagePath</key>
            <string>disk.qcow2</string>
            <key>ImageType</key>
            <string>Disk</string>
            <key>Interface</key>
            <string>virtio</string>
            <key>Removable</key>
            <false/>
        </dict>
        <dict>
            <key>Identifier</key>
            <string>drive1</string>
            <key>ImagePath</key>
            <string>$SCRIPT_DIR/$DEBIAN_ISO</string>
            <key>ImageType</key>
            <string>CD</string>
            <key>Interface</key>
            <string>ide</string>
            <key>Removable</key>
            <true/>
        </dict>
    </array>
    <key>Networks</key>
    <array>
        <dict>
            <key>Hardware</key>
            <string>virtio-net-pci</string>
            <key>Mode</key>
            <string>shared</string>
        </dict>
    </array>
    <key>USB</key>
    <array>
        <dict>
            <key>Hardware</key>
            <string>usb-ehci</string>
        </dict>
        <dict>
            <key>Hardware</key>
            <string>usb-xhci</string>
        </dict>
    </array>
    <key>Display</key>
    <dict>
        <key>Hardware</key>
        <string>virtio-gpu-pci</string>
    </dict>
</dict>
</plist>
EOF

    # Create empty disk image
    qemu-img create -f qcow2 "$utm_file/disk.qcow2" "${VM_DISK_SIZE}M"
    
    # Import the VM into UTM
    open "$utm_file"
    
    log_success "UTM VM configuration created. Please check UTM app."
    log_info "The VM should appear in UTM. You may need to adjust settings manually."
}

install_vm() {
    log_info "Installing EASE VM in UTM..."
    
    check_requirements
    download_debian_iso
    
    # Remove existing VM if it exists
    if utm_vm_exists; then
        if [[ "$FORCE" != "true" ]]; then
            read -p "VM '$VM_NAME' already exists. Remove it? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_error "Installation cancelled"
                exit 1
            fi
        fi
        log_info "Removing existing VM..."
        utm_delete_vm 2>/dev/null || true
        sleep 2
    fi
    
    # Create new VM
    create_utm_vm
    
    log_success "EASE VM created in UTM!"
    
    echo
    log_info "Next steps:"
    echo "1. Check UTM app - the VM should be imported"
    echo "2. Start VM: $0 start"
    echo "3. Install Debian (follow the installer)"
    echo "4. After OS installation: $0 provision"
    echo "5. Configure USB adapters in UTM interface"
}

start_vm() {
    log_info "Starting EASE VM..."
    
    if ! utm_vm_exists; then
        log_error "VM '$VM_NAME' not found in UTM. Run '$0 install' first."
        exit 1
    fi
    
    if utm_vm_running; then
        log_warning "VM is already running"
        return 0
    fi
    
    # Start UTM if not running
    if ! pgrep -q "UTM"; then
        log_info "Starting UTM app..."
        open -a UTM
        sleep 3
    fi
    
    utm_start_vm
    sleep 3
    
    if utm_vm_running; then
        log_success "EASE VM started"
        log_info "Connect Wi-Fi adapters via UTM's USB menu"
    else
        log_error "Failed to start VM"
        exit 1
    fi
}

stop_vm() {
    log_info "Stopping EASE VM..."
    
    if ! utm_vm_exists; then
        log_warning "VM '$VM_NAME' not found"
        return 0
    fi
    
    if ! utm_vm_running; then
        log_warning "VM is not running"
        return 0
    fi
    
    utm_stop_vm
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
    
    if ! utm_vm_exists; then
        echo "Status: Not installed"
        echo "Run '$0 install' to create the VM"
        return 0
    fi
    
    echo "VM Name: $VM_NAME"
    
    if utm_vm_running; then
        echo "Status: Running ✅"
        echo "UTM App: Running"
        
        # Try to get VM IP (this is tricky with UTM)
        log_info "To connect: $0 ssh"
        
    else
        echo "Status: Stopped ❌"
        echo "UTM App: $(pgrep -q "UTM" && echo "Running" || echo "Not running")"
    fi
}

provision_vm() {
    log_info "Provisioning EASE environment..."
    
    if ! utm_vm_running; then
        log_error "VM is not running. Start it first with: $0 start"
        exit 1
    fi
    
    log_warning "Automatic provisioning via script is limited with UTM."
    log_info "Please manually SSH into the VM and run the following commands:"
    
    cat << 'EOF'

# SSH into your VM first, then run these commands:

sudo apt update && sudo apt upgrade -y

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
    bc \
    firmware-realtek \
    firmware-atheros \
    firmware-ralink \
    firmware-misc-nonfree

# Install WiFi Explorer sensor
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

sudo systemctl daemon-reload
sudo systemctl enable wifiexplorer-sensor
sudo systemctl start wifiexplorer-sensor

EOF

    log_info "Use '$0 ssh' to connect to the VM and run these commands."
}

configure_usb() {
    case "$1" in
        --list)
            log_info "To see and connect USB devices in UTM:"
            echo "1. Select your VM in UTM"
            echo "2. Click the USB icon in the toolbar"
            echo "3. Available devices will be listed"
            echo "4. Click on your Wi-Fi adapter to connect it"
            echo
            log_info "UTM USB connection is done through the GUI interface."
            ;;
        --connect)
            log_info "To connect USB devices:"
            echo "1. Open UTM"
            echo "2. Select EASE-VM"  
            echo "3. Click USB icon in toolbar"
            echo "4. Select your Wi-Fi adapter"
            ;;
        --disconnect)
            log_info "To disconnect USB devices:"
            echo "1. Open UTM"
            echo "2. Select EASE-VM"
            echo "3. Click USB icon in toolbar" 
            echo "4. Uncheck your Wi-Fi adapter"
            ;;
        *)
            log_info "USB Configuration for UTM"
            echo
            echo "🔌 To use Wi-Fi adapters with EASE:"
            echo "1. Plug in your USB Wi-Fi adapter"
            echo "2. In UTM, select the EASE-VM"
            echo "3. Click the USB icon in the toolbar"
            echo "4. Check your Wi-Fi adapter to connect it to the VM"
            echo
            echo "📱 Supported adapters:"
            echo "  • ASUS USB-N53"
            echo "  • ALFA AWUS051NH, AWUS036NHA"
            echo "  • COMFAST CF-912AC"
            echo "  • Edimax EW-7822UAC, EW-7833UAC"
            echo "  • TP-Link compatible chipsets"
            echo
            echo "Use '$0 usb --connect' for connection help"
            echo "Use '$0 usb --list' for device listing help"
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
    
    if utm_vm_exists; then
        utm_delete_vm
        log_success "EASE VM removed from UTM"
    else
        log_warning "VM not found in UTM"
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
    
    if ! utm_vm_exists; then
        log_error "VM not found. Run '$0 install' first."
        exit 1
    fi
    
    log_warning "VM configuration updates must be done manually in UTM:"
    echo "1. Open UTM"
    echo "2. Select EASE-VM"
    echo "3. Click 'Edit' button"
    echo "4. Adjust System settings (Memory: ${VM_MEMORY}MB, CPUs: $VM_CPUS)"
    echo "5. Save changes"
    
    log_info "Alternatively, recreate VM with new settings:"
    echo "$0 remove --force && $0 install --memory $VM_MEMORY --cpus $VM_CPUS"
}

show_logs() {
    log_info "EASE VM Logs:"
    
    if ! utm_vm_running; then
        log_error "VM is not running"
        exit 1
    fi
    
    log_warning "Log viewing requires SSH access to the VM."
    log_info "Use '$0 ssh' to connect, then run:"
    echo
    echo "# Check WiFi Explorer Sensor status"
    echo "sudo systemctl status wifiexplorer-sensor"
    echo
    echo "# View sensor logs"
    echo "sudo journalctl -u wifiexplorer-sensor -f"
    echo
    echo "# Check network interfaces"
    echo "ip link show"
}

test_adapters() {
    log_info "Testing Wi-Fi adapter functionality..."
    
    if ! utm_vm_running; then
        log_error "VM is not running. Start it first with: $0 start"
        exit 1
    fi
    
    log_warning "Adapter testing requires SSH access to the VM."
    log_info "Use '$0 ssh' to connect, then run:"
    echo
    echo "# List network interfaces"
    echo "ip link show"
    echo
    echo "# Check for wireless interfaces"
    echo "iwconfig"
    echo
    echo "# Test wireless capabilities"
    echo "iw list"
    echo
    echo "# Check WiFi Explorer sensor"
    echo "sudo systemctl status wifiexplorer-sensor"
}

backup_vm() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        backup_file="ease-vm-backup-$(date +%Y%m%d-%H%M%S).utm"
    fi
    
    log_info "Backing up EASE VM to: $backup_file"
    
    if ! utm_vm_exists; then
        log_error "VM not found. Nothing to backup."
        exit 1
    fi
    
    if utm_vm_running; then
        log_warning "VM is running. Stop it first for a clean backup."
        read -p "Stop VM and continue with backup? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            stop_vm
            sleep 3
        else
            log_error "Backup cancelled"
            exit 1
        fi
    fi
    
    # UTM VMs are stored in ~/Library/Containers/com.utmapp.UTM/Data/Documents/
    local utm_vm_path="$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/${VM_NAME}.utm"
    
    if [[ -d "$utm_vm_path" ]]; then
        log_info "Creating backup..."
        cp -R "$utm_vm_path" "$backup_file"
        log_success "Backup created: $backup_file"
        
        # Get backup size
        local backup_size=$(du -sh "$backup_file" | cut -f1)
        log_info "Backup size: $backup_size"
    else
        log_error "VM directory not found at: $utm_vm_path"
        exit 1
    fi
}

restore_vm() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        log_error "Please specify backup file: $0 restore <backup_file.utm>"
        exit 1
    fi
    
    if [[ ! -d "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log_info "Restoring EASE VM from: $backup_file"
    
    # Stop and remove existing VM if it exists
    if utm_vm_exists; then
        if [[ "$FORCE" != "true" ]]; then
            read -p "Existing VM will be replaced. Continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_error "Restore cancelled"
                exit 1
            fi
        fi
        
        if utm_vm_running; then
            stop_vm
            sleep 2
        fi
        
        utm_delete_vm
        sleep 2
    fi
    
    # Copy backup to UTM directory
    local utm_documents="$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/"
    mkdir -p "$utm_documents"
    
    log_info "Copying backup to UTM directory..."
    cp -R "$backup_file" "$utm_documents/${VM_NAME}.utm"
    
    # Refresh UTM (reopen it)
    if pgrep -q "UTM"; then
        osascript -e 'quit app "UTM"'
        sleep 2
    fi
    open -a UTM
    
    log_success "VM restored successfully!"
    log_info "Check UTM app - the restored VM should appear"
}

ssh_vm() {
    log_info "Connecting to EASE VM via SSH..."
    
    if ! utm_vm_running; then
        log_error "VM is not running. Start it first with: $0 start"
        exit 1
    fi
    
    log_warning "SSH connection requires:"
    echo "1. VM must have SSH server installed and running"
    echo "2. You need to know the VM's IP address"
    echo "3. You need the username/password you set during installation"
    echo
    
    log_info "To find the VM's IP address:"
    echo "1. In UTM, select your VM"
    echo "2. Look at the bottom status bar for network info"
    echo "3. Or log into the VM console and run: ip addr show"
    echo
    
    read -p "Enter VM IP address (or press Enter to skip): " vm_ip
    
    if [[ -n "$vm_ip" ]]; then
        read -p "Enter username: " username
        log_info "Connecting to $username@$vm_ip..."
        ssh "$username@$vm_ip"
    else
        log_info "SSH connection skipped. Use 'ssh username@vm_ip' manually."
    fi
}

optimize_vm() {
    log_info "Optimizing VM performance..."
    
    if ! utm_vm_exists; then
        log_error "VM not found. Run '$0 install' first."
        exit 1
    fi
    
    log_info "Manual optimization steps for UTM:"
    echo
    echo "1. Open UTM and select EASE-VM"
    echo "2. Click 'Edit'"
    echo "3. In System tab:"
    echo "   - Enable 'Force Multicore'"
    echo "   - Set CPU cores to $VM_CPUS or more"
    echo "   - Set Memory to ${VM_MEMORY}MB or more"
    echo "4. In QEMU tab:"
    echo "   - Add QEMU arguments: -enable-kvm (if supported)"
    echo "5. In Network tab:"
    echo "   - Consider using 'Bridged' instead of 'Shared'"
    echo "6. Save settings and restart VM"
    echo
    
    if utm_vm_running; then
        log_info "Restart VM to apply optimizations:"
        echo "$0 restart"
    fi
    
    log_success "Optimization guide provided"
}

# Parse command line arguments
COMMAND=""
FORCE=false
VERBOSE=false
ACCELERATION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        install|start|stop|restart|status|provision|usb|remove|update|logs|test|backup|restore|ssh|optimize)
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
            # UTM doesn't have a direct headless mode like Parallels
            log_warning "UTM doesn't support true headless mode"
            shift
            ;;
        --acceleration)
            ACCELERATION=true
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
        --list|--connect|--disconnect)
            # USB subcommands
            configure_usb "$1"
            exit 0
            ;;
        *)
            # Handle backup/restore file arguments
            if [[ "$COMMAND" == "backup" || "$COMMAND" == "restore" ]]; then
                BACKUP_FILE="$1"
                shift
            else
                log_error "Unknown option: $1"
                show_help
                exit 1
            fi
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
    backup)
        backup_vm "$BACKUP_FILE"
        ;;
    restore)
        restore_vm "$BACKUP_FILE"
        ;;
    ssh)
        ssh_vm
        ;;
    optimize)
        optimize_vm
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
