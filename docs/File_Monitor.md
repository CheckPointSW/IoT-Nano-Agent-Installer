# File Monitor Plugin

The File Monitor plugin is a **file access control and monitoring tool** which is designed to enforce strict security policies on file operations, log violations, and prevent malicious activities such as privilege escalation, persistence, and code injection.

---

## **What Does It Protect From?**

### 1. Path Traversal Attacks
- Detects and blocks attempts to access files using path traversal techniques (e.g., `../`, `..`, `~`) to prevent unauthorized access to restricted directories.

### 2. Unauthorized File Access
- Enforces access control by checking file paths against a whitelist and a blacklist, explicitly allowing or denying access as configured.

### 3. Modification of Executable Files
- Prevents tampering with executable files (e.g., ELF binaries, shared libraries) by blocking write operations.
- Blocks access to files with certain extensions (e.g., `.sh`, `.py`, `.js`, `.class`, `.jar`, `.so`, `.lua`) to prevent execution of scripts or dynamic libraries.

### 4. Unauthorized File Creation
- Blocks file creation in restricted directories (e.g., `init.d`, `systemd`) to prevent unauthorized configuration changes or persistence mechanisms.

### 5. Dangerous Permission Changes
- Prevents changes to file permissions that could make files executable, reducing the risk of privilege escalation or malicious script execution.

---

## **Additional Features**

### Prevention Levels
- Enforces different levels of prevention based on configuration (e.g., `FILEMON_PL`), allowing for flexible security policies.

### Monitoring and Logging
- Logs all unauthorized access attempts and reports them to nano service, providing visibility into potential security incidents.

---

## How to Enable

Follow the steps below to enable the File Monitor plugin:

### Step 1: Enable the Plugin in Configuration
1. Verify that the `filemon` plugin is included in the `PLUGINS` variable:
   ```sh
   grep "PLUGINS =" /etc/cp/workloadProtection/wlp.conf | grep "filemon"
   ```
   If the output does not include `filemon`, edit the configuration file `wlp.conf` to add it:
   ```ini
   [Plugins]
   PLUGINS = filemon
   ```
3. Save the file. The Nano Agent service will automatically apply the updated configuration.

---

### Step 2: Add `LD_PRELOAD` to the Protected Process
The Nano Agent requires the `LD_PRELOAD` environment variable to be set for the process you want to protect.

- **To run a command or process protected once**, you can directly call:
  ```sh
  LD_PRELOAD=libwlp-core.so <process_command>
  ```

- **To make a service protected permanently**, this can be done by modifying the startup script of the process. For example, if your process is managed by `systemd`, you can add the `LD_PRELOAD` variable to the service file. Refer to the [SSH Audit documentation](./SSH_Audit.md) for a detailed example on how to modify a service file or startup script.

---

### Step 3: Configure Blacklist and Whitelist
The File Monitor plugin uses a blacklist and whitelist to enforce file modification rules:

1. **Blacklist**:  
   Files listed in the blacklist cannot be modified by the process, even if they are not executables.  
   Location:  
   ```sh
   /etc/cp/workloadProtection/filemon/blacklist
   ```
   Example:
   ```plaintext
   /etc/passwd
   /var/log/secure
   ```

2. **Whitelist**:  
   Files listed in the whitelist can be modified by the process, even if they are executables.  
   Location:  
   ```sh
   /etc/cp/workloadProtection/filemon/whitelist
   ```
   Example:
   ```plaintext
   /usr/local/bin/allowed_script.sh
   /opt/custom_app/executable
   ```

3. **Edit the Lists**:  
   To add or remove files from the blacklist or whitelist, edit the respective files:
   ```sh
   sudo nano /etc/cp/workloadProtection/filemon/blacklist
   sudo nano /etc/cp/workloadProtection/filemon/whitelist
   ```

---

### Step 4: Verify File Monitor Functionality
To confirm that the File Monitor plugin is working as expected:

1. **Monitor Logs in Real-Time**:  
   Open a shell and monitor the logs:
   ```sh
   tail -f /tmp/wlp_log.txt | grep "FILEMON"
   ```
   Logs will display messages in the format:
   ```
   [Time PID] [FILEMON] Blocked access to /path/to/file by process <process_name>.
   ```

2. **Simulate Unauthorized Access**:  
   - Copy the `ls` binary to a local directory:
     ```sh
     cp /bin/ls ./ls
     ```
   - Verify the copy by calling it:
     ```sh
     ./ls
     ```
     This should display the contents of the current directory.

   - Attempt to modify the copied binary using `LD_PRELOAD`:
     ```sh
     LD_PRELOAD=libwlp-core.so sh -c "echo 'hello' >> ls"
     ```
     **Expected Output**:
     ```
     [MAIN] [PID] Workload Protection started. Running: /usr/bin/dash
     sh: 1: echo: echo: I/O error
     ```

   - Check the logs for the blocked modification:
     ```sh
     tail -f /tmp/wlp_log.txt | grep "FILEMON"
     ```
     **Expected Log Entry**:
     ```
     [TIME PID TID] [FILEMON] Unauthorized access to file /your/local/ls
     ```

   - Verify the Local `ls` Binary:  
     Ensure the `ls` binary was not corrupted by checking its strings:
     ```sh
     strings ls | tail -n 1
     ```
     The output should not contain the string `hello` or any unexpected modifications.

3. **Test Whitelist Functionality**:  
   - Add the copied `ls` binary to the whitelist:
     ```sh
     echo "$(pwd)/ls" | sudo tee -a /etc/cp/workloadProtection/filemon/whitelist
     ```
   - Attempt to modify the copied binary again:
     ```sh
     LD_PRELOAD=libwlp-core.so sh -c "echo 'hello' >> ls"
     ```
     **Expected Output**:  
     The modification will succeed without any errors.

   - Verify that the local `ls` binary was modified:
     ```sh
     strings ls | tail -n 1
     ```
     **Expected Output**:
     ```
     hello
     ```

   - Verify that no log entry is generated for this modification:
     ```sh
     tail -f /tmp/wlp_log.txt | grep "FILEMON"
     ```
     No new log entries should appear for this operation.

---

## Troubleshooting

If you encounter issues while using the File Monitor plugin, refer to the following troubleshooting steps:

- **No logs are generated**:  
  Ensure the `filemon` plugin is listed in the `PLUGINS` variable in `/etc/cp/workloadProtection/wlp.conf` and that the `LD_PRELOAD` variable is correctly set for the process.

- **Service fails to start**:  
  Verify that the `libwlp-core.so` library is accessible and compatible with your system. Check the system logs for any errors related to the Nano Agent.

- **Access denied for valid operations**:  
  Ensure the file being accessed is included in the whitelist if it is allowed to be modified by the protected process. Update the whitelist as needed:
  ```sh
  sudo nano /etc/cp/workloadProtection/filemon/whitelist
  ```

- **Sensitive files are not protected**:  
  Verify that non-executable sensitive files (e.g., `/etc/passwd`, `/var/log/secure`) are included in the blacklist. Update the blacklist as needed:
  ```sh
  sudo nano /etc/cp/workloadProtection/filemon/blacklist
  ```

- **Logs do not show file access violations**:  
  Check the orchestration log for detailed event information:
  ```sh
  grep "FILEMON" /var/log/nano_agent/cp-nano-orchestration.log | tail -n 1
  ```
  If no relevant logs are found, ensure the plugin is enabled and relevant to the process being protected.

For further assistance, refer to the [Nano Agent Documentation](https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/Quantum-IoT-Nano-Agent-Installation/Default.htm) or contact Check Point support.

---
