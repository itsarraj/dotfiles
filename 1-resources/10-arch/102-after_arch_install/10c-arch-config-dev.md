---
id: 20260914120550
title: Arch Config Dev - Post-Install Dev Stack
date: 2026-09-14 12:05
type: note # note | concept | snippet | bug | journal | reference
status: draft # draft | stable | evergreen
tags: [archlinux, dev, tools]
links: [[10a-arch-config]]
---
# Log
- 2026-01-01 01:40 - Created note (split from system post-install config).
- 2026-09-14 12:05 - Gave this note its own id/title/checklist; kept as canonical home for bun/fnm and other dev stack.

# Notes
# Things to be done after arch install (dev stack)
- [ ] Redis / Valkey
- [ ] Bun + fnm (Node.js)
- [ ] RustFS
- [ ] SQLx CLI
- [ ] Miniconda
- [ ] AI/ML (Hugging Face) stack
- [ ] Jupyter in conda env
- [ ] React Native / Android ADB
- [ ] OpenJDK Multi-Version Setup (archlinux-java)

System post-install (swap, boot, wifi, paru, perf): see [[10a-arch-config]]

## 1: setup the redis valkey for arch linux -------------------------------

On Arch Linux, you may see Valkey even when you think you installed “Redis”.

- Valkey is a Redis-compatible fork.
- On Arch, the service may be `valkey.service`.
- You might also see `redis.service` behaving like an alias/compat name (systemd can point it to valkey).

Important: `redis` / `valkey` are not the usual commands to run in a shell.
- Client command is typically `redis-cli` (or `valkey-cli` if available).
- The server is managed via systemd (`systemctl ... valkey` / `systemctl ... redis`).

Check what you have:
```bash
systemctl status valkey.service
systemctl status redis.service
```

```bash
sudo pacman -S --needed valkey

# Start/enable (use whichever exists on your system)
sudo systemctl enable --now valkey.service
# or:
sudo systemctl enable --now redis.service

# Verify server is listening (default: 127.0.0.1:6379)
redis-cli ping || valkey-cli ping
```

## 2: Bun + fnm (Node.js) -------------------------------

Canonical copy for Node tooling. System post-install (paru, boot, swap): [[10a-arch-config]].

### Bun
```bash
curl -fsSL https://bun.com/install | bash
bun --version
```

### fnm (Fast Node Manager)
Install:
```bash
curl -fsSL https://fnm.vercel.app/install | bash
```

Enable in Bash (add to `~/.bashrc`):
```bash
eval "$(fnm env --use-on-cd --shell bash)"
```

Reload shell:
```bash
source ~/.bashrc
```

Install Node.js (recommended: latest LTS):
```bash
fnm install --lts
fnm default --lts
fnm use --lts
```

Optional: also install the absolute latest:
```bash
fnm install --latest
```

Verify:
```bash
fnm list
node --version
npm --version
```
## 3: RustFS installation   -------------------------------
RustFS is a high-performance, distributed object storage system built in Rust.

```bash
curl -O https://rustfs.com/install_rustfs.sh && bash install_rustfs.sh
```

docker pull rustfs/rustfs:latest
docker run -d \
  --name rustfs \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /data:/data \
  rustfs/rustfs:latest

docker exec -it rustfs /bin/bash

## 4: SQLx CLI installation   -------------------------------
```bash sqlx cli installation
cargo install sqlx-cli
```

```bash sqlx cli usage
sqlx database create
sqlx migrate add <migration_name>
sqlx migrate run
sqlx migrate revert
sqlx migrate info
```

## 5: miniconda installation   -------------------------------

Installing on arch 
paru -S miniconda3
conda --version


This is mainly for my AI/ML environments (keep them isolated from system Python).

Related notes:
- Hugging Face + AI stack: `1-resources/10-arch/10a-arch-config-extended.md` (moved into this note)
- Jupyter/notebooks inside env: `1-resources/10-arch/10a-arch-config-extended copy.md` (moved into this note)

### Install (system-wide recommended)
Pick a location like `/opt/miniconda3` (clean for Arch + multi-project use).

```bash
# download (x86_64 Linux)
cd /tmp
# -O: save file as remote name
# -L: follow redirects (safer)
curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
# install
sudo bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3

# Options explained:
# -b: batch (no prompts)  |  -p: install prefix (path)
# -b: batch mode (no prompts / no interactive license questions). It installs immediately with defaults.
# -p /opt/miniconda3: prefix path (the install directory). Here it installs Miniconda into /opt/miniconda3 instead of the default location.

# optional: add conda to PATH for all users (or do bash sourcing below)
sudo ln -sf /opt/miniconda3/bin/conda /usr/local/bin/conda
```

If you encounter any issues, try updating conda by running:

```bash
conda update -n base -c defaults conda
```



### Bash activation
```bash
echo '[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh' >> ~/.bashrc
source ~/.bashrc
conda --version
```

If `conda activate` fails:
```bash
conda init bash
```

### Create env (example)
```bash
conda create -n ai python=3.10 -y
conda activate ai
python --version
which python
```

