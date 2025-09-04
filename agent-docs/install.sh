#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$DOTFILES/agent-docs"

# Function to process template and create destination file
process_template() {
  local destination="$1"

  # Derive template name from destination (e.g., CLAUDE.md -> CLAUDE.tpl.md)
  local filename; filename=$(basename "$destination")
  local name_without_ext="${filename%.*}"
  local template_name="${name_without_ext}.tpl.md"
  local template_file="$SCRIPT_DIR/$template_name"
  local common_template="$SCRIPT_DIR/common.tpl.md"

  echo -e "\n${GREEN}Setting up $filename...${NC}"

  if [ -f "$template_file" ]; then
    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$destination")"
    # Process template - replace {{REPO_PATH}} with actual path
    sed "s|{{REPO_PATH}}|$SCRIPT_DIR|g" "$template_file" >"$destination"

    # Append common bits if common.tpl.md exists
    if [ -f "$common_template" ]; then
      echo "" >>"$destination"  # Add blank line separator
      sed "s|{{REPO_PATH}}|$SCRIPT_DIR|g" "$common_template" >>"$destination"
    fi

    echo -e "${GREEN}✓ Created $filename${NC}"
  else
    echo -e "${RED}Error: $template_name not found${NC}"
    exit 1
  fi
}

# Function to link settings files
link_settings() {
  local tool="$1"
  local settings_file="$2"

  local repo_settings="$SCRIPT_DIR/settings/$tool.json"

  echo -e "\n${GREEN}$tool settings configuration...${NC}"

  if [ -L "$settings_file" ] && [ "$(readlink "$settings_file")" = "$repo_settings" ]; then
    echo -e "${GREEN}✓ Settings already linked${NC}"
  elif [ -f "$settings_file" ]; then
    echo -e "${YELLOW}Existing settings.json found${NC}"
    echo -e "${YELLOW}Review $repo_settings for recommended settings${NC}"
    echo -e "${YELLOW}Run ${BLUE}rm $settings_file${NC} to remove the existing settings${NC}"
    exit 1
  else
    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$settings_file")"
    ln -s "$repo_settings" "$settings_file"
    echo -e "${GREEN}✓ Linked settings${NC}"
  fi
}

# Function to merge settings from template into existing config
merge_settings() {
  local tool="$1"
  local config_file="$2"

  local repo_settings="$SCRIPT_DIR/settings/$tool.json"

  echo -e "\n${GREEN}$tool configuration...${NC}"

  if [ ! -f "$repo_settings" ]; then
    echo -e "${YELLOW}No settings template found for $tool${NC}"
    return 0
  fi

  if [ ! -f "$config_file" ]; then
    echo -e "${YELLOW}Config file $config_file not found, creating from template${NC}"
    mkdir -p "$(dirname "$config_file")"
    cp "$repo_settings" "$config_file"
    echo -e "${GREEN}✓ Created config from template${NC}"
  else
    echo -e "${YELLOW}Merging settings into existing config${NC}"
    
    # Use jq to merge the repo settings into the existing config
    # The + operator merges objects, with the right side taking precedence
    if command -v jq >/dev/null 2>&1; then
      local temp_file; temp_file=$(mktemp)
      jq -s '.[0] * .[1]' "$config_file" "$repo_settings" > "$temp_file" && mv "$temp_file" "$config_file"
      echo -e "${GREEN}✓ Merged settings${NC}"
    else
      echo -e "${RED}jq not available - cannot merge settings automatically${NC}"
      echo -e "${YELLOW}Manual merge required: $repo_settings -> $config_file${NC}"
    fi
  fi
}

echo -e "${BLUE}Agent Docs Installer${NC}"
echo -e "${BLUE}====================${NC}"
echo

# 1. Install slash commands
echo -e "${GREEN}Installing slash commands...${NC}"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$CLAUDE_COMMANDS_DIR"

if [ -d "$SCRIPT_DIR/commands" ]; then
  cp "$SCRIPT_DIR/commands"/*.md "$CLAUDE_COMMANDS_DIR/" 2>/dev/null || {
    echo -e "${YELLOW}No command files found${NC}"
  }
  count=$(find "$CLAUDE_COMMANDS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo -e "${GREEN}✓ Installed $count commands${NC}"
fi

# 2. Create md files from template
process_template "$HOME/.claude/CLAUDE.md"
process_template "$HOME/.config/AGENT.md"
process_template "$HOME/.config/AGENTS.md"

# 3. Optional: Install tool settings
link_settings claude "$HOME/.claude/settings.json"
link_settings amp "$HOME/.config/amp/settings.json"
merge_settings claude-mcp "$HOME/.claude.json"

# Done
echo -e "\n${GREEN}✅ Installation complete!${NC}"
echo
echo -e "Commands installed to: ${BLUE}~/.claude/commands/${NC}"
echo -e "Claude memory: ${BLUE}~/.claude/CLAUDE.md${NC}"
echo -e "AmpCode memory: ${BLUE}~/.config/AGENT.md${NC}"
echo -e "Agents: ${BLUE}~/.config/AGENTS.md${NC}"
echo -e "\nType ${BLUE}/${NC} in Claude Code to see available commands"
