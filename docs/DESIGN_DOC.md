Project Sentinel: Design Document
Status: Inception | Version: 0.1 | Date: 2025-09-21

1. Abstract
Project Sentinel is an AI-driven, kernel-level security platform engineered to provide autonomous threat detection and response for modern cloud-native environments. By leveraging eBPF for deep, frictionless kernel telemetry, Sentinel streams syscall and network activity to a sophisticated AI control plane. This control plane employs a transformer-based neural network to learn the "grammar" of normal system behavior, enabling it to detect and mitigate novel zero-day attacks in real-time. Upon detecting a high-confidence anomaly, a policy-driven response engine autonomously generates and deploys mitigating eBPF firewall rules across the fleet in under 100 milliseconds, establishing a proactive, self-healing security posture without requiring human intervention.

2. Goals, Vision & Success Metrics

2.1 Vision Statement

To create a fully autonomous security fabric that acts as an immune system for the cloud, continuously learning, adapting, and defending against an evolving threat landscape.

2.2 Core Goals

Primary Goal: To detect and automatically mitigate zero-day threats and novel attack vectors in a Kubernetes environment before they can cause significant harm.

Secondary Goal: To provide deep, contextual security observability into distributed applications with minimal performance overhead.

2.3 Key Performance Indicators (KPIs)

The success of Sentinel will be measured against the following engineering targets:

Detection Accuracy: Achieve Precision/Recall > 99.5% on a suite of simulated zero-day and container escape exploits.

End-to-End Mitigation Latency: p99 latency from event creation in the kernel to mitigating eBPF rule deployment must be < 100ms.

Agent Performance Overhead: The Sentinel agent must impose an overhead of < 2% CPU and < 100MB RAM per node under a sustained load of 1 million events/sec.

3. System Principles & Safeguards

An autonomous security system wields significant power. Sentinel is designed around principles that ensure safety, trustworthiness, and operational stability.

Explainability First: The system must not be a black box. Every detection must be accompanied by a human-readable explanation from the XAI engine, enabling operators to trust and verify its decisions.

Least Invasive Mitigation: The response engine will always default to the most surgical, least disruptive action possible (e.g., blocking a single malicious IP before isolating an entire pod).

Declarative Policy & GitOps: All response actions are governed by declarative SecurityPolicy CRDs stored in version control. There is no imperative, hardcoded logic, ensuring all actions are auditable, reviewable, and follow GitOps principles.

Human-in-the-Loop Mode: The platform will support an "alert-only" or "dry-run" mode, allowing operators to validate the AI's accuracy and the impact of its proposed mitigations before enabling fully autonomous blocking.

4. V1 Architecture

The system is composed of four primary planes: Data, Control, Response, and Observability, operating in a continuous, closed loop.

This diagram is rendered from docs/arch.md.

The data flow is as follows:

eBPF Probes capture kernel events, sending them to the local Sentinel Agent.

The Agent enriches the data and streams it to a central Kafka Cluster.

The AI/ML Service consumes this stream, using the Transformer Model to score events for anomalies in real-time. Historical data is stored in ClickHouse for model training.

High-scoring anomalies are analyzed by the XAI Engine and sent as alerts to the Policy Engine.

The Policy Engine generates a response and uses gRPC to command the relevant on-node Agent to deploy a mitigating eBPF rule, all of which is monitored by Prometheus and Grafana.

5. Technology Stack Justification
The technology choices for Project Sentinel are deliberate, prioritizing performance, safety, scalability, and cutting-edge AI capabilities.

5.1 Agent Language: Rust

The Sentinel agent runs as a privileged DaemonSet on every node, making its stability and security paramount.

Why Rust? Memory Safety and Concurrency. Rust's ownership model and borrow checker eliminate entire classes of bugs (null pointer dereferences, buffer overflows, data races) at compile time. This is non-negotiable for a security-critical component running with high privileges. Its "fearless concurrency" allows for efficient, multi-threaded processing of high-volume eBPF event streams without sacrificing safety.

Alternative Considered: Go. While Go offers excellent concurrency, it is not memory-safe in the same way as Rust. Its garbage collector can introduce non-deterministic latency, and the risk of memory-related vulnerabilities, though lower than in C++, still exists. For a kernel-adjacent security agent, Rust's compile-time guarantees are superior.

