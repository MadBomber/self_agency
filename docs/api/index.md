# API Reference

Complete reference for SelfAgency's public API.

## Modules and Classes

- [**SelfAgency Module**](self-agency-module.md) -- The main mixin module with `_()`, `_source_for`, `_save!`, and `on_method_generated`
- [**Configuration**](configuration.md) -- `SelfAgency::Configuration` class and singleton methods (`configure`, `reset!`, `ensure_configured!`)
- [**Errors**](errors.md) -- Error hierarchy: `Error`, `GenerationError`, `ValidationError`, `SecurityError`

## Quick Reference

### Instance Methods (from `include SelfAgency`)

| Method | Returns | Description |
|--------|---------|-------------|
| `_(description, scope:)` | `Array<Symbol>` | Generate and install methods from a description |
| `_source_for(method_name)` | `String` or `nil` | Retrieve source code for a method |
| `_save!(as:, path:)` | `String` | Save generated methods as a subclass file |
| `on_method_generated(name, scope, code)` | - | Lifecycle hook (override in your class) |

### Class Methods (from `extend ClassMethods`)

| Method | Returns | Description |
|--------|---------|-------------|
| `_source_for(method_name)` | `String` or `nil` | Retrieve source code at the class level |

### Module-Level Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `SelfAgency.configure { \|c\| ... }` | `Configuration` | Configure the gem (required) |
| `SelfAgency.configuration` | `Configuration` | Access current configuration |
| `SelfAgency.reset!` | - | Restore defaults |
| `SelfAgency.ensure_configured!` | - | Raise if not configured |
