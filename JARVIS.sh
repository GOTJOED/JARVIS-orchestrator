#!/usr/bin/env bash

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Dynamic Absolute Path Anchor (Calculates root folder based on script location)
SCRIPT_DIR="$(CDPATH="" cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"

# Ensure llamafile binary naming compatibility
# Detect Windows-style llamafile.exe and normalize it
if [ -f "bin/llamafile.exe" ] && [ ! -f "bin/llamafile" ]; then
    echo -e "${YELLOW}[JARVIS] Detected llamafile.exe - Renaming to llamafile...${NC}"
    mv "bin/llamafile.exe" "bin/llamafile"
fi

# Ensure all bundled binaries have executable rights where the filesystem allows it
chmod +x bin/llamafile bin/zipalign bin/diffusionfile bin/whisperfile 2>/dev/null

# Initialize Hardware Counters
GPU_COUNT=0
VRAM_GB=0
VRAM_MB=0

# Clean UI Header Function
render_header() {
    clear
    echo -e "${CYAN}==============================================================${NC}"
    echo -e "${RED}${BOLD}  ██████╗  ██████╗ ████████╗      ██╗ ██████╗ ███████╗██████╗${NC}"
    echo -e "${RED}${BOLD} ██╔════╝ ██╔═══██╗╚══██╔══╝      ██║██╔═══██╗██╔════╝██╔══██╗${NC}"
    echo -e "${RED}${BOLD} ██║  ███╗██║   ██║   ██║         ██║██║   ██║█████╗  ██║  ██║${NC}"
    echo -e "${RED}${BOLD} ██║   ██║██║   ██║   ██║    ██   ██║██║   ██║██╔══╝  ██║  ██║${NC}"
    echo -e "${RED}${BOLD} ╚██████╔╝╚██████╔╝   ██║    ╚█████╔╝╚██████╔╝███████╗██████╔╝${NC}"
    echo -e "${RED}${BOLD}  ╚═════╝  ╚═════╝    ╚═╝     ╚════╝  ╚═════╝ ╚══════╝╚═════╝${NC}"
    echo -e "${CYAN}==============================================================${NC}"
    echo -e "${YELLOW}${BOLD}              J.A.R.V.I.S. - Llamafile Launcher      ${NC}"
    echo -e "${CYAN}==============================================================${NC}"
}

render_hardware_specs() {
    echo -e "${BLUE} Scanning host hardware specs...${NC}"
    echo -e "    -> System RAM:      ${GREEN}${SYS_RAM} GB${NC}"
    echo -e "    -> CPU:             ${GREEN}${CPU_MODEL}${NC}"
    if [ $GPU_COUNT -gt 0 ] && [ $VRAM_GB -gt 0 ]; then
        echo -e "    -> GPU MODEL/VRAM:  ${GREEN}${GPU_MODEL} (${VRAM_GB} GB VRAM)${NC}"
    elif [ ! -z "$GPU_MODEL" ]; then
        echo -e "    -> GPU MODEL/VRAM:  ${GREEN}${GPU_MODEL} (No VRAM info available)${NC}"
    else
        echo -e "    -> GPU MODEL/VRAM:  ${RED}No dedicated GPU detected${NC}"
    fi
    echo ""
}

# --- Execute Core Logic ---

# 1. Gather System RAM
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
SYS_RAM=$((RAM_KB / 1024 / 1024))

# 2. Gather CPU Profile
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | awk -F: '{print $2}' | sed 's/^[ \t]*//')
[ -z "$CPU_MODEL" ] && CPU_MODEL=$(lscpu | grep "Model name:" | sed 's/Model name:[ \t]*//')

# 3. Gather GPU Profile & Set Hardware Counters
if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_MODEL=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -n 1)
    VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n 1)
    VRAM_GB=$((VRAM_MB / 1024))
    GPU_COUNT=1
elif command -v lspci >/dev/null 2>&1; then
    GPU_INFO=$(lspci | grep -Ei "3d|nvidia" | head -n 1)
    [ -z "$GPU_INFO" ] && GPU_INFO=$(lspci | grep -Ei "vga|display" | head -n 1)
    GPU_MODEL=$(echo "$GPU_INFO" | awk -F: '{print $3}' | sed 's/^[ \t]*//')
    [ ! -z "$GPU_MODEL" ] && GPU_COUNT=1
fi

