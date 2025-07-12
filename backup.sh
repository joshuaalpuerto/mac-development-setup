#!/bin/bash

###
# Section for helpers and colors
##

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Print section header
print_header() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

# Print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Print info message
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}


# Ask for confirmation
confirm() {
    read -p "$1 (Y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]
}

###
# End of helpers and colors
##

# Welcome message
clear
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}  Mac Development Backup Script  ${NC}"
echo -e "${GREEN}=================================${NC}"
echo
echo "This script will help you backup your Mac development settings."
echo "You can choose which components to backup."
echo

# Security warning
echo -e "${RED}==================================================${NC}"
echo -e "${RED}  SECURITY WARNING - READ BEFORE PROCEEDING      ${NC}"
echo -e "${RED}==================================================${NC}"
echo -e "${YELLOW}This script will backup your Mac settings and configurations.${NC}"
echo -e "${YELLOW}Some of these settings may contain sensitive information.${NC}"
echo -e "${YELLOW}NEVER commit sensitive information to a public repository:${NC}"
echo -e "${RED}- API tokens or passwords${NC}"
echo -e "${RED}- Personal credentials${NC}"
echo -e "${RED}- Database connection strings${NC}"
echo

if ! confirm "I understand the security risks and will not commit sensitive information to a public repository"; then
    print_error "Backup aborted due to security concerns"
    exit 1
fi

echo
echo

# Create backup directory && clear it for fresh copy
backup_dir="backups"
backup_iterm_dir="$backup_dir/iterm2"
backup_ohmyzsh_dir="$backup_dir/ohmyzsh"
backup_homebrew_dir="$backup_dir/homebrew"
backup_vscode_dir="$backup_dir/vscode"
backup_git_dir="$backup_dir/git"
backup_node_dir="$backup_dir/node"
backup_python_dir="$backup_dir/python"
backup_docker_dir="$backup_dir/docker"
backup_database_dir="$backup_dir/database"
backup_macos_dir="$backup_dir/macos"

## clear backup directory
rm -rf "$backup_dir"
mkdir -p "$backup_dir"

mkdir -p "$backup_iterm_dir"
mkdir -p "$backup_ohmyzsh_dir"
mkdir -p "$backup_homebrew_dir"
mkdir -p "$backup_vscode_dir"
mkdir -p "$backup_git_dir"
mkdir -p "$backup_node_dir"
mkdir -p "$backup_python_dir"
mkdir -p "$backup_docker_dir"
mkdir -p "$backup_database_dir"
mkdir -p "$backup_macos_dir"  

## END Folder settings

