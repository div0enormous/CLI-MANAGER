#!/usr/bin/env python3
# cli_manager.py - CLI Manager Tool with AI assistance

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
    "model": "gemini-2.0-flash"
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
            print(f"{Fore.YELLOW}API key not found. Please set it using 'cms'")
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
        Please explain what this error means in simple terms and just show the main error and the perfect solution in less words:
        
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
                test_model = genai.GenerativeModel("gemini-2.0-flash")
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
    parser.add_argument("cm -s", help="Update tool settings", action="store_true")
    parser.add_argument("cmf", help="Show full AI response without word limit", action="store_true")
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
