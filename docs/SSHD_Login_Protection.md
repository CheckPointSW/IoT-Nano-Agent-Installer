# SSHD Login Protection Plugin

The **SSHD Login Protection** plugin streamlines the process of securing SSH servers by:
- Preventing brute force login attempts through rate limiting.
- Denying login attempts with blacklisted passwords, even if the password is correct.

The password blacklist is stored in:
```sh
/etc/cp/workloadProtection/sshd/blacklist
```

This plugin simplifies the implementation of security measures to protect SSH services against unauthorized access and weak password vulnerabilities.

---

### What is a Brute Force Attack?
A brute force attack is a method used by attackers to gain unauthorized access to a system by systematically trying all possible password combinations. This type of attack can compromise accounts with weak or commonly used passwords.

A common subtype of brute force attacks is the **dictionary attack**, where attackers use a predefined list of commonly used passwords (a "dictionary") to guess the correct password. This approach is faster than trying all possible combinations and is particularly effective against accounts with weak or predictable passwords.

The SSHD Login Protection plugin mitigates this threat by:
- **Rate Limiting**: Restricting the number of login attempts within a specific time frame, making brute force and dictionary attacks impractical.
- **Password Blacklist**: Denying login attempts with blacklisted passwords, encouraging the use of strong, secure passwords.

---

## How to Enable

Follow the steps below to enable the SSHD Login Protection plugin:

### Step 1: Enable the Plugin in Configuration
1. Open the Nano Agent configuration file:
   ```sh
   sudo nano /etc/cp/workloadProtection/wlp.conf
   ```
2. Locate the `[Plugins]` section and ensure the `sshd` plugin is included in the `PLUGINS` variable:
   ```ini
   [Plugins]
   PLUGINS = sshd, antibf
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

### Step 3: Verify SSHD Login Protection Functionality
To confirm that the SSHD Login Protection plugin is working as expected:

1. **Configure Rate Limiting**:  
   Open the Nano Agent configuration file and ensure the following settings are configured:
   ```ini
   SSHD_RATELIMIT_MAX = 3
   SSHD_RATELIMIT_SAMPLE_SEC = 120
   ```
   This configuration allows up to 3 failed login attempts within 120 seconds before the rate limit is triggered.

2. **Monitor Logs in Real-Time**:  
   Open a shell and monitor the logs:
   ```sh
   tail -f /tmp/wlp_log.txt | grep "SSHD"
   ```
   Logs will display messages in the format:
   ```
   [Time PID] [SSHD] Ratelimit: n/3
   ```

3. **Simulate Failed Login Attempts**:  
   Enter incorrect passwords multiple times:
   ```sh
   ssh user@protected-system
   ```
   Repeat this command to trigger the rate limit. When the rate limit is reached (3 failed login attempts within 120 seconds), the following log will appear:
   ```
   [Time PID] [SSHD] Ratelimit reached (3 login attempts in 120 seconds).
   ```

4. **Verify Rate Limit Behavior**:  
   After the rate limit is triggered, even correct passwords will not work until the 120-second timeout has passed.

5. **Test the Blacklist Functionality**:  
   Add a weak password to the blacklist file:
   ```sh
   echo "weakpassword123" | sudo tee -a /etc/cp/workloadProtection/sshd/blacklist
   ```
   Attempt to log in with the blacklisted password. The login will be denied, and the following log will appear:
   ```
   [Time PID] [SSHD] Password [weakpassword123] is in the blacklist.
   ```

This confirms that the SSHD Login Protection plugin is actively preventing brute force login attempts and enforcing the password blacklist.

---

## Troubleshooting
- **No logs are generated**:  
  Ensure the `sshd` plugin is listed in the `PLUGINS` variable in `wlp.conf` and that the `LD_PRELOAD` variable is correctly set.

- **Service fails to start**:  
  Verify that the `libwlp-core.so` library is accessible and compatible with your system.

- **Login denied for valid password**:  
  Check if the password is listed in the blacklist file:
  ```sh
  cat /etc/cp/workloadProtection/sshd/blacklist | grep <password>
  ```
  If the password is blacklisted, consider changing the password to a stronger one. Removing the password from the blacklist is possible but not recommended:
  ```sh
  sudo nano /etc/cp/workloadProtection/sshd/blacklist
  ```

For further assistance, refer to the [Nano Agent Documentation](https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/Quantum-IoT-Nano-Agent-Installation/Default.htm).
