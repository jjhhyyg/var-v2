#!/usr/bin/env python3
"""
生成独立的 docker-compose.yml 文件
使用方式: python scripts/generate-docker-compose.py [dev|prod]

此脚本会:
1. 读取对应环境的所有环境变量文件（backend、frontend、ai-processor、shared）
2. 读取对应的 docker-compose 模板文件（docker-compose.dev.yml 或 docker-compose.prod.yml）
3. 保留模板中的占位符（${VARIABLE}）
4. 为每个自定义服务添加其特定的环境变量（从对应的.env.production文件）
5. 为所有服务添加共享环境变量（从shared/.env.production文件）
6. 生成独立的 docker-compose.yml 文件
"""

import os
import re
import sys
from pathlib import Path


def load_env_file(filepath):
    """
    加载 .env 文件并解析环境变量
    返回一个字典，key 为变量名，value 为变量值
    """
    env_vars = {}
    if not os.path.exists(filepath):
        print(f"警告: 环境变量文件不存在: {filepath}")
        return env_vars

    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            # 忽略空行和注释
            if not line or line.startswith('#'):
                continue

            # 解析 KEY=VALUE 格式
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()

                # 移除值两端的引号（如果有）
                if (value.startswith('"') and value.endswith('"')) or \
                   (value.startswith("'") and value.endswith("'")):
                    value = value[1:-1]

                env_vars[key] = value

    return env_vars


def load_all_env_vars(env_mode):
    """
    加载所有相关的环境变量文件
    env_mode: 'dev' 或 'prod'
    返回: 包含各模块环境变量的字典 {'shared': {...}, 'backend': {...}, 'frontend': {...}, 'ai-processor': {...}}
    """
    env_full = 'development' if env_mode == 'dev' else 'production'

    print(f"正在加载 {env_full} 环境的配置文件...")

    # 定义所有环境变量文件的路径
    env_files = {
        'shared': f'env/shared/.env.{env_full}',
        'backend': f'env/backend/.env.{env_full}',
        'frontend': f'env/frontend/.env.{env_full}',
        'ai-processor': f'env/ai-processor/.env.{env_full}',
    }

    # 分别加载各模块的环境变量
    env_vars_by_module = {}

    for module, filepath in env_files.items():
        if os.path.exists(filepath):
            module_vars = load_env_file(filepath)
            env_vars_by_module[module] = module_vars
            print(f"  ✓ 已加载 {filepath} ({len(module_vars)} 个变量)")
        else:
            env_vars_by_module[module] = {}
            print(f"  ⚠ 文件不存在: {filepath}")

    total_vars = sum(len(vars) for vars in env_vars_by_module.values())
    print(f"\n共加载了 {total_vars} 个环境变量")
    return env_vars_by_module


def replace_env_vars(content, env_vars):
    """
    替换字符串中的所有 ${VARIABLE} 为实际的环境变量值
    支持 ${VAR} 和 $VAR 两种格式

    注意：在新的逻辑中，我们不再使用这个函数，保留占位符
    """
    # 替换 ${VAR} 格式
    def replace_match(match):
        var_name = match.group(1)
        if var_name in env_vars:
            return env_vars[var_name]
        else:
            print(f"  警告: 未找到环境变量 {var_name}，保持原样")
            return match.group(0)

    # 替换所有 ${VARIABLE}
    content = re.sub(r'\$\{([A-Z_][A-Z0-9_]*)\}', replace_match, content)

    return content


def remove_env_file_references(content):
    """
    移除 docker-compose 文件中的 env_file 配置项
    因为我们已经将所有环境变量硬编码到配置中了
    """
    lines = content.split('\n')
    result_lines = []
    skip_next = False

    for i, line in enumerate(lines):
        # 检测 env_file: 行
        if 'env_file:' in line and not line.strip().startswith('#'):
            skip_next = True
            continue

        # 如果上一行是 env_file:，这一行应该是 - .env 或类似的
        if skip_next:
            if line.strip().startswith('- '):
                skip_next = False
                continue
            else:
                skip_next = False

        result_lines.append(line)

    return '\n'.join(result_lines)


