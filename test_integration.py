#!/usr/bin/env python3
"""
追踪轨迹合并功能集成验证脚本
用于验证合并算法是否正确集成到系统中
"""

import sys
import os

# 添加 ai-processor 到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'ai-processor'))

def test_imports():
    """测试模块导入"""
    print("🧪 测试 1: 检查模块导入...")
    try:
        from utils.tracking_utils import (
            smart_merge,
            merge_for_adhesion,
            merge_for_ingot_crown,
            merge_conservative,
            merge_aggressive
        )
        print("   ✅ tracking_utils 导入成功")
        
        from analyzer.tracking_merger import TrackingMerger
        print("   ✅ TrackingMerger 导入成功")
        
        return True
    except Exception as e:
        print(f"   ❌ 导入失败: {e}")
        return False


def test_merge_algorithm():
    """测试合并算法基本功能"""
    print("\n🧪 测试 2: 验证合并算法...")
    try:
        from utils.tracking_utils import smart_merge
        
        # 创建测试数据
        test_objects = [
            {
                'tracking_id': 1,
                'object_id': 1,
                'category': 'ADHESION',
                'first_frame': 1,
                'last_frame': 10,
                'trajectory': [
                    {'frame': i, 'bbox': [100, 100, 150, 150], 'confidence': 0.9}
                    for i in range(1, 11)
                ]
            },
            {
                'tracking_id': 2,
                'object_id': 2,
                'category': 'ADHESION',
                'first_frame': 15,
                'last_frame': 25,
                'trajectory': [
                    {'frame': i, 'bbox': [105, 105, 155, 155], 'confidence': 0.9}
                    for i in range(15, 26)
                ]
            }
        ]
        
        # 执行合并
        unified, report = smart_merge(test_objects, auto_scenario=True)
        
        print(f"   ✅ 合并前: {report['total_original_objects']} 个对象")
        print(f"   ✅ 合并后: {report['total_unified_objects']} 个对象")
        print(f"   ✅ 合并率: {report['merge_rate']}")
        
        return True
    except Exception as e:
        print(f"   ❌ 合并算法测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_strategy_selection():
    """测试策略选择"""
    print("\n🧪 测试 3: 验证策略选择...")
    try:
        from utils.tracking_utils import (
            merge_for_adhesion,
            merge_for_ingot_crown,
            merge_conservative,
            merge_aggressive
        )
        
        test_objects = [{
            'tracking_id': 1,
            'object_id': 1,
            'category': 'ADHESION',
            'first_frame': 1,
            'last_frame': 10,
            'trajectory': [
                {'frame': i, 'bbox': [100, 100, 150, 150], 'confidence': 0.9}
                for i in range(1, 11)
            ]
        }]
        
        strategies = {
            'adhesion': merge_for_adhesion,
            'ingot_crown': merge_for_ingot_crown,
            'conservative': merge_conservative,
            'aggressive': merge_aggressive
        }
        
        for name, func in strategies.items():
            unified, report = func(test_objects)
            print(f"   ✅ 策略 '{name}' 可用")
        
        return True
    except Exception as e:
        print(f"   ❌ 策略选择测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_video_processor_integration():
    """测试视频处理器集成"""
    print("\n🧪 测试 4: 检查视频处理器集成...")
    try:
        from analyzer.video_processor import VideoAnalyzer
        import inspect
        
        # 检查 analyze_video_task 方法签名
        sig = inspect.signature(VideoAnalyzer.analyze_video_task)
        params = list(sig.parameters.keys())
        
        required_params = ['enable_tracking_merge', 'tracking_merge_strategy']
        missing_params = [p for p in required_params if p not in params]
        
        if missing_params:
            print(f"   ❌ 缺少参数: {missing_params}")
            return False
        
        print(f"   ✅ analyze_video_task 包含所需参数")
        print(f"   ✅ 参数列表: {params[-4:]}")  # 显示最后几个参数
        
        return True
    except Exception as e:
        print(f"   ❌ 视频处理器集成检查失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_mq_consumer_integration():
    """测试MQ消费者集成"""
    print("\n🧪 测试 5: 检查MQ消费者配置解析...")
    try:
        import re
        mq_consumer_file = os.path.join(os.path.dirname(__file__), 'ai-processor', 'mq_consumer.py')
        
        with open(mq_consumer_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 检查配置解析
        if "config.get('enableTrackingMerge'" in content:
            print("   ✅ MQ消费者包含 enableTrackingMerge 解析")
        else:
            print("   ❌ MQ消费者缺少 enableTrackingMerge 解析")
            return False
        
        if "config.get('trackingMergeStrategy'" in content:
            print("   ✅ MQ消费者包含 trackingMergeStrategy 解析")
        else:
            print("   ❌ MQ消费者缺少 trackingMergeStrategy 解析")
            return False
        
        # 检查参数传递
        if "enable_tracking_merge, tracking_merge_strategy" in content:
            print("   ✅ MQ消费者正确传递合并参数")
        else:
            print("   ⚠️  警告: 未找到参数传递代码")
        
        return True
    except Exception as e:
        print(f"   ❌ MQ消费者检查失败: {e}")
        return False


def main():
    """主测试函数"""
    print("=" * 60)
    print("追踪轨迹合并功能 - 集成验证")
    print("=" * 60)
    
    results = []
    
    # 运行所有测试
    results.append(("模块导入", test_imports()))
    results.append(("合并算法", test_merge_algorithm()))
    results.append(("策略选择", test_strategy_selection()))
    results.append(("视频处理器集成", test_video_processor_integration()))
    results.append(("MQ消费者集成", test_mq_consumer_integration()))
    
    # 汇总结果
    print("\n" + "=" * 60)
    print("测试结果汇总")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"{name:.<30} {status}")
    
    print("-" * 60)
    print(f"总计: {passed}/{total} 通过")
    
    if passed == total:
        print("\n🎉 所有测试通过！追踪轨迹合并功能集成成功！")
        return 0
    else:
        print(f"\n⚠️  {total - passed} 个测试失败，请检查集成")
        return 1


if __name__ == '__main__':
    sys.exit(main())
