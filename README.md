# DirtyFrag-Blocker v2.1 🛡️

**DirtyFrag-Blocker** is an emergency mitigation tool designed to protect Linux systems against the **Dirty Frag (CVE-2026-3491)** and **Copy Fail 2** Local Privilege Escalation (LPE) vulnerabilities.

As official patches from distributions (Ubuntu, RHEL, Debian, Proxmox) are currently in development, this tool provides an immediate "shield" by disabling the vulnerable entry points in the Linux kernel.

## ⚠️ Warning
**Applying the "Secure" option will disable the following features:**
* **IPsec VPNs:** Site-to-site or client VPNs using kernel-mode encryption (`esp4`/`esp6`).
* **AFS Clients:** Access to the Andrew File System (`rxrpc`).
* **Kernel Crypto Offloading:** Specific high-performance encryption tasks (`af_alg`).

Standard web traffic (HTTPS), SSH, and database connections are generally **unaffected**.

---

## 🚀 How to Run

You can run the script directly via `curl` for a quick audit, or clone the repository for full usage.

### Option 1: Quick Audit (Safe)
This will download and launch the interface without making any changes until you select "Secure."
```bash
curl -sSL https://raw.githubusercontent.com/lsmithx2/DirtyFrag-Blocker/main/mitigate.sh | sudo bash
