GOT JOED: Automated Llamafile Orchestrator v1 Launcher
Welcome to the GOT JOED repository. This project is designed to provide a "plug-and-play" AI experience, bringing the power of Llamafile to both Linux and Windows environments without the usual configuration headaches. Whether you are on a high-end machine or legacy hardware, this toolkit optimizes and launches your models automatically.

Current Project Status: v1
This version focuses on automation of the execution environment. Please note that at this stage, this toolkit does not yet include automated MCP (Model Context Protocol) servers or automated AI tool chaining. Those advanced features are currently in development and are reserved for a future release.

How It Works
JARVIS.sh (Linux Automation)
JARVIS.sh is your intelligent Linux backend. It performs the following automatically:

Hardware Profiling: Detects your CPU threads and NVIDIA GPU capabilities.

Adaptive Layer Offloading: Calculates exactly how many model layers to put into your VRAM to prevent system crashes.

Llamafile Normalization: Automatically handles binary permissions and environment variables to ensure llamafile runs seamlessly on SUSE or other Linux distributions.

JARVIS.ps1 (Windows Automation)
JARVIS.ps1 serves as the Windows counterpart, providing a stable, user-friendly launch path:

Loopback Port Allocation: Automatically scans for an available local port (starting at 8080) to ensure your model can launch even if other services are active.

Stability Patching: Automatically applies the required --no-warmup and --no-mmap compatibility flags to bypass memory-mapping errors common on NTFS filesystems.

Dynamic Renaming: Safely manages binary naming to ensure compatibility between different Llamafile versions.

Getting Started
Place your GGUF model files inside the model/ folder.

Ensure your bin/ directory contains the latest llamafile binaries.

Execute the appropriate script for your OS:

Linux: bash JARVIS.sh

Windows: Right-click JARVIS.ps1 -> "Run with PowerShell"

Maintained by GOT JOED. Bringing robust AI tools to any environment.