### Back up iterm2 configuration
if confirm "Backup iTerm2 configuration?"; then
    print_header "Backing Up iTerm2 Configuration"

    # Check if iTerm2 is installed
    iterm2_prefs="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    iterm2_app_support="$HOME/Library/Application Support/iTerm2"

    if [ ! -f "$iterm2_prefs" ] && [ ! -d "$iterm2_app_support" ]; then
        print_error "iTerm2 does not appear to be installed or configured."
        exit 1
    fi

    # Backup main preferences file
    if [ -f "$iterm2_prefs" ]; then
        print_info "Backing up iTerm2 main preferences..."
        cp "$iterm2_prefs" "$backup_iterm_dir/com.googlecode.iterm2.plist"
        print_success "Backed up main iTerm2 preferences"
    else
        print_info "Main iTerm2 preferences file not found"
    fi

    # Backup Application Support directory
    if [ -d "$iterm2_app_support" ]; then
        print_info "Backing up iTerm2 application support files..."
        
        # Create subdirectories
        mkdir -p "$backup_iterm_dir/AppSupport"
        
        # Copy the entire iTerm2 app support directory
        cp -R "$iterm2_app_support/"* "$backup_iterm_dir/AppSupport/" 2>/dev/null || true
        print_success "Backed up iTerm2 application support files"
        
        # List what was backed up
        if [ -d "$backup_iterm_dir/AppSupport" ]; then
            print_info "Backed up files include:"
            ls -la "$backup_iterm_dir/AppSupport/" | while read line; do
                echo "  $line"
            done
        fi
    else
        print_info "iTerm2 Application Support directory not found"
    fi

    # Export iTerm2 preferences in a more portable format
    if [ -f "$iterm2_prefs" ]; then
        print_info "Exporting iTerm2 preferences to JSON format..."
        
        # Convert plist to JSON for easier reading/editing
        if command -v plutil >/dev/null 2>&1; then
            plutil -convert json "$iterm2_prefs" -o "$backup_iterm_dir/preferences.json" 2>/dev/null || true
            print_success "Exported preferences to JSON format"
        else
            print_info "plutil not available, skipping JSON export"
        fi
    fi

    # Backup specific iTerm2 components if they exist
    print_info "Backing up specific iTerm2 components..."

    # Color schemes
    if [ -d "$iterm2_app_support/ColorPresets" ]; then
        mkdir -p "$backup_iterm_dir/ColorPresets"
        cp -R "$iterm2_app_support/ColorPresets/"* "$backup_iterm_dir/ColorPresets/" 2>/dev/null || true
        print_success "Backed up color schemes"
    fi

    # Dynamic profiles
    if [ -d "$iterm2_app_support/DynamicProfiles" ]; then
        mkdir -p "$backup_iterm_dir/DynamicProfiles"
        cp -R "$iterm2_app_support/DynamicProfiles/"* "$backup_iterm_dir/DynamicProfiles/" 2>/dev/null || true
        print_success "Backed up dynamic profiles"
    fi

    # Scripts
    if [ -d "$iterm2_app_support/Scripts" ]; then
        mkdir -p "$backup_iterm_dir/Scripts"
        cp -R "$iterm2_app_support/Scripts/"* "$backup_iterm_dir/Scripts/" 2>/dev/null || true
        print_success "Backed up scripts"
    fi

    # Key mappings
    if [ -f "$iterm2_app_support/AppSupport/KeyBindings.itermkeymap" ]; then
        cp "$iterm2_app_support/KeyBindings.itermkeymap" "$backup_iterm_dir/" 2>/dev/null || true
        print_success "Backed up key mappings"
    fi

    # Create a quick profile export as well (if iTerm2 is running)
    if pgrep -x "iTerm2" > /dev/null; then
        print_info "iTerm2 is running. You can also export profiles manually:"
        echo "  1. Open iTerm2 → Preferences → Profiles"
        echo "  2. Select your profiles"
        echo "  3. Click 'Other Actions' → 'Save Profile as JSON'"
        echo "  4. Save to backups/iterm2/manual_export/"
        mkdir -p "$backup_iterm_dir/manual_export"
    fi

    print_success "iTerm2 configuration backup completed!"
    print_info "Backup saved to: $backup_iterm_dir/"
    echo
    print_info "📁 Backup includes:"
    echo "  • Main preferences file"
    echo "  • All profiles and color schemes"
    echo "  • Custom key bindings"
    echo "  • Scripts and automations"
    echo "  • Complete application settings"
    echo
    print_info "🔄 To restore on a new machine:"
    echo "  cd $backup_iterm_dir && ./restore_iterm2.sh" 

fi
### End of Iterm 2 backup

echo
echo

