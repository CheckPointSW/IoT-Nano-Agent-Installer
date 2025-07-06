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
1. Verify that the `sshaudit` plugin is included in the `PLUGINS` variable:
   ```sh
   grep "PLUGINS =" /etc/cp/workloadProtection/wlp.conf | grep "sshaudit"
   ```
   If the output does not include `sshaudit`, edit the configuration file `wlp.conf` to add it:
   ```ini
   [Plugins]
   PLUGINS = sshaudit
   ```
2. Save the file. The Nano Agent service will automatically apply the updated configuration.

---

### Step 2: Add `LD_PRELOAD` to the SSH Service
The Nano Agent requires the `LD_PRELOAD` environment variable to be set for the SSH service.

**Note:** This section varies significantly between systems, and there isn't an exact command to execute. That is why the instructions are written as general directives to accommodate different system configurations.

#### Option 1: Systems Utilizing `systemd`
1. Identify the SSH service:
   Run the following command to list SSH-related services:
   ```sh
   systemctl list-unit-files | grep -Ei "ssh|dropbear"
   ```
   This will show services like `sshd.service`, `dropbear.service` or `ssh@.service`.

   - If you see `@` in the service name, it is a template service used for per-connection servers. Modifying the template applies changes to all new instances.

2. Add `LD_PRELOAD` to the service:
   Edit the service configuration:
   ```sh
   sudo systemctl edit <service_filename>
   ```
   Add the following lines to the override file:
   ```ini
   [Service]
   Environment="LD_PRELOAD=libwlp-core.so"
   ```
   Save and close the editor.

   #### Example for Editing Dropbear Template
   ```ini
   ### Editing /etc/systemd/system/dropbear@.service.d/override.conf
   ### Anything between here and the comment below will become the contents of the drop-in file

   [Service]
   Environment="LD_PRELOAD=libwlp-core.so"

   ### Edits below this comment will be discarded

   # [Unit]
   # Description=SSH Per-Connection Server
   # Wants=dropbearkey.service
   # After=syslog.target dropbearkey.service
   #
   # [Service]
   # Environment="DROPBEAR_RSAKEY_DIR=/etc/dropbear"
   # EnvironmentFile=-/etc/default/dropbear
   # ExecStart=-/usr/sbin/dropbear -i -r ${DROPBEAR_RSAKEY_DIR}/dropbear_rsa_host_key  $DROPBEAR_EXTRA_ARGS
   # ExecReload=/bin/kill -HUP $MAINPID
   # StandardInput=socket
   # KillMode=process
   ```

3. Restart the service:
   ```sh
   sudo systemctl restart <service_filename>
   ```
   > **Note:** Restarting is not required for template services like `ssh@.service`.


#### Option 2: Systems Utilizing `init.d`
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