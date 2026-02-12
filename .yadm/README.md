# Dotfiles

Managed with [yadm](https://yadm.io/) - Yet Another Dotfiles Manager

## Quick Start

### Installation

```bash
# Clone your dotfiles
yadm clone <your-repo-url>

# Or install yadm first, then clone
mkdir -p ~/.local/bin
curl -fLo ~/.local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm
chmod +x ~/.local/bin/yadm
export PATH="$HOME/.local/bin:$PATH"
yadm clone <your-repo-url>
```

## Usage

### Add files to tracking
```bash
yadm add ~/.bashrc
yadm commit -m "Add bashrc"
yadm push
```

### Check status
```bash
yadm status
```

### Pull latest changes
```bash
yadm pull
```

### View tracked files
```bash
yadm list
```

## Common Commands

```bash
yadm add <file>          # Add file to tracking
yadm rm --cached <file>  # Remove file from tracking
yadm commit -m "msg"     # Commit changes
yadm push                # Push to remote
yadm pull                # Pull from remote
yadm status              # Check status
yadm diff                # Show diff
yadm log                 # View commit history
```

## Configuration

- **Bootstrap script**: `~/.config/yadm/bootstrap` - runs after clone
- **Yadm config**: `~/.config/yadm/config`

## Features

### Encryption (Optional)
To encrypt sensitive files:
```bash
yadm encrypt              # Encrypt files in ~/.config/yadm/encrypt
yadm decrypt              # Decrypt files
```

### Alternate Files
Yadm supports OS/host-specific configs:
- `.bashrc##os.Linux`
- `.bashrc##hostname.myhost`

### Templates
Yadm can process templates for dynamic configurations.

## Learn More

- [YADM Documentation](https://yadm.io/)
- [YADM GitHub](https://github.com/TheLocehiliosan/yadm)
