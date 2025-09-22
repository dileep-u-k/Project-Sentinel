Project Sentinel: Visionary Architecture Diagram

This diagram outlines the complete, forward-looking architecture of Project Sentinel. It is designed using Mermaid.js and can be rendered by any compatible Markdown viewer.

```
graph TD
    subgraph Kubernetes Cluster Node 1
        A[eBPF Probes (C)] -->|Syscall/Network Events| B{Sentinel Agent (Rust)};
    end

    subgraph Kubernetes Cluster Node 2
        A2[eBPF Probes (C)] -->|Syscall/Network Events| B2{Sentinel Agent (Rust)};
    end

    subgraph Kubernetes Cluster Node N
        A3[...] --> B3{...};
    end

    subgraph "Data Plane: High-Throughput Telemetry"
        direction LR
        B --> C[Kafka Cluster];
        B2 --> C;
        B3 --> C;
        C -->|Raw Event Stream| D[ClickHouse Database];
    end

    subgraph "Control Plane: AI-Powered Brain"
        direction TB
        subgraph "AI/ML Service (Python/Rust)"
            E[Real-time Consumer] --> F{Transformer Model};
            F -->|Anomaly Score| G[XAI Engine];
            G -->|Explanation| H[Alert Generation];
            I[GAN Trainer] -.->|Hardens| F;
            D -.->|Historical Data for Training| I;
        end
        H --> J[Policy Engine (Rust)];
    end
    
    subgraph "Response Plane: Autonomous Mitigation"
        J -->|gRPC: Deploy Rule| B;
        J -->|gRPC: Deploy Rule| B2;
        J -->|gRPC: Deploy Rule| B3;
        B -- inserts --> K[Kernel TC/XDP Hooks];
        B2 -- inserts --> K2[Kernel TC/XDP Hooks];
        B3 -- inserts --> K3[...];
    end

    subgraph "Observability & Management"
        H --> L[Prometheus];
        B --> L;
        B2 --> L;
        B3 --> L;
        L --> M[Grafana Dashboards];
        J --> L;
    end

    style A fill:#bde0fe,stroke:#333,stroke-width:2px
    style B fill:#ffc8dd,stroke:#333,stroke-width:2px
    style C fill:#c9f5d9,stroke:#333,stroke-width:2px
    style D fill:#c9f5d9,stroke:#333,stroke-width:2px
    style F fill:#fcf6bd,stroke:#333,stroke-width:2px,font-weight:bold
    style G fill:#fcf6bd,stroke:#333,stroke-width:2px
    style I fill:#fcf6bd,stroke:#333,stroke-width:2px
    style J fill:#a2d2ff,stroke:#333,stroke-width:2px,font-weight:bold
    style L fill:#ffb4a2,stroke:#333,stroke-width:2px
```