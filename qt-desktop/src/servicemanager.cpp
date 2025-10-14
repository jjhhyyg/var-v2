#include "servicemanager.h"
#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>

ServiceManager::ServiceManager(QObject *parent)
    : QObject(parent)
    , m_backendProcess(nullptr)
    , m_backendStatus(ServiceStatus::Stopped)
    , m_backendHealthTimer(nullptr)
    , m_backendPort(8080)
    , m_aiProcessorProcess(nullptr)
    , m_aiProcessorStatus(ServiceStatus::Stopped)
    , m_aiProcessorHealthTimer(nullptr)
    , m_aiProcessorPort(5000)
    , m_networkManager(nullptr)
    , m_autoRestart(true)
    , m_healthCheckInterval(5000)
    , m_startupTimeout(30000)
{
    loadConfiguration();
    setupHealthChecks();

    // 创建进程对象
    m_backendProcess = new QProcess(this);
    m_aiProcessorProcess = new QProcess(this);

    // 连接后端服务信号
    connect(m_backendProcess, &QProcess::readyReadStandardOutput,
            this, &ServiceManager::onBackendOutput);
    connect(m_backendProcess, &QProcess::readyReadStandardError,
            this, &ServiceManager::onBackendError);
    connect(m_backendProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ServiceManager::onBackendFinished);

    // 连接AI服务信号
    connect(m_aiProcessorProcess, &QProcess::readyReadStandardOutput,
            this, &ServiceManager::onAiProcessorOutput);
    connect(m_aiProcessorProcess, &QProcess::readyReadStandardError,
            this, &ServiceManager::onAiProcessorError);
    connect(m_aiProcessorProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ServiceManager::onAiProcessorFinished);

    // 网络管理器
    m_networkManager = new QNetworkAccessManager(this);
    connect(m_networkManager, &QNetworkAccessManager::finished,
            this, &ServiceManager::onHealthCheckFinished);
}

ServiceManager::~ServiceManager()
{
    stopAllServices();
}

void ServiceManager::loadConfiguration()
{
    // 获取应用程序路径
    QString appPath = QCoreApplication::applicationDirPath();

    // 设置服务可执行文件路径
#ifdef Q_OS_WIN
    m_backendExecutable = QDir(appPath).filePath("backend/backend.exe");
    m_aiProcessorExecutable = QDir(appPath).filePath("ai-processor/ai-processor.exe");
#elif defined(Q_OS_MACOS)
    m_backendExecutable = QDir(appPath).filePath("../Resources/backend/backend");
    m_aiProcessorExecutable = QDir(appPath).filePath("../Resources/ai-processor/ai-processor");
#else
    m_backendExecutable = QDir(appPath).filePath("backend/backend");
    m_aiProcessorExecutable = QDir(appPath).filePath("ai-processor/ai-processor");
#endif

    qDebug() << "Backend executable:" << m_backendExecutable;
    qDebug() << "AI Processor executable:" << m_aiProcessorExecutable;

    // TODO: 从配置文件读取端口等配置
}

void ServiceManager::setupHealthChecks()
{
    // 后端健康检查定时器
    m_backendHealthTimer = new QTimer(this);
    m_backendHealthTimer->setInterval(m_healthCheckInterval);
    connect(m_backendHealthTimer, &QTimer::timeout,
            this, &ServiceManager::checkBackendHealth);

    // AI引擎健康检查定时器
    m_aiProcessorHealthTimer = new QTimer(this);
    m_aiProcessorHealthTimer->setInterval(m_healthCheckInterval);
    connect(m_aiProcessorHealthTimer, &QTimer::timeout,
            this, &ServiceManager::checkAiProcessorHealth);
}

// ========== 服务控制 ==========

void ServiceManager::startAllServices()
{
    qDebug() << "Starting all services...";

    // 启动后端服务
    if (startBackendService()) {
        updateBackendStatus(ServiceStatus::Starting, "正在启动后端服务...");
    } else {
        updateBackendStatus(ServiceStatus::Failed, "后端服务启动失败");
    }

    // 启动AI处理服务
    if (startAiProcessorService()) {
        updateAiProcessorStatus(ServiceStatus::Starting, "正在启动AI处理引擎...");
    } else {
        updateAiProcessorStatus(ServiceStatus::Failed, "AI处理引擎启动失败");
    }
}

