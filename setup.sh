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
echo -e "${GREEN}  Mac Development Setup Script   ${NC}"
echo -e "${GREEN}=================================${NC}"
echo
echo "This script will help you set up your new Mac for development."
echo "You can choose which components to install."
echo "The script will prompt you for necessary information during the setup process."
echo

# Define backup directory
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

# === CORE DEVELOPMENT TOOLS ===
print_header "CORE DEVELOPMENT TOOLS"
echo "These are essential tools for development:"

if confirm "Set up Homebrew and install it's packages from backup? (package manager for macOS)"; then
    # Install Homebrew if not already installed
    print_header "Installing Homebrew"

    if command_exists brew; then
        print_success "Homebrew is already installed."
        
        # Update Homebrew
        print_info "Updating Homebrew..."
        brew update
        print_success "Homebrew updated successfully."
    else
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == 'arm64' ]]; then
            print_info "Configuring Homebrew for Apple Silicon..."
            
            # Check which shell is being used
            if [[ $SHELL == *"zsh"* ]]; then
                if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile; then
                    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            elif [[ $SHELL == *"bash"* ]]; then
                if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.bash_profile; then
                    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            fi
        fi
        
        print_success "Homebrew installed successfully."
    fi

    # Install Homebrew Bundle if not already installed
    if ! brew list --formula | grep -q "^brew-bundle$"; then
        print_info "Installing Homebrew Bundle..."
        brew tap Homebrew/bundle
        print_success "Homebrew Bundle installed successfully."
    else
        print_success "Homebrew Bundle is already installed."
    fi 

    # End install homebre

    print_header "Installing Packages from Brewfile"

    # Check if Homebrew is installed
    if ! command_exists brew; then
        print_error "Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi

    # Check if Brewfile exists in backup location
    if [ -f "$backup_homebrew_dir/Brewfile" ]; then
        BREWFILE_PATH="$backup_homebrew_dir/Brewfile"
    elif [ -f "Brewfile" ]; then
        BREWFILE_PATH="Brewfile"
    else
        print_error "Brewfile not found in $backup_homebrew_dir/ or current directory."
        
        # Ask if user wants to create a new Brewfile
        if confirm "Do you want to create a new Brewfile?"; then
            print_info "Creating a new Brewfile..."
            mkdir -p $backup_homebrew_dir
            BREWFILE_PATH="$backup_homebrew_dir/Brewfile"
            touch "$BREWFILE_PATH"
            print_success "Empty Brewfile created at $BREWFILE_PATH. You can edit it later."
        else
            exit 1
        fi
    fi

    # Ask if user wants to edit the Brewfile before installation
    if confirm "Do you want to review/edit the Brewfile before installation?"; then
        # Determine which editor to use
        if [ -n "$EDITOR" ]; then
            $EDITOR "$BREWFILE_PATH"
        elif command_exists nano; then
            nano "$BREWFILE_PATH"
        elif command_exists vim; then
            vim "$BREWFILE_PATH"
        else
            print_error "No editor found. Please edit the Brewfile manually."
        fi
    fi

    # Install packages from Brewfile
    print_info "Installing packages from Brewfile..."
    brew bundle --file="$BREWFILE_PATH"

    if [ $? -eq 0 ]; then
        print_success "All packages from Brewfile installed successfully."
    else
        print_error "Some packages failed to install. Check the output above for details."
    fi

    # Cleanup
    if confirm "Do you want to clean up (remove outdated packages)?"; then
        print_info "Cleaning up..."
        brew cleanup
        print_success "Cleanup completed."
    fi 
fi

# === SHELL AND ENVIRONMENT SETUP ===
print_header "SHELL AND ENVIRONMENT SETUP"
echo "Configure your shell environment:"

