#!/bin/bash

# ComfyUI Installation Script for RunPod
# Optimized for runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04
# Includes Civicomfy custom node and SD 1.5 model download

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Configuration
WORKSPACE_DIR="/workspace"
COMFYUI_DIR="$WORKSPACE_DIR/ComfyUI"
REPO_URL="https://github.com/comfyanonymous/ComfyUI.git"
MANAGER_REPO="https://github.com/ltdrdata/ComfyUI-Manager.git"
CIVICOMFY_REPO="https://github.com/MoonGoblinDev/Civicomfy.git"
SD15_MODEL_URL="https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors"

log "🚀 ComfyUI RunPod Installation gestartet..."

# 1. Environment Analysis
log "🔍 Analysiere RunPod Umgebung..."
info "Python Version: $(python3 --version)"
info "Pip Version: $(pip --version)"

if command -v nvidia-smi &> /dev/null; then
    info "GPU Info:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    info "CUDA Version: $(nvidia-smi | grep "CUDA Version" | sed 's/.*CUDA Version: \([0-9.]*\).*/\1/')"
else
    warning "Keine NVIDIA GPU erkannt"
fi

# Check PyTorch installation
if python3 -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')" 2>/dev/null; then
    info "PyTorch bereits installiert und funktionsfähig"
else
    warning "PyTorch nicht gefunden oder nicht funktionsfähig"
fi

# 2. Create workspace directory
log "📁 Erstelle Arbeitsverzeichnis..."
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# 3. Update pip (use existing Python environment)
log "⬆️ Aktualisiere pip..."
pip install --upgrade pip

# 4. Clone ComfyUI if not exists
if [ -d "$COMFYUI_DIR" ]; then
    warning "ComfyUI bereits vorhanden, überspringe Klonen..."
    cd "$COMFYUI_DIR"
    git pull origin master || warning "Git pull fehlgeschlagen"
else
    log "📥 Klone ComfyUI von GitHub..."
    git clone "$REPO_URL" "$COMFYUI_DIR"
    cd "$COMFYUI_DIR"
fi

# 5. Install ComfyUI requirements
log "📋 Installiere ComfyUI Requirements..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    warning "requirements.txt nicht gefunden"
fi

# 6. Create models directory structure
log "📁 Erstelle Model-Verzeichnisse..."
mkdir -p models/checkpoints
mkdir -p models/vae
mkdir -p models/loras
mkdir -p models/controlnet
mkdir -p models/clip_vision
mkdir -p models/embeddings

# 7. Download SD 1.5 model
log "📥 Lade Stable Diffusion 1.5 Model herunter..."
if [ ! -f "models/checkpoints/v1-5-pruned-emaonly-fp16.safetensors" ] && [ ! -f "models/checkpoints/v1-5-pruned-emaonly.ckpt" ]; then
    info "Lade SD 1.5 Model (ca. 2GB) im sicheren safetensors Format..."
    wget -O models/checkpoints/v1-5-pruned-emaonly-fp16.safetensors "$SD15_MODEL_URL" || {
        error "Model Download fehlgeschlagen"
        info "Versuche alternative Download-Methode..."
        curl -L -o models/checkpoints/v1-5-pruned-emaonly-fp16.safetensors "$SD15_MODEL_URL"
    }
    log "✅ SD 1.5 Model erfolgreich heruntergeladen"
else
    info "SD 1.5 Model bereits vorhanden"
fi

# 8. Install custom nodes
log "🔧 Installiere Custom Nodes..."
cd custom_nodes

# Install ComfyUI Manager
if [ ! -d "ComfyUI-Manager" ]; then
    log "📥 Installiere ComfyUI Manager..."
    git clone "$MANAGER_REPO"
else
    info "ComfyUI Manager bereits installiert"
    cd ComfyUI-Manager
    git pull origin main || warning "ComfyUI Manager Update fehlgeschlagen"
    cd ..
fi

# Install Civicomfy
if [ ! -d "Civicomfy" ]; then
    log "📥 Installiere Civicomfy Custom Node..."
    git clone "$CIVICOMFY_REPO"
    
    # Install Civicomfy requirements if they exist
    if [ -f "Civicomfy/requirements.txt" ]; then
        log "📋 Installiere Civicomfy Requirements..."
        pip install -r Civicomfy/requirements.txt
    fi
else
    info "Civicomfy bereits installiert"
    cd Civicomfy
    git pull origin main || warning "Civicomfy Update fehlgeschlagen"
    cd ..
fi

# 9. Return to ComfyUI main directory
cd "$COMFYUI_DIR"

# 10. Create launch script for RunPod
log "📝 Erstelle Launch-Script..."
cat > launch_comfyui.sh << 'LAUNCH_EOF'
#!/bin/bash
cd /workspace/ComfyUI
echo "🚀 Starte ComfyUI auf RunPod..."
echo "ComfyUI wird verfügbar sein auf: http://localhost:8188"
echo "Für externen Zugriff verwende die RunPod Public URL"
# Setze Umgebungsvariable für PyTorch 2.6+ Kompatibilität mit alten Checkpoints
export PYTORCH_ENABLE_MPS_FALLBACK=1
export SAFETENSORS_FAST_GPU=1
python main.py --listen 0.0.0.0 --port 8188 --disable-smart-memory --force-fp16
LAUNCH_EOF

chmod +x launch_comfyui.sh

# 11. Final system check
log "🔍 Finale Systemprüfung..."
info "ComfyUI Installation: ✅"
info "Custom Nodes: $(ls -1 custom_nodes | wc -l) installiert"
info "Models: $(ls -1 models/checkpoints | wc -l) verfügbar"

# 12. Display completion message
log "🎉 Installation abgeschlossen!"
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "ComfyUI ist installiert und wird jetzt automatisch gestartet..."
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 13. Auto-start ComfyUI
log "🚀 Starte ComfyUI automatisch..."
echo ""
info "ComfyUI wird auf http://localhost:8188 verfügbar sein"
info "Für externen Zugriff verwende die RunPod Public URL"
info "Zum Beenden drücke Ctrl+C"
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Start ComfyUI directly with PyTorch 2.6+ compatibility
cd "$COMFYUI_DIR"
export PYTORCH_ENABLE_MPS_FALLBACK=1
export SAFETENSORS_FAST_GPU=1
python main.py --listen 0.0.0.0 --port 8188 --disable-smart-memory --force-fp16
