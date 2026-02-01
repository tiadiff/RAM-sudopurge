# RAM-sudopurge (RAM Monitor)

A lightweight macOS menu bar application designed to monitor RAM usage and provide a quick way to purge inactive memory with administrator privileges.

![Icon](RAMMonitor/RAMMonitor.app/Contents/Resources/RAMMonitor.icns)

## Features

*   **Real-time Monitoring**: Displays the current RAM usage (Active + Wired + Compressed) in the system menu bar.
*   **Auto-Update**: Refreshes memory statistics every 45 seconds.
*   **One-Click Purge**: Includes a menu option to execute `sudo purge` to free up RAM.
*   **Smart Elevation**: The app automatically requests administrator privileges (via password) **only once** upon launch. It then runs as root, allowing you to use the "Purge" function repeatedly without ever entering your password again.
*   **Native & Lightweight**: Built with Swift, no external dependencies.
*   **Emoji Icon**: The application uses a custom 🧹 emoji icon.

## Installation

1.  Clone this repository or download the source.
2.  Navigate to the `RAMMonitor/RAMMonitor.app` folder.
3.  Double-click `RAMMonitor.app` to launch it.
4.  **Note**: The first time you run it, you will be prompted to enter your password to allow the app to run with the necessary privileges for the `purge` command.

## Building from Source

If you prefer to build the application yourself, a build script is provided.

1.  Open a terminal in the project directory.
2.  Run the build script:
    ```bash
    cd RAMMonitor
    ./build.sh
    ```
3.  The `RAMMonitor.app` bundle will be generated in the `RAMMonitor` directory.

## Requirements

*   macOS 12.0 or later (Tested on macOS Monterey).

## License

This project is open source. Feel free to modify and distribute.
