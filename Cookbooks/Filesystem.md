# Filesystem
A PowerShell 5 cookbook about files, folders, and the filesystem.

## Search

### Search by Item
```powershell
# search in the current directory
gci -filter "{name}"
```

```powershell
# search throughout the subtree rooted at the current directory
gci -recurse -filter "{name}"
```

```powershell
# search for files only
gci -filter "{name}" -File
```

```powershell
# silence errors (e.g. "Access Permissions Denied")
gci -filter "{name}" -ErrorAction SilentlyContinue
```

### Search by Content
