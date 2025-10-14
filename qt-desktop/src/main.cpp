#include "mainwindow.h"
#include <QApplication>
#include <QStyleFactory>
#include <QScreen>

int main(int argc, char *argv[])
{
    // 启用高DPI支持
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

    QApplication app(argc, argv);

    // 设置应用信息
    app.setApplicationName("VAR熔池分析系统");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("USTB");
    app.setOrganizationDomain("ustb.edu.cn");

    // 设置应用样式（可选：使用Fusion风格，跨平台一致）
    app.setStyle(QStyleFactory::create("Fusion"));

    // 创建并显示主窗口
    MainWindow window;

    // 居中显示
    QScreen *screen = QGuiApplication::primaryScreen();
    QRect screenGeometry = screen->geometry();
    int x = (screenGeometry.width() - window.width()) / 2;
    int y = (screenGeometry.height() - window.height()) / 2;
    window.move(x, y);

    window.show();

    return app.exec();
}