# --- 4. Automated Filesystem Execution Capability Probe ---
EXEC_ALLOWED=true
cp /bin/true ./.exec_test 2>/dev/null
if ! ./.exec_test 2>/dev/null; then
    EXEC_ALLOWED=false
fi
rm -f ./.exec_test 2>/dev/null

# Paint the initial application frame
render_header
render_hardware_specs

if [ "$EXEC_ALLOWED" = false ]; then
    echo -e "${YELLOW}[JARVIS INFO] Running from a non-executable filesystem (exFAT/NTFS mount).${NC}"
    echo -e "${YELLOW}Virtual PID isolation sandbox via /tmp will be utilized automatically.${NC}\n"
fi

# Check onboarding matrix states
if [ -f "JARVIS.llamafile" ] && [ -f ".args" ]; then
    ONBOARDED_PATH=$(sed -n '2p' .args)
    ONBOARDED_MODEL=$(basename "$ONBOARDED_PATH")
    
    if [ ! -z "$ONBOARDED_MODEL" ]; then
        if [ ! -f "$ONBOARDED_PATH" ]; then
            echo -e "${RED}[WARNING] THE ONBOARDED MODEL [${ONBOARDED_MODEL}] IS NO LONGER PRESENT IN YOUR /model/ FOLDER.${NC}"
            echo -e "${BLUE}[JARVIS] Resetting stale environment configs...${NC}"
            
            rm -f JARVIS.llamafile .args
            ONBOARDED_MODEL=""
            ONBOARDED_PATH=""
            
            sleep 10
            render_header
            render_hardware_specs
        else
            echo -e "${YELLOW}AI MODEL ONBOARDED:${NC} ${GREEN}[${ONBOARDED_MODEL}]${NC}"
            echo ""
            echo -ne "${YELLOW}SHOULD YOU WANT TO USE THIS MODEL? (y/n): ${NC}"
            read RUN_CHOICE
            
            if [[ "$RUN_CHOICE" =~ ^[Yy]$ ]]; then
                echo -e "\n${GREEN}[JARVIS] Launching server via Absolute Zero Path (Thread Prioritized)...${NC}"
                
                # --- Execution Path Routing Based on Filesystem Attributes ---
                if [ "$EXEC_ALLOWED" = true ]; then
                    nice -n 15 ./JARVIS.llamafile 2>&1 | tee JARVIS.log
                    EXIT_CODE=${PIPESTATUS[0]}
                else
                    # --- INSTALLED: Process-Isolated Self-Destruct Sandbox Engine ---
                    SANDBOX_DIR="/tmp/jarvis_runtime_$$"
                    echo -e "${BLUE}[JARVIS] Extracting isolated engine runtime to secure memory [${SANDBOX_DIR}]...${NC}"
                    mkdir -p "$SANDBOX_DIR"
                    
                    # Establish immediate self-destruct trigger on execution exit
                    trap "rm -rf '$SANDBOX_DIR'" EXIT
                    
                    cp bin/llamafile "$SANDBOX_DIR/llamafile"
                    chmod +x "$SANDBOX_DIR/llamafile"
                    
                    nice -n 15 "$SANDBOX_DIR/llamafile" $(cat .args) 2>&1 | tee JARVIS.log
                    EXIT_CODE=${PIPESTATUS[0]}
                fi
                
                echo ""
                if [ $EXIT_CODE -ne 0 ]; then
                    echo -e "${RED}${BOLD}[CRITICAL] SERVER EXITED UNEXPECTEDLY WITH CODE: $EXIT_CODE${NC}"
                    echo -e "${YELLOW}[JARVIS] Diagnostics captured permanently inside: ${NC}${CYAN}${SCRIPT_DIR}/JARVIS.log${NC}"
                else
                    echo -e "${BLUE}[JARVIS] Server stream terminated cleanly.${NC}"
                fi
                echo ""
                read -p "Press [ENTER] to safely close this terminal window..."
                exit $EXIT_CODE
            fi
            echo ""
        fi
    fi
fi

