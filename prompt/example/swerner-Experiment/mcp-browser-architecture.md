# Protocollie - Architecture & Design Document

## Overview

Protocollie is a desktop application built with Tauri 2.0 that serves as a comprehensive testing and exploration tool for Model Context Protocol servers. Similar to Postman for APIs, it allows developers to connect to multiple MCP servers, explore their capabilities, and test their functionality in real-time.

## Target Users

Protocollie is designed for **MCP server developers**, **AI/LLM integration engineers**, and **technical product managers** who need to rapidly prototype, test, and debug MCP implementations. Just as early Postman users were API developers tired of using curl commands, Protocollie serves developers building AI-powered tools who need a professional interface to understand what MCP servers expose, test tool calls with complex arguments, and validate responses before integrating them into production applications.

## Core Architecture

### Technology Stack

- **Frontend**: React/TypeScript with Tailwind CSS
- **Backend**: Rust with Tauri 2.0
- **MCP Integration**: Direct system Node.js processes with JSON-RPC protocol
- **Node.js Runtime**: System Node.js (users have Node.js installed as MCP developers)
- **Data Storage**: Hybrid approach (SQLite + in-memory + JSON)
- **IPC**: Tauri's command system + direct process stdin/stdout communication

### Architecture Decision Rationale

We chose to use direct system Node.js processes instead of bundled sidecars or Rust MCP implementations for several key reasons:

1. **Target Audience Alignment**: MCP developers already have Node.js installed for most MCP servers (`npx`, `npm` packages)
2. **Simplified Architecture**: Direct process spawning is simpler than complex sidecar coordination and bundling
3. **Universal Command Support**: Works with any MCP server type - `npx`, `python`, `ruby`, custom binaries
4. **Real-world Usage**: Matches how developers actually run MCP servers in development and production
5. **Enhanced Error Messaging**: Can provide specific guidance for missing dependencies with installation instructions

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (React/TS)                       │
│                  - Dynamic server management UI              │
│                  - Tool execution and result visualization   │
├─────────────────────────────────────────────────────────────┤
│                    Tauri IPC Bridge                          │
│                  - Type-safe command interface               │
│                  - Server lifecycle management               │
├─────────────────────────────────────────────────────────────┤
│                    Rust Backend (Tauri)                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Core App Manager                        │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │   │
│  │  │   MCP       │  │   Session   │  │   Data     │ │   │
│  │  │  Process    │  │   Manager   │  │  Storage   │ │   │
│  │  │  Manager    │  │             │  │ (SQLite)   │ │   │
│  │  └─────────────┘  └─────────────┘  └────────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│              Multiple MCP Server Processes                   │
│               (One process per server connection)            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │    node     │  │     npx     │  │   python    │       │
│  │ script.cjs  │  │  @mcp/git   │  │  server.py  │       │
│  │   stdin/    │  │   stdin/    │  │   stdin/    │       │
│  │   stdout    │  │   stdout    │  │   stdout    │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## Backend Design

### Core Components

#### 1. MCP Process Manager (Rust)
See `mcp_process.rs` for implementation. Key methods:
- `MCPProcess::start(command, args)` - Spawn MCP server with stdio pipes
- `send_initialize()` - MCP protocol handshake
- `execute_mcp_tool(tool_name, arguments)` - Execute tools via JSON-RPC
- `list_mcp_tools()` - Discover available tools
- Enhanced Node.js detection with helpful error messages

#### 2. Global Process Registry  
See `mcp_process.rs:279` - Central management using `HashMap<String, MCPProcess>`

#### 3. Tauri Commands
See `server_commands.rs` for all Tauri command implementations:
- `connect_server()`, `disconnect_server()` - Server lifecycle
- `list_tools()`, `execute_tool()` - Tool operations  
- `add_server()`, `update_server()`, `delete_server()` - Configuration management

#### 4. Data Storage Layer
See `db.rs` for SQLite implementation with servers, history, collections, and preferences tables.

### Distribution Strategy

**No bundling required:**
- Application uses system Node.js directly
- No platform-specific binaries to generate or maintain
- Smaller app distribution size
- Simpler build process

**System requirements:**
- Node.js installed for Node.js-based MCP servers (`node`, `npx` commands)
- Python installed for Python-based MCP servers
- Other runtimes as needed by specific MCP servers

**User guidance:**
- Clear error messages when dependencies are missing
- Installation instructions for Node.js/Python/other runtimes
- Links to official installation guides
- Platform-specific package manager commands

## Frontend Design

