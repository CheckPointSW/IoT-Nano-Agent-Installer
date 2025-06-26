# SSH Audit Plugin

The **SSH Audit** plugin provides comprehensive auditing of all shell commands executed via SSH. It logs critical details such as:
- The user who executed the command.
- The timestamp of the command execution.
- The command itself.

This plugin is particularly useful for monitoring administrative activities and ensuring accountability on protected systems.

---

## How to Enable

Follow the steps below to enable the SSH Audit plugin:

### Step 1: Enable the Plugin in Configuration
1. Open the Nano Agent configuration file:
   ```sh
   sudo nano /etc/cp/workloadProtection/wlp.conf
   ```
2. Locate the `[Plugins]` section and ensure the `sshaudit` plugin is included in the `PLUGINS` variable:
   ```ini
   [Plugins]
   PLUGINS = sshd, antibf, sshaudit
   ```
3. Save the file. The Nano Agent service will automatically apply the updated configuration.

---

### Step 2: Add `LD_PRELOAD` to the SSH Service
The Nano Agent requires the `LD_PRELOAD` environment variable to be set for the SSH service. Depending on your system's initialization method, follow one of the options below:

#### Option 1: Using `systemd`
1. Identify the SSH service running on your system:
   ```sh
   systemctl list-units --type=service | grep -i ssh
   ```
   This will display any SSH-related services (e.g., `sshd`, `dropbear`).

2. Edit the corresponding service file:
   - For OpenSSH (`sshd`):
     ```sh
     sudo nano /lib/systemd/system/ssh.service
     ```
   - For Dropbear:
     ```sh
     sudo nano /lib/systemd/system/dropbear.service
     ```

3. Add or modify the `Environment` variable in the `[Service]` section:
   ```sh
   Environment="LD_PRELOAD=libwlp-core.so"
   ```

4. Save the file and reload the systemd configuration:
   ```sh
   sudo systemctl daemon-reload
   sudo systemctl restart ssh
   ```
   For Dropbear, use:
   ```sh
   sudo systemctl daemon-reload
   sudo systemctl restart dropbear*
   ```

#### Option 2: Using `init.d`
1. Locate the SSH startup script:
   - For OpenSSH:
     ```sh
     sudo nano /etc/init.d/ssh
     ```
   - For Dropbear:
     ```sh
     sudo nano /etc/init.d/dropbear
     ```

2. Add the following line near the top of the script, after the shebang (`#!/bin/sh`):
   ```sh
   export LD_PRELOAD=libwlp-core.so
   ```

3. Save the file and restart the SSH service:
   ```sh
   sudo /etc/init.d/ssh restart
   ```
   For Dropbear, use:
   ```sh
   sudo /etc/init.d/dropbear restart
   ```

---

### Step 3: Verify SSH Audit Functionality
To confirm that the SSH Audit plugin is working as expected:

1. Open two SSH sessions to the protected system:
   - **Session 1 (Monitoring)**: Monitor the system logs for audit entries:
     ```sh
     sudo tail -f /var/log/syslog | grep "cp-ssh-audit"
     ```
   - **Session 2 (Executing Commands)**: Execute commands via SSH:
     ```sh
     ls
     whoami
     ```

2. In the first session, you should see real-time logs of the commands executed in the second session. Example log entry:
   ```
   cp-ssh-audit: User 'user' executed command 'ls' at 2023-10-01T12:34:56Z
   ```

This confirms that the SSH Audit plugin is capturing and logging all relevant activities.

---

## Troubleshooting
- **No logs are generated**: Ensure the `sshaudit` plugin is listed in the `PLUGINS` variable in `wlp.conf` and that the `LD_PRELOAD` variable is correctly set.
- **Service fails to start**: Verify that the `libwlp-core.so` library is accessible and compatible with your system.

For further assistance, refer to the [Nano Agent Documentation](https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/Quantum-IoT-Nano-Agent-Installation/Default.htm).