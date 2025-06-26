# Anti Shell Injection Plugin

The **Anti Shell Injection** plugin detects and blocks command injection attempts in any protected process.

### What is Shell Injection?
Shell injection is a type of security vulnerability that occurs when an attacker injects malicious commands into a program's input, which are then executed by the system's shell. This can lead to unauthorized access, data theft, or system compromise. The Anti Shell Injection plugin prevents such attacks by detecting and blocking these malicious commands in real time.

---

## How to Enable

Follow the steps below to enable the Anti Shell Injection plugin:

### Step 1: Enable the Plugin in Configuration
1. Open the Nano Agent configuration file:
   ```sh
   sudo nano /etc/cp/workloadProtection/wlp.conf
   ```
2. Locate the `[Plugins]` section and ensure the `antisi3` plugin is included in the `PLUGINS` variable:
   ```ini
   [Plugins]
   PLUGINS = antisi3
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

### Step 3: Verify Anti Shell Injection Functionality
To confirm that the Anti Shell Injection plugin is working as expected, follow these steps:

#### Testing on a Vulnerable Server Example
In this section, we will test the plugin using an example of a vulnerable webserver (`si_vulnerable_webserver.sample`) and an exploit (`antisi.exploit`). The example server is designed to receive an IP address as input and ping it. This demonstrates how the plugin detects and blocks shell injection attempts. You must follow a similar process to test your own server or application.

1. **Prepare the Environment**:
   - Ensure no instances of the vulnerable webserver or exploit are running:
     ```sh
     kill -9 $(pidof si_vulnerable_webserver.sample) 
     echo "" > /tmp/wlp_log.txt
     ```
   - Ensure the vulnerable webserver and exploit have executable permissions:
     ```sh
     chmod +x /etc/cp/workloadProtection/samples/si_vulnerable_webserver.sample
     chmod +x /etc/cp/workloadProtection/samples/antisi.exploit
     ```

2. **Demonstrate the Intended Purpose of the Server**:
   - Start the vulnerable webserver:
     ```sh
     /etc/cp/workloadProtection/samples/si_vulnerable_webserver.sample 3333 &
     ```
   - Use the server as intended by providing a valid IP address to ping:
     ```sh
     echo "8.8.8.8" | nc localhost 3333
     ```
   - Expected output:
     ```
     PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
     64 bytes from 8.8.8.8: icmp_seq=1 ttl=128 time=6.29 ms

     --- 8.8.8.8 ping statistics ---
     1 packets transmitted, 1 received, 0% packet loss, time 0ms
     rtt min/avg/max/mdev = 6.292/6.292/6.292/0.000 ms
     ```
   - Stop the webserver:
     ```sh
     kill -9 $(pidof si_vulnerable_webserver.sample)
     ```

3. **Test Exploit Without Protection**:
   - Start the vulnerable webserver without the Nano Agent library:
     ```sh
     /etc/cp/workloadProtection/samples/si_vulnerable_webserver.sample 3333 &
     ```
   - Run the exploit against the webserver:
     ```sh
     /etc/cp/workloadProtection/samples/antisi.exploit 3333 && sleep 0.5
     ```
   - **Expected Behavior**:  
     The exploit will succeed, and you will see output indicating you have been hacked.
   - Stop the webserver:
     ```sh
     kill -9 $(pidof si_vulnerable_webserver.sample)
     ```

4. **Test Exploit With Protection**:
   - Start the vulnerable webserver with the Nano Agent library preloaded:
     ```sh
     LD_PRELOAD=/usr/lib/libwlp-core.so /etc/cp/workloadProtection/samples/si_vulnerable_webserver.sample 3333 &
     ```
   - Run the exploit against the webserver:
     ```sh
     /etc/cp/workloadProtection/samples/antisi.exploit 3333 && sleep 0.5
     ```
   - Stop the exploit and the webserver:
     ```sh
     kill -9 $(pidof antisi.exploit) 
     kill -9 $(pidof si_vulnerable_webserver.sample)
     ```

5. **Check the Logs**:
   - Search the logs for shell injection detection:
     ```sh
     grep "ANTISI" /tmp/wlp_log.txt
     ```
   - Alternatively, check the orchestration log for detailed event information:
     ```sh
     grep "Shell Injection" /var/log/nano_agent/cp-nano-orchestration.log | tail -n 1
     ```
   - If the plugin is working correctly, you should see a log entry similar to:
     ```
     Shell injection detected at: [ping -c 1 8.8.8.8;echo ...;cat ./skull.txt 2>&1]
     ```
     Or a JSON log containing shell injection information.

   - If no log entry is found, the plugin is not functioning as expected.

#### Testing Your Own Server
To test your own server or application:
1. Follow the same steps as above, replacing the vulnerable webserver and exploit with your own server and a relevant test case.
2. Ensure the `LD_PRELOAD` variable is set for your server's startup script.
3. Simulate a shell injection attempt and check the logs for detection.

---

## Troubleshooting

If you encounter issues while using the Anti Shell Injection plugin, refer to the following troubleshooting steps:

- **No logs are generated**:  
  Ensure the `antisi3` plugin is listed in the `PLUGINS` variable in `/etc/cp/workloadProtection/wlp.conf` and that the `LD_PRELOAD` variable is correctly set for the process.

- **Service fails to start**:  
  Verify that the `libwlp-core.so` library is accessible and compatible with your system. Check the system logs for any errors related to the Nano Agent.

- **Exploit succeeds with protection enabled**:  
  Ensure the process is started with the `LD_PRELOAD` variable set. Verify that the Nano Agent is running and that the plugin is initialized correctly.

- **Logs do not show shell injection detection**:  
  Check the orchestration log for detailed event information:
  ```sh
  grep "Shell Injection" /var/log/nano_agent/cp-nano-orchestration.log | tail -n 1
  ```
  If no relevant logs are found, ensure the plugin is enabled and relevant to the process being protected.

For further assistance, refer to the [Nano Agent Documentation](https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/Quantum-IoT-Nano-Agent-Installation/Default.htm) or contact Check Point support.

---