### Back up Oh My Zsh configuration
if confirm "Backup Oh My Zsh configuration? (themes, plugins, etc.)"; then
    print_header "Backing Up Oh My Zsh Configuration"

    # Create necessary directories
    mkdir -p backups/ohmyzsh/custom/themes
    mkdir -p backups/ohmyzsh/custom/plugins

    # Backup .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$backup_ohmyzsh_dir/"
        print_success "Backed up .zshrc"
    else
        print_error ".zshrc not found"
    fi

    # Backup .p10k.zsh if it exists
    if [ -f "$HOME/.p10k.zsh" ]; then
        cp "$HOME/.p10k.zsh" "$backup_ohmyzsh_dir/"
        print_success "Backed up .p10k.zsh"
    else
        print_info ".p10k.zsh not found, skipping"
    fi

    # Backup custom themes
    print_info "Backing up custom themes..."
    if [ -d "$HOME/.oh-my-zsh/custom/themes" ]; then
        # Only copy custom themes (not the default ones or powerlevel10k which will be installed fresh)
        find "$HOME/.oh-my-zsh/custom/themes" -maxdepth 1 -type f -not -path "*/\.*" -exec cp {} "$backup_ohmyzsh_dir/custom/themes/" \;
        
        # Check if there are any custom themes that are directories (except powerlevel10k which we'll install fresh)
        for theme_dir in "$HOME/.oh-my-zsh/custom/themes"/*/; do
            theme_name=$(basename "$theme_dir")
            if [ "$theme_name" != "powerlevel10k" ] && [ "$theme_name" != "." ] && [ "$theme_name" != ".." ]; then
                mkdir -p "$backup_ohmyzsh_dir/custom/themes/$theme_name"
                cp -R "$theme_dir"* "$backup_ohmyzsh_dir/custom/themes/$theme_name/"
                print_success "Backed up custom theme: $theme_name"
            fi
        done
    else
        print_info "No custom themes directory found, skipping"
    fi

    # Backup custom plugins
    print_info "Backing up custom plugins..."
    if [ -d "$HOME/.oh-my-zsh/custom/plugins" ]; then
        # Skip standard plugins that will be installed fresh (zsh-syntax-highlighting, zsh-autosuggestions)
        for plugin_dir in "$HOME/.oh-my-zsh/custom/plugins"/*/; do
            plugin_name=$(basename "$plugin_dir")
            if [ "$plugin_name" != "zsh-syntax-highlighting" ] && [ "$plugin_name" != "zsh-autosuggestions" ] && [ "$plugin_name" != "." ] && [ "$plugin_name" != ".." ]; then
                mkdir -p "$backup_ohmyzsh_dir/custom/plugins/$plugin_name"
                cp -R "$plugin_dir"* "$backup_ohmyzsh_dir/custom/plugins/$plugin_name/"
                print_success "Backed up custom plugin: $plugin_name"
            fi
        done
    else
        print_info "No custom plugins directory found, skipping"
    fi

    # Backup custom aliases or functions if they exist
    if [ -d "$HOME/.oh-my-zsh/custom" ]; then
        mkdir -p "$backup_ohmyzsh_dir/custom"
        find "$HOME/.oh-my-zsh/custom" -maxdepth 1 -type f -name "*.zsh" -exec cp {} "$backup_ohmyzsh_dir/custom/" \;
        for file in "$backup_ohmyzsh_dir/custom/*.zsh"; do
            if [ -f "$file" ]; then
                print_success "Backed up custom file: $(basename "$file")"
            fi
        done
    fi

    print_success "Oh My Zsh configuration backup completed!"
    print_info "Your Oh My Zsh configuration has been backed up to the $backup_ohmyzsh_dir directory."
    print_info "You can now commit these files to your Git repository." 
fi
### End of ZSH backup

echo
echo

### Back up Homebrew installed packages list
if confirm "Backup Homebrew installed packages list?"; then
    print_header "Backing up Homebrew Packages"

    # Check if Homebrew is installed
    if ! command_exists "brew"; then
        print_error "Homebrew is not installed. Skipping Homebrew backup."
        exit 0
    fi

    # Backup Homebrew packages
    print_info "Exporting list of installed Homebrew packages..."

    # Export all installed formulae
    brew leaves > "$backup_homebrew_dir/brew_leaves.txt"
    print_success "Exported list of top-level formulae to brew_leaves.txt"

    # Export all installed casks
    brew list --cask > "$backup_homebrew_dir/brew_casks.txt"
    print_success "Exported list of installed casks to brew_casks.txt"

    # Export all taps
    brew tap > "$backup_homebrew_dir/brew_taps.txt"
    print_success "Exported list of taps to brew_taps.txt"

    # Create a complete Brewfile
    print_info "Creating Brewfile with all installed packages..."
    brew bundle dump --file="$backup_homebrew_dir/Brewfile"
    print_success "Created Brewfile with all installed packages"

    print_success "Homebrew backup completed!" 
fi
### End of Homebrew backup

echo
echo

### Back up Git global configuration
if confirm "Backup Git global configuration?"; then
    print_header "Backing up Git global configuration"

    # Backup Git global configuration
    if [ -f "$HOME/.gitconfig" ]; then
        cp "$HOME/.gitconfig" "$backup_git_dir/"
        print_success "Git global config backed up"
    fi

    # Backup Git global ignore file
    if [ -f "$HOME/.gitignore_global" ]; then
        cp "$HOME/.gitignore_global" "$backup_git_dir/"
        print_success "Git global ignore file backed up"
    fi

    print_success "Git global configuration backup completed!" 
fi
### End of Git backup

echo
echo

