# ComfyUI RunPod Installer

Ein vollständiges Installationsskript für ComfyUI auf RunPod, optimiert für das `runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04` Image.

## Features

- ✅ **Umgebungsanalyse**: Prüft Python, CUDA, PyTorch und GPU-Status
- ✅ **Intelligente Installation**: Nutzt die bestehende PyTorch-Umgebung (kein venv nötig)
- ✅ **ComfyUI**: Klont und installiert ComfyUI von GitHub
- ✅ **Model-Download**: Lädt automatisch das SD 1.5 pruned Model herunter (~4GB)
- ✅ **Custom Nodes**: Installiert ComfyUI Manager und Civicomfy
- ✅ **RunPod-optimiert**: Konfiguriert für externen Zugriff über RunPod

## Installation

### 1. Script auf RunPod hochladen

Lade das `runpod_comfyui_installer.sh` Script in dein RunPod `/workspace` Verzeichnis hoch.

### 2. Script ausführen

```bash
cd /workspace
chmod +x runpod_comfyui_installer.sh
./runpod_comfyui_installer.sh
```

### 3. ComfyUI starten

Nach der Installation kannst du ComfyUI auf zwei Arten starten:

**Option A: Direkt starten**

```bash
cd /workspace/ComfyUI
python main.py --listen 0.0.0.0 --port 8188
```

**Option B: Launch-Script verwenden**

```bash
cd /workspace/ComfyUI
./launch_comfyui.sh
```

## Was wird installiert?

### Verzeichnisstruktur

```
/workspace/
├── ComfyUI/
│   ├── models/
│   │   ├── checkpoints/
│   │   │   └── v1-5-pruned-emaonly-fp16.safetensors
│   │   ├── vae/
│   │   ├── loras/
│   │   ├── controlnet/
│   │   ├── clip_vision/
│   │   └── embeddings/
│   ├── custom_nodes/
│   │   ├── ComfyUI-Manager/
│   │   └── Civicomfy/
│   └── launch_comfyui.sh
```

### Custom Nodes

- **ComfyUI Manager**: Für einfache Installation weiterer Custom Nodes
- **Civicomfy**: Custom Node von MoonGoblinDev für erweiterte Funktionen

### Models

- **Stable Diffusion 1.5 pruned**: Standard-Model für Bildgenerierung

## Zugriff auf ComfyUI

Nach dem Start ist ComfyUI verfügbar unter:

- **Lokal**: `http://localhost:8188`
- **RunPod Public URL**: Verwende die von RunPod bereitgestellte Public URL

## Troubleshooting

### GPU nicht erkannt

```bash
nvidia-smi
```

Sollte GPU-Informationen anzeigen. Falls nicht, prüfe die RunPod-Konfiguration.

### PyTorch CUDA-Support

```bash
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

### Port bereits belegt

Falls Port 8188 belegt ist, verwende einen anderen:

```bash
python main.py --listen 0.0.0.0 --port 8189
```

## Script-Features

- **Farbige Ausgabe**: Übersichtliche Fortschrittsanzeigen
- **Fehlerbehandlung**: Robuste Installation mit Fallback-Optionen
- **Intelligente Updates**: Erkennt bestehende Installationen und aktualisiert sie
- **Vollständige Logs**: Detaillierte Informationen über jeden Installationsschritt

## Systemanforderungen

- RunPod mit NVIDIA GPU
- `runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04` Image
- Mindestens 8GB freier Speicherplatz für Models

## Support

Bei Problemen prüfe:

1. GPU-Status mit `nvidia-smi`
2. Python-Version mit `python3 --version`
3. PyTorch-Installation mit `python3 -c "import torch; print(torch.__version__)"`
4. Verfügbaren Speicherplatz mit `df -h`