void ServiceManager::stopAllServices()
{
    qDebug() << "Stopping all services...";

    // 停止健康检查
    m_backendHealthTimer->stop();
    m_aiProcessorHealthTimer->stop();

    // 停止服务
    stopBackendService();
    stopAiProcessorService();
}

void ServiceManager::restartService(const QString &serviceName)
{
    qDebug() << "Restarting service:" << serviceName;

    if (serviceName == "backend") {
        stopBackendService();
        QTimer::singleShot(2000, this, [this]() {
            startBackendService();
        });
    } else if (serviceName == "ai-processor") {
        stopAiProcessorService();
        QTimer::singleShot(2000, this, [this]() {
            startAiProcessorService();
        });
    }
}

bool ServiceManager::isAllServicesRunning() const
{
    return m_backendStatus == ServiceStatus::Running &&
           m_aiProcessorStatus == ServiceStatus::Running;
}

// ========== 后端服务管理 ==========

bool ServiceManager::startBackendService()
{
    if (m_backendProcess->state() != QProcess::NotRunning) {
        qWarning() << "Backend service is already running";
        return false;
    }

    // 检查可执行文件是否存在
    if (!QFile::exists(m_backendExecutable)) {
        qCritical() << "Backend executable not found:" << m_backendExecutable;
        return false;
    }

    // 设置工作目录
    QString workingDir = QFileInfo(m_backendExecutable).absolutePath();
    m_backendProcess->setWorkingDirectory(workingDir);

    // 启动进程
    m_backendProcess->start(m_backendExecutable, QStringList());

    if (!m_backendProcess->waitForStarted(5000)) {
        qCritical() << "Failed to start backend service:" << m_backendProcess->errorString();
        return false;
    }

    qDebug() << "Backend service started, PID:" << m_backendProcess->processId();

    // 启动健康检查
    QTimer::singleShot(5000, this, &ServiceManager::checkBackendHealth);

    return true;
}

void ServiceManager::stopBackendService()
{
    if (m_backendProcess->state() != QProcess::NotRunning) {
        qDebug() << "Stopping backend service...";
        m_backendProcess->terminate();

        if (!m_backendProcess->waitForFinished(5000)) {
            qWarning() << "Backend service did not terminate gracefully, killing...";
            m_backendProcess->kill();
            m_backendProcess->waitForFinished();
        }

        updateBackendStatus(ServiceStatus::Stopped, "后端服务已停止");
    }
}

void ServiceManager::onBackendOutput()
{
    QByteArray output = m_backendProcess->readAllStandardOutput();
    qDebug() << "[Backend]" << output.trimmed();
}

void ServiceManager::onBackendError()
{
    QByteArray error = m_backendProcess->readAllStandardError();
    qWarning() << "[Backend Error]" << error.trimmed();
}

void ServiceManager::onBackendFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    qDebug() << "Backend service finished with exit code:" << exitCode;

    if (exitStatus == QProcess::CrashExit) {
        updateBackendStatus(ServiceStatus::Crashed, "后端服务崩溃");

        if (m_autoRestart) {
            qDebug() << "Auto-restarting backend service...";
            QTimer::singleShot(3000, this, [this]() {
                startBackendService();
            });
        }
    } else {
        updateBackendStatus(ServiceStatus::Stopped, "后端服务已退出");
    }
}

void ServiceManager::checkBackendHealth()
{
    QString healthUrl = QString("http://localhost:%1/actuator/health").arg(m_backendPort);
    QNetworkRequest request(healthUrl);
    request.setAttribute(QNetworkRequest::User, "backend");

    m_networkManager->get(request);
}

// ========== AI处理服务管理 ==========

bool ServiceManager::startAiProcessorService()
{
    if (m_aiProcessorProcess->state() != QProcess::NotRunning) {
        qWarning() << "AI processor service is already running";
        return false;
    }

    // 检查可执行文件是否存在
    if (!QFile::exists(m_aiProcessorExecutable)) {
        qCritical() << "AI processor executable not found:" << m_aiProcessorExecutable;
        return false;
    }

    // 设置工作目录
    QString workingDir = QFileInfo(m_aiProcessorExecutable).absolutePath();
    m_aiProcessorProcess->setWorkingDirectory(workingDir);

    // 启动进程
    m_aiProcessorProcess->start(m_aiProcessorExecutable, QStringList());

    if (!m_aiProcessorProcess->waitForStarted(5000)) {
        qCritical() << "Failed to start AI processor service:" << m_aiProcessorProcess->errorString();
        return false;
    }

    qDebug() << "AI processor service started, PID:" << m_aiProcessorProcess->processId();

    // 启动健康检查
    QTimer::singleShot(10000, this, &ServiceManager::checkAiProcessorHealth);

    return true;
}

