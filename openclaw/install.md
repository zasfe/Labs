

**Window + WSL2 + Docker + Openclaw**

```

sudo apt update
sudo apt install -y nodejs
sudo apt install -y unzip ripgrep
curl -fsSL https://bun.com/install | bash

# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"
# Download and install Node.js:
nvm install 24
# Verify the Node.js version:
node -v # Should print "v24.15.0".
# Download and install pnpm:
corepack enable pnpm
# Verify pnpm version:
pnpm -v


# 1. Set Up the Docker Repository 
sudo apt update
sudo apt install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2. Install Docker and Docker Compose 
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin podman


# 3. Verify Installation
sudo systemctl status docker
docker --version
docker compose version

# 4. Optional: Run Docker Without Sudo 
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect


npm install -g @openai/codex


bun install -g opencode-ai
bunx oh-my-openagent install --no-tui --claude=no --openai=yes --gemini=no --copilot=no

npx @slkiser/opencode-quota init




```
