# Logs and Events Overview

The IoT Nano Agent generates various logs and events to help monitor and troubleshoot its functionality. 

---

## Orchestration Log (`orchestration.log`)

The `orchestration.log` file is the primary log file for the IoT Nano Agent and provides detailed information about the agent's operations. It is located at:
```sh
/var/log/nano_agent/cp-nano-orchestration.log
```

### Incident Log Overview - Event
The `orchestration.log` includes incident logs that provide critical details about detected security events. Each incident log entry is formatted as a JSON object and contains the following key information:
- **Event Time**: The exact time the incident occurred.
- **Event Name**: A descriptive name for the security event, including the type of protection and the command or process involved.
- **Event Code**: A unique identifier for this type of security event in a format of 015-[0-9].
- **Event Severity**: The severity level of the incident (e.g., Critical).
- **Event Priority**: The priority level of the incident (e.g., High).
- **Event Type**: The type of event (e.g., Event Driven).
- **Event Level**: The log level of the event (e.g., Log).
- **Event Source**: Details about the source of the event, including the agent ID, service name, and engine version.
- **Event Data**: Additional data about the event, such as a log index.

Example log entry:
```json
{
  "eventTime": "2022-03-09T16:34:39.001",
  "eventName": "IoT Embedded: Command Injection Blocked :: Shell Injection :: <PROCESS NAME> :: Command: ping -c 1 8.8.8.8;echo",
  "eventCode": "015-0001",
  "eventSeverity": "Critical",
  "eventPriority": "High",
  "eventType": "Event Driven",
  "eventLevel": "Log",
  "eventLogLevel": "info",
  "eventAudience": "Security",
  "eventAudienceTeam": "",
  "eventFrequency": 0,
  "eventTags": [
    "Threat Prevention"
  ],
  "eventSource": {
    "agentId": "0ed80a90-c574-48c5-948e-658c2f4b0e8d",
    "eventTraceId": "",
    "eventSpanId": "",
    "issuingEngineVersion": "1ed81be",
    "serviceName": "Workload Protection"
  },
  "eventData": {
    "logIndex": 2
  }
}
```

These logs are essential for understanding and responding to security incidents.

To get updates on new Events, use Linux inotify tool on the log file itself. syslog and Cloud logging are supported in the premium edition of the Nano agent.

---

## Workload Protection Log (`wlp_log.txt`)

The `wlp_log.txt` file is located in `/tmp/` and provides additional runtime information about the Nano Agent's workload protection activities. It is useful for debugging and verifying the agent's behavior during application execution. Maximum size for this file is 1MB.

---

## Crash Files

In the event of a crash, the Nano Agent generates crash files that contain diagnostic information to help identify the root cause. These files are typically located in the `/var/log/nano_agent/` directory and can be shared with Check Point support for further analysis.

---

For more detailed information, refer to the full documentation:  
[Quantum IoT Nano Agent Logging](https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/Quantum-IoT-Nano-Agent-Installation/Topics-NanoAgent-Installation-Guide/Logging.htm?tocpath=Logs%7C_____0#Logs)
