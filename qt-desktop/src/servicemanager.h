#ifndef SERVICEMANAGER_H
#define SERVICEMANAGER_H

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QNetworkAccessManager>
#include <QNetworkReply>

/**
 * @brief 服务管理器类
 *
 * 职责：
 * 1. 启动和停止后端服务（Spring Boot）
 * 2. 启动和停止AI处理引擎（Python）
 * 3. 监控服务健康状态
 * 4. 处理服务崩溃和自动重启
 */
class ServiceManager : public QObject
{
    Q_OBJECT

public:
    // 服务状态枚举
    enum class ServiceStatus {
        Stopped,        // 已停止
        Starting,       // 启动中
        Running,        // 运行中
        Failed,         // 启动失败
        Crashed         // 崩溃
    };
    Q_ENUM(ServiceStatus)

    explicit ServiceManager(QObject *parent = nullptr);
    ~ServiceManager();

    // 服务控制
    void startAllServices();
    void stopAllServices();
    void restartService(const QString &serviceName);

    // 状态查询
    ServiceStatus getBackendStatus() const { return m_backendStatus; }
    ServiceStatus getAiProcessorStatus() const { return m_aiProcessorStatus; }
    bool isAllServicesRunning() const;

    // 配置获取
    int getBackendPort() const { return m_backendPort; }
    int getAiProcessorPort() const { return m_aiProcessorPort; }

signals:
    // 服务状态变化信号
    void backendStatusChanged(ServiceStatus status, const QString &message);
    void aiProcessorStatusChanged(ServiceStatus status, const QString &message);
    void allServicesReady();
    void serviceError(const QString &serviceName, const QString &error);

private slots:
    // 进程输出处理
    void onBackendOutput();
    void onBackendError();
    void onBackendFinished(int exitCode, QProcess::ExitStatus exitStatus);

    void onAiProcessorOutput();
    void onAiProcessorError();
    void onAiProcessorFinished(int exitCode, QProcess::ExitStatus exitStatus);

    // 健康检查
    void checkBackendHealth();
    void checkAiProcessorHealth();
    void onHealthCheckFinished(QNetworkReply *reply);

private:
    // 初始化函数
    void loadConfiguration();
    void setupHealthChecks();
    QString getExecutablePath(const QString &serviceName);

    // 服务启动函数
    bool startBackendService();
    bool startAiProcessorService();

    // 服务停止函数
    void stopBackendService();
    void stopAiProcessorService();

    // 状态更新函数
    void updateBackendStatus(ServiceStatus status, const QString &message);
    void updateAiProcessorStatus(ServiceStatus status, const QString &message);
    void checkAllServicesReady();

private:
    // 后端服务
    QProcess *m_backendProcess;
    ServiceStatus m_backendStatus;
    QTimer *m_backendHealthTimer;
    int m_backendPort;
    QString m_backendExecutable;

    // AI处理服务
    QProcess *m_aiProcessorProcess;
    ServiceStatus m_aiProcessorStatus;
    QTimer *m_aiProcessorHealthTimer;
    int m_aiProcessorPort;
    QString m_aiProcessorExecutable;

    // 网络管理
    QNetworkAccessManager *m_networkManager;

    // 配置
    QString m_servicePath;          // 服务可执行文件路径
    bool m_autoRestart;             // 自动重启标志
    int m_healthCheckInterval;      // 健康检查间隔（毫秒）
    int m_startupTimeout;           // 启动超时时间（毫秒）
};

#endif // SERVICEMANAGER_H
