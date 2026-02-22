# 🐳 Docker Android

A minimalist setup to run a containerized Android emulator, accessible via `scrcpy` for high-performance screen mirroring.

## ✅ Prerequisites

-   **Windows:** Docker Desktop
-   **Linux:** A native installation of Docker Engine.

## ⚡ Quick Start

1.  **Clone the repository.**

2.  **Configure the emulator.**
    You can customize the Android device by editing parameters in `docker-compose.yml`.

    **Build Arguments (`args`):**
    -   `API_LEVEL`
    -   `CMD_LINE_VERSION`
    -   `IMG_TYPE`
    -   `ARCHITECTURE`
    -   `DEVICE_ID`

    **Environment Variables (`environment`):**
    -   `MEMORY`
    -   `CORES`
    -   `WIDTH`
    -   `HEIGHT`
    -   `DENSITY`
    -   `DISABLE_ANIMATION`
    -   `DISABLE_HIDDEN_POLICY`

3.  **Run the setup script.**
    This will handle everything from downloading dependencies to launching the emulator and screen mirror client.

    -   **For Linux:**
        ```sh
        ./start-android.sh
        ```

    -   **For Windows:**
        ```bat
        .\start-android.bat
        ```

## 🤝 Credits

This project is heavily inspired by and builds upon the excellent work from the [budtmo/docker-android](https://github.com/HQarroum/docker-android) repository.

## 📝 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
