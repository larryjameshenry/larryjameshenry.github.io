# Diagrams for "The Rise of AIOps: Leveraging AI for Smarter DevOps Automation"

## Static Thresholds vs. Dynamic Baselines

This diagram illustrates why static alerting thresholds generate noise and how AI-driven dynamic baselines adapt to normal traffic patterns (seasonality) to reduce alert fatigue.

```mermaid
graph TD
    subgraph "Scenario: Normal Monday Morning Traffic Spike"
        direction TB
        Traffic[Traffic Volume]
        
        subgraph "Traditional Monitoring (Static)"
            StaticLine[Static Threshold: > 80%]
            Alert1[ALERT! CPU > 80%]
            
            Traffic -->|Spikes to 85%| StaticLine
            StaticLine -->|Triggered| Alert1
            Alert1 -->|Result| Fatigue[False Positive / Noise]
        end

        subgraph "AIOps Monitoring (Dynamic)"
            DynamicBand[Dynamic Baseline<br/>(Learned 'Normal' Range: 70-90%)]
            NoAlert[No Alert<br/>(Within Expected Range)]
            
            Traffic -->|Spikes to 85%| DynamicBand
            DynamicBand -->|Evaluated| NoAlert
            NoAlert -->|Result| Quiet[Peace & Focus]
        end
    end

    subgraph "Scenario: Sunday 3 AM Anomaly"
        direction TB
        Traffic2[Traffic Volume]
        
        subgraph "AIOps Detection"
            DynamicBand2[Dynamic Baseline<br/>(Learned 'Normal' Range: 5-15%)]
            RealAlert[ALERT! Anomaly Detected]
            
            Traffic2 -->|Spikes to 40%| DynamicBand2
            DynamicBand2 -->|Deviation > Threshold| RealAlert
            RealAlert -->|Result| Action[True Incident]
        end
    end

    classDef alert fill:#ffebee,stroke:#c62828,stroke-width:2px;
    classDef ok fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    classDef neutral fill:#e1f5fe,stroke:#0277bd,stroke-width:2px;

    class Alert1,RealAlert,Fatigue,Action alert;
    class NoAlert,Quiet,ok;
    class Traffic,Traffic2,StaticLine,DynamicBand,DynamicBand2 neutral;
```
