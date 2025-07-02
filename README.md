# IoT Nano Agent Installer

The **IoT Nano Agent** is a lightweight security solution provided by Check Point Software Technologies to protect Linux-based IoT devices. It offers advanced security features for IoT devices from access control to runtime protection. This installer is a shell-based script designed to simplify the deployment and installation of the Nano Agent on supported systems.

---

## What is the IoT Nano Agent?

The IoT Nano Agent is a software component that provides runtime protection for specific programs on IoT devices. It is designed to be lightweight and efficient, making it suitable for resource-constrained environments. The installer provides a 90-day trial version of the Nano Agent, which includes the following protections:

- **SSHD login protection** Block brute force login attacks on SSH deamon
- **SSH audit** Audit all shell commands running in the system, including the admin and the time
- **Web login rate limit** Block brute force login attacks on web servers
- **Command injection protection** Advanced protection that identifies attempts to run shell injection
- **File Monitor** Advanced protection that identifies unauthorized access to files, and blocks attempt to manipulate executables in runtime

### How It Works

After a successful installation, you can run your application under protection. When an application is running with protection, the Nano agent uses advanced function hooking techniques to attach itself to the program, then it monitors system commands to verify that no malicious activity is being executed. The security is running without interrupting the normal activity of the program. Consider applying the security to all applications that have user interfaces, APIs, or any external interfaces.

> **Note:** Only dynamically-compiled binary files are supported. No code changes are required in the protected program.

To enable protection for an executable, you must run the program with the `LD_PRELOAD=libwlp-core.so` environment variable. This can be done either from the shell or by modifying the program's initialization script (e.g., systemd service file). For example, to protect SSHD, you need to add the `LD_PRELOAD` variable to its `.service` file. 

For more detailed information, please visit the full documentation of [QUANTUM IOT PROTECT NANO AGENT](https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/Quantum-IoT-Nano-Agent-Installation/Default.htm).

---

## Supported Platforms and System Requirements

The IoT Nano Agent trial version supports the following platforms and has specific system requirements:

| Platform   | Architecture            | Required `glibc` Version | Minimum Disk Space | Minimum RAM |
|------------|-------------------------|--------------------------|--------------------|-------------|
| **x86_64** | 64-bit Intel/AMD systems | > 2.23                  | 30 MB             | 60 MB (*)    |
| **aarch64**| ARM64 systems            | > 2.28                  | 30 MB             | 50 MB (*)    |

> **Note:** These are the requirements for the trial version. The **full version supports additional platforms and architectures**.
The installer will automatically download the installation file based on the detected platform.
It also checks for required utilities and libraries and will alert you in case any are missing.
> 
> **Note(*):** RAM consumption might be higher at certain platforms, when workload protection enforces on many applications

---

## Getting Started

To get started with the IoT Nano Agent Installer, you have two options:  
**Option 1: Download the Installer Directly** or **Option 2: Clone the Repository**.  
Choose one of the following methods:

### Option 1: Download the Installer Directly
To download only the installer, you can use the GitHub GUI or `wget`:

#### Using GitHub GUI:
1. Navigate to the [`iot_nano_agent_installer.sh`](./iot_nano_agent_installer.sh).
2. Click on the "Download raw file" button to download the file to your system.

#### Using `wget`:
Run the following command to download the installer directly:
```sh
wget https://raw.githubusercontent.com/CheckPointSW/IoT-Nano-Agent-Installer/main/iot_nano_agent_installer.sh
```

#### Once downloaded, make the script executable and run it:
```sh
chmod +x iot_nano_agent_installer.sh
sudo ./iot_nano_agent_installer.sh install
```

### Option 2: Clone the Repository
```sh
git clone git@github.com:romanlo993/IoT-Nano-Agent-Installer.git
cd IoT-Nano-Agent-Installer
sudo ./iot_nano_agent_installer.sh install
```

---

## Post-Installation Verification 

After the Nano Agent is installed, it runs in the background. However, applications are not protected until explicitly executed with protection enabled.

### Verify Nano Agent Installation
To confirm the Nano Agent is running, perform the following checks:

1. Verify the orchestrator process is active:
   ```sh
   ps aux | grep orchestration
   ```
   You should see a process named `cp-nano-orchestration` in the output.

2. Check the orchestrator log for the following message:
   ```sh
   grep "Your system is secured by Nano agent" /var/log/nano_agent/cp-nano-orchestration.log | tail -n 1
   ```
   The output should be a JSON-formatted log entry that includes the substring `Your system is secured by Nano agent`.
   This indicates the agent is active and ready to protect applications.

### Sanity Test
Perform a simple test to verify the Nano Agent is functioning correctly:
1. Run a command with the Nano Agent's library preloaded:
   ```sh
   LD_PRELOAD=libwlp-core.so ls
   ```
