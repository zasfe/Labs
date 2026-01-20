# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Start for New Sessions

**Before starting any work, read these files in order:**

1. **`pair_programming.md`** - Our workflow process for story-driven development
2. **`project_plan_{some_extension}.md`** - Current progress and next story to work on  
3. **`technical_considerations.md`** - Lessons learned and implementation decisions
4. **`mcp-browser-architecture.md`** - Overall architecture and design decisions

**For color migration work, also read:**
5. **`color_migration_analysis_report.md`** - Comprehensive color audit and semantic mapping guide

**Key workflow reminders:**
- Always use the TodoWrite tool to track story progress
- Follow the exact human verification format from pair_programming.md
- Never run `pnpm tauri dev` - human handles manual testing
- Update technical_considerations.md with lessons learned after each story

## Overview

Protocollie is a desktop application built with Tauri 2.0 and React/TypeScript that serves as a comprehensive testing and exploration tool for Model Context Protocol (MCP) servers. It functions similarly to Postman for APIs, allowing developers to connect to multiple MCP servers, explore their capabilities, and test their functionality in real-time.

## Development Commands

### Frontend Development
- `pnpm dev` - Start development server (runs Vite dev server)
- `pnpm build` - Build the React frontend for production
- `pnpm preview` - Preview production build

### Tauri Development
- `pnpm tauri build` - Build the complete desktop application
- `pnpm tauri build --no-bundle` - Build without bundling (faster, good for testing compilation)
- `pnpm tauri` - Access Tauri CLI commands
- **Note:** Do NOT run `pnpm tauri dev` in automated workflows - human handles manual testing

### Package Management
- Uses `pnpm` as the package manager (not npm or yarn)
- Lock file: `pnpm-lock.yaml`

## Architecture Overview

### Technology Stack
- **Frontend**: React 18 + TypeScript + Vite + Tailwind CSS v4
- **Backend**: Rust with Tauri 2.0
- **Desktop Framework**: Tauri 2.0 (cross-platform desktop apps)
- **MCP Integration**: Direct system Node.js processes with JSON-RPC protocol
- **Data Storage**: SQLite with rusqlite + in-memory + JSON hybrid approach
- **Process Communication**: Direct stdin/stdout IPC with individual MCP server processes

### System Node.js MCP Architecture (Implemented)
The application uses direct system Node.js processes for MCP server communication:
- **Rust/Tauri**: Manages desktop app, UI, and individual MCP server process lifecycle
- **System Node.js**: Direct process spawning for each MCP server connection
- **Communication**: Direct stdin/stdout IPC with JSON-RPC protocol per process
- **Benefits**: Simple architecture, universal command support, smaller app size, matches real-world MCP usage

**Implementation Status:** ✅ Complete - Direct process management, universal command support, enhanced error messaging, JSON-RPC protocol, process lifecycle management, and tool execution all working.

## Project Structure Overview

See `mcp-browser-architecture.md` for detailed component organization. Key locations:
- `src/` - React frontend with components, hooks, types
- `src-tauri/src/` - Rust backend with database, MCP process management, and Tauri commands
- Documentation files in root directory

## MCP Integration Context

This application is specifically designed for MCP (Model Context Protocol) server testing and exploration. The app provides a Postman-like interface for MCP server development and testing with dynamic server connection management, tool execution, and request/response history.

## Theme System Notes

**IMPORTANT**: This app uses a custom theme system, NOT Tailwind's default dark mode.

### Key Points for Theme-Aware Components:
- Use `useTheme()` hook: `const { resolvedTheme } = useTheme()`
- **Never use `dark:` prefixes** - they don't work with our `.light` class system
- Create conditional styling based on `resolvedTheme === 'light'` vs `'dark'`
- See `mcp-browser-architecture.md` for detailed theme implementation patterns

### Common Theme Issues Fixed:
- Selection highlighting unreadable in light mode → Use theme-conditional colors
- Code/kbd elements unreadable in dark mode → Use theme-aware backgrounds
- Badge components using incompatible `dark:` prefixes → Remove and use theme-neutral colors
