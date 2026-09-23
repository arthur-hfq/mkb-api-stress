# api-stress

> **Docker-Isolated API Stress & Load Testing Engine with Live Container Telemetry**

```
╔══════════════════════════════════════════════════════════════╗
║  [MARKAB] STRESS TEST REPORT                                 ║
╠══════════════════════════════════════════════════════════════╣
║
║  ENVIRONMENT : Docker (0.5  CPU | 256m   RAM)
║  TOTAL REQS  : 100
║  SUCCESS     : 100 (100%)
║  FAILED      : 0 (0%)
║
╠── HTTP STATUS VISUALIZER ──────────────────────────────────╣
║  2XX (OK)      : 100  │ ████████████████████
║  3XX (Redirect): 0    │ 
║  4XX (Client)  : 0    │ 
║  5XX (Server)  : 0    │ 
║
╠── LATENCY ─────────────────────────────────────────────────╣
║  AVG     : 14ms
║  MIN     : 5ms
║  MAX     : 42ms
║  P95     : 22ms
║  P99     : 38ms
║
╠── THROUGHPUT ──────────────────────────────────────────────╣
║  REQ/SEC    : 168.42
║  TOTAL TIME : 1420ms
║
╠── CONTAINER RESOURCES (LIVE PROFILING) ────────────────────╣
║  IDLE : CPU: 0.12% | MEM: 32.4MiB / 256MiB | NET: 1.2kB / 0B
║
║  CPU LOAD TIMELINE (Capacity Reached %):
║    14.2%  |██
║    58.6%  |███████████
║    94.0%  |██████████████████
║    31.5%  |██████
║
║  MAX CPU : 94.0% (Normalized)
║  MAX RAM : 54.1MiB
║
╚══════════════════════════════════════════════════════════════╝
```

`api-stress` is a lightweight, zero-dependency CLI tool that benchmarks your web APIs inside **resource-constrained, ephemeral Docker containers**. Instead of running load tests on unconstrained host machines (which mask CPU bottlenecks and memory leaks), `api-stress` boots your backend with exact CPU and RAM quotas, bombards it with concurrent traffic, samples live resource consumption every 200ms, and outputs a brutalist terminal report.

---

## ⚡ Why api-stress?

1. **True Resource Ceilings**: Run your Node, Go, Rust, or Python service with `0.25 CPU` and `128MB RAM` to see how it performs in production container environments (ECS, Kubernetes, Cloud Run).
2. **Zero Dependencies on Host**: No need to install `k6`, `wrk`, or `ab`. If you have Docker, Bash, and `curl`, you are ready.
3. **Live Container Profiling**: While the stress test fires, a background telemetry daemon samples Docker container metrics, computing a **Normalized CPU Capacity Timeline** and peak memory consumption.
4. **Auto-Clean & Safe**: Automatic process traps ensure orphaned test containers are cleaned up, even if you abort mid-flight (`Ctrl+C`).
5. **Interactive & Scriptable**: Run interactively with step-by-step prompts, or pass CLI flags in your CI/CD pipeline or Neovim buffers.

---

## 🚀 Installation

### Automated Install

Clone this repository and run the installer:

```bash
git clone https://github.com/<your-username>/api-stress.git
cd api-stress
chmod +x install.sh
./install.sh
```

This installs `api-stress` and a `markab-docker-stress` symlink to `~/.local/bin/`.

Ensure `~/.local/bin` is in your `$PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## 🛠️ Usage

### 1. Interactive Mode Wizard

Simply navigate to any API project folder and run:

```bash
api-stress
```

The wizard inspects your repository, suggests defaults for start commands and runtimes, and guides you through resource limits and request concurrency.

### 2. Command Line Flags

```bash
api-stress [OPTIONS]
```

| Flag | Long Option | Description | Default |
| :--- | :--- | :--- | :--- |
| `-d` | `--dir` | Target project root directory | Current directory |
| `-c` | `--cpus` | Container CPU quota (e.g. `0.25`, `0.5`, `1.0`) | `0.5` |
| `-m` | `--memory` | Container RAM limit (e.g. `128m`, `256m`, `1g`) | `256m` |
| `-s` | `--cmd` | Server start command inside container | Auto-detected |
| `-p` | `--port` | Internal container port the server listens on | `3000` |
| `-r` | `--route` | Route path to target | `/` |
| `-X` | `--method` | HTTP Method (`GET`, `POST`, `PUT`, `DELETE`) | `GET` |
| `-n` | `--count` | Total number of requests | `100` |
| `-C` | `--concurrency`| Number of concurrent workers | `10` |
| `-t` | `--timeout` | Timeout per request in seconds | `5` |
| `-b` | `--body` | JSON body string for POST/PUT requests | None |
| `-i` | `--interactive`| Force interactive setup mode | - |
| `-h` | `--help` | Display usage instructions | - |

---

## 📋 Examples

### Test the Included Express Mock API

An example Express API is included in `examples/express-api/` with routes for fast JSON, CPU-intensive math, slow simulated delays, and 500 errors:

```bash
# 1. Fast users endpoint
api-stress -d ./examples/express-api -s "node index.js" -p 3000 -r "/api/users" -n 200 -C 20

# 2. CPU-intensive route with 0.25 CPU constraint
api-stress -d ./examples/express-api --cpus 0.25 --memory 128m -s "node index.js" -p 3000 -r "/api/cpu" -n 50 -C 5

# 3. POST request with JSON payload
api-stress -d ./examples/express-api -s "node index.js" -p 3000 -r "/api/users" -X POST -b '{"name":"Tester"}' -n 100 -C 10
```

---

## 🔌 Neovim Integration

`api-stress` integrates directly into Neovim, rendering real-time streaming output in a floating window.

### Setup

Copy [`integrations/neovim/markab_stress.lua`](integrations/neovim/markab_stress.lua) into your Neovim config (e.g. `~/.config/nvim/lua/markab_stress.lua`), and add a keymapping:

```lua
-- In your init.lua or mappings.lua:
vim.keymap.set("n", "<leader>st", function()
  require("markab_stress").stress_test()
end, { desc = "Stress: API Load Test" })
```

When you press `<leader>st` inside any project buffer, Neovim prompts for CPU, RAM, and routes, and executes the benchmark in a floating panel with live streaming output.

---

## 🔍 Supported Runtimes

`api-stress` automatically mounts your local workspace into the appropriate base container:

| Stack | Detection Trigger | Base Docker Image |
| :--- | :--- | :--- |
| **Node.js** | `package.json` | `node:22-alpine` |
| **Python** | `requirements.txt`, `Pipfile`, `pyproject.toml` | `python:3.12-slim` |
| **Go** | `go.mod` | `golang:1.23-alpine` |
| **Rust** | `Cargo.toml` | `rust:1.79-slim` |
| **PHP** | `composer.json` | `php:8.3-cli` |
| **Ruby** | `Gemfile` | `ruby:3.3-slim` |
| **Other** | Default fallback | `alpine:latest` |

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