if confirm "Set up iTerm2? (terminal emulator)"; then
    if [!  -d "/Applications/iTerm.app" ]; then
        echo "iTerm2 is not installed. Installing now..."
        brew install --cask iterm2
    fi

    if [ ! -d "$backup_iterm_dir" ]; then
        print_info "No iTerm2 backup found at $backup_iterm_dir"
        print_info "Skipping iTerm2 restoration. You can:"
        echo "  1. Install iTerm2 manually from https://iterm2.com/"
        echo "  2. Run backup_iterm2.sh after configuring iTerm2 to create a backup"
        return 0
    fi

    # Check if there are any backup files
    if [ ! "$(ls -A "$backup_iterm_dir" 2>/dev/null)" ]; then
        print_info "iTerm2 backup directory is empty. Skipping restoration."
        return 0
    fi

    print_info "Found iTerm2 backup. Restoring configuration..."

    # Check if iTerm2 is running and warn user
    if pgrep -x "iTerm2" > /dev/null; then
        echo -e "${RED}⚠️  WARNING: iTerm2 is currently running!${NC}"
        echo -e "${YELLOW}For best results, please quit iTerm2 before restoring settings.${NC}"
        if ! confirm "Continue anyway?"; then
            print_info "iTerm2 restoration cancelled. Please quit iTerm2 and run setup again."
            return 1
        fi
    fi

    # Define target directories
    iterm2_prefs="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    iterm2_app_support="$HOME/Library/Application Support/iTerm2"

    # Create Application Support directory if it doesn't exist
    mkdir -p "$iterm2_app_support"

    # Restore main preferences file
    if [ -f "$backup_iterm_dir/com.googlecode.iterm2.plist" ]; then
        if [ -f "$iterm2_prefs" ] && ! confirm "iTerm2 preferences already exist. Overwrite?"; then
            print_info "Skipping main preferences restoration"
        else
            print_info "Restoring main iTerm2 preferences..."
            cp "$backup_iterm_dir/com.googlecode.iterm2.plist" "$iterm2_prefs"
            print_success "Restored main preferences"
        fi
    else
        print_info "Main preferences file not found in backup"
    fi

    # Restore Application Support files
    if [ -d "$backup_iterm_dir/AppSupport" ]; then
        print_info "Restoring iTerm2 application support files..."
        cp -R "$backup_iterm_dir/AppSupport/"* "$iterm2_app_support/" 2>/dev/null || true
        print_success "Restored application support files"
    fi

    # Restore specific components
    if [ -d "$backup_iterm_dir/ColorPresets" ]; then
        print_info "Restoring color schemes..."
        mkdir -p "$iterm2_app_support/ColorPresets"
        cp -R "$backup_iterm_dir/ColorPresets/"* "$iterm2_app_support/ColorPresets/" 2>/dev/null || true
        print_success "Restored color schemes"
    fi

    if [ -d "$backup_iterm_dir/DynamicProfiles" ]; then
        print_info "Restoring dynamic profiles..."
        mkdir -p "$iterm2_app_support/DynamicProfiles"
        cp -R "$backup_iterm_dir/DynamicProfiles/"* "$iterm2_app_support/DynamicProfiles/" 2>/dev/null || true
        print_success "Restored dynamic profiles"
    fi

    if [ -d "$backup_iterm_dir/Scripts" ]; then
        print_info "Restoring scripts..."
        mkdir -p "$iterm2_app_support/Scripts"
        cp -R "$backup_iterm_dir/Scripts/"* "$iterm2_app_support/Scripts/" 2>/dev/null || true
        print_success "Restored scripts"
    fi

    if [ -f "$backup_iterm_dir/KeyBindings.itermkeymap" ]; then
        print_info "Restoring key mappings..."
        cp "$backup_iterm_dir/KeyBindings.itermkeymap" "$iterm2_app_support/" 2>/dev/null || true
        print_success "Restored key mappings"
    fi

    print_success "iTerm2 configuration restoration completed!"
    echo
    print_info "📝 Important Notes:"
    echo "• Launch iTerm2 to verify your settings have been restored"
    echo "• Some settings may require restarting iTerm2 to take effect"
    echo "• If you had custom profiles, they should now be available"
    echo "• Color schemes and key bindings should be restored as well"
    echo
    print_info "🎨 To verify restoration:"
    echo "1. Open iTerm2"
    echo "2. Go to Preferences (⌘,)"
    echo "3. Check your Profiles, Colors, and Keys tabs"
    echo "4. Verify your custom settings are present"

    print_success "iTerm2 setup completed!"
