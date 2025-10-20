# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

- **Build project**: `acton build`
- **Run tests**: `acton test`

## Testing

### Running Tests
- **Run all tests**: `acton test`
- **Run all tests from a module**: `acton test --module <module_name>`
  - Example: `acton test --module test_drivers`
- **Run specific test**: `acton test --name <test_name>` (use function name WITHOUT `_test_` prefix)
  - Example: For function `_test_driver_state_transition_validation`, run: `acton test --name driver_state_transition_validation`
- **Update golden files**: `acton test --name <test_name> --golden-update`
  - Updates expected output when test behavior changes intentionally
  - Note: The test will show as "FAIL" once while updating the golden file - this is expected behavior
- **Golden files location**: `test/golden/<module_name>/<test_name>`

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
- **Multi-Platform Support**: Base driver with Juniper JUNOS, Cisco IOS XR, and Cisco IOS XE implementations
- **State-Based Validation**: Prevents invalid operations and ensures proper command sequencing
- **Enhanced Error Handling**: Centralized error management with automatic cleanup and recovery

**Driver State Machine**:
```
State transitions:

INITIALIZING ──→ READY
                  │
                  ├──→ EXECUTING_COMMAND ──→ READY
                  │
                  ├──→ ENTERING_CONFIG ──→ CONFIG_MODE ──┬──→ APPLYING_CONFIG ──→ COMMITTING ──┬──→ READY
                  │                                      │                                      │
                  │                                      └──→ READY (exit)                      └──→ ABORTING_CONFIG ──→ READY
                  │                                                                                   (on failure)
                  └──→ ROLLING_BACK ──→ READY

Special transitions (from any state):
- Any state ──→ ERROR ──→ READY (recovery)
- Any state ──→ DISCONNECTED ──→ INITIALIZING (reconnect)

Valid state transitions:
- INITIALIZING: → READY, ERROR, DISCONNECTED
- READY: → EXECUTING_COMMAND, ENTERING_CONFIG, ROLLING_BACK, ERROR, DISCONNECTED
- EXECUTING_COMMAND: → READY, ERROR, DISCONNECTED
- ENTERING_CONFIG: → CONFIG_MODE, ERROR, DISCONNECTED
- CONFIG_MODE: → APPLYING_CONFIG, ABORTING_CONFIG, READY, ERROR, DISCONNECTED
- APPLYING_CONFIG: → COMMITTING, ERROR, DISCONNECTED
- COMMITTING: → READY, ABORTING_CONFIG, ERROR, DISCONNECTED
- ABORTING_CONFIG: → READY, ERROR, DISCONNECTED
- ROLLING_BACK: → READY, ERROR, DISCONNECTED
- ERROR: → READY, DISCONNECTED
- DISCONNECTED: → INITIALIZING
```

**Driver States**:
- `INITIALIZING`: Driver startup and initialization
- `READY`: Ready for commands or configuration operations
- `EXECUTING_COMMAND`: Processing a single command
- `ENTERING_CONFIG`: Transitioning to configuration mode
- `CONFIG_MODE`: In device configuration mode, ready to apply configuration
- `APPLYING_CONFIG`: Applying configuration commands sequentially
- `COMMITTING`: Committing/saving configuration changes (platform-specific)
- `ABORTING_CONFIG`: Rolling back after commit failure (automatic)
- `ROLLING_BACK`: Explicit rollback to previous configuration (user-requested)
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

**Key Operations**:
- **execute_command(command)**: Execute a single operational command
- **configure_and_commit(config_list)**: Apply configuration atomically with automatic rollback on failure
- **rollback_configuration(commits_back)**: Revert to a previous configuration state

**Platform-Specific Commands**:
- **Juniper JUNOS**: `rollback`, `rollback N`, `commit`, `exit`
- **Cisco IOS XR**: `abort`, `rollback configuration last N`, `commit`, `end`
- **Cisco IOS XE**: `archive config` (checkpoint), `configure replace` (rollback), `write memory` (save)

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