## 6: AI/ML (Hugging Face) stack checklist   -------------------------------

This section is merged from `10a-arch-config-extended.md`.

### System packages (baseline)
```bash
sudo pacman -S --needed base-devel git wget curl ca-certificates
```

Optional but useful:
```bash
sudo pacman -S --needed unzip jq
```

### Conda shell activation (Bash)
If conda is installed system-wide (common path: `/opt/miniconda3`), ensure it’s sourced in Bash:

```bash
echo '[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh' >> ~/.bashrc
source ~/.bashrc
conda --version
```

If `conda activate` fails, run once and restart the terminal:
```bash
conda init bash
```

### Create env for Hugging Face work
Target Python: 3.10 or 3.11 (stable, wide wheel support).

```bash
conda create -n ai python=3.10 -y
conda activate ai
python --version
which python
```

### Install Hugging Face ecosystem (core)
```bash
pip install -U pip
pip install transformers datasets accelerate huggingface_hub
```

### Deep learning backend (pick one)

PyTorch (most common with Hugging Face)

CPU-only:
```bash
pip install torch torchvision torchaudio
```

GPU notes:
- NVIDIA: install the correct CUDA-enabled torch build (follow PyTorch install selector).
- AMD (ROCm): only certain GPUs are supported; for unsupported cards, use CPU or consider container/remote GPU.

TensorFlow (less common for HF these days)
```bash
pip install tensorflow
```

### Optional add-ons (only if needed)

Efficient finetuning / low-VRAM inference:
```bash
pip install bitsandbytes peft
```

UIs / quick demos:
```bash
pip install gradio streamlit
```

### Hugging Face login (for private models / pushing)
```bash
huggingface-cli login
```

Token path: `https://huggingface.co/settings/tokens`

### Quick verification (first model run)
```bash
python - <<'PY'
from transformers import pipeline

pipe = pipeline("text-generation", model="gpt2")
out = pipe("Hello AI", max_length=20, num_return_sequences=1)
print(out[0]["generated_text"])
PY
```

### Storage layout tip (for large models/datasets)
- Fast disk (NVMe): conda envs + HF model cache (frequent reads).
- Large disk (SATA/HDD): datasets + experiment outputs/logs.

Useful env vars (optional):
```bash
# HF cache
export HF_HOME="$HOME/.cache/huggingface"
# datasets cache
export HF_DATASETS_CACHE="$HOME/.cache/huggingface/datasets"
```

## 7: Jupyter notebooks inside the conda env   -------------------------------

This section is merged from `10a-arch-config-extended copy.md`.

### Install notebooks (inside the (ai) env)
Run after `conda activate ai`:

```bash
pip install jupyterlab notebook ipykernel
```

- JupyterLab: modern UI (recommended)
- Jupyter Notebook: classic UI
- ipykernel: connects the env to notebooks

### Link the env kernel to Jupyter
```bash
python -m ipykernel install --user --name ai --display-name "Python (ai)"
```

### Start
```bash
jupyter lab
```

or:
```bash
jupyter notebook
```

### Test inside a notebook
Create a new notebook, select the `Python (ai)` kernel, then run:

```python
from transformers import pipeline

pipe = pipeline("text-generation", model="gpt2")
pipe("Hello AI", max_length=20)
```

### Optional (common data + plotting)
```bash
pip install matplotlib pandas numpy
```

Widgets:
```bash
pip install ipywidgets
```

## 8: React Native / Android device (ADB) setup   -------------------------------

This section is merged from `1-resources/10-arch/docs.md`.

### Install adb (Arch)
```bash
sudo pacman -S --needed android-tools
adb version
```

### Identify device vendor/product IDs
```bash
lsusb
```

Example output:
```
Bus 002 Device 007: ID 2717:ff48 Xiaomi Inc. Mi/Redmi series (MTP + ADB)
```

### Udev rule for the device
Create rules file:

```bash
cat <<'EOF' | sudo tee /etc/udev/rules.d/51-android.rules
# Xiaomi / Redmi (MTP + ADB)
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", ATTR{idProduct}=="ff48", MODE="0666", GROUP="plugdev", SYMLINK+="android%n"

# Broader Xiaomi rule (covers most modes)
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="plugdev"
EOF
```

Alternative (community rules):
```bash
sudo curl -fsSL https://raw.githubusercontent.com/M0Rf30/android-udev-rules/main/51-android.rules -o /etc/udev/rules.d/51-android.rules
```

Reload rules:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Unplug and replug the phone.

Check:
```bash
adb devices
```

### Notes
- If `plugdev` group does not exist on your system, either create it or switch the rule to a group you use for USB device access (commonly `uucp` on Arch), then add your user to that group and re-login.

---

## 9: OpenJDK Multi-Version Setup (archlinux-java) -------------------------------

### Install OpenJDK Versions
```bash
sudo pacman -S --needed --noconfirm jdk-openjdk jdk17-openjdk jdk11-openjdk
```

### List Installed Java Environments
```bash
archlinux-java status
```

### Set Default Java Version
```bash
sudo archlinux-java set java-17-openjdk
```

### Verify Default Version
```bash
java -version
```