### Component Structure
See `src/components/` for implementation:
- `ui/` - Reusable UI primitives (Modal, Button, Input, Card, ErrorBoundary)
- `forms/` - Form-specific components with validation logic (AddServerForm, EditServerForm)
- `layout/` - Layout and navigation components:
  - `Layout` - Three-panel layout structure with resizable panels
  - `Header` - Enhanced header with branding, theme toggle, and navigation
  - `Sidebar` - Sectioned navigation with server management
  - `MainContent` - Dynamic content area with breadcrumb navigation and contextual rendering
  - `ToolSelector` - Tool selection dropdown with search and filtering
  - `ToolDisplay` - Tool execution interface with parameter forms
  - `RightPanel` - Contextual information panel (expandable for future features)
- `hooks/` - Custom hooks for state management and side effects
- `types/` - TypeScript interfaces and type definitions

### Key Features Implemented

1. **Professional Three-Panel Layout** - Resizable panels with sidebar, main content, and right panel
2. **Enhanced Header** - Branding, theme toggle, and workspace selector
3. **Organized Sidebar Navigation** - Sectioned design with server management and search
4. **Dynamic Main Content** - Context-aware content with breadcrumb navigation
5. **Tool Selection Interface** - Dropdown with search, filtering, and metadata display
6. **Server Management** - Add/edit/remove server configurations with real-time connection status
7. **Tool Discovery** - Dynamic tool listing with parameter information and search
8. **Tool Execution** - Complex parameter forms with validation and execution tracking
9. **Request History** - Comprehensive execution tracking with contextual filtering and detailed inspection
10. **Context-Aware Right Panel** - Tool documentation, filtered execution history, and server information

## Key Benefits of System Node.js Architecture

### 1. **Target Audience Alignment**
- MCP developers already have Node.js installed for most servers
- No additional dependencies - users need Node.js anyway for `npx` commands
- Smaller app distribution size (no bundled Node.js binaries)
- Matches real-world development workflows

### 2. **Universal Command Support**
- Works with any MCP server type: `node`, `npx`, `python`, `ruby`, custom binaries
- Enhanced error messaging with specific installation guidance
- Support for the entire MCP ecosystem out of the box
- No restrictions based on runtime or language

### 3. **Simplified Architecture**
- Direct process spawning - no complex sidecar coordination
- One process per MCP server with independent stdio communication
- Easier debugging and maintenance
- Clean JSON-RPC protocol implementation

### 4. **True Process Isolation**
- Each MCP server runs in its own OS process
- Crashes don't affect other servers or the main app
- Individual process lifecycle management
- Clean resource cleanup and management

## Development Phases

### Phase 1: Core MVP ✅ (41/41 stories completed)
- Basic stdio transport support ✅
- Server connection management ✅  
- Tool exploration and execution ✅
- Request history tracking ✅

### Phase 2: Enhanced Tool Execution UX & Professional Design ✅ (22/22 stories completed)
**Goal**: Transform from functional MVP to polished professional dev tool

**Phase 2.0: Professional Layout Foundation ✅ (6/6 stories completed)**
- Three-panel layout structure ✅
- Enhanced header with navigation ✅
- Redesigned left sidebar navigation ✅
- Tool selection dropdown in main panel ✅
- Dynamic main content area ✅
- Right panel context system ✅

**Phase 2a: Enhanced Tool Execution Interface ✅ (4/4 stories completed)**
- Advanced parameter input forms with Monaco Editor ✅
- Syntax highlighting for results ✅
- Tool execution templates ✅
- Request history enhancement ✅

**Phase 2b: Professional UI/UX Design System ✅ (5/5 stories completed)**
- Comprehensive design system ✅
- Enhanced dark/light theme system ✅
- Professional header and navigation ✅
- Enhanced server management UI ✅
- Tool discovery and organization ✅

**Phase 2c: Developer Experience Enhancements ✅ (2/2 stories completed)**
- Code editor integration with Monaco ✅
- Response viewer enhancement ✅

**Phase 2e: Visual Polish and Branding ✅ (5/5 stories completed)**
- Professional branding ✅
- Onboarding and help system ✅
- Accessibility enhancements ✅
- Responsive design ✅
- Help modal improvements ✅

**Key achievements:**
- Professional three-panel layout with responsive design
- Monaco Editor integration for complex parameter input
- Comprehensive syntax highlighting for all response types
- Advanced tool organization with favorites and recent usage
- Professional branding and onboarding system
- Full accessibility support with keyboard navigation
- Enhanced server management with health monitoring

### Phase 3: Enhanced Features & Content Types ⏳ (0/25 stories completed)
**Goal**: Extend MCP protocol support and add advanced organization features

**Phase 3a: Enhanced Error Handling & User Feedback (0/7 stories)**
- Basic error message enhancement
- Error classification system  
- Error recovery suggestions
- Basic retry mechanisms
- Toast notification system
- Enhanced loading states
- Enhanced keyboard shortcuts

