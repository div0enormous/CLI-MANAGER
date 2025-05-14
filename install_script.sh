#!/bin/bash
# Install script for CLI Manager Tool

# ASCII banner
echo '
 ╔═══════════════════════════════════════════════╗
 ║                                               ║
 ║   ██████╗██╗     ██╗    ███╗   ███╗ ██████╗   ║
 ║  ██╔════╝██║     ██║    ████╗ ████║██╔════╝   ║
 ║  ██║     ██║     ██║    ██╔████╔██║██║  ███╗  ║
 ║  ██║     ██║     ██║    ██║╚██╔╝██║██║   ██║  ║
 ║  ╚██████╗███████╗██║    ██║ ╚═╝ ██║╚██████╔╝  ║
 ║   ╚═════╝╚══════╝╚═╝    ╚═╝     ╚═╝ ╚═════╝   ║
 ║                                               ║
 ║         CLI Manager Tool Installer            ║
 ║          💚MADE BY DIBYENDU DEY               ║
 ╚═══════════════════════════════════════════════╝
'

echo "[+] Initializing installation process..."
sleep 1

# Define installation directory
INSTALL_DIR="$HOME/.clitools"
BIN_DIR="$HOME/.local/bin"

# Check if Python is installed
echo "[+] Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "[-] Python3 is not installed. Please install Python 3.6 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "[+] Python version $PYTHON_VERSION detected."

# Check and install pip if needed
echo "[+] Checking pip installation..."
if ! command -v pip3 &> /dev/null; then
    echo "[+] Installing pip..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y python3-pip
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-pip
    elif command -v brew &> /dev/null; then
        brew install python3
    else
        echo "[-] Could not install pip automatically. Please install pip manually."
        exit 1
    fi
fi

# Check and install venv if needed
echo "[+] Checking venv installation..."
if ! python3 -c 'import ensurepip' &> /dev/null; then
    echo "[+] Installing venv..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y python3-venv
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-venv
    elif command -v brew &> /dev/null; then
        brew install python3
    else
        echo "[-] Could not install venv automatically. Please install venv manually."
        exit 1
    fi
fi

# Create installation directory
echo "[+] Creating installation directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Create virtual environment
echo "[+] Setting up virtual environment..."
python3 -m venv "$INSTALL_DIR/venv"

# Make venv executable
chmod +x "$INSTALL_DIR/venv/bin/activate"
source "$INSTALL_DIR/venv/bin/activate" || {
    echo "[-] Failed to activate virtual environment. Trying alternative method..."
    export PYTHONPATH="$INSTALL_DIR/venv/lib/python$PYTHON_VERSION/site-packages:$PYTHONPATH"
    export PATH="$INSTALL_DIR/venv/bin:$PATH"
}

# Create requirements.txt
echo "[+] Creating requirements file..."
cat > "$INSTALL_DIR/requirements.txt" << EOF
# Core dependencies
pip>=22.0.0
virtualenv>=20.0.0
setuptools>=60.0.0
wheel>=0.37.0

# Tool dependencies
colorama>=0.4.4
google-generativeai>=0.3.0
requests>=2.28.0
EOF

# Install requirements
echo "[+] Installing required packages..."
python3 -m pip install --upgrade pip &> /dev/null
python3 -m pip install -r "$INSTALL_DIR/requirements.txt" &> /dev/null

# Create shortcuts
echo "[+] Creating shortcuts..."
mkdir -p "$INSTALL_DIR/shortcuts"

# Create shortcut for settings
cat > "$INSTALL_DIR/shortcuts/cms" << EOF
#!/bin/bash
source "$INSTALL_DIR/venv/bin/activate"
python3 "$INSTALL_DIR/cli_manager.py" --settings
EOF
chmod +x "$INSTALL_DIR/shortcuts/cms"
ln -sf "$INSTALL_DIR/shortcuts/cms" "$BIN_DIR/cms"

# Create shortcut for full responses
cat > "$INSTALL_DIR/shortcuts/cmf" << EOF
#!/bin/bash
source "$INSTALL_DIR/venv/bin/activate"
python3 "$INSTALL_DIR/cli_manager.py" -s "\$@" --full
EOF
chmod +x "$INSTALL_DIR/shortcuts/cmf"
ln -sf "$INSTALL_DIR/shortcuts/cmf" "$BIN_DIR/cmf"

# Create shortcut for command execution with error handling
cat > "$INSTALL_DIR/shortcuts/cmr" << EOF
#!/bin/bash
source "$INSTALL_DIR/venv/bin/activate"
python3 "$INSTALL_DIR/cli_manager.py" -c "\$@"
EOF
chmod +x "$INSTALL_DIR/shortcuts/cmr"
ln -sf "$INSTALL_DIR/shortcuts/cmr" "$BIN_DIR/cmr"