5.2 Kernel Instrumentation: C & libbpf/aya

The interface with the Linux kernel must be as low-level and performant as possible.

Why C & libbpf? Direct Kernel ABI & Performance. eBPF programs are written in a restricted C, which is the native language of the kernel. Using libbpf (or Rust wrappers like aya that build upon it) provides a robust, future-proof way to interact with the kernel's eBPF API. This "Compile Once - Run Everywhere" (CO-RE) approach ensures maximum performance and portability across different kernel versions.

Alternative Considered: BCC (BPF Compiler Collection). BCC is an excellent tool for ad-hoc debugging and scripting but is not suitable for a production agent. It relies on runtime compilation, which adds significant overhead and dependencies (LLVM/Clang) to the production nodes.

5.3 Anomaly Detection Model: Transformers

The core of Sentinel's intelligence lies in its ability to understand the context of system events, not just individual data points.

Why Transformers? Contextual Sequence Understanding. The transformer architecture, originally designed for natural language processing, is uniquely suited for modeling sequences of system events (syscalls, network flows). Its self-attention mechanism allows it to weigh the importance of different events in a long sequence, learning complex relationships like "a java process should never be the parent of a /bin/bash process, especially after receiving an anomalous LDAP connection."

Alternative Considered: LSTM/RNNs. While capable of processing sequences, LSTMs are notoriously difficult to train and suffer from the vanishing gradient problem, making it hard for them to capture very long-range dependencies common in system behavior. Transformers do not have this limitation and have become the state-of-the-art for sequence modeling tasks.

5.4 Event Streaming: Kafka

The telemetry data from thousands of nodes must be collected reliably and scalably.

Why Kafka? Scalability, Durability, and Ecosystem. Kafka is the industry standard for high-throughput, distributed event streaming. It can effortlessly scale to handle trillions of events per day. Its durability guarantees that no security telemetry is lost, and its rich ecosystem of connectors allows for seamless integration with downstream systems like ClickHouse and the AI training pipeline.

Alternative Considered: NATS / RabbitMQ. While excellent message queues, they are not primarily designed as durable, replayable logs in the same way Kafka is. For a security use case where a historical, replayable stream of events is crucial for training and forensics, Kafka's log-based architecture is superior.

5.5 Event Storage: ClickHouse

Security analytics requires querying massive datasets at interactive speeds.

Why ClickHouse? Speed and Efficiency for Analytical Queries. ClickHouse is an open-source columnar database built for Online Analytical Processing (OLAP). Its performance on large-scale analytical queries (e.g., "find all processes that communicated with this IP address across the entire fleet in the last 30 days") is orders of magnitude faster than traditional row-based databases. Its efficient data compression and storage make it cost-effective for retaining vast amounts of security telemetry.

Alternative Considered: Elasticsearch. While popular for log analysis, Elasticsearch's performance can degrade on complex, high-cardinality analytical queries typical of security investigations. ClickHouse is purpose-built for this type of workload and generally offers superior query performance and storage efficiency.

6. Future Research Vectors

Project Sentinel is designed as a platform for continued innovation. Upon completion of the core vision, future research will explore:

Multi-Modal Anomaly Detection: Fusing syscall and network telemetry with process memory analysis (e.g., via eBPF probes on mmap/mprotect) to build a more holistic understanding of application behavior.

Automated Attack Narrative Generation: Using a Large Language Model (LLM) to consume a stream of alerts from the XAI engine and automatically generate a high-level summary of the entire attack chain (e.g., "Initial access was gained via RCE in the api-gateway pod, followed by lateral movement to the user-db pod via an anomalous internal connection...").

Causality-Informed AI: Moving beyond correlation to causation by building a model that understands the causal graph of process and network interactions, drastically reducing false positives.

7. Non-Goals
Host-based Intrusion Detection (HIDS) for traditional IT: Sentinel is not designed to replace traditional antivirus or HIDS on bare-metal, non-containerized servers. Its focus is exclusively on cloud-native, containerized workloads.

Static Application Security Testing (SAST): Sentinel is a runtime security platform. It does not perform static analysis of source code or container images.

Web Application Firewall (WAF): While Sentinel observes network traffic, it does not perform deep packet inspection of L7 application data (e.g., SQL injection, XSS) and is not a replacement for a dedicated WAF.