### Back up VSCode settings and extensions
if confirm "Backup VSCode settings and extensions?"; then
    print_header "Backing up VSCode settings and extensions"

    # Backup VSCode settings
    if [ -d "$HOME/Library/Application Support/Code/User" ]; then
        cp "$HOME/Library/Application Support/Code/User/settings.json" "$backup_vscode_dir/" 2>/dev/null || true
        print_success "VSCode settings backed up"
    else
        print_info "VSCode user settings not found, skipping"
    fi

    # Backup VSCode keybindings
    if [ -f "$HOME/Library/Application Support/Code/User/keybindings.json" ]; then
        cp "$HOME/Library/Application Support/Code/User/keybindings.json" "$backup_vscode_dir/" 2>/dev/null || true
        print_success "VSCode keybindings backed up"
    else
        print_info "VSCode keybindings not found, skipping"
    fi

    # Backup VSCode snippets
    if [ -d "$HOME/Library/Application Support/Code/User/snippets" ]; then
        cp "$HOME/Library/Application Support/Code/User/snippets/"* "$backup_vscode_dir/snippets/" 2>/dev/null || true
        print_success "VSCode snippets backed up"
    else
        print_info "VSCode snippets not found, skipping"
    fi

    # Export list of installed extensions
    if command -v code >/dev/null 2>&1; then
        code --list-extensions > "$backup_vscode_dir/extensions.txt"
        print_success "VSCode extensions list backed up"
    else
        print_info "VSCode CLI not found, skipping extensions backup"
    fi

    print_success "VSCode settings and extensions backup completed!" 
fi
### End of VSCode backup

echo
echo

### Back up npm global packages
if confirm "Backup npm global packages?"; then
    print_header "Backing up npm global packages"

    if command -v npm >/dev/null 2>&1; then
        npm list -g --depth=0 > "$backup_node_dir/npm_global_packages.txt"
        print_success "npm global packages list backed up"
    else
        print_info "npm not found, skipping"
    fi

    print_success "npm global packages backup completed!" 
fi
### End of npm global packages backup

echo
echo

### Back up pnpm global packages
if confirm "Backup pnpm global packages?"; then
    print_header "Backing up pnpm global packages"

    if command -v pnpm >/dev/null 2>&1; then
        pnpm list -g > "$backup_node_dir/pnpm_global_packages.txt" 2>/dev/null || true
        print_success "pnpm global packages list backed up"
    else
        print_info "pnpm not found, skipping"
    fi

    print_success "pnpm global packages backup completed!" 
fi
### End of pnpm global packages backup

echo
echo

# I don't think we need global packages for python
# That's the purpose of having environment is to prevent global packages from being installed
# ### Back up Python packages
# if confirm "Backup Python packages?"; then
#     print_header "Backing up Python packages"

#     # Backup Python packages
#     print_info "Backing up Python packages..."
#     if command -v pip >/dev/null 2>&1; then
#         pip list > "$backup_python_dir/pip_packages.txt"
#         print_success "pip packages list backed up"
#     else
#         print_info "pip not found, skipping"
#     fi

#     # Backup pyenv Python versions
#     print_info "Backing up pyenv Python versions..."
#     if command -v pyenv >/dev/null 2>&1; then
#         pyenv versions > "$backup_python_dir/pyenv_versions.txt"
#         print_success "pyenv versions backed up"
#     else
#         print_info "pyenv not found, skipping"
#     fi

#     # Backup conda python versions
#     print_info "Backing up conda python versions..."
#     if command -v conda >/dev/null 2>&1; then
#         conda list > "$backup_python_dir/conda_python_versions.txt"
#         print_success "conda python versions backed up"
#     else
#         print_info "conda not found, skipping"
#     fi

#     print_success "Python packages backup completed!" 
# fi
# ### End of Python backup

echo
echo

### Back up nvm Node.js versions
if confirm "Backup nvm Node.js versions?"; then
    print_header "Backing up nvm Node.js versions"

    # Backup nvm Node.js versions
    print_info "Backing up nvm Node.js versions..."
    if [ -d "$HOME/.nvm" ]; then
        if command -v nvm >/dev/null 2>&1; then
            nvm ls > "$backup_node_dir/nvm_versions.txt" 2>/dev/null || true
            print_success "nvm versions backed up"
        else
            ls -la "$HOME/.nvm/versions/node" > "$backup_node_dir/nvm_versions.txt" 2>/dev/null || true
            print_success "nvm versions directory listing backed up"
        fi
    fi

    print_success "nvm Node.js versions backup completed!" 