# Copy CLI Manager script
echo "[+] Installing CLI Manager Tool..."
cat > "$INSTALL_DIR/cli_manager.py" << 'EOF'
#!/usr/bin/env python3
# cli_tools.py - CLI Manager Tool with AI assistance

import os
import sys
import json
import argparse
import subprocess
import signal
import re
from pathlib import Path
import google.generativeai as genai
from colorama import Fore, Style, init

# Initialize colorama
init(autoreset=True)

# Config file path
CONFIG_DIR = os.path.expanduser("~/.clitools")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")

# Default settings
DEFAULT_CONFIG = {
    "alias": "cm",
    "text_color": "green",
    "text_size": "normal",
    "word_limit": 150,
    "api_key": "",
    "model": "gemini-pro"
}

# Color mapping
COLOR_MAP = {
    "red": Fore.RED,
    "green": Fore.GREEN,
    "blue": Fore.BLUE,
    "yellow": Fore.YELLOW,
    "cyan": Fore.CYAN,
    "magenta": Fore.MAGENTA,
    "white": Fore.WHITE
}

class CLIManager:
    def __init__(self):
        self.load_config()
        self.setup_ai()
        
    def load_config(self):
        # Create config directory if it doesn't exist
        if not os.path.exists(CONFIG_DIR):
            os.makedirs(CONFIG_DIR)
            
        # Create config file if it doesn't exist
        if not os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, 'w') as f:
                json.dump(DEFAULT_CONFIG, f, indent=4)
            self.config = DEFAULT_CONFIG
        else:
            try:
                with open(CONFIG_FILE, 'r') as f:
                    self.config = json.load(f)
                # Add any missing keys from DEFAULT_CONFIG
                updated = False
                for key, value in DEFAULT_CONFIG.items():
                    if key not in self.config:
                        self.config[key] = value
                        updated = True
                if updated:
                    self.save_config()
            except json.JSONDecodeError:
                print(f"{Fore.RED}Config file corrupted, resetting to defaults.")
                self.config = DEFAULT_CONFIG
                self.save_config()
    
    def save_config(self):
        with open(CONFIG_FILE, 'w') as f:
            json.dump(self.config, f, indent=4)
    
    def setup_ai(self):
        if not self.config["api_key"]:
            print(f"{Fore.YELLOW}API key not found. Please set it using 'cm --settings'")
            return
        
        try:
            genai.configure(api_key=self.config["api_key"])
            self.model = genai.GenerativeModel(self.config["model"])
        except Exception as e:
            print(f"{Fore.RED}Failed to initialize AI: {str(e)}")
    
    def format_output(self, text):
        color = COLOR_MAP.get(self.config["text_color"], Fore.GREEN)
        
        # Apply word limit if specified
        if self.config["word_limit"] > 0:
            words = text.split()
            if len(words) > self.config["word_limit"]:
                text = " ".join(words[:self.config["word_limit"]]) + "...\n(Response truncated. Use --full for complete response)"
        
        # Apply text size (this is basic, could be expanded)
        if self.config["text_size"] == "large":
            return f"\n{color}=== AI Response ===\n{text}\n===============\n"
        elif self.config["text_size"] == "small":
            return f"\n{color}{text}\n"
        else:  # normal
            return f"\n{color}> {text}\n"
    
    def handle_error(self, command_output, exit_code):
        """Process error output and get AI explanation"""
        if not command_output.strip():
            return "No error output to analyze."
        
        # Clean the error message
        cleaned_error = self.clean_error_message(command_output)
        
        prompt = f"""
        This is a terminal command error with exit code {exit_code}. 
        Please explain what this error means in simple terms and suggest a solution:
        
        {cleaned_error}
        """
        
        try:
            response = self.model.generate_content(prompt)
            return response.text
        except Exception as e:
            return f"Failed to get AI explanation: {str(e)}"
    
    def clean_error_message(self, error_message):
        """Clean up error messages to make them more readable"""
        # Remove ANSI color codes
        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
        cleaned = ansi_escape.sub('', error_message)
        
        # Remove duplicate blank lines
        cleaned = re.sub(r'\n\s*\n', '\n\n', cleaned)
        
        # Truncate if too long
        if len(cleaned) > 1500:
            cleaned = cleaned[:1500] + "...(truncated)"
            
        return cleaned
    
    def ask_ai(self, query, full_response=False):
        """Ask AI a question and get response"""
        temp_config = self.config.copy()
        if full_response:
            temp_config["word_limit"] = 0
            
        try:
            response = self.model.generate_content(query)
            return self.format_output(response.text)
        except Exception as e:
            return f"{Fore.RED}Error: {str(e)}"
    
    def update_settings(self):
        """Interactive settings update"""
        print(f"{Fore.CYAN}Current Settings:")
        for key, value in self.config.items():
            # Don't show the full API key
            if key == "api_key" and value:
                masked_key = value[:4] + "*" * (len(value) - 8) + value[-4:] if len(value) > 8 else "****"
                print(f"{key}: {masked_key}")
            else:
                print(f"{key}: {value}")
        
        print("\nWhich setting would you like to change?")
        print("Available options: " + ", ".join(self.config.keys()))
        setting = input("> ").strip().lower()
        
        if setting not in self.config:
            print(f"{Fore.RED}Invalid setting: {setting}")
            return
            
        if setting == "api_key":
            new_value = input(f"Enter new {setting} value: ").strip()
            # Test the API key
            try:
                genai.configure(api_key=new_value)
                test_model = genai.GenerativeModel("gemini-pro")
                test_response = test_model.generate_content("Say 'API key is working!'")
                print(f"{Fore.GREEN}API key validated successfully!")
                self.config[setting] = new_value
                self.save_config()
                self.setup_ai()
            except Exception as e:
                print(f"{Fore.RED}Invalid API key: {str(e)}")
        elif setting == "text_color":
            print("Available colors: " + ", ".join(COLOR_MAP.keys()))
            new_value = input(f"Enter new {setting} value: ").strip().lower()
            if new_value in COLOR_MAP:
                self.config[setting] = new_value
                self.save_config()
                print(f"{Fore.GREEN}Setting updated successfully!")
            else:
                print(f"{Fore.RED}Invalid color. Please choose from: {', '.join(COLOR_MAP.keys())}")
        elif setting == "text_size":
            print("Available sizes: small, normal, large")
            new_value = input(f"Enter new {setting} value: ").strip().lower()
            if new_value in ["small", "normal", "large"]:
                self.config[setting] = new_value
                self.save_config()
                print(f"{Fore.GREEN}Setting updated successfully!")
            else:
                print(f"{Fore.RED}Invalid size. Please choose from: small, normal, large")
        elif setting == "word_limit":
            try:
                new_value = int(input(f"Enter new {setting} value (0 for no limit): ").strip())
                if new_value < 0:
                    print(f"{Fore.RED}Word limit must be non-negative.")
                else:
                    self.config[setting] = new_value
                    self.save_config()
                    print(f"{Fore.GREEN}Setting updated successfully!")
            except ValueError:
                print(f"{Fore.RED}Please enter a valid number.")
        else:
            new_value = input(f"Enter new {setting} value: ").strip()
            self.config[setting] = new_value
            self.save_config()
            print(f"{Fore.GREEN}Setting updated successfully!")


