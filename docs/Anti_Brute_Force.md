# Anti Brute Force Plugin (Web Login)

The **Anti Brute Force** plugin protects web servers by limiting login attempts to prevent brute force attacks.

---

## **What Does It Protect From?**

### 1. Brute Force Attacks
- Limits the number of login attempts within a specific time frame, making brute force attacks impractical.

### 2. Weak Password Usage
- Identifies and blocks login attempts using weak or commonly used passwords from a predefined blacklist, enforcing stronger password policies.

**Note**: The blacklist is shared with the `SSHD Login Protection` plugin and is located at:
```sh
/etc/cp/workloadProtection/sshd/blacklist
```

---

## **Additional Features**

### Monitoring and Logging
- Logs all blocked login attempts and reports them to the Nano Agent service, providing visibility into potential security incidents.

---

## **How to Enable**

Follow the steps below to enable the Anti Brute Force plugin:

### Step 1: Enable the Plugin in Configuration
1. Verify that the `antibf` plugin is included in the `PLUGINS` variable:
   ```sh
   grep "PLUGINS =" /etc/cp/workloadProtection/wlp.conf | grep "antibf"
   ```
   If the output does not include `antibf`, edit the configuration file `wlp.conf` to add it:
   ```ini
   [Plugins]
   PLUGINS = antibf
   ```
2. Verify the rate-limiting configuration:
   ```ini
   # ANTIBF Ratelimit sample seconds (how many login attempts are allowed in how many seconds)
   ANTIBF_RATELIMIT_SAMPLE_SEC = 10

   # ANTIBF Ratelimit sample retries (how many attempts are allowed for every RATELIMIT_SAMPLE_SEC seconds)
   ANTIBF_RATELIMIT_MAX = 3
   ```
   Ensure these values are set according to your security requirements.

3. Save the file. The Nano Agent service will automatically apply the updated configuration.

---

### Step 2: Add `LD_PRELOAD` to the Protected Process
The Nano Agent requires the `LD_PRELOAD` environment variable to be set for the process you want to protect.

- **To run a command or process protected once**, you can directly call:
  ```sh
  LD_PRELOAD=libwlp-core.so <web_server_command>
  ```

- **To make a service protected permanently**, this can be done by modifying the startup script of the process. For example, if your process is managed by `systemd`, you can add the `LD_PRELOAD` variable to the service file. Refer to the [SSH Audit documentation](./SSH_Audit.md) for a detailed example on how to modify a service file or startup script.

---

### Step 3: Verify Anti Brute Force Functionality
To confirm that the Anti Brute Force plugin is working as expected, follow these steps:

#### Testing on a Vulnerable Server Example
In this section, we will test the plugin using an example of a vulnerable webserver (`bf_vulnerable_webserver.sample`) and a brute force simulation (`bf_simulation.sample`). The example server is designed to simulate a login mechanism with a username and password. This demonstrates how the plugin detects and blocks brute force attacks.

**Note**: The brute force simulation (`bf_simulation.sample`) is custom to the example server and will not work on other servers.

1. **Prepare the Environment**:
   - Ensure the vulnerable webserver and brute force simulation have executable permissions:
     ```sh
     chmod +x /etc/cp/workloadProtection/samples/bf_vulnerable_webserver.sample
     chmod +x /etc/cp/workloadProtection/samples/bf_simulation.sample
     ```

2. **Run the Server Unprotected**:
   - Start the vulnerable webserver:
     ```sh
     /etc/cp/workloadProtection/samples/bf_vulnerable_webserver.sample
     ```
   - The server will run on the default port `9888`. If you have a browser, you can open `http://localhost:9888` to access the login page.
   - The credentials are:
     - Username: `admin`
     - Password: `IoT`

