# CLI Manager Tool

<div align="center">
  <img src="https://img.shields.io/badge/Python-3.6+-blue.svg" alt="Python 3.6+">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
  <img src="https://img.shields.io/badge/OS-Linux%20%7C%20macOS-lightgrey" alt="OS: Linux | macOS">
</div>

<p align="center">
  <img src="https://img.shields.io/badge/Powered%20by-Google%20Gemini%20AI-blue?logo=google&logoColor=white" alt="Powered by Google Gemini AI">
</div>
<p align="center">

</p>

CLI Manager is an intelligent terminal assistant that simplifies command-line operations by converting cryptic error messages into human-readable explanations, providing AI-powered answers to your questions directly in the terminal, and automatically starting with your terminal sessions.

## ✨ Features

- **🔍 Smart Error Handler**: Intercepts terminal errors, cleans up messy error messages, and provides clear explanations and solutions
- **🤖 AI Assistant**: Get answers directly in your terminal with a simple command
- **🚀 Auto-start**: Automatically starts when you open a terminal session
- **🎨 Customization**: Configure text color, size, word limits, and more

## 📋 Requirements

- Python 3.6+
- Google Gemini API key ([Get one here](https://aistudio.google.com/app/apikey))
- Linux or macOS (Windows support coming soon)

## 🔧 Installation

### Automatic Installation (Recommended)

```bash
# Download the installer
curl -O https://raw.githubusercontent.com/yourusername/cli-manager/main/install.sh

# Make it executable
chmod +x install.sh

# Run the installer
./install.sh
```

During installation, you'll be prompted to enter your Google Gemini API key. You can also set or update this later.

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/cli-manager.git
cd cli-manager

# Run the installer
./install.sh
```

## 🚀 Usage

### Basic Commands

```bash
# Get help and see all available commands
cm --help

# Ask AI a question
cm -s "what is chmod?"

# Configure settings (API key, text color, etc.)
cm --settings

# Run a command and explain any errors
cm -c "find / -name missing_file"

# Get full AI response without word limit
cm -s "explain docker networking" --full
```

### Examples

#### 1. Getting Help with Commands

<p align="center">
  <img src="https://i.imgur.com/AbCdEfG.png" alt="Command Help Example" width="600px">
</p>

```bash
cm -s "how do I list all docker containers including stopped ones?"
```

Output:
```
> To list all Docker containers including stopped ones, use:
  docker ps -a
  
  The -a or --all flag shows all containers (default shows just running).
```

#### 2. Error Explanation

<p align="center">
  <img src="https://i.imgur.com/GhIjKlM.png" alt="Error Explanation Example" width="600px">
</p>

```bash
cm -c "docker rnu nginx"
```

Output:
```
docker: 'rnu' is not a docker command.
See 'docker --help'

> It looks like you have a typo in your command. You typed "docker rnu nginx" 
  but the correct command should be "docker run nginx". The command "rnu" 
  doesn't exist in Docker. Try running "docker run nginx" instead.
```

#### 3. Technical Explanations

```bash
cm -s "what is the difference between TCP and UDP?"
```

Output:
```
> TCP (Transmission Control Protocol) and UDP (User Datagram Protocol) are transport layer protocols.

  TCP:
  - Connection-oriented: establishes a connection before sending data
  - Reliable: guarantees delivery with acknowledgments and retransmissions
  - Ordered packet delivery
  - Flow control and congestion control
  - Used for web browsing, email, file transfers

  UDP:
  - Connectionless: sends data without establishing a connection
  - Unreliable: no guarantee of delivery or order
  - Faster with less overhead
  - No congestion control
  - Used for streaming, gaming, DNS lookups
```

## ⚙️ Configuration

You can configure CLI Manager using the settings command:

```bash
cm --settings
```

Available settings:
- **alias**: Change the command name (default: cm)
- **text_color**: Choose from red, green, blue, yellow, cyan, magenta, white
- **text_size**: small, normal, or large
- **word_limit**: Maximum words in AI responses (0 for no limit)
- **api_key**: Your Google Gemini API key
- **model**: AI model to use (default: gemini-pro)

## 🔍 Troubleshooting

### Common Issues and Solutions

#### 1. ModuleNotFoundError: No module named 'google'

```
Traceback (most recent call last):
  File "/home/user/.clitools/cli_manager.py", line 12, in <module>
    import google.generativeai as genai
ModuleNotFoundError: No module named 'google'
```

**Solution**: Reinstall the package and ensure the virtual environment is active:

```bash
source ~/.clitools/venv/bin/activate
pip install -U google-generativeai
```

#### 2. Command 'cm' not found

**Solution**: Ensure the bin directory is in your PATH and the launcher is properly installed:

```bash
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
source ~/.bashrc
```

Or reinstall using:

```bash
chmod +x ~/.local/bin/cm
```

#### 3. API Key Issues

```
Failed to initialize AI: Error: 400 API key not valid.
```

**Solution**: Update your API key:

```bash
cm --settings
# Select "api_key" and enter your new key
```

#### 4. Virtual Environment Problems

**Solution**: Recreate the virtual environment:

```bash
rm -rf ~/.clitools/venv
python3 -m venv ~/.clitools/venv
source ~/.clitools/venv/bin/activate
pip install -r ~/.clitools/requirements.txt
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📃 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built using Google's Generative AI (Gemini)
- Inspired by the need to simplify terminal experiences for developers


         MADE BY DIBYENDU DEY WITH ♥️
