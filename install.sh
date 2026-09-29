#!/bin/bash

set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -eq 0 ]]; then
    echo "Please run this script as a regular user, not root."
    exit 1
fi

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if [[ ! -f webui.sh ]]; then
    echo "Error: webui.sh not found. Run this script inside the Forge repository."
    exit 1
fi

VENV_DIR="$PWD/venv"
PYTHON="$VENV_DIR/bin/python"

echo ""
echo "==> Installing Forge environment"

echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y git curl libgl1 libglib2.0-0

if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if ! command -v uv >/dev/null 2>&1; then
    echo "Error: uv was not found after installation."
    exit 1
fi

if [[ ! -x "$PYTHON" ]]; then
    echo "Creating Python 3.10 virtual environment..."
    uv python install 3.10
    uv venv --python 3.10 "$VENV_DIR"
fi

echo "Installing Python packages..."
uv pip install --python "$PYTHON" pip "setuptools==69.5.1" wheel joblib

if ! "$PYTHON" -c 'import torch; assert torch.__version__.startswith("2.3.1")' 2>/dev/null; then
    echo "Installing PyTorch (CUDA 12.1)..."
    uv pip install --python "$PYTHON" \
        torch==2.3.1 torchvision==0.18.1 \
        --index-url https://download.pytorch.org/whl/cu121 \
        --extra-index-url https://pypi.org/simple
fi

if ! "$PYTHON" -c 'import clip' 2>/dev/null; then
    echo "Installing OpenAI CLIP..."
    "$PYTHON" -m pip install --no-build-isolation \
        "https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip"
fi

uv pip install --python "$PYTHON" "numpy==1.26.2" "scikit-image==0.21.0"

printf 'numpy==1.26.2\nscikit-image==0.21.0\n' > "$VENV_DIR/constraints.txt"
printf '[global]\nconstraint = %s\n' "$VENV_DIR/constraints.txt" > "$VENV_DIR/pip.conf"

echo ""
echo "==> Summary"

echo ""
echo "Forge environment installed successfully"

echo ""
echo "Run:"
echo "  COMMANDLINE_ARGS=\"--share --gradio-auth admin:SET_THE_PASSWORD --xformers\" ./webui.sh"
