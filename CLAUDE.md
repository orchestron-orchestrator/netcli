# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

- **Build project**: `acton build --dev`
- **Run tests**: `acton test`

## Project Structure

This is the netcli package - a CLI client library system built on Acton with the following architecture:

- **Build system**: Uses Zig build system (`build.zig`) for compiling generated C code from Acton
- **Dependencies**: Acton base libraries and ActonDB (configured in `build.zig.zon`)

## Code Architecture

The project provides CLI client libraries for network device management:

### SSH Client Library (`src/ssh.act`)
- Generic SSH client actor with sshpass support
- Multiple authentication methods: password, SSH key, or none
- Configurable connection options (timeout, host key checking, subsystems)
- Callback-based interface for async operations
- Used as foundation for higher-level clients

### Router Client Library (`src/router_client.act`)
- State machine-based router CLI client for modern platforms
- Platform-agnostic interface supporting Juniper cRPD and Cisco IOS XRd
- Transaction management with commit/rollback support
- Generic string command execution
- Built on SSH client library

### Router Driver System (`src/drivers.act`)
- **Formal State Machine Architecture**: Implements a complete state machine for router device interactions
- **Multi-Platform Support**: Base driver with Juniper JUNOS and Cisco IOS XR implementations
- **State-Based Validation**: Prevents invalid operations and ensures proper command sequencing
- **Enhanced Error Handling**: Centralized error management with automatic cleanup and recovery

**Driver State Machine**:
```
INITIALIZING → READY → EXECUTING_COMMAND → READY
                ↓                    ↓
         ENTERING_CONFIG → CONFIG_MODE → APPLYING_CONFIG → TRANSACTION_ACTIVE
                  ↓              ↓                              ↓       ↓
              ROLLING_BACK  ABORTING_CONFIG              COMMITTING  ABORTING_CONFIG
                  ↓              ↓                              ↓       ↓
                 READY ←← READY ←←                           READY ←← READY
                                                              ↓
                                                           ERROR → READY/DISCONNECTED
```

**Driver States**:
- `INITIALIZING`: Driver startup and initialization
- `READY`: Ready for commands or configuration operations
- `EXECUTING_COMMAND`: Processing a single command
- `ENTERING_CONFIG`: Transitioning to configuration mode
- `CONFIG_MODE`: In device configuration mode
- `APPLYING_CONFIG`: Applying configuration commands sequentially
- `TRANSACTION_ACTIVE`: Configuration applied but not committed (can commit or abort)
- `COMMITTING`: Committing configuration changes
- `ABORTING_CONFIG`: Discarding current configuration changes
- `ROLLING_BACK`: Reverting to previous committed configuration
- `ERROR`: Error state with automatic cleanup
- `DISCONNECTED`: SSH connection lost

**Key Features**:
- **State Validation**: Each operation validates current state before execution
- **Transition Logging**: All state changes are logged for debugging
- **Callback Management**: Proper cleanup of pending callbacks on errors
- **Sequential Config**: Configuration commands applied one at a time with prompt validation
- **Transaction Support**: Full transaction management with commit/abort capabilities
- **Rollback Operations**: Support for reverting to previous configurations
- **Platform Abstraction**: Device-specific prompt patterns and command syntax

**Transaction Management**:
- **configure()**: Enter config mode and apply changes → TRANSACTION_ACTIVE state
- **commit_transaction()**: Commit active transaction to device (internal driver method)
- **abort_configuration()**: Discard current uncommitted changes
- **rollback_configuration(commits_back)**: Revert to previous configuration state

**Platform-Specific Commands**:
- **Juniper JUNOS**: `rollback`, `rollback N`, `commit`, `exit`
- **Cisco IOS XR**: `abort`, `rollback configuration last N`, `commit`, `end`

### Usage Examples
- `src/router_example.act`: Router client examples for both Juniper and Cisco platforms
- `src/test_drivers.act`: Comprehensive test suite for driver state machine functionality

## Acton Language Notes

- In Acton, the actor methods must not use `self` as any argument, nor actor init argument
- You cannot use "is not None" on attributes, functions or methods. First create a local variable.
    - **Exception**: Actor attributes can be used directly in conditionals (e.g., `if _driver is not None:`) - avoid unnecessary local variable assignments like `driver = _driver`
- Use `dict.get_def(key, default)` for getting a value from dict with default

## Notes for refactoring

- **No backward compatibility required** - this is a new project, complete redesigns are acceptable
- Each simplification should be done incrementally with testing
- Buffer class changes have highest impact but require careful testing
- All changes should maintain core functionality and test coverage
- Focus on simplicity and maintainability over preserving existing APIs
- Before writing code, prepare a detailed plan for changes