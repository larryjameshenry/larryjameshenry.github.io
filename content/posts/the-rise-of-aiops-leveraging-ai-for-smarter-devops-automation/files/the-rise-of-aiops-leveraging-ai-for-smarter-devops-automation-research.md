# Research Dossier: The Rise of AIOps: Leveraging AI for Smarter DevOps Automation

This dossier compiles research for the article "The Rise of AIOps," covering predictive scaling with KEDA, automated root cause analysis with Prometheus, and using LLMs for log analysis.

## Section 1: Beyond Static Thresholds

### 1.2 Predictive Scaling (KEDA + AI)

**Key Points:**
*   **Architecture:** Move from reactive (HPA based on current CPU) to proactive.
*   **Components:**
    1.  **Monitoring:** Prometheus collects metrics.
    2.  **Forecasting Service:** A Python service (using Prophet or LSTM) consumes historical metrics and predicts future load (e.g., 15 mins ahead).
    3.  **KEDA External Scaler:** Exposes the predicted metrics to Kubernetes.
    4.  **HPA:** Scales pods based on the *predicted* value, not the current value.

**Content Elements:**
*   **Architecture Diagram:**
    `Prometheus -> Forecasting Service (Python/Prophet) -> KEDA External Scaler -> Kubernetes HPA -> Pods`

## Section 2: AI in the Incident Lifecycle

### 2.1 Automated Root Cause Analysis (RCA)

**Key Points:**
*   **Anomaly Detection:** Using statistical methods to find "unknown unknowns" rather than static thresholds.
*   **Prometheus Implementation:** Use `recording rules` to calculate dynamic baselines (e.g., using `deriv()` or `predict_linear()`) and alert on deviations.

**Content Elements:**
*   **Prometheus Anomaly Alert Example:**
    ```yaml
    - alert: HighErrorRateSpike
      expr: |
        # Alert if 5xx rate increases by >1% per second (sudden spike)
        deriv(job:http_server_requests_5xx_rate5m[10m]) > 0.01
        AND
        # AND current rate is significant (>1%)
        job:http_server_requests_5xx_rate5m > 0.01
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Sudden spike in 5xx errors detected on {{ $labels.service }}"
    ```

## Hands-On Example: AI-Powered Log Analyzer

**Scenario:** A Python script that reads a log file and uses OpenAI's GPT-4o (or a local LLM) to explain errors.

**Implementation Steps:**
1.  Read the log file.
2.  Construct a prompt with the error context.
3.  Call the API.
4.  Print the remediation.

**Code Solution:**
```python
import os
from openai import OpenAI

# Initialize client (assumes OPENAI_API_KEY is set)
client = OpenAI()

def analyze_logs(log_file_path):
    with open(log_file_path, 'r') as f:
        # Read last 50 lines to fit context window
        logs = f.readlines()[-50:]
    
    log_content = "".join(logs)
    
    prompt = f"""
    Analyze the following server logs and identify the root cause of the error. 
    Provide a summary and a suggested fix in plain English.
    
    Logs:
    {log_content}
    """

    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "You are a senior DevOps engineer."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.5
        )
        
        print("\n--- AI Analysis ---")
        print(response.choices[0].message.content)
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # Create a dummy log for testing
    with open("app.log", "w") as f:
        f.write("2023-10-27 10:00:01 [INFO] Starting server...\n")
        f.write("2023-10-27 10:00:05 [ERROR] ConnectionRefusedError: [Errno 111] Connection refused: 'db-prod-1:5432'\n")
        f.write("2023-10-27 10:00:06 [CRITICAL] Database health check failed. Retrying in 5s...\n")
    
    analyze_logs("app.log")
```

## Best Practices & Optimization

### Performance & Security (Small Language Models)

**Key Points:**
*   **Privacy:** Don't send sensitive PII logs to public APIs. Use local models.
*   **Tools:** Use **Ollama** or **LM Studio** to run models locally.
*   **Recommended Models (2025):**
    *   **Mistral 7B / Mixtral 8x7B:** Excellent balance of speed and reasoning.
    *   **Phi-3 (Microsoft):** Extremely lightweight, good for simple reasoning tasks.
    *   **Llama 3:** The open-source standard for general-purpose tasks.

## Troubleshooting Common Issues

**Issue 1: "The AI explanation is generic"**
*   **Solution:** "Prompt Engineering." Provide context. Instead of just the log, paste the config file (sanitized) or describe the recent deployment change in the system prompt.

**Issue 2: "Predictive scaling is flapping"**
*   **Solution:** Increase the training window for the prediction model (e.g., from 24 hours to 2 weeks) to capture weekly seasonality (traffic is lower on weekends).