void ServiceManager::stopAiProcessorService()
{
    if (m_aiProcessorProcess->state() != QProcess::NotRunning) {
        qDebug() << "Stopping AI processor service...";
        m_aiProcessorProcess->terminate();

        if (!m_aiProcessorProcess->waitForFinished(5000)) {
            qWarning() << "AI processor service did not terminate gracefully, killing...";
            m_aiProcessorProcess->kill();
            m_aiProcessorProcess->waitForFinished();
        }

        updateAiProcessorStatus(ServiceStatus::Stopped, "AI处理引擎已停止");
    }
}

void ServiceManager::onAiProcessorOutput()
{
    QByteArray output = m_aiProcessorProcess->readAllStandardOutput();
    qDebug() << "[AI Processor]" << output.trimmed();
}

void ServiceManager::onAiProcessorError()
{
    QByteArray error = m_aiProcessorProcess->readAllStandardError();
    qWarning() << "[AI Processor Error]" << error.trimmed();
}

void ServiceManager::onAiProcessorFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    qDebug() << "AI processor service finished with exit code:" << exitCode;

    if (exitStatus == QProcess::CrashExit) {
        updateAiProcessorStatus(ServiceStatus::Crashed, "AI处理引擎崩溃");

        if (m_autoRestart) {
            qDebug() << "Auto-restarting AI processor service...";
            QTimer::singleShot(3000, this, [this]() {
                startAiProcessorService();
            });
        }
    } else {
        updateAiProcessorStatus(ServiceStatus::Stopped, "AI处理引擎已退出");
    }
}

void ServiceManager::checkAiProcessorHealth()
{
    QString healthUrl = QString("http://localhost:%1/health").arg(m_aiProcessorPort);
    QNetworkRequest request(healthUrl);
    request.setAttribute(QNetworkRequest::User, "ai-processor");

    m_networkManager->get(request);
}

// ========== 健康检查 ==========

void ServiceManager::onHealthCheckFinished(QNetworkReply *reply)
{
    QString serviceName = reply->request().attribute(QNetworkRequest::User).toString();

    if (reply->error() == QNetworkReply::NoError) {
        // 健康检查成功
        if (serviceName == "backend") {
            if (m_backendStatus != ServiceStatus::Running) {
                updateBackendStatus(ServiceStatus::Running, "后端服务运行正常");
                m_backendHealthTimer->start();
                checkAllServicesReady();
            }
        } else if (serviceName == "ai-processor") {
            if (m_aiProcessorStatus != ServiceStatus::Running) {
                updateAiProcessorStatus(ServiceStatus::Running, "AI处理引擎运行正常");
                m_aiProcessorHealthTimer->start();
                checkAllServicesReady();
            }
        }
    } else {
        // 健康检查失败，继续等待
        qDebug() << serviceName << "health check failed, retrying...";

        if (serviceName == "backend" && m_backendStatus == ServiceStatus::Starting) {
            QTimer::singleShot(2000, this, &ServiceManager::checkBackendHealth);
        } else if (serviceName == "ai-processor" && m_aiProcessorStatus == ServiceStatus::Starting) {
            QTimer::singleShot(2000, this, &ServiceManager::checkAiProcessorHealth);
        }
    }

    reply->deleteLater();
}

// ========== 状态更新 ==========

void ServiceManager::updateBackendStatus(ServiceStatus status, const QString &message)
{
    m_backendStatus = status;
    emit backendStatusChanged(status, message);
    qDebug() << "Backend status:" << message;
}

void ServiceManager::updateAiProcessorStatus(ServiceStatus status, const QString &message)
{
    m_aiProcessorStatus = status;
    emit aiProcessorStatusChanged(status, message);
    qDebug() << "AI Processor status:" << message;
}

void ServiceManager::checkAllServicesReady()
{
    if (isAllServicesRunning()) {
        qDebug() << "All services are ready!";
        emit allServicesReady();
    }
}
