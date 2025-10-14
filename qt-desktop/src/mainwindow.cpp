#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QMessageBox>
#include <QCloseEvent>
#include <QDesktopServices>
#include <QUrl>
#include <QStandardPaths>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
    , m_webView(nullptr)
    , m_serviceManager(nullptr)
    , m_trayIcon(nullptr)
    , m_trayMenu(nullptr)
    , m_servicesReady(false)
    , m_minimizeToTray(true)
{
    setupUi();
    setupTrayIcon();
    setupWebEngine();
    setupConnections();

    // 启动服务
    showLoadingScreen("正在启动服务，请稍候...");
    m_serviceManager->startAllServices();
}

MainWindow::~MainWindow()
{
    // 停止所有服务
    if (m_serviceManager) {
        m_serviceManager->stopAllServices();
    }

    delete ui;
}

void MainWindow::setupUi()
{
    ui->setupUi(this);

    setWindowTitle("VAR熔池分析系统");
    resize(1280, 800);

    // 创建服务管理器
    m_serviceManager = new ServiceManager(this);
}

void MainWindow::setupTrayIcon()
{
    // 创建托盘图标
    m_trayIcon = new QSystemTrayIcon(this);
    m_trayIcon->setIcon(QIcon(":/icons/app-icon.png"));
    m_trayIcon->setToolTip("VAR熔池分析系统");

    // 创建托盘菜单
    m_trayMenu = new QMenu(this);
    m_trayMenu->addAction("显示主窗口", this, &MainWindow::showNormal);
    m_trayMenu->addAction("打开数据目录", this, &MainWindow::openDataDirectory);
    m_trayMenu->addSeparator();
    m_trayMenu->addAction("重启服务", this, &MainWindow::restartServices);
    m_trayMenu->addAction("设置", this, &MainWindow::showSettingsDialog);
    m_trayMenu->addAction("关于", this, &MainWindow::showAboutDialog);
    m_trayMenu->addSeparator();
    m_trayMenu->addAction("退出", this, &MainWindow::quitApplication);

    m_trayIcon->setContextMenu(m_trayMenu);
    m_trayIcon->show();
}

void MainWindow::setupWebEngine()
{
    // 创建WebEngineView
    m_webView = new QWebEngineView(this);
    setCentralWidget(m_webView);

    // 设置初始页面
    m_webView->setUrl(QUrl("about:blank"));
}

void MainWindow::setupConnections()
{
    // 连接服务管理器信号
    connect(m_serviceManager, &ServiceManager::backendStatusChanged,
            this, &MainWindow::onBackendStatusChanged);
    connect(m_serviceManager, &ServiceManager::aiProcessorStatusChanged,
            this, &MainWindow::onAiProcessorStatusChanged);
    connect(m_serviceManager, &ServiceManager::allServicesReady,
            this, &MainWindow::onAllServicesReady);

    // 连接托盘图标信号
    connect(m_trayIcon, &QSystemTrayIcon::activated,
            this, &MainWindow::onTrayIconActivated);
}

void MainWindow::closeEvent(QCloseEvent *event)
{
    if (m_minimizeToTray && m_trayIcon->isVisible()) {
        hide();
        m_trayIcon->showMessage("VAR熔池分析系统",
                                "应用已最小化到托盘，服务继续运行",
                                QSystemTrayIcon::Information,
                                2000);
        event->ignore();
    } else {
        event->accept();
    }
}

// ========== 槽函数实现 ==========

void MainWindow::onBackendStatusChanged(ServiceManager::ServiceStatus status, const QString &message)
{
    QString statusText = QString("后端服务: %1").arg(message);
    updateStatusBar(statusText);

    if (status == ServiceManager::ServiceStatus::Failed) {
        QMessageBox::critical(this, "服务错误",
                            "后端服务启动失败，请检查配置或查看日志");
    }
}

void MainWindow::onAiProcessorStatusChanged(ServiceManager::ServiceStatus status, const QString &message)
{
    QString statusText = QString("AI引擎: %1").arg(message);
    updateStatusBar(statusText);

    if (status == ServiceManager::ServiceStatus::Failed) {
        QMessageBox::warning(this, "服务警告",
                           "AI处理引擎启动失败，视频分析功能将不可用");
    }
}

void MainWindow::onAllServicesReady()
{
    m_servicesReady = true;
    hideLoadingScreen();

    // 加载Web UI
    QString backendUrl = QString("http://localhost:%1")
                            .arg(m_serviceManager->getBackendPort());
    m_webView->setUrl(QUrl(backendUrl));

    updateStatusBar("所有服务已就绪");

    m_trayIcon->showMessage("VAR熔池分析系统",
                           "所有服务已启动，可以开始使用",
                           QSystemTrayIcon::Information,
                           2000);
}

void MainWindow::onTrayIconActivated(QSystemTrayIcon::ActivationReason reason)
{
    if (reason == QSystemTrayIcon::DoubleClick) {
        showNormal();
        activateWindow();
    }
}

void MainWindow::showAboutDialog()
{
    QString aboutText = QString(
        "<h3>VAR熔池分析系统</h3>"
        "<p>版本: 1.0.0</p>"
        "<p>基于深度学习的焊接熔池视频智能分析系统</p>"
        "<p>&copy; 2025 USTB. All rights reserved.</p>"
        "<p><a href='https://github.com/jjhhyyg/var-v2'>项目主页</a></p>"
    );

    QMessageBox::about(this, "关于", aboutText);
}

void MainWindow::showSettingsDialog()
{
    // TODO: 实现设置对话框
    QMessageBox::information(this, "设置", "设置功能开发中...");
}

void MainWindow::openDataDirectory()
{
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDesktopServices::openUrl(QUrl::fromLocalFile(dataPath));
}

void MainWindow::restartServices()
{
    QMessageBox::StandardButton reply = QMessageBox::question(
        this, "重启服务",
        "确定要重启所有服务吗？当前任务可能会中断。",
        QMessageBox::Yes | QMessageBox::No
    );

    if (reply == QMessageBox::Yes) {
        showLoadingScreen("正在重启服务...");
        m_servicesReady = false;
        m_serviceManager->stopAllServices();
        QTimer::singleShot(2000, m_serviceManager, &ServiceManager::startAllServices);
    }
}

void MainWindow::quitApplication()
{
    m_minimizeToTray = false;
    close();
    qApp->quit();
}

// ========== UI辅助函数 ==========

void MainWindow::updateStatusBar(const QString &message)
{
    ui->statusbar->showMessage(message, 5000);
}

void MainWindow::showLoadingScreen(const QString &message)
{
    // TODO: 实现加载遮罩
    updateStatusBar(message);
}

void MainWindow::hideLoadingScreen()
{
    // TODO: 隐藏加载遮罩
    updateStatusBar("就绪");
}