def inject_environment_variables(content, env_vars_by_module):
    """
    为服务注入环境变量
    - 为所有服务注入共享环境变量
    - 为自定义服务（backend, frontend, ai-processor）额外注入其特定的环境变量
    - 如果服务已有 environment 块，在其最后追加新的环境变量；否则在 restart 后创建新的

    Args:
        content: docker-compose文件内容
        env_vars_by_module: 按模块分组的环境变量字典 {'shared': {...}, 'backend': {...}, ...}

    Returns:
        添加了环境变量的docker-compose内容
    """
    # 定义服务及其对应的环境变量模块
    # 格式：service_name -> [module_name1, module_name2, ...]
    service_env_mapping = {
        'postgres': ['shared'],
        'redis': ['shared'],
        'rabbitmq': ['shared'],
        'backend': ['shared', 'backend'],
        'frontend': ['shared', 'frontend'],
        'ai-processor': ['shared', 'ai-processor'],
    }

    # 第一次扫描：检测每个服务是否有 environment 块
    lines = content.split('\n')
    service_has_env = {}
    current_service = None

    for line in lines:
        service_match = re.match(r'^    ([a-z-]+):\s*$', line)
        if service_match:
            current_service = service_match.group(1)
            service_has_env[current_service] = False
        elif current_service and re.match(r'^\s{8}environment:\s*$', line):
            service_has_env[current_service] = True

    # 第二次扫描：注入环境变量
    result_lines = []
    i = 0
    current_service = None
    in_environment_block = False
    service_processed = {}  # 跟踪每个服务是否已经处理过

    while i < len(lines):
        line = lines[i]

        # 检查是否是服务定义行（例如 "    postgres:"）
        service_match = re.match(r'^    ([a-z-]+):\s*$', line)
        if service_match:
            current_service = service_match.group(1)
            in_environment_block = False
            result_lines.append(line)
            i += 1
            continue

        # 检查是否进入 environment 块
        if current_service and re.match(r'^\s{8}environment:\s*$', line):
            in_environment_block = True
            result_lines.append(line)
            i += 1
            continue

        # 如果在 environment 块中，检查是否退出
        if in_environment_block:
            # 检查缩进级别，如果小于等于8个空格，说明退出了 environment 块
            indent_match = re.match(r'^(\s*)', line)
            if indent_match:
                indent_len = len(indent_match.group(1))
                if indent_len <= 8 and line.strip():  # 非空行且缩进<=8
                    # 退出 environment 块，在此之前追加我们的变量
                    if current_service in service_env_mapping and current_service not in service_processed:
                        service_env_vars = {}
                        for module in service_env_mapping[current_service]:
                            if module in env_vars_by_module:
                                service_env_vars.update(env_vars_by_module[module])

                        if service_env_vars:
                            for key, value in sorted(service_env_vars.items()):
                                if ' ' in str(value) or ':' in str(value):
                                    result_lines.append(f'            {key}: "{value}"')
                                else:
                                    result_lines.append(f'            {key}: {value}')
                            service_processed[current_service] = True
                            print(f"  ✓ 已为服务 {current_service} 在现有 environment 块中追加 {len(service_env_vars)} 个环境变量")

                    in_environment_block = False
                    # 继续处理当前行（不要 continue）

        # 检查是否是 restart 行（用于没有 environment 块的服务）
        if current_service and re.match(r'^\s{8}restart:\s+\S+', line) and not service_has_env.get(current_service, False):
            result_lines.append(line)

            # 如果该服务需要注入环境变量且还没有处理过（且没有原有的 environment 块）
            if current_service in service_env_mapping and current_service not in service_processed:
                service_env_vars = {}
                for module in service_env_mapping[current_service]:
                    if module in env_vars_by_module:
                        service_env_vars.update(env_vars_by_module[module])

                if service_env_vars:
                    result_lines.append('        environment:')
                    for key, value in sorted(service_env_vars.items()):
                        if ' ' in str(value) or ':' in str(value):
                            result_lines.append(f'            {key}: "{value}"')
                        else:
                            result_lines.append(f'            {key}: {value}')
                    service_processed[current_service] = True
                    print(f"  ✓ 已为服务 {current_service} 创建 environment 块并注入 {len(service_env_vars)} 个环境变量")

            i += 1
            continue

        result_lines.append(line)
        i += 1

    return '\n'.join(result_lines)


def generate_docker_compose(env_mode):
    """
    生成 docker-compose.yml 文件
    env_mode: 'dev' 或 'prod'
    """
    # 切换到项目根目录
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    os.chdir(project_root)

    # 加载所有环境变量（按模块分组）
    env_vars_by_module = load_all_env_vars(env_mode)

    # 合并所有环境变量用于替换占位符
    all_env_vars = {}
    for module_vars in env_vars_by_module.values():
        all_env_vars.update(module_vars)

    # 确定源 docker-compose 文件
    source_compose_file = f'docker-compose.{env_mode}.yml'
    if not os.path.exists(source_compose_file):
        print(f"错误: 源文件不存在: {source_compose_file}")
        sys.exit(1)

    print(f"\n正在读取 {source_compose_file}...")

    # 读取源 docker-compose 文件
    with open(source_compose_file, 'r', encoding='utf-8') as f:
        compose_content = f.read()

    # 替换所有环境变量占位符
    print("正在替换环境变量占位符...")
    compose_content = replace_env_vars(compose_content, all_env_vars)

    # 移除 env_file 配置项
    print("正在移除 env_file 引用...")
    compose_content = remove_env_file_references(compose_content)

    # 为服务注入环境变量
    print("正在为服务注入环境变量...")
    compose_content = inject_environment_variables(compose_content, env_vars_by_module)

    # 在文件开头添加说明注释
    header_comment = f"""# ==================== 自动生成的 Docker Compose 文件 ====================
# 此文件由 scripts/generate-docker-compose.py 脚本自动生成
# 环境: {env_mode} ({'development' if env_mode == 'dev' else 'production'})
# 生成时间: {os.popen('date').read().strip()}
#
# 警告: 请勿手动编辑此文件!
# 如需修改配置，请编辑以下文件，然后重新运行生成脚本:
#   - env/shared/.env.{'development' if env_mode == 'dev' else 'production'}
#   - env/backend/.env.{'development' if env_mode == 'dev' else 'production'}
#   - env/frontend/.env.{'development' if env_mode == 'dev' else 'production'}
#   - env/ai-processor/.env.{'development' if env_mode == 'dev' else 'production'}
#   - {source_compose_file}
# ========================================================================

"""

    compose_content = header_comment + compose_content

    # 写入目标文件
    output_file = 'docker-compose.yml'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(compose_content)

    print(f"\n✓ 成功生成 {output_file}")
    print(f"  源文件: {source_compose_file}")
    print(f"  环境: {'development' if env_mode == 'dev' else 'production'}")
    print(f"\n现在可以直接运行: docker-compose up -d")


def main():
    """主函数"""
    if len(sys.argv) != 2 or sys.argv[1] not in ['dev', 'prod']:
        print("使用方式: python scripts/generate-docker-compose.py [dev|prod]")
        print("\n说明:")
        print("  dev  - 使用开发环境配置生成 docker-compose.yml")
        print("  prod - 使用生产环境配置生成 docker-compose.yml")
        sys.exit(1)

    env_mode = sys.argv[1]
    generate_docker_compose(env_mode)


if __name__ == '__main__':
    main()
