---
id: 20260502100000
title: Arch — AMD GPU compute (RX 570 / Polaris) — ROCm, OpenCL, PyTorch
date: 2026-05-02 10:00
type: note
status: draft
tags: [arch, amd, rocm, pytorch, opencl]
links:
  - 1-resources/10-arch/10a-arch-config-dev.md
---
# Log
- 2026-05-02 10:00 - Created note for host uranium@chernobyl (Ryzen 5 3600, Radeon RX 570, Arch kernel 7.x).

# Notes
# AMD GPU Compute (RX 570 / Polaris)
- [ ] Mental Model (CUDA vs ROCm)
- [ ] Hardware Baseline & Constraints
- [ ] ROCm Runtime Packages Installation
- [ ] PyTorch ROCm Compatibility & Testing
- [ ] OpenCL Path & Clinfo
- [ ] Practical Strategy & Verification Checklist
- [ ] Environment Variables Reminder

Reference stack doc: `1-resources/10-arch/10a-arch-config-dev.md` (conda, HF, Jupyter).

## 1: Mental Model (CUDA vs ROCm) -------------------------------

- `export MATCHER_DEVICE=cuda` is wrong on AMD: CUDA is NVIDIA-only.
- Graphics use the in-kernel `amdgpu` driver (normal on Arch); that does not imply PyTorch sees a GPU for compute.
- PyTorch “GPU” checks use the CUDA-style API even when the backend is ROCm (`torch.cuda.is_available()` still applies naming-wise).

---

## 2: Hardware Baseline & Constraints -------------------------------

- CPU: AMD Ryzen 5 3600
- GPU: AMD Radeon RX 570 (Polaris)
- Symptom: `python -c "import torch; print(torch.cuda.is_available())"` prints `False` with default CPU PyTorch or without a working ROCm stack.

---

## 3: ROCm Runtime Packages Installation -------------------------------

Install runtime pieces:

```bash
sudo pacman -S rocm-opencl-runtime rocm-hip-runtime
```

Sanity check:

```bash
/opt/rocm/bin/rocminfo
```

Expectations for RX 570 (Polaris):

- ROCm upstream targets newer RDNA/CDNA hardware; Polaris is often unsupported or flaky.
- Even with packages installed, HIP or PyTorch ROCm wheels may still refuse the GPU or crash. Treat as experimental.

---

## 4: PyTorch ROCm Compatibility & Testing -------------------------------

ROCm builds are published on PyTorch’s index; version pins move over time — check the official install matrix before copying:

```bash
pip install torch torchvision --index-url https://download.pytorch.org/whl/rocm5.6
```

Test:

```bash
python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else '')"
```

If this stays `False` or errors, fall back to CPU or remote GPU; fighting Polaris-specific gaps often wastes time.

---

## 5: OpenCL Path & Clinfo -------------------------------

PyTorch does not use OpenCL as its primary GPU path. OpenCL is still useful for other tools and for verifying userspace compute sees the GPU:

```bash
sudo pacman -S opencl-mesa clinfo
clinfo
```

For Python GPU work outside CUDA/ROCm, options include `pyopencl` or frameworks that target OpenCL explicitly.

---

## 6: Practical Strategy & Verification Checklist -------------------------------

- Prefer CPU PyTorch for reliability (batch size, quantization, smaller models).
- Threading: `torch.set_num_threads(...)` where appropriate.
- For heavy GPU needs: cloud GPU or newer AMD (RX 6000+) / NVIDIA.

### Quick Verification Checklist:

```bash
lspci | grep VGA
clinfo
/opt/rocm/bin/rocminfo
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
```

---

## 7: Environment Variables Reminder -------------------------------

- Do not force `MATCHER_DEVICE=cuda` on AMD unless the application explicitly maps that name to ROCm or CPU (many do not).
- After experiments: `unset MATCHER_DEVICE` unless you know the app’s semantics.