fi
### End of nvm Node.js backup

echo
echo

### Back up shell configuration files (Not sure if this is needed)
# We might need to configure the bashrc to put nvm 
#if confirm "Backup shell configuration files?"; then
#    print_header "Backing up shell configuration files"
#
#    # Backup shell aliases and functions
#    print_info "Backing up shell configuration files..."
#    for file in ".zshrc" ".bashrc" ".bash_profile" ".profile" ".zprofile"; do
#        if [ -f "$HOME/$file" ]; then
#            cp "$HOME/$file" "$backup_dir/shell/"
#            print_success "Backed up $file"
#        fi
#    done
#fi

echo
echo

### Back up macOS preferences
if confirm "Backup macOS preferences?"; then
    print_header "Backing up macOS preferences"

    # Backup macOS preferences
    print_info "Backing up macOS preferences..."

    # Dock: size, position, auto-hide, app arrangement - saves hours of customization
    defaults export com.apple.dock "$backup_macos_dir/dock.plist" 2>/dev/null || true
    print_success "Dock preferences backed up"

    # Finder: view style, hidden files, extensions - critical for dev workflow
    defaults export com.apple.finder "$backup_macos_dir/finder.plist" 2>/dev/null || true
    print_success "Finder preferences backed up"

    # Terminal: colors, fonts, profiles - maintains dev environment appearance
    defaults export com.apple.Terminal "$backup_macos_dir/terminal.plist" 2>/dev/null || true
    print_success "Terminal preferences backed up"

    # Mouse/Trackpad: speed, gestures, click behavior - highly personal comfort settings
    defaults export com.apple.driver.AppleBluetoothMultitouch.mouse "$backup_macos_dir/mouse.plist" 2>/dev/null || true
    defaults export com.apple.driver.AppleBluetoothMultitouch.trackpad "$backup_macos_dir/trackpad.plist" 2>/dev/null || true
    defaults export com.apple.AppleMultitouchTrackpad "$backup_macos_dir/apple_trackpad.plist" 2>/dev/null || true
    print_success "Mouse and trackpad preferences backed up"

    # Keyboard: repeat rate, function keys, text shortcuts - affects typing efficiency
    defaults export com.apple.keyboard "$backup_macos_dir/keyboard.plist" 2>/dev/null || true
    defaults export com.apple.HIToolbox "$backup_macos_dir/input_sources.plist" 2>/dev/null || true
    print_success "Keyboard preferences backed up"

    # Display: resolution, color profiles, Night Shift - visual comfort and accuracy
    defaults export com.apple.displays "$backup_macos_dir/displays.plist" 2>/dev/null || true
    print_success "Display preferences backed up"

    # Sound: volume, alerts, device preferences - prevents jarring audio surprises
    defaults export com.apple.sound "$backup_macos_dir/sound.plist" 2>/dev/null || true
    print_success "Sound preferences backed up"

    # Accessibility: zoom, contrast, motor assistance - essential for specific needs
    defaults export com.apple.universalaccess "$backup_macos_dir/accessibility.plist" 2>/dev/null || true
    print_success "Accessibility preferences backed up"

    # System Preferences: app layout and organization - familiar interface
    defaults export com.apple.systempreferences "$backup_macos_dir/systempreferences.plist" 2>/dev/null || true
    print_success "System preferences backed up"

    # Global settings: language, region, UI behavior - affects entire system (MOST IMPORTANT)
    mkdir -p "$backup_macos_dir/global_domain"
    defaults export -g "$backup_macos_dir/global_domain/global_domain.plist" 2>/dev/null || true
    print_success "Global system preferences backed up"

    # Backup hosts file
    if [ -f "/etc/hosts" ]; then
        sudo cp "/etc/hosts" "$backup_macos_dir/" 2>/dev/null || true
        print_success "Hosts file backed up"
    fi
    
    print_success "macOS preferences backup completed!"
fi

echo
echo

