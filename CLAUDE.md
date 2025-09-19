# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Type

This is a HarmonyOS application project using ArkTS/ETS (Extended TypeScript) and the Hvigor build system.

## Build System

This project uses Hvigor, HarmonyOS's build tool. Build commands must be run through DevEco Studio IDE or the hvigorw wrapper script if available.

Common build operations:
- Build: Use DevEco Studio IDE or `hvigor assembleApp`
- Clean: `hvigor clean`
- Test: Tests are located in `entry/src/ohosTest/` and `entry/src/test/`

## Project Structure

- **entry/**: Main application module
  - `src/main/ets/`: ArkTS source code
    - `entryability/EntryAbility.ets`: Main application entry point
    - `pages/`: UI pages (e.g., Index.ets)
  - `src/main/resources/`: Application resources
  - `src/ohosTest/`: Integration tests
  - `src/test/`: Unit tests

## Key Configuration Files

- `oh-package.json5`: Project dependencies (similar to npm package.json)
- `build-profile.json5`: Build configuration including SDK versions and signing configs
- `entry/src/main/module.json5`: Module configuration defining abilities, pages, and permissions
- `hvigorfile.ts`: Build system configuration

## Development Notes

- Target SDK: HarmonyOS 5.1.1(19)
- Main UI framework: ArkUI with declarative syntax using @Component and @Entry decorators
- Test framework: Uses @ohos/hypium for testing with @ohos/hamock for mocking
- Code style: Follows .clang-format configuration