def create_parser():
    parser = argparse.ArgumentParser(description="CLI Manager Tool with AI assistance")
    parser.add_argument("-s", "--ask", help="Ask AI a question", nargs='+')
    parser.add_argument("-e", "--explain", help="Explain the last command error", action="store_true")
    parser.add_argument("--settings", help="Update tool settings", action="store_true")
    parser.add_argument("--full", help="Show full AI response without word limit", action="store_true")
    parser.add_argument("-c", "--command", help="Run a command and explain any errors", nargs='+')
    return parser


def main():
    parser = create_parser()
    args = parser.parse_args()
    
    cli_manager = CLIManager()
    
    if args.settings:
        cli_manager.update_settings()
    elif args.ask:
        query = " ".join(args.ask)
        print(cli_manager.ask_ai(query, args.full))
    elif args.command:
        cmd = " ".join(args.command)
        try:
            process = subprocess.run(cmd, shell=True, text=True, capture_output=True)
            print(process.stdout)
            
            if process.returncode != 0:
                explanation = cli_manager.handle_error(process.stderr, process.returncode)
                print(cli_manager.format_output(explanation))
        except Exception as e:
            print(f"{Fore.RED}Error executing command: {str(e)}")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
EOF

# Make script executable
chmod +x "$INSTALL_DIR/cli_manager.py"

# Create launcher script
echo "[+] Creating launcher script..."
cat > "$BIN_DIR/cm" << EOF
#!/bin/bash
source "$INSTALL_DIR/venv/bin/activate"
python3 "$INSTALL_DIR/cli_manager.py" "\$@"
EOF

# Make launcher executable
chmod +x "$BIN_DIR/cm"

# Add auto-start to appropriate shell config
echo "[+] Setting up auto-start..."
SHELL_CONFIG=""

