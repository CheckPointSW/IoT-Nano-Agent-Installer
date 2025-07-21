# Configuration Guide

The IoT Nano Agent configuration is primarily managed through the file located at:
```sh
/etc/cp/workloadProtection/wlp.conf
```

This file contains key settings that control the behavior of the Nano Agent and its plugins. The configuration is automatically updated for protected services, but in cases of major changes (e.g., adding or disabling a plugin), the service may require a restart to apply the changes.

---

## Common Changes

Below are some common configuration changes you may need to make:

### Plugins
The `PLUGINS` variable defines the list of enabled plugins for the Nano Agent. Each plugin provides specific protections, such as SSH auditing or shell injection prevention.

To enable or disable plugins:
1. Open the configuration file:
   ```sh
   sudo nano /etc/cp/workloadProtection/wlp.conf
   ```
2. Locate the `[Plugins]` section and modify the `PLUGINS` variable. For example:
   ```ini
   [Plugins]
   PLUGINS = sshaudit, antisi3, filemon
   ```
   - To add a plugin, include its name in the list (e.g., `antisi3`).
   - To disable a plugin, remove its name from the list.

3. Save the file and restart the relevant service if required.

### Prevention
The `PREVENTION` variable controls whether the Nano Agent actively blocks malicious activities or operates in detection mode.

To change the prevention mode:
1. Open the configuration file:
   ```sh
   sudo nano /etc/cp/workloadProtection/wlp.conf
   ```
2. Locate the `[General]` section and modify the `PREVENTION` variable. For example:
   ```ini
   [General]
   PREVENTION = True
   ```
   - Set to `True` to enable prevention mode (actively blocks threats).
   - Set to `False` to enable detection mode (logs threats without blocking).

3. Save the file. A service restart is typically not required for this change.

---

## Allow and Block Lists

The Nano Agent uses `whitelist` and `blacklist` files to manage exceptions for certain plugins. These files are located in sub-directories within `/etc/cp/workloadProtection/`:
-   `filemon`: For the File Monitor plugin.
-   `antisi`: For the Anti-Shell Injection / Remote Code Execution plugin.

Each of these directories contains a `whitelist` and a `blacklist` file. You can add one file path per line, and wildcards (`*`) are supported.

For example, to allow all files to be written in the `/tmp/` directory, add the following line to the appropriate `whitelist` file:
```sh
/tmp/*
```

Similarly, to block all files in the `/var/log/` directory, add the following line to the appropriate `blacklist` file:
```sh
/var/log/*
```

Changes to these files take effect immediately and do not require a service restart.

---

## Killswitch

The Nano Agent includes a killswitch mechanism to disable protections in case of unpredicted behavior or for debugging purposes. This is controlled through the file:
```sh
/etc/cp/workloadProtection/killswitch
```

You can write the following values to this file:
-   `0`: Enable all protections.
-   `1`: Disable all plugins.
-   `2`: Disable protection completly.

Changes to the killswitch file take effect immediately and do not require a service restart.

---


For more detailed information about configuration options, refer to the [Nano Agent Documentation](https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/Quantum-IoT-Nano-Agent-Installation/Default.htm).