2. Expected output:
   ```
   Workload Protection started. Running: /usr/bin/ls
   <output of the ls command>
   ```
   This confirms the Nano Agent is intercepting and monitoring the `ls` command.

If the expected output is not observed, ensure the Nano Agent is installed correctly and the `libwlp-core.so` library is accessible.

---

## Enable Nano Agent Runtime Protection on Applications

The Nano Agent provides runtime protection through a set of **protection plugins**. Each plugin offers a specific type of protection. When a protected service or process is started, all plugins are initialized. During initialization, each plugin checks its relevancy to the process being protected and disables itself if it is irrelevant.

### How Protection Plugins Work
1. **Initialization**: All plugins listed in the `PLUGINS` variable in the Nano Agent configuration file (`/etc/cp/workloadProtection/wlp.conf`) are initialized when a process is started with the Nano Agent.
2. **Relevance Check**: During initialization, each plugin determines whether it is relevant to the process being protected. If a plugin is irrelevant, it disables itself automatically.
3. **Requirements**: For a protection plugin to work:
   - The plugin must be listed in the `PLUGINS` variable in `wlp.conf`.
   - The process must be started with the `libwlp-core.so` library preloaded using the `LD_PRELOAD` environment variable.
   - The protection must be relevant to the process being protected.

### Available Protection Plugins
Below is a list of available protection plugins, along with links to their detailed documentation. Each plugin has a sample scenario to demonstrate the protection:

1. [SSH Audit](./docs/SSH_Audit.md)  
   Audits all shell commands executed via SSH, including the user and timestamp.

2. [SSHD Login Protection](./docs/SSHD_Login_Protection.md)  
   Protects SSH servers by blocking brute force login attempts.

3. [Anti Brute Force (Web Login)](./docs/Anti_Brute_Force.md)  
   Protects web servers by limiting login attempts to prevent brute force attacks.

4. [Anti Shell Injection](./docs/Anti_Shell_Injection.md)  
   Detects and blocks command injection attempts.

5. [File Monitor](./docs/File_Monitor.md)  
   Monitors and blocks unauthorized access to files and attempts to manipulate executables at runtime.

---

## Using Nano Agent

The IoT Nano Agent is designed to both prevent attacks and inform users about potential security events. 

### Detection Mode
Upon installation, the Nano Agent is configured in **detection mode** by default. This allows users to explore and understand how the agent monitors and logs events without immediately affecting the system's behavior. Detection mode is ideal for observing the agent's capabilities and ensuring compatibility with your applications.

### Prevention Mode
Once users are comfortable with the agent's behavior, they can enable **prevention mode** to actively block malicious activities. This mode ensures that the system is protected against threats in real time. Review the configuration file to move from Detection mode to Prevention mode.

For more information about event logs and how to interpret them, refer to the [Logs Overview](./docs/Logs.md) documentation.

---

## Installer Supported Commands

### Install
```sh
./nano_agent_installer install [--version VERSION] [--update] [--clean]
```
- Installs Nano Agent.
- **--version**      Install a specific version.
- **--update**       Update if a newer version is available.
- **--clean**        Install without backing up/restoring configuration.

### Uninstall
```sh
./nano_agent_installer uninstall
```
- Uninstalls Nano Agent and removes files from `/etc/cp/`.

### Version
```sh
./nano_agent_installer version [--latest | --list]
```
- Without flags      Show the currently installed Nano Agent version.
- **--latest**        Show the latest available package version.
- **--list**          Show the installed version and list all available versions.

### Help
```sh
./nano_agent_installer -h | --help
```
- Displays this help message.

---

## Requirements

- Linux-based IoT device
- Root or sudo privileges
- `curl`
- `sha256sum` or `shasum`

---

## File Structure
- **iot_nano_agent_installer**: Main shell script.
- Manifest files per platform are expected under:  
  `https://raw.githubusercontent.com/romanlo993/IoT-Nano-Agent-Installer/main/manifests/<platform>`
- Nano Agent packages are fetched as `.sh` installers via GitHub Releases.

---

## Installation Path
Nano Agent is installed to:
```sh
/etc/cp/
```
The installed version is saved in:
```sh
/etc/cp/VERSION
```

---

## License
The installer provides you an access to a trial version of Check Point IoT Protect Nano agent.
The trial version of Check Point IoT Nano agent is limited to 90 days, and is available for developement and testing usage only. Commercial or production usages with this product are prohibited without explicit approval in written by Check Point Software [https://checkpoint.com](https://checkpoint.com)
The installer is under APACHE License – see the [LICENSE](LICENSE) file.

---

## Maintainers
Check Point Software Technologies [https://checkpoint.com](https://checkpoint.com)

Email us: [iot-device-security@checkpoint.com](iot-device-security@checkpoint.com)

---

> For any issues, please contact the maintainer or raise an issue on [GitHub](https://github.com/romanlo993/IoT-Nano-Agent-Installer).
