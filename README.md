# LocalCap

LocalCap is an Apple application written in Swift that handles the video recording aspect of running OpenCap locally on an Ubuntu or Windows computer. This app is designed to facilitate seamless video capture for use in biomechanical analysis and other advanced computer vision tasks within the OpenCap framework.

## Features

- **Video Recording:** Captures videos in the resolution and frame rate required by the OpenCap system.

## Planned Features:
- **Intrinsics calculation** The ability to calculate the intrinsics of your device, if it's not currently in OpenCaps supported devices list.
## Installation

To get started with LocalCap, follow these steps:

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/AntonBrinkCodes/LocalCap.git
   cd LocalCap

## Open the Project in Xcode:

- Double-click on the `LocalCap.xcodeproj` file to open the project in Xcode.

## Build the Application:

1. Select your target device or simulator.
2. Press `Cmd + R` to build and run the application.

## Run OpenCap on your Ubuntu/Windows machine:

- Follow the instructions provided in the [opencap-core-local](https://github.com/AntonBrinkCodes/opencap-core-local) repository to set up and run the server locally on your Ubuntu or Windows machine.

## Install and Configure the Web App:

- Follow the instructions in the [localcap-viewer](https://github.com/AntonBrinkCodes/localcap-viewer) repository to set up the web application that controls LocalCap and communicates with the FastAPI WebSocket server used to run OpenCap locally.

## Usage

### Connect with OpenCap:

- Ensure your macOS device running LocalCap is on the same network as your Ubuntu/Windows machine running OpenCap.

### Control Video Recording:

1. Use the [localcap-viewer](https://github.com/AntonBrinkCodes/localcap-viewer) web application to start, stop, and manage video recordings on the LocalCap app.
2. The web app communicates with the FastAPI WebSocket server to synchronize video capture and processing with OpenCap.

### Adjust Settings via the Web App:

- Configure video resolution, frame rate, and other settings directly from the web interface to ensure optimal performance and compatibility with OpenCap.

### Access Recorded Videos:

- Videos are automatically saved and organized in the designated directory for easy retrieval and processing.

## Contribution

Contributions to LocalCap are welcome! If you have any suggestions, bug reports, or would like to add features, please open an issue or submit a pull request. Please ensure your contributions align with the project's coding standards and conventions.

## Acknowledgements

- Special thanks to the OpenCap project for providing the framework for advanced computer vision tasks.
- Thanks to the contributors and users for making this project better with each update.

## Contact

For any questions or support, please reach out via the Issues section on GitHub.

