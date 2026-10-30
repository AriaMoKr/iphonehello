# Builds the cross-platform Qt version (hello_qt.cpp). The Win32 version uses the Makefile.
cmake_minimum_required(VERSION 3.16)
project(hello_qt LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Use Qt 6 if it is installed, otherwise Qt 5.
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Widgets)

# WIN32 and MACOSX_BUNDLE make it a GUI app: no console window on Windows, an .app on macOS.
add_executable(hello_qt WIN32 MACOSX_BUNDLE hello_qt.cpp)
target_link_libraries(hello_qt PRIVATE Qt${QT_VERSION_MAJOR}::Widgets)
