# Bug修复总结 - Windows环境中文乱码问题

## 修复日期
2025-10-13

## 问题描述

在Windows环境下部署时，发现两处中文显示乱码的问题：

1. **视频导出中的中文类别名乱码**
   - 现象：导出的结果视频中，检测目标的中文类别名（如"熔池未到边"、"粘连物"等）显示为乱码
   - 位置：`ai-processor/analyzer/video_processor.py`

2. **PDF报告导出中文乱码**
   - 现象：导出的PDF报告中，除了图表的中文正常显示外，其他所有中文内容都是乱码
   - 位置：`frontend/app/composables/useReportGenerator.ts`

## 根本原因分析

### 问题1：视频导出乱码

**原因**：
- OpenCV的`cv2.putText()`不支持中文字符
- 项目使用PIL库的`ImageFont`来绘制中文，但fallback字体`ImageFont.load_default()`不支持中文
- Windows环境下字体路径可能无法正确识别

**相关代码位置**：`ai-processor/analyzer/video_processor.py:26-78`

### 问题2：PDF报告乱码

**原因**：
- jsPDF默认不支持中文字符，使用的是标准PDF字体（如Helvetica）
- 需要手动加载中文TTF字体文件并转换为base64格式
- 必须使用`addFileToVFS`和`addFont`方法注册自定义字体

**相关代码位置**：`frontend/app/composables/useReportGenerator.ts:606-710`

## 解决方案

### 方案1：修复视频导出乱码

**修改文件**：`ai-processor/analyzer/video_processor.py`

**修改内容**：
1. 增强了`cv2_add_chinese_text`函数的字体加载逻辑
2. 添加了更多的字体路径选项（Windows、macOS、Linux）
3. 增加了Windows环境的特殊处理：
   - 直接通过字体名称加载（如`msyh.ttc`、`simhei.ttf`）
   - 添加了详细的错误日志和fallback机制

**关键改进**：
```python
# Windows环境下的额外尝试
if platform.system() == 'Windows':
    try:
        font = ImageFont.truetype("msyh.ttc", font_size)
        logger.info("成功通过字体名称加载 msyh.ttc")
    except:
        try:
            font = ImageFont.truetype("simhei.ttf", font_size)
            logger.info("成功通过字体名称加载 simhei.ttf")
        except:
            logger.warning("无法加载任何中文字体，文本可能无法正常显示")
```

### 方案2：修复PDF报告乱码

**新建文件**：`frontend/app/utils/chineseFont.ts`
- 创建了中文字体加载工具模块
- 提供动态加载字体文件的功能
- 支持从`public/fonts/`目录加载TTF字体并转换为base64

**修改文件**：`frontend/app/composables/useReportGenerator.ts`

**修改内容**：
1. 导入中文字体工具函数
2. 新增`loadChineseFont`函数，用于加载和注册中文字体
3. 在`exportToPDF`函数中调用字体加载逻辑
4. 添加了字体加载失败的fallback机制

**关键改进**：
```typescript
// 加载中文字体
const fontLoaded = await loadChineseFont(pdf)

// 设置字体（如果加载成功则使用中文字体）
if (fontLoaded) {
  pdf.setFont(CHINESE_FONT_CONFIG.fontName, CHINESE_FONT_CONFIG.fontStyle)
}
```

**配置文件**：`frontend/public/fonts/README.md`
- 创建了详细的字体配置说明文档
- 提供了字体下载链接和安装步骤
- 包含字体子集化的最佳实践

## 使用方法

### 视频导出

修复后的代码会自动尝试加载Windows系统字体，无需额外配置。确保系统中存在以下字体之一：
- 微软雅黑（msyh.ttc）
- 黑体（simhei.ttf）
- 宋体（simsun.ttc）

### PDF报告

需要手动配置中文字体：

1. **下载字体文件**
   ```bash
   # 推荐使用思源黑体
   # 下载地址：https://github.com/googlefonts/noto-cjk/releases
   ```

2. **放置字体文件**
   ```
   frontend/public/fonts/NotoSansSC-Regular.ttf
   ```

3. **字体子集化（可选，推荐）**
   ```bash
   pip install fonttools brotli
   pyftsubset NotoSansSC-Regular.ttf \
     --output-file=NotoSansSC-Subset.ttf \
     --unicodes=U+4E00-9FFF,U+3000-303F,U+FF00-FFEF
   ```

详细说明请参考：`frontend/public/fonts/README.md`

## 技术要点

### PIL字体加载机制

1. **绝对路径方式**：`ImageFont.truetype('C:/Windows/Fonts/msyh.ttc', size)`
2. **相对路径/名称方式**：`ImageFont.truetype('msyh.ttc', size)` （Windows会在系统字体目录查找）
3. **Fallback机制**：如果加载失败，使用`ImageFont.load_default()`（不支持中文）

### jsPDF字体加载流程

1. **加载字体文件**：从服务器获取TTF文件
2. **转换为base64**：使用FileReader API转换
3. **添加到VFS**：`pdf.addFileToVFS(filename, base64String)`
4. **注册字体**：`pdf.addFont(filename, fontName, fontStyle)`
5. **设置字体**：`pdf.setFont(fontName, fontStyle)`

### 字体文件大小优化

- 完整中文字体：10-15MB
- 子集化后：2-3MB（包含常用汉字）
- 建议使用字体子集化工具提取项目实际使用的字符

## 测试建议

### 视频导出测试

1. 在Windows环境下运行视频分析任务
2. 导出标注视频
3. 检查视频中的中文标签是否正确显示
4. 查看日志确认字体加载情况

### PDF报告测试

1. 确保字体文件已放置在正确位置
2. 打开任务详情页，点击"导出PDF"
3. 检查PDF中的中文是否正确显示
4. 测试各种中文场景：
   - 任务名称
   - 时间格式
   - 图表标题
   - 数据单位

## 已知限制

1. **PDF字体需要手动配置**：首次部署需要下载并配置字体文件
2. **字体文件较大**：建议进行子集化处理
3. **字体加载失败时**：PDF会使用默认字体（中文显示为空白），但不会报错

## 相关文件清单

### 修改的文件
- `ai-processor/analyzer/video_processor.py`
- `frontend/app/composables/useReportGenerator.ts`

### 新增的文件
- `frontend/app/utils/chineseFont.ts`
- `frontend/public/fonts/README.md`
- `BUGFIX_SUMMARY.md`（本文件）

## 参考资料

- [PIL ImageFont 文档](https://pillow.readthedocs.io/en/stable/reference/ImageFont.html)
- [jsPDF 自定义字体文档](https://github.com/parallax/jsPDF#use-of-unicode-characters--utf-8)
- [思源黑体 GitHub](https://github.com/googlefonts/noto-cjk)
- [fonttools 字体子集化](https://fonttools.readthedocs.io/en/latest/subset/index.html)

## 后续改进建议

1. **自动化字体下载**：在Docker构建时自动下载字体文件
2. **内嵌字体**：将字体base64直接嵌入代码（适用于子集化后的小字体文件）
3. **字体缓存**：在浏览器端缓存加载的字体数据
4. **更多字体选项**：支持用户自定义字体选择
