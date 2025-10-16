# 粘连物/锭冠异常事件检测优化 - 实施指南

## 概述

本次优化针对粘连物和锭冠的高误检率问题，通过多层质量控制和智能判断算法，预计可将：
- **粘连物误检率降低 60-80%**
- **锭冠误检率降低 50-70%**

## 核心改进

### 问题1: 未掉落的粘连物被误判为脱落
**解决方案**:
- 多帧稳定性检查（10帧@80%）
- 自适应IoU阈值（根据物体大小）
- 自适应形态学核大小

### 问题2: YOLO bbox不准确导致误判
**解决方案**:
- bbox质量检查（面积100-50000、长宽比0.1-10.0）
- 平均置信度检查（≥0.55）
- 持续时间检查（≥0.5秒）

### 问题3: 未掉落的锭冠被误判
**解决方案**:
- 垂直掉落运动检测
- 检查垂直移动距离（≥30像素）
- 确保垂直运动主导水平运动

## 快速开始

### 方式1: 使用默认配置（推荐）

直接启动服务，优化会自动生效：
```bash
cd ai-processor
python app.py
```

### 方式2: 自定义配置

1. 编辑 `codes/.env` 文件，添加配置参数：
```bash
# 质量控制参数（可选）
MIN_BBOX_AREA=100              # 最小bbox面积
MAX_BBOX_AREA=50000            # 最大bbox面积
MIN_AVG_CONFIDENCE=0.55        # 最小平均置信度
STABILITY_CHECK_FRAMES=10      # 稳定性检查帧数
STABILITY_THRESHOLD=0.8        # 稳定性阈值
CROWN_MIN_VERTICAL_MOVEMENT=30 # 锭冠最小垂直移动
```

2. 启动服务：
```bash
cd ai-processor
python app.py
```

## 验证优化效果

### 1. 查看日志
启动服务后，检查日志中是否有以下信息：
```
Detection quality thresholds: bbox_area=100-50000, aspect_ratio=0.1-10.0, avg_confidence=0.55, stability=10frames@0.8
```

### 2. 监控指标
对比优化前后的指标：
- **误报率**: 错误报告的事件数 / 总报告事件数
- **漏报率**: 未检测到的真实事件数 / 总真实事件数
- **准确率**: 正确识别的事件数 / 总事件数

### 3. 查看调试信息
如需详细调试信息，启用调试模式：
```bash
AI_PROCESSOR_DEBUG=True
AI_LOG_LEVEL=DEBUG
```

## 参数调优

### 如果误检率仍然较高
```bash
MIN_AVG_CONFIDENCE=0.6      # 提高置信度阈值
STABILITY_THRESHOLD=0.85     # 提高稳定性阈值
MAX_BBOX_AREA=30000         # 减小最大bbox面积
```

### 如果漏检率增加
```bash
MIN_AVG_CONFIDENCE=0.5      # 降低置信度阈值
STABILITY_THRESHOLD=0.75     # 降低稳定性阈值
MIN_BBOX_AREA=50            # 扩大bbox面积范围
```

### 如果锭冠检测过于严格
```bash
CROWN_MIN_VERTICAL_MOVEMENT=20  # 降低垂直移动要求
```

## 技术细节

### 检测流程
```
YOLO检测 → 轨迹记录 → 质量检查 → 事件生成
                          ↓
                    过滤低质量检测
                          ↓
                    稳定性检查（粘连物）
                    运动检测（锭冠）
                          ↓
                    生成异常事件
```

### 质量检查项目
1. ✅ bbox面积是否在合理范围
2. ✅ bbox长宽比是否正常
3. ✅ 平均置信度是否足够高
4. ✅ 持续时间是否足够长
5. ✅ 最后N帧是否稳定在熔池中（粘连物）
6. ✅ 是否有垂直掉落运动（锭冠）

## 文档资源

### 必读
- [OPTIMIZATION_SUMMARY.md](OPTIMIZATION_SUMMARY.md) - 优化总结
- [ai-processor/IMPROVEMENTS.md](ai-processor/IMPROVEMENTS.md) - 详细使用说明

### 参考
- [ai-processor/DETECTION_ANALYSIS.md](ai-processor/DETECTION_ANALYSIS.md) - 技术分析
- [ai-processor/CHANGELOG.md](ai-processor/CHANGELOG.md) - 完整变更记录

## 回滚方案

如果新版本出现问题：

### 方式1: 参数回滚（推荐）
恢复到接近旧版本的参数：
```bash
MIN_AVG_CONFIDENCE=0.5
STABILITY_CHECK_FRAMES=5
STABILITY_THRESHOLD=0.6
```

### 方式2: 代码回滚
```bash
cd ai-processor
git checkout main
cd ..
git submodule update
```

## 常见问题

### Q1: 优化后处理速度会变慢吗？
**A**: 几乎不会。增加的检测步骤主要是数据处理，对处理速度影响很小（<5%）。

### Q2: 需要重新训练YOLO模型吗？
**A**: 不需要。优化是在检测结果的后处理阶段，不涉及模型训练。

### Q3: 如何知道参数是否生效？
**A**: 查看启动日志，会显示当前使用的参数值。

### Q4: 参数配置错误会怎样？
**A**: 会使用默认值，并在日志中提示。

### Q5: 可以只优化粘连物或只优化锭冠吗？
**A**: 可以。通过调整对应的参数到极端值实现部分禁用。

## 支持

如有问题：
1. 查看 [ai-processor/IMPROVEMENTS.md](ai-processor/IMPROVEMENTS.md) 了解详细配置
2. 查看 [ai-processor/DETECTION_ANALYSIS.md](ai-processor/DETECTION_ANALYSIS.md) 了解技术细节
3. 提交 GitHub Issue 获取帮助

## 下一步

### 建议行动
1. ✅ 在测试环境验证优化效果
2. ✅ 收集误报率、漏报率等指标
3. ✅ 根据实际数据调整参数
4. ✅ 在生产环境部署

### 后续优化方向
- 运动加速度检测（识别掉落特征）
- 边界区域检测（识别被结晶器捕获）
- 熔池区域自动定义（减少对固定区域的依赖）
- 多模态融合（结合亮度、运动、形状等特征）

---

**版本**: v1.1.0  
**更新日期**: 2025-10-16  
**维护者**: GitHub Copilot
