// A minimal Qt Widgets program: one window that says "Hello, World!".
// Same app as hello.cpp, but it also builds on Linux, macOS, iOS and Android.

#include <QApplication>
#include <QLabel>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QLabel label("Hello, World!");
    label.setAlignment(Qt::AlignCenter);
    label.setWindowTitle("Hello World");
    label.resize(400, 200);
    label.show();

    return app.exec();  // runs until the window is closed
}