fi

if confirm "Set up Oh My Zsh? (shell, plugins, themes)"; then
    # Check if Zsh is installed
    if ! command_exists zsh; then
        print_error "Zsh is not installed. Installing Zsh..."
        brew install zsh
        
        # Set Zsh as default shell
        if [ $? -eq 0 ]; then
            print_info "Setting Zsh as default shell..."
            chsh -s $(which zsh)
            print_success "Zsh set as default shell."
        else
            print_error "Failed to install Zsh."
            exit 1
        fi
    else
        print_success "Zsh is already installed."
    fi

    # Install Oh My Zsh if not already installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        
        if [ $? -eq 0 ]; then
            print_success "Oh My Zsh installed successfully."
        else
            print_error "Failed to install Oh My Zsh."
            exit 1
        fi
    else
        print_success "Oh My Zsh is already installed."
    fi

    # Install Zsh plugins
    print_info "Setting up Zsh plugins..."

    # Install zsh-syntax-highlighting
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        print_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        print_success "zsh-syntax-highlighting installed."
    else
        print_success "zsh-syntax-highlighting is already installed."
    fi

    # Install zsh-autosuggestions
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        print_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        print_success "zsh-autosuggestions installed."
    else
        print_success "zsh-autosuggestions is already installed."
    fi

    # Install powerlevel10k theme
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        print_info "Installing powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
        print_success "powerlevel10k theme installed."
    else
        print_success "powerlevel10k theme is already installed."
    fi

    # Update .zshrc file
    print_info "Updating .zshrc file..."

    # Backup existing .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
        print_success "Backed up existing .zshrc file."
    fi

    # Check if we have a backed-up .zshrc in the repository
    if [ -f "$backup_ohmyzsh_dir/.zshrc" ]; then
        print_info "Found backed-up .zshrc in repository. Using it..."
        cp "$backup_ohmyzsh_dir/.zshrc" "$HOME/.zshrc"
        print_success "Restored .zshrc from repository backup."
        
        # Check if we have a backed-up .p10k.zsh in the repository
        if [ -f "$backup_ohmyzsh_dir/.p10k.zsh" ]; then
            print_info "Found backed-up .p10k.zsh in repository. Using it..."
            cp "$backup_ohmyzsh_dir/.p10k.zsh" "$HOME/.p10k.zsh"
            print_success "Restored .p10k.zsh from repository backup."
        fi
        
        # Copy any custom themes
        if [ -d "$backup_ohmyzsh_dir/custom/themes" ]; then
            print_info "Copying custom themes from repository..."
            cp -R "$backup_ohmyzsh_dir/custom/themes"/* "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/" 2>/dev/null || true
            print_success "Restored custom themes from repository backup."
        fi
        
        # Copy any custom plugins
        if [ -d "$backup_ohmyzsh_dir/custom/plugins" ]; then
            print_info "Copying custom plugins from repository..."
            cp -R "$backup_ohmyzsh_dir/custom/plugins"/* "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/" 2>/dev/null || true
            print_success "Restored custom plugins from repository backup."
        fi
        
        # Copy any custom .zsh files
        if [ -d "$backup_ohmyzsh_dir/custom" ]; then
            print_info "Copying custom .zsh files from repository..."
            find "$backup_ohmyzsh_dir/custom" -maxdepth 1 -type f -name "*.zsh" -exec cp {} "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/" \; 2>/dev/null || true
            print_success "Restored custom .zsh files from repository backup."
        fi

        # Source the zshrc file
        source "$HOME/.zshrc"
    fi

    print_success "Shell environment setup completed."
    print_info "Note: Some changes may require restarting your terminal or running 'source ~/.zshrc'." 
fi

if confirm "Set up Node.js? (nvm, npm global packages)"; then
    print_header "Setting Up Node.js Environment"

    # Check if Node.js is already installed via Homebrew
    if command_exists node && command_exists brew && brew list | grep -q "^node$"; then
        print_info "Node.js is already installed via Homebrew."
        node_version=$(node -v)
        print_info "Current Node.js version: $node_version"
        
        if confirm "Do you want to continue with the Homebrew version of Node.js?"; then
            print_info "Continuing with Homebrew version of Node.js."
        else
            print_info "We'll install nvm for better Node.js version management."
            if confirm "Do you want to uninstall the Homebrew version of Node.js?"; then
                print_info "Uninstalling Homebrew Node.js..."
                brew uninstall node
                print_success "Homebrew Node.js uninstalled."
            else
                print_info "Keeping Homebrew Node.js alongside nvm."
            fi
        fi
    fi

    # Install nvm (Node Version Manager)
    if [ ! -d "$HOME/.nvm" ]; then
        print_info "Installing nvm (Node Version Manager)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        
        # Source nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        if command_exists nvm; then
            print_success "nvm installed successfully."
        else
            print_error "Failed to install nvm. Please check the output above for details."
            exit 1
        fi
    else
        print_success "nvm is already installed."
        
        # Source nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Update nvm
        print_info "Updating nvm..."
        (
            cd "$NVM_DIR"
            git fetch --tags origin
            git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
        ) && \. "$NVM_DIR/nvm.sh"
        print_success "nvm updated successfully."
    fi

    # Install Node.js LTS version
    if command_exists nvm; then
        if confirm "Do you want to install the latest LTS version of Node.js?"; then
            print_info "Installing Node.js LTS version..."
            nvm install --lts
            nvm use --lts
            nvm alias default node
            
            node_version=$(node -v)
            print_success "Node.js LTS version $node_version installed and set as default."
        fi
        
        # Ask if user wants to install additional Node.js versions
        if confirm "Do you want to install additional Node.js versions?"; then
            read -p "Enter Node.js versions to install (e.g., 14.17.0 16.13.0): " node_versions
            
            for version in $node_versions; do
                print_info "Installing Node.js version $version..."
                nvm install $version
                print_success "Node.js version $version installed."
            done
        fi
    else
        print_error "nvm is not available. Skipping Node.js installation."
    fi

    # Install pnpm
    if command_exists npm; then
        if ! command_exists pnpm; then
            print_info "Installing pnpm..."
            
            # Check if Homebrew is installed
            if command_exists brew; then
                brew install pnpm
            else
                npm install -g pnpm
            fi
            
            if [ $? -eq 0 ]; then
                print_success "pnpm installed successfully."
                
                # Configure pnpm
                print_info "Configuring pnpm..."
                
                # Add pnpm to shell configuration
                if [[ $SHELL == *"zsh"* ]]; then
                    if ! grep -q 'export PNPM_HOME' ~/.zshrc; then
                        echo '# pnpm configuration' >> ~/.zshrc
                        echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.zshrc
                        echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.zshrc
                        echo 'alias npm="pnpm"' >> ~/.zshrc
                    fi
                elif [[ $SHELL == *"bash"* ]]; then
                    if ! grep -q 'export PNPM_HOME' ~/.bashrc; then
                        echo '# pnpm configuration' >> ~/.bashrc
                        echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.bashrc
                        echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.bashrc
                        echo 'alias npm="pnpm"' >> ~/.bashrc
                    fi
                fi
                
                # Initialize pnpm
                export PNPM_HOME="$HOME/.local/share/pnpm"
                export PATH="$PNPM_HOME:$PATH"
                
                print_success "pnpm configured."
            else
                print_error "Failed to install pnpm."
            fi
        else
            print_success "pnpm is already installed."
        fi
        
        # Determine which package manager to use
        PACKAGE_MANAGER="npm"
        if command_exists pnpm; then
            PACKAGE_MANAGER="pnpm"
        fi       
        
        # Configure npm defaults
        if confirm "Do you want to configure npm defaults for new projects?"; then
            print_info "Configuring npm defaults..."
            
            # Set npm init defaults
            read -p "Enter default author name (leave empty to skip): " author_name
            if [ -n "$author_name" ]; then
                npm config set init-author-name "$author_name"
            fi
            
            read -p "Enter default author email (leave empty to skip): " author_email
            if [ -n "$author_email" ]; then
                npm config set init-author-email "$author_email"
            fi
            
            read -p "Enter default author URL (leave empty to skip): " author_url
            if [ -n "$author_url" ]; then
                npm config set init-author-url "$author_url"
            fi
            
            read -p "Enter default license (leave empty for MIT): " license
            if [ -n "$license" ]; then
                npm config set init-license "$license"
            else
                npm config set init-license "MIT"
            fi
            
            print_success "npm defaults configured."
        fi
    else
        print_error "npm is not available. Skipping npm package installation."
    fi

    print_success "Node.js environment setup completed." 
fi

if confirm "Set up Python? (miniconda)"; then
    print_header "Setting Up Python Environment"

    # check if python is installed otherwise install it
    if ! command_exists python3; then
        print_info "Python is not installed. Installing Python..."
        brew install python
        print_success "Python installed successfully."
    else
        print_success "Python is already installed."
    fi
    
    # Check if Miniconda is already installed
    if [ -d "$HOME/miniconda3" ]; then
        print_info "Miniconda is already installed."
        print_success "Miniconda is already installed."
    else
        print_info "Installing Miniconda..."
        curl -L -O "https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
        bash Miniconda3-latest-MacOSX-arm64.sh -b -p $HOME/miniconda3
        rm Miniconda3-latest-MacOSX-arm64.sh
        print_success "Miniconda installed successfully."
    fi  

    print_success "Python environment setup completed."
fi

if confirm "Set up Go?"; then
    print_header "Setting Up Go Environment"

    # check if go is installed otherwise install it
    if ! command_exists go; then
        print_info "Go is not installed. Installing Go..."
        brew install go
        print_success "Go installed successfully."
    else
        print_success "Go is already installed."
    fi
fi

if confirm "Set up PostgreSQL?"; then
    print_header "Setting Up PostgreSQL Database"

    # Check if PostgreSQL is already installed
    if command_exists psql; then
        print_success "PostgreSQL is already installed."
        postgres_version=$(psql --version)
        print_info "Current PostgreSQL version: $postgres_version"
    else
        print_info "Installing PostgreSQL..."
        brew install postgresql@15
        
        if [ $? -eq 0 ]; then
            print_success "PostgreSQL installed successfully."
            
            # Start PostgreSQL service
            print_info "Starting PostgreSQL service..."
            brew services start postgresql@15
            
            if [ $? -eq 0 ]; then
                print_success "PostgreSQL service started successfully."
            else
                print_error "Failed to start PostgreSQL service."
            fi
        else
            print_error "Failed to install PostgreSQL."
            exit 1
        fi
    fi

    # Set up default PostgreSQL role
    if confirm "Do you want to create a default PostgreSQL role (postgres) with superuser privileges?"; then
        print_info "Setting up default PostgreSQL role..."
        
        # Wait a moment for PostgreSQL to be fully ready
        sleep 2
        
        # Create the postgres role with login and password
        print_info "Creating postgres role..."
        psql postgres -c "CREATE ROLE postgres WITH LOGIN PASSWORD 'postgres';" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_success "Created postgres role with login and password."
        else
            print_info "postgres role might already exist, continuing..."
        fi
        
        # Grant superuser privileges
        print_info "Granting superuser privileges to postgres role..."
        psql postgres -c "ALTER ROLE postgres SUPERUSER;" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_success "Granted superuser privileges to postgres role."
        else
            print_info "Superuser privileges might already be set, continuing..."
        fi
        
        print_info "Default PostgreSQL role setup completed."
        print_info "You can now connect using: psql -U postgres -h localhost"
        print_info "Password: postgres"
    fi

    # Install PostgreSQL GUI tools
    if confirm "Do you want to install pgAdmin (PostgreSQL GUI tool)?"; then
        print_info "Installing pgAdmin..."
        brew install --cask pgadmin4
        
        if [ $? -eq 0 ]; then
            print_success "pgAdmin installed successfully."
        else
            print_error "Failed to install pgAdmin."
        fi
    fi

    # Install additional PostgreSQL tools
    if confirm "Do you want to install additional PostgreSQL tools (pg_dump, pg_restore, etc.)?"; then
        print_info "Installing PostgreSQL tools..."
        brew install postgresql@15
        
        if [ $? -eq 0 ]; then
            print_success "PostgreSQL tools installed successfully."
        else
            print_error "Failed to install PostgreSQL tools."
        fi
    fi

    print_info "PostgreSQL setup information:"
    echo "• Service status: $(brew services list | grep postgresql)"
    echo "• Default port: 5432"
    echo "• Data directory: /opt/homebrew/var/postgresql@15"
    echo "• Log file: /opt/homebrew/var/log/postgresql@15.log"
    echo
    print_info "Useful commands:"
    echo "• Start service: brew services start postgresql@15"
    echo "• Stop service: brew services stop postgresql@15"
    echo "• Restart service: brew services restart postgresql@15"
    echo "• Connect to database: psql -U postgres -h localhost"
    echo "• Create database: createdb mydatabase"
    echo "• Drop database: dropdb mydatabase"

    print_success "PostgreSQL setup completed!"
fi

# === CONFIGURATION AND PREFERENCES ===
print_header "CONFIGURATION AND PREFERENCES"
echo "Configure your development environment:"

if confirm "Configure Git?"; then
    print_header "Setting Up Git Configuration"

    # Check if Git is installed
    if ! command_exists git; then
        print_error "Git is not installed. Installing Git..."
        brew install git
        
        if [ $? -ne 0 ]; then
            print_error "Failed to install Git."
            exit 1
        fi
    else
        print_success "Git is already installed."
    fi

    # Check for Git backup file
    if [ -f "$backup_git_dir/.gitconfig" ]; then
        print_info "Found .gitconfig backup file."
        
        # Backup current .gitconfig if it exists
        if [ -f "$HOME/.gitconfig" ]; then
            print_info "Backing up current .gitconfig..."
            cp "$HOME/.gitconfig" "$HOME/.gitconfig.bak.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Replace with backup .gitconfig
        print_info "Restoring Git configuration from backup..."
        cp "$backup_git_dir/.gitconfig" "$HOME/.gitconfig"
        
        if [ $? -eq 0 ]; then
            print_success "Git configuration restored from backup."
            
            # Display restored configuration
            print_info "Restored configuration:"
            echo "• User name: $(git config --global user.name)"
            echo "• User email: $(git config --global user.email)"
            
            # List aliases if any exist
            aliases=$(git config --global --get-regexp alias 2>/dev/null)
            if [ -n "$aliases" ]; then
                echo "• Aliases:"
                git config --global --get-regexp alias | sed 's/alias\./  /' | sed 's/ / = /'
            fi
        else
            print_error "Failed to restore .gitconfig from backup."
            exit 1
        fi
    else
        print_error "No .gitconfig backup found at $backup_git_dir/.gitconfig"
        print_info "Please ensure you have a .gitconfig backup file, or configure Git manually."
        exit 1
    fi

    print_success "Git setup completed!"
fi

if confirm "Configure VSCode?"; then
    print_header "Restoring VSCode Settings"

    # Check if VSCode is installed
    if ! command_exists code; then
        print_error "VSCode is not installed. Please install VSCode first."
        exit 1
    fi

    # Create VSCode directories if they don't exist
    vscode_dir="$HOME/Library/Application Support/Code/User"
    mkdir -p "$vscode_dir"

    # Check if backup exists
    if [ ! -d "$backup_vscode_dir" ]; then
        print_error "VSCode backup not found at $backup_vscode_dir"
        exit 1
    fi

    # Restore settings.json
    if [ -f "$backup_vscode_dir/settings.json" ]; then
        print_info "Restoring settings.json..."
        cp "$backup_vscode_dir/settings.json" "$vscode_dir/"
        print_success "Restored settings.json"
    fi

    # Restore keybindings.json
    if [ -f "$backup_vscode_dir/keybindings.json" ]; then
        print_info "Restoring keybindings.json..."
        cp "$backup_vscode_dir/keybindings.json" "$vscode_dir/"
        print_success "Restored keybindings.json"
    fi

    # Restore snippets
    if [ -d "$backup_vscode_dir/snippets" ]; then
        print_info "Restoring code snippets..."
        mkdir -p "$vscode_dir/snippets"
        cp -R "$backup_vscode_dir/snippets/"* "$vscode_dir/snippets/"
        print_success "Restored code snippets"
    fi

    # Install extensions
    if [ -f "$backup_vscode_dir/extensions.txt" ]; then
        print_info "Installing VSCode extensions..."
        while read extension; do
            if [ ! -z "$extension" ]; then
                print_info "Installing extension: $extension"
                code --install-extension "$extension"
            fi
        done < "$backup_vscode_dir/extensions.txt"
        print_success "VSCode extensions installed"
    fi

    print_success "VSCode settings restoration completed!" 
fi

if confirm "Restore macOS preferences?"; then
    print_header "Restoring Mac Settings from Backup"

    # Check if backup directory exists
    if [ ! -d "$backup_macos_dir" ]; then
        print_error "Backup directory not found at $backup_macos_dir"
        exit 1
    fi

    # Restore macOS preferences
    print_info "Restoring macOS preferences..."

    # Function to restore a plist file
    restore_plist() {
        local domain=$1
        local file=$2
        
        if [ -f "$file" ]; then
            defaults import "$domain" "$file" 2>/dev/null
            if [ $? -eq 0 ]; then
                print_success "Restored $domain preferences"
            else
                print_error "Failed to restore $domain preferences"
            fi
        else
            print_info "No backup found for $domain, skipping"
        fi
    }

    # Restore Dock settings
    restore_plist "com.apple.dock" "$backup_macos_dir/dock.plist"

    # Restore Finder settings
    restore_plist "com.apple.finder" "$backup_macos_dir/finder.plist"

    # Restore Terminal settings
    restore_plist "com.apple.Terminal" "$backup_macos_dir/terminal.plist"

    # Restore mouse settings
    restore_plist "com.apple.driver.AppleBluetoothMultitouch.mouse" "$backup_macos_dir/mouse.plist"

    # Restore trackpad settings
    restore_plist "com.apple.driver.AppleBluetoothMultitouch.trackpad" "$backup_macos_dir/trackpad.plist"
    restore_plist "com.apple.AppleMultitouchTrackpad" "$backup_macos_dir/apple_trackpad.plist"

    # Restore keyboard settings
    restore_plist "com.apple.keyboard" "$backup_macos_dir/keyboard.plist"
    restore_plist "com.apple.HIToolbox" "$backup_macos_dir/input_sources.plist"

    # Restore display settings
    restore_plist "com.apple.displays" "$backup_macos_dir/displays.plist"

    # Restore sound settings
    restore_plist "com.apple.sound" "$backup_macos_dir/sound.plist"

    # Restore accessibility settings
    restore_plist "com.apple.universalaccess" "$backup_macos_dir/accessibility.plist"

    # Restore system preferences
    restore_plist "com.apple.systempreferences" "$backup_macos_dir/systempreferences.plist"

    # Restore global domain settings
    if [ -f "$backup_macos_dir/global_domain/global_domain.plist" ]; then
        defaults import -g "$backup_macos_dir/global_domain/global_domain.plist" 2>/dev/null
        if [ $? -eq 0 ]; then
            print_success "Restored global system preferences"
        else
            print_error "Failed to restore global system preferences"
        fi
    fi

    # Restore hosts file (requires sudo)
    if [ -f "$backup_macos_dir/hosts" ] && confirm "Do you want to restore the hosts file? (requires sudo)"; then
        sudo cp "$backup_macos_dir/hosts" "/etc/hosts" 2>/dev/null
        if [ $? -eq 0 ]; then
            print_success "Restored hosts file"
        else
            print_error "Failed to restore hosts file"
        fi
    fi

    print_info "Some settings may require logging out or restarting your Mac to take effect."
    print_success "Mac settings restoration completed!" 
fi

print_header "Setup Complete!"
echo "Your Mac has been set up according to your preferences. For the some settings to take effect, you may need to restart your terminal or log out and back in."
echo "If you encounter any issues, please check the individual script files in the 'scripts' directory."
echo
echo "Happy coding! 🚀"
echo
echo "Note: To backup your settings, run the backup.sh script." 
echo "Note: for p10k theme icons to show up properly, please install the recommended fonts: $ p10k configure (then just answer Yes) " 