### Back up database configurations
if confirm "Backup database configurations?"; then
    print_header "Backing up database configurations"

    # Backup database configurations
    print_info "Backing up database configurations..."
    mkdir -p "$backup_databases_dir"

    # Backup MySQL configuration
    if [ -f "$HOME/.my.cnf" ]; then
        cp "$HOME/.my.cnf" "$backup_databases_dir/"
        print_success "MySQL configuration backed up"
    fi

    # Backup PostgreSQL configuration
    if [ -f "$HOME/.psqlrc" ]; then
        cp "$HOME/.psqlrc" "$backup_databases_dir/"
        print_success "PostgreSQL configuration backed up"
    fi

    # Backup MongoDB configuration
    if [ -f "$HOME/.mongorc.js" ]; then
        cp "$HOME/.mongorc.js" "$backup_databases_dir/"
        print_success "MongoDB configuration backed up"
    fi

    print_success "Database configurations backup completed!" 
fi
### End of database configurations backup

echo
echo

### Back up Docker configurations
if confirm "Backup Docker configurations?"; then
    print_header "Backing up Docker configurations"

    # Backup Docker configurations
    print_info "Backing up Docker configurations..."
    mkdir -p "$backup_docker_dir"

    # Backup Docker configuration
    if [ -d "$HOME/.docker" ]; then
        cp "$HOME/.docker/config.json" "$backup_docker_dir/" 2>/dev/null || true
        print_success "Docker configuration backed up"
    fi

    print_success "Docker configurations backup completed!" 
fi
### End of Docker configurations backup

echo
echo

# Backup application licenses
print_info "Note: Application licenses should be backed up manually."
print_info "Common locations include:"
print_info "- Email (search for 'license' or 'purchase')"
print_info "- Documents folder"
print_info "- Application-specific folders in ~/Library/Application Support/"

# Create a README file with instructions
cat > "$backup_dir/README.md" << 'EOL'
# Mac Backup

This directory contains backed up settings and configurations from your Mac.

## Contents

- `git/`: Git global configuration
- `vscode/`: Visual Studio Code settings and extensions list
- `brew/`: Homebrew packages, casks, and taps
- `npm_global_packages.txt`: List of globally installed npm packages
- `pnpm_global_packages.txt`: List of globally installed pnpm packages
- `python/`: Python packages
- `node/`: Node.js versions
- `shell/`: Shell configuration files
- `macos/`: macOS preferences including:
  - Dock, Finder, Terminal settings
  - Mouse and trackpad settings
  - Keyboard settings and input sources
  - Display settings
  - Sound settings
  - Accessibility options
  - Global system preferences
- `databases/`: Database client configurations
- `docker/`: Docker configuration

## Restoring

Most of these files can be restored by copying them to their original locations on your new Mac.
The setup scripts in this repository will handle many of these automatically.

For manual restoration:
- Git: Copy to `~/`
- VSCode: Copy to `~/Library/Application Support/Code/User/`
- Homebrew: Use `brew bundle install --file=Brewfile`
- npm: Install packages listed in npm_global_packages.txt
- pnpm: Install packages listed in pnpm_global_packages.txt
- node: Install Node.js versions listed in nvm_versions.txt
- shell: Copy to `~/`
- macos: Import preferences with `defaults import domain path/to/file.plist`
  - For example: `defaults import com.apple.dock path/to/dock.plist`
  - For mouse settings: `defaults import com.apple.driver.AppleBluetoothMultitouch.mouse path/to/mouse.plist`
  - For trackpad settings: `defaults import com.apple.driver.AppleBluetoothMultitouch.trackpad path/to/trackpad.plist`
  - For global settings: `defaults import -g path/to/global_domain.plist`
  - Note: You may need to restart or log out/in for some settings to take effect
- databases: Copy to `~/`
- docker: Copy to `~/.docker/`

## Security Warning

Some of these files may contain sensitive information. Review them carefully before committing to a public repository.
Consider using a private repository or encrypting sensitive files.
EOL

# Create timestamps for the backups
timestamp=$(date +"%Y%m%d_%H%M%S")
backup_archive_name="backup_${timestamp}.tar.gz"

# Create public backup archive
echo "Creating public backup archive..."
tar -czf "$backup_dir/$backup_archive_name" -C "$backup_dir" .
print_success "Created backup archive: $backup_dir/$backup_archive_name"

print_success "Mac settings backup completed!"
print_info "Your Mac settings have been backed up to the $backup_dir directory."
print_info "You can copy the archive to your drive or cloud storage."