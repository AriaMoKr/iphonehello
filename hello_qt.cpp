// A minimal Qt Widgets program: one window that says "Hello, World!".
// Same app as hello.cpp, but it also builds on Linux, macOS, iOS and Android, and as a web page.

#include <QApplication>
#include <QIcon>
#include <QLabel>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QLabel label("Hello, World!");
    label.setAlignment(Qt::AlignCenter);
    label.setWindowTitle("Hello World");
    // The icon in the title bar and the taskbar, on Windows and Linux and in the web page (hello_qt.qrc
    // compiles it into the app). macOS, iOS and Android show the app's own icon (CMakeLists.txt).
    label.setWindowIcon(QIcon(":/hello_qt.png"));
    label.resize(400, 200);
    label.show();
    return app.exec();  // runs until the window is closed
}