**Phase 3b: MCP Prompts Support (0/5 stories)**
- Basic prompts discovery
- Prompts display and navigation
- Basic prompt execution
- Prompt parameter input
- Prompts history integration

**Phase 3c: MCP Resources Support (0/5 stories)**
- Basic resources discovery
- Resources display and navigation
- Basic resource content viewing
- Resource content formatting
- Resources history integration

**Phase 3d: Basic Collections and Organization (0/8 stories)**
- Server grouping interface
- Group-based operations
- Request favorites system
- Enhanced search across content
- Basic workspace switching
- Workspace data management
- Basic export functionality
- Basic import functionality

**Key goals:**
- Complete MCP protocol support (tools, prompts, resources)
- Professional error handling and user feedback
- Basic collections and workspace management
- Enhanced organization and search capabilities

### Phase 4: Remote Transports
- SSE transport implementation
- OAuth authentication
- WebSocket support
- Cloud sync capabilities

### Phase 5: Advanced Testing & Automation
- Batch tool execution (moved from Phase 2a)
- Environment variable management (moved from Phase 2c)
- Performance monitoring (moved from Phase 2c)
- Request chaining (moved from Phase 2d)
- Mock and test data management (moved from Phase 2d)
- API documentation generation (moved from Phase 2d)
- Integration testing framework (moved from Phase 2d)
- Plugin system foundation (moved from Phase 2d)
- Workspace management and organization
- Automated testing

## Future Extensibility

### Transport Plugins
```rust
#[async_trait]
pub trait TransportAdapter {
    async fn connect(&self, config: &TransportConfig) -> Result<Box<dyn Transport>>;
    fn supported_type(&self) -> TransportType;
}
```

### Export Formats
- Postman collections
- OpenAPI-like specifications  
- Custom test suites

### Advanced Features
- Request chaining
- Environment variables and workspace management
- Batch tool execution
- Pre/post request scripts
- Performance testing

## Theme System & UI Architecture

### Custom Theme Implementation
- **System**: Custom `.light` class-based theming (not Tailwind's default `dark:` system)
- **Provider**: React context with `useTheme()` hook provides `resolvedTheme` ('light'|'dark')
- **CSS Variables**: Light theme overrides in `App.css` change Tailwind class colors via CSS variables
- **Theme Toggle**: Automatic system preference detection with manual override capability

### Theme-Aware Component Patterns
Components requiring theme support should:
1. Import `useTheme()` hook: `import { useTheme } from '../../hooks/useTheme'`
2. Get resolved theme: `const { resolvedTheme } = useTheme()`
3. Create conditional styling functions that return appropriate classes for each theme
4. **Avoid `dark:` prefixes** - they don't work with the custom theme system

### Recent Theme Fixes (Story 3.1)
- **ServerCard**: Fixed selection highlighting readability in light mode
- **HelpModal**: Fixed code/kbd element readability in dark mode  
- **Badge Component**: Removed incompatible `dark:` prefixes
- **Error Display**: Unified theme-neutral error colors for both light/dark modes
- **CSS Coverage**: Enhanced gray class overrides for broader theme compatibility

## Appendix: What is MCP?

The Model Context Protocol (MCP) is an open protocol that standardizes how applications provide context to Large Language Models (LLMs). Think of MCP like a USB-C port for AI applications - just as USB-C provides a standardized way to connect devices to various peripherals, MCP provides a standardized way to connect AI models to different data sources and tools.

### Key MCP Concepts:

**MCP Servers** are lightweight programs that expose specific capabilities (tools, prompts, and resources) through the protocol. For example, a Git MCP server might expose tools like `git_status`, `git_commit`, and `git_diff` that an LLM can call.

**MCP Clients** are applications (like Claude Desktop or IDEs) that connect to MCP servers to access their capabilities. They maintain 1:1 connections with servers.

**Core Primitives:**
- **Resources**: Data and content that servers expose (files, documents, live data)
- **Tools**: Functions that LLMs can execute through the server (API calls, system commands, calculations)
- **Prompts**: Reusable prompt templates and workflows
- **Sampling**: Allows servers to request LLM completions

**Transport Layers**: MCP supports multiple transport mechanisms:
- **stdio**: Communication through standard input/output (for local processes)
- **SSE (Server-Sent Events)**: For HTTP-based connections
- **WebSocket**: For bidirectional streaming (planned)

The protocol enables LLMs to interact with external systems in a controlled, secure way while maintaining clear boundaries between the AI model and the tools/data it accesses. This standardization means developers can write MCP servers once and have them work with any MCP-compatible client, similar to how REST APIs work with any HTTP client.
