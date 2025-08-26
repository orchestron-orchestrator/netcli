# netcli - NETCONF <> CLI Conversion System
[![REUSE Compliance Check](https://github.com/orchestron-orchestrator/netcli/actions/workflows/reuse-compliance.yml/badge.svg)](https://github.com/orchestron-orchestrator/netcli/actions/workflows/reuse-compliance.yml)

netcli converts CLI configuration to NETCONF XML / RESTCONF JSON and vice versa. This is performed by round-tripping the configuration through virtual devices, like crpd (containerized JUNOS) or XRd (containerized IOS XR).

## Components

This package provides the CLI client libraries needed for the conversion system:

### Core Libraries

- **SSH Client (`src/ssh.act`)** - Generic SSH client actor with multiple authentication methods
- **Router Client (`src/router_client.act`)** - Platform-agnostic router CLI client with transaction support
- **Router Drivers (`src/drivers.act`)** - Formal state machine architecture for device-specific operations

### Supported Platforms

- **Juniper JUNOS** (including containerized cRPD)
- **Cisco IOS XR** (including containerized XRd)

### Key Features

- **State Machine Architecture** - Prevents invalid operations and ensures proper command sequencing
- **Transaction Management** - Full commit/rollback support with automatic cleanup
- **Multi-Platform Support** - Device-agnostic interface with platform-specific implementations  
- **Robust Error Handling** - Centralized error management with automatic recovery
- **Async Operations** - Callback-based interface for non-blocking operations

## Usage

See `src/router_example.act` for comprehensive examples of using the router client libraries with both Juniper and Cisco platforms.
