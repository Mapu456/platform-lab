# Week 1 — Process Internals: SIGTERM Investigation

## Environment

- job-api version:
- Java version:
- OS / kernel:
- Date:

---

## Signal Capability Check

```
# Command run:
grep SigCgt /proc/<pid>/status

# Raw output:
SigCgt: <hex>

# Decoded bitmask (python3 -c "print(bin(0x<hex>))"):

# Is bit 15 (SIGTERM) set? yes / no
```

---

## strace Output — SIGTERM to exit

```
# Command:
strace -p <pid> -e trace=signal,exit_group

# Trigger:
kill -SIGTERM <pid>

# Observed output:
```

---

## Timeline: SIGTERM → Clean Exit

| t=0ms | SIGTERM received |
|-------|-----------------|
| t=?   | |
| t=?   | |
| t=?   | process exits    |

---

## /proc Observations

### Open file descriptors at shutdown start

```
ls -la /proc/<pid>/fd/
```

### TCP connections at shutdown start

```
cat /proc/<pid>/net/tcp
# decoded:
```

---

## Shell Script — Process State Inspector

See `../../scripts/inspect-job-api.sh`

### Sample output on a running job-api:

```
```

### Sample output mid-shutdown (SIGTERM sent, 30s window active):

```
```

---

## Break Exercise: server.shutdown=immediate

**What changed:**
**How we detected it (strace evidence):**
**Difference vs graceful:**