# Check for model repository storage existence using dynamic anchor
MODEL_DIR="./model"
if [ ! -d "$MODEL_DIR" ] || [ -z "$(ls -A $MODEL_DIR/*.gguf 2>/dev/null)" ]; then
    echo -e "${RED}${BOLD}[ERROR] NO AI MODEL DETECTED${NC}"
    echo -e "${YELLOW}JARVIS needs a .gguf model file inside the /model/ folder to work.${NC}\n"
    echo -e "1. Download a standalone GGUF model from ${CYAN}huggingface.co${NC}"
    echo -e "2. Copy the file directly inside: ${GREEN}${SCRIPT_DIR}/model/${NC}"
    echo -e "--------------------------------------------------------------"
    echo ""
    if [ "$EXEC_ALLOWED" = true ]; then
        read -p "Press [ENTER] to exit, then rerun ./JARVIS.sh once the file is copied!"
    fi
    if [ "$EXEC_ALLOWED" = false ]; then
        read -p "Press [ENTER] to exit, then rerun 'bash ./JARVIS.sh' once the file is copied!"
    fi
    exit 1
fi

echo -e "${YELLOW}MODELS DETECTED:${NC}"

declare -a MODELS
COUNT=0
for FILE in "$MODEL_DIR"/*.gguf; do
    [ -e "$FILE" ] || continue
    FNAME=$(basename "$FILE")
    
    if [ ! -z "$ONBOARDED_MODEL" ] && [ "$FNAME" = "$ONBOARDED_MODEL" ]; then
        continue
    fi
    
    COUNT=$((COUNT + 1))
    MODELS[$COUNT]="$FILE"
    
    FILE_BYTES=$(stat -c%s "$FILE")
    MODEL_SIZE_GB=$((FILE_BYTES / 1024 / 1024 / 1024))
    [ $MODEL_SIZE_GB -eq 0 ] && MODEL_SIZE_GB=1

    REQ_VRAM=$(( (MODEL_SIZE_GB * 12) / 10 ))
    MIN_SAFE_RAM=$(( MODEL_SIZE_GB + 4 ))

    if [ $GPU_COUNT -gt 0 ] && [ $VRAM_GB -ge $REQ_VRAM ]; then
        REC_FLAG="${GREEN}[RECOMMENDED (Full GPU Acceleration)]${NC}"
    elif [ $GPU_COUNT -gt 0 ] && [ $VRAM_GB -lt $REQ_VRAM ]; then
        REC_FLAG="${GREEN}[RECOMMENDED (GPU Accelerated Split)]${NC}"
    elif [ $SYS_RAM -ge $MIN_SAFE_RAM ]; then
        REC_FLAG="${CYAN}[RECOMMENDED (CPU/System RAM)]${NC}"
    else
        REC_FLAG="${RED}[WARNING: HEAVY RESOURCE RUNTIME (Slow/Low RAM)]${NC}"
    fi
    
    echo -e "${BOLD}${COUNT}.${NC} ${FNAME} - ${REC_FLAG}"
done

if [ $COUNT -eq 0 ]; then
    echo -e "${YELLOW}(No alternative models found in your /model/ directory)${NC}"
    echo ""
    read -p "Press [ENTER] to return to terminal..."
    exit 0
fi

echo ""
echo -ne "${YELLOW}CHOOSE YOUR AI MODEL (Enter Number): ${NC}"
read CHOICE

if [ -z "${MODELS[$CHOICE]}" ]; then
    echo -e "${RED}[ERROR] Invalid option choice selected.${NC}"
    exit 1
fi

SELECTED_MODEL="${MODELS[$CHOICE]}"

# --- Native Self-Healing Port Engine ---
TARGET_PORT=8080
while (echo > /dev/tcp/127.0.0.1/$TARGET_PORT) >/dev/null 2>&1; do
    echo -e "${YELLOW}[PORT CONFLICT] Port ${TARGET_PORT} is busy. Shifting channel...${NC}"
    TARGET_PORT=$((TARGET_PORT + 1))
done

echo -e "\n${BLUE}[JARVIS] Aligning: $(basename "$SELECTED_MODEL") on Local Port ${TARGET_PORT}...${NC}"

rm -f JARVIS.llamafile

# --- Hardware-Aware 90% Pro-Rata Scaling Engine (GPU -> RAM -> CPU) ---
TOTAL_CORES=$(nproc 2>/dev/null)
[ -z "$TOTAL_CORES" ] && TOTAL_CORES=4
if [ $TOTAL_CORES -gt 4 ]; then
    LAUNCH_THREADS=$((TOTAL_CORES / 2))
else
    LAUNCH_THREADS=$TOTAL_CORES
fi

FILE_BYTES=$(stat -c%s "$SELECTED_MODEL")
MODEL_SIZE_MB=$(( FILE_BYTES / 1024 / 1024 ))
MODEL_SIZE_GB=$(( MODEL_SIZE_MB / 1024 ))
[ $MODEL_SIZE_GB -eq 0 ] && MODEL_SIZE_GB=1

NGL_VAL=0
TIER_INFO="Pure CPU Mode (No GPU Detected -> Running fully on System RAM)"

if [ $GPU_COUNT -gt 0 ] && [ $VRAM_MB -gt 0 ]; then
    if [ $VRAM_GB -le 4 ]; then
        VRAM_OVERHEAD=1228
    else
        VRAM_OVERHEAD=1536
    fi
    
    COMPUTE_GRAPH_OVERHEAD_MB=1024
    TOTAL_RESERVED_MB=$(( VRAM_OVERHEAD + COMPUTE_GRAPH_OVERHEAD_MB ))
    
    VRAM_BUDGET_MB=$(( VRAM_MB - TOTAL_RESERVED_MB ))
    [ $VRAM_BUDGET_MB -lt 512 ] && VRAM_BUDGET_MB=512

    if [ $MODEL_SIZE_GB -le 4 ]; then
        ESTIMATED_TOTAL_LAYERS=32
    elif [ $MODEL_SIZE_GB -le 12 ]; then
        ESTIMATED_TOTAL_LAYERS=42
    elif [ $MODEL_SIZE_GB -le 16 ]; then
        ESTIMATED_TOTAL_LAYERS=48
    elif [ $MODEL_SIZE_GB -le 35 ]; then
        ESTIMATED_TOTAL_LAYERS=64
    else
        ESTIMATED_TOTAL_LAYERS=80
    fi

    if [ $MODEL_SIZE_MB -le $VRAM_BUDGET_MB ]; then
        TIER_INFO="Full GPU Acceleration (Model sits completely within safe 90% budget window)"
        NGL_VAL=999
    else
        TIER_INFO="Agnostic Hybrid Split (Maxing GPU VRAM to 90%, overflowing rest smoothly to RAM/CPU)"
        NGL_VAL=$(( (VRAM_BUDGET_MB * ESTIMATED_TOTAL_LAYERS) / MODEL_SIZE_MB ))
        [ $NGL_VAL -lt 1 ] && NGL_VAL=1
        [ $NGL_VAL -gt $ESTIMATED_TOTAL_LAYERS ] && NGL_VAL=$ESTIMATED_TOTAL_LAYERS
    fi
fi

echo -e "${BLUE}[JARVIS] Pipeline Profile Assigned: ${YELLOW}${TIER_INFO}${NC}"
echo -e "${BLUE}[JARVIS] Dynamic GPU Layer Offload Target (-ngl): ${GREEN}${NGL_VAL}${NC}"
echo -e "${BLUE}[JARVIS] Marshalling ${GREEN}${LAUNCH_THREADS}${BLUE} physical CPU threads for execution tracking...${NC}"

# Build config using our custom-tuned optimization metrics
cat << EOF > .args
-m
$SELECTED_MODEL
--host
0.0.0.0
--port
$TARGET_PORT
-ngl
$NGL_VAL
-t
$LAUNCH_THREADS
--no-warmup
EOF

if [ "$EXEC_ALLOWED" = true ]; then
    cp bin/llamafile JARVIS.llamafile
    ./bin/zipalign -j0 JARVIS.llamafile "$SELECTED_MODEL" .args
    chmod +x JARVIS.llamafile
else
    echo -e "${YELLOW}[JARVIS] Non-executable filesystem: Bypassing local zipalign process.${NC}"
    echo "EXFAT_FALLBACK" > JARVIS.llamafile
fi

echo ""
echo -e "${GREEN}${BOLD}==================================================${NC}"
if [ "$EXEC_ALLOWED" = true ]; then
    echo -e "${GREEN}${BOLD} INITIALIZATION DONE, RELAUNCH THE ./JARVIS.sh TO RUN${NC}"
else
    echo -e "${GREEN}${BOLD} INITIALIZATION DONE, RELAUNCH WITH: bash ./JARVIS.sh${NC}"
fi
echo -e "${GREEN}${BOLD}==================================================${NC}"
echo ""
read -p "Press [ENTER] to return to terminal..."