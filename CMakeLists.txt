# Builds the cross-platform Qt version (hello_qt.cpp). The Win32 version uses the Makefile.
cmake_minimum_required(VERSION 3.16)
project(hello_qt LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Use Qt 6 if it is installed, otherwise Qt 5.
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Widgets)

# The version: the newest release tag at or before this commit, as git describe gives it when CMake
# configures the build. 0.5.0 on the commit tagged v0.5.0, 0.5.0-3-g<commit> three commits later, and
# 0.0.0 without git or such a tag.
set(version 0.0.0)
set(release 0.0.0) # the tag's three numbers
set(commits 0)     # the commits since the tag
find_package(Git QUIET)
if(GIT_FOUND)
    execute_process(COMMAND "${GIT_EXECUTABLE}" describe --tags --match "v[0-9]*.[0-9]*.[0-9]*"
                    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                    OUTPUT_VARIABLE describe OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
endif()
if(describe MATCHES "^v([0-9]+\\.[0-9]+\\.[0-9]+)(-([0-9]+)-g[0-9a-f]+)?$")
    set(release ${CMAKE_MATCH_1})
    if(CMAKE_MATCH_3)
        set(commits ${CMAKE_MATCH_3})
    endif()
    string(SUBSTRING "${describe}" 1 -1 version)
else()
    message(WARNING "git describe found no release tag (vX.Y.Z), so the version is 0.0.0")
endif()
message(STATUS "hello_qt version ${version}")

# WIN32 and MACOSX_BUNDLE make it a GUI app: no console window on Windows, an .app on macOS and iOS.
# On macOS and iOS, Qt's own qt_add_executable also writes the app's Info.plist (and on iOS its launch
# screen), with the properties set below. On Android it builds the app as a library, which Qt's Java code
# loads, and adds the target apk, which packs both into an APK. For WebAssembly (Emscripten) it builds
# hello_qt.js and hello_qt.wasm and puts a web page for them beside them: hello_qt.html and Qt's
# qtloader.js, which starts the app.
if((APPLE OR ANDROID OR EMSCRIPTEN) AND QT_VERSION_MAJOR GREATER_EQUAL 6)
    qt_add_executable(hello_qt MACOSX_BUNDLE hello_qt.cpp)
else()
    add_executable(hello_qt WIN32 MACOSX_BUNDLE hello_qt.cpp)
endif()
target_link_libraries(hello_qt PRIVATE Qt${QT_VERSION_MAJOR}::Widgets)

if(APPLE)
    # One identifier for the macOS and iPhone apps. Apple's versions are only numbers, so a build after a
    # release has that release's version.
    set_target_properties(hello_qt PROPERTIES
        MACOSX_BUNDLE_GUI_IDENTIFIER io.github.ariamokr.iphonehello
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${release}
        MACOSX_BUNDLE_BUNDLE_VERSION ${release})
elseif(WIN32)
    # The version resource, as for hello.exe (version.rc)
    string(REPLACE "." "," numbers "${release}")
    target_sources(hello_qt PRIVATE version.rc)
    set_source_files_properties(version.rc PROPERTIES COMPILE_DEFINITIONS
        "NAME=hello_qt;VERSION=${version};VERSION_NUMBERS=${numbers},${commits}")
elseif(ANDROID)
    # The identifier of the Apple apps. Android's version code is a number that has to grow from one
    # version to the next: the four numbers in one, 500003 for 0.5.0 three commits later (and at least 1).
    # The app is built for Android 16 (API level 36), the newest Android that Qt 6.12 supports, rather
    # than for the newest SDK platform installed.
    string(REPLACE "." ";" numbers "${release}")
    list(GET numbers 0 major)
    list(GET numbers 1 minor)
    list(GET numbers 2 patch)
    math(EXPR code "((${major} * 100 + ${minor}) * 100 + ${patch}) * 1000 + ${commits}")
    if(code LESS 1)
        set(code 1)
    endif()
    set_target_properties(hello_qt PROPERTIES
        QT_ANDROID_PACKAGE_NAME io.github.ariamokr.iphonehello
        QT_ANDROID_VERSION_NAME ${version}
        QT_ANDROID_VERSION_CODE ${code}
        QT_ANDROID_COMPILE_SDK_VERSION 36
        QT_ANDROID_TARGET_SDK_VERSION 36)
endif()
