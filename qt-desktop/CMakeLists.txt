cmake_minimum_required(VERSION 3.16)
project(VAR-PoolAnalysis VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# 查找Qt6包
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Widgets
    Network
    WebEngineWidgets
    WebChannel
)

# 项目源文件
set(PROJECT_SOURCES
    src/main.cpp
    src/mainwindow.cpp
    src/mainwindow.h
    src/mainwindow.ui
    src/servicemanager.cpp
    src/servicemanager.h
)

# 资源文件
set(PROJECT_RESOURCES
    resources/resources.qrc
)

# 创建可执行文件
if(WIN32)
    add_executable(${PROJECT_NAME} WIN32
        ${PROJECT_SOURCES}
        ${PROJECT_RESOURCES}
    )
elseif(APPLE)
    add_executable(${PROJECT_NAME} MACOSX_BUNDLE
        ${PROJECT_SOURCES}
        ${PROJECT_RESOURCES}
    )
else()
    add_executable(${PROJECT_NAME}
        ${PROJECT_SOURCES}
        ${PROJECT_RESOURCES}
    )
endif()

# 链接Qt库
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Widgets
    Qt6::Network
    Qt6::WebEngineWidgets
    Qt6::WebChannel
)

# 设置输出目录
set_target_properties(${PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

# 安装配置
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

# macOS特殊配置
if(APPLE)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/installer/Info.plist.in"
        MACOSX_BUNDLE_BUNDLE_NAME "VAR熔池分析系统"
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.ustb.var-pool-analysis"
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
    )
endif()

# Windows特殊配置
if(WIN32)
    # 添加应用图标
    target_sources(${PROJECT_NAME} PRIVATE resources/app.rc)
endif()