3. **Simulate a Brute Force Attack**:
   - In another terminal, run the brute force attack simulation:
     ```sh
     /etc/cp/workloadProtection/samples/bf_simulation.sample
     ```
   - The simulation will attempt to connect multiple times to the server with different passwords, eventually finding the correct password `IoT`.

   **Expected Output**:
   ```
   Starting brute force attack simulation on 127.0.0.1:9888
   Attempt 88: Trying password 'IoK' - Failed                
   Attempt 89: Trying password 'IoL' - Failed                
   Attempt 90: Trying password 'IoM' - Failed                
   Attempt 91: Trying password 'IoN' - Failed                
   Attempt 92: Trying password 'IoO' - Failed                
   Attempt 93: Trying password 'IoP' - Failed                
   Attempt 94: Trying password 'IoQ' - Failed                
   Attempt 95: Trying password 'IoR' - Failed                
   Attempt 96: Trying password 'IoS' - Failed                
   Attempt 97: Trying password 'IoT'
   Login successful with password: 'IoT'
   Brute force attack was successful!!!
   ```

4. **Exit the Previous Server**:
   - Stop the unprotected server before running it again:
     ```sh
     kill -9 $(pidof bf_vulnerable_webserver.sample)
     ```

5. **Run the Server with Protection**:
   - Start the vulnerable webserver with the Nano Agent library preloaded:
     ```sh
     LD_PRELOAD=libwlp-core.so /etc/cp/workloadProtection/samples/bf_vulnerable_webserver.sample
     ```
   - **Note**: If you encounter the error `Failed to bind. errno 98`, it means the port is still in use. Wait a few seconds for the port to be released, or manually free the port by identifying and killing the process using it:
     ```sh
     sudo lsof -i :9888
     sudo kill -9 <PID>
     ```

   - **Expected Output**:
     ```
     [MAIN] [PID] Workload Protection started. Running: /etc/cp/workloadProtection/samples/bf_vulnerable_webserver.sample.
     ```

6. **Simulate the Brute Force Attack Again**:
   - Run the brute force attack simulation as before:
     ```sh
     /etc/cp/workloadProtection/samples/bf_simulation.sample
     ```
   - **Expected Output**:
     ```
     Starting brute force attack simulation on 127.0.0.1:9888
     Attempt 91: Trying password 'IoN' - Blocked by Check Point
     Attempt 92: Trying password 'IoO' - Blocked by Check Point
     Attempt 93: Trying password 'IoP' - Blocked by Check Point
     Attempt 94: Trying password 'IoQ' - Blocked by Check Point
     Attempt 95: Trying password 'IoR' - Blocked by Check Point
     Attempt 96: Trying password 'IoS' - Blocked by Check Point
     Attempt 97: Trying password 'IoT' - Blocked by Check Point
     Attempt 98: Trying password 'IoU' - Blocked by Check Point
     Attempt 99: Trying password 'IoV' - Blocked by Check Point
     Attempt 100: Trying password 'IoW'
     Failed to find the correct password.
     ```

   - **Note**: During the attack, if you have a browser on the tested device, you can go to `http://localhost:9888` and try to log in. Even when using the correct credentials, you should see a Check Point error page. After waiting 10 seconds following the attack, the login should work as expected.

7. **Check the Logs**:
   - Search the logs for brute force detection:
     ```sh
     grep "Login Protection" /var/log/nano_agent/cp-nano-orchestration.log | tail -n 1
     ```

   - If no log entry is found, the plugin is not functioning as expected.

---

## **Troubleshooting**

If you encounter issues while using the Anti Brute Force plugin, refer to the following troubleshooting steps:

- **No logs are generated**:  
  Ensure the `antibf` plugin is listed in the `PLUGINS` variable in `/etc/cp/workloadProtection/wlp.conf` and that the `LD_PRELOAD` variable is correctly set for the process.

- **Service fails to start**:  
  Verify that the `libwlp-core.so` library is accessible and compatible with your system. Check the system logs for any errors related to the Nano Agent.

- **Blocked login attempts are not detected**:  
  Ensure the plugin is enabled and relevant to the process being protected. Verify that the Nano Agent is running and monitoring the correct process.

- **Logs do not show blocked login attempts**:  
  Check the orchestration log for detailed event information:
  ```sh
  grep "Login Protection" /var/log/nano_agent/cp-nano-orchestration.log | tail -n 1
  ```
  If no relevant logs are found, ensure the plugin is enabled and relevant to the process being protected.

For further assistance, refer to the [Nano Agent Documentation](https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/Quantum-IoT-Nano-Agent-Installation/Default.htm) or contact Check Point support.

---
