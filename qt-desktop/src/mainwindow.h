#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QWebEngineView>
#include <QSystemTrayIcon>
#include <QMenu>
#include "servicemanager.h"

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

/**
 * @brief 主窗口类
 *
 * 职责：
 * 1. 管理应用UI界面（嵌入WebEngineView）
 * 2. 管理后端服务生命周期
 * 3. 处理用户交互
 * 4. 系统托盘管理
 */
class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

protected:
    // 重写关闭事件，支持最小化到托盘
    void closeEvent(QCloseEvent *event) override;

private slots:
    // 服务状态变化槽函数
    void onBackendStatusChanged(ServiceManager::ServiceStatus status, const QString &message);
    void onAiProcessorStatusChanged(ServiceManager::ServiceStatus status, const QString &message);
    void onAllServicesReady();

    // UI交互槽函数
    void onTrayIconActivated(QSystemTrayIcon::ActivationReason reason);
    void showAboutDialog();
    void showSettingsDialog();
    void openDataDirectory();
    void restartServices();
    void quitApplication();

private:
    // 初始化函数
    void setupUi();
    void setupTrayIcon();
    void setupWebEngine();
    void setupConnections();

    // UI更新函数
    void updateStatusBar(const QString &message);
    void showLoadingScreen(const QString &message);
    void hideLoadingScreen();

private:
    Ui::MainWindow *ui;
    QWebEngineView *m_webView;           // Web视图
    ServiceManager *m_serviceManager;     // 服务管理器
    QSystemTrayIcon *m_trayIcon;         // 系统托盘图标
    QMenu *m_trayMenu;                   // 托盘菜单

    // 状态标志
    bool m_servicesReady;
    bool m_minimizeToTray;
};

#endif // MAINWINDOW_H