if [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -f "$HOME/.profile" ]; then
    SHELL_CONFIG="$HOME/.profile"
fi

if [ -n "$SHELL_CONFIG" ]; then
    # Check if entry already exists
    if ! grep -q "# CLI Manager Tool Auto-start" "$SHELL_CONFIG"; then
        echo "" >> "$SHELL_CONFIG"
        echo "# CLI Manager Tool Auto-start" >> "$SHELL_CONFIG"
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$SHELL_CONFIG"
        echo "# Show a reminder to set the API key if not set" >> "$SHELL_CONFIG"
        echo "if [ -f \"$INSTALL_DIR/venv/bin/activate\" ]; then" >> "$SHELL_CONFIG"
        echo "    source \"$INSTALL_DIR/venv/bin/activate\" &>/dev/null || export PYTHONPATH=\"$INSTALL_DIR/venv/lib/python\$(python3 -c 'import sys; print(f\"{sys.version_info.major}.{sys.version_info.minor}\")')/site-packages:\$PYTHONPATH\"" >> "$SHELL_CONFIG"
        echo "    if ! python3 -c 'import os; exit(0 if os.path.exists(\"$INSTALL_DIR/config.json\") and \"api_key\" in open(\"$INSTALL_DIR/config.json\").read() and len(open(\"$INSTALL_DIR/config.json\").read().split(\"api_key\")[1].split(\":\")[1].split(\",\")[0].strip(\"\\\"\").strip()) > 10 else 1)' &>/dev/null; then" >> "$SHELL_CONFIG"
        echo "        echo \"[CLI Manager] API key not set. Run 'cms' to set it up.\"" >> "$SHELL_CONFIG"
        echo "    fi" >> "$SHELL_CONFIG"
        echo "    deactivate &>/dev/null" >> "$SHELL_CONFIG"
        echo "fi" >> "$SHELL_CONFIG"
        echo "[+] Auto-start setup completed."
    else
        echo "[+] Auto-start already configured."
    fi
else
    echo "[-] Could not find a shell configuration file to add auto-start."
    echo "    Please add the following line to your shell configuration file:"
    echo "    export PATH=\"\$PATH:$BIN_DIR\""
fi

# Get API key
echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║       Setup Google Gemini API Key             ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
echo "To use this tool, you need a Google Gemini API key."
echo "You can get one from https://aistudio.google.com/app/apikey"
echo ""
read -p "Enter your Google Gemini API key: " API_KEY

if [ -n "$API_KEY" ]; then
    # Create a temporary Python script to update the config
    cat > "$INSTALL_DIR/temp_config.py" << EOF
#!/usr/bin/env python3
import json
import os

CONFIG_FILE = "$INSTALL_DIR/config.json"

# Create or update config
if os.path.exists(CONFIG_FILE):
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
    except:
        config = {
            "alias": "cm",
            "text_color": "green",
            "text_size": "normal",
            "word_limit": 150,
            "model": "gemini-pro"
        }
else:
    config = {
        "alias": "cm",
        "text_color": "green",
        "text_size": "normal",
        "word_limit": 150,
        "model": "gemini-pro"
    }

config["api_key"] = "$API_KEY"

with open(CONFIG_FILE, 'w') as f:
    json.dump(config, f, indent=4)

print("API key saved successfully!")
EOF

    # Run the temp script to update config
    source "$INSTALL_DIR/venv/bin/activate"
    python3 "$INSTALL_DIR/temp_config.py"
    rm "$INSTALL_DIR/temp_config.py"
    
    # Test API key
    echo "[+] Testing API key..."
    if ! python3 -c "
import sys
try:
    import google.generativeai as genai
    genai.configure(api_key='$API_KEY')
    model = genai.GenerativeModel('gemini-pro')
    response = model.generate_content('Hello')
    print('[+] API key works correctly!')
    sys.exit(0)
except Exception as e:
    print(f'[-] API key test failed: {str(e)}')
    sys.exit(1)
" ; then
        echo "[-] API key validation failed. Please update it later using 'cm --settings'"
    fi
else
    echo "[-] No API key provided. You can set it later using 'cm --settings'"
fi

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║              Installation Complete            ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
echo "CLI Manager Tool has been installed successfully!"
echo ""
echo "To use the tool:"
echo "  - For help: cm --help"
echo "  - To ask AI: cm -s \"your question here\""
echo "  - To update settings: cms"
echo "  - To get full AI response: cmf \"your question here\""
echo "  - To run command with error handling: cmr \"your command\""
echo ""
echo "You may need to restart your terminal or run 'source $SHELL_CONFIG'"
echo "to use the shortcuts without specifying the full path."
echo ""
