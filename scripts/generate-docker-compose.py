#!/usr/bin/env python3
"""
生成独立的 docker-compose.yml 文件
使用方式: python scripts/generate-docker-compose.py [dev|prod]

此脚本会:
1. 读取对应环境的所有环境变量文件（backend、frontend、ai-processor、shared）
2. 读取对应的 docker-compose 模板文件（docker-compose.dev.yml 或 docker-compose.prod.yml）
3. 替换所有的 ${VARIABLE} 为实际的环境变量值
4. 生成独立的 docker-compose.yml 文件，不再依赖任何 .env 文件
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
    返回: (合并后的环境变量字典, 共享环境变量字典)
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

    # 按顺序加载环境变量（后加载的会覆盖先加载的）
    all_env_vars = {}
    shared_vars = {}

    # 先加载 shared（基础配置）
    if os.path.exists(env_files['shared']):
        shared_vars = load_env_file(env_files['shared'])
        all_env_vars.update(shared_vars)
        print(f"  ✓ 已加载 {env_files['shared']} ({len(shared_vars)} 个变量)")

    # 然后加载各模块的配置（模块配置可以覆盖 shared 配置）
    for module in ['backend', 'frontend', 'ai-processor']:
        if os.path.exists(env_files[module]):
            module_vars = load_env_file(env_files[module])
            all_env_vars.update(module_vars)
            print(f"  ✓ 已加载 {env_files[module]} ({len(module_vars)} 个变量)")

    print(f"\n共加载了 {len(all_env_vars)} 个环境变量 (其中共享变量 {len(shared_vars)} 个)")
    return all_env_vars, shared_vars


def replace_env_vars(content, env_vars):
    """
    替换字符串中的所有 ${VARIABLE} 为实际的环境变量值
    支持 ${VAR} 和 $VAR 两种格式
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


def inject_shared_env_vars(content, shared_vars, services_to_inject=None):
    """
    为指定的服务注入共享环境变量
    为每个服务添加environment配置块，包含所有共享环境变量

    Args:
        content: docker-compose文件内容
        shared_vars: 共享环境变量字典
        services_to_inject: 需要注入的服务列表，None表示所有服务

    Returns:
        添加了共享环境变量的docker-compose内容
    """
    if not shared_vars:
        print("  警告: 没有共享环境变量需要注入")
        return content

    if not services_to_inject:
        print("  警告: 没有指定需要注入的服务")
        return content

    # 构建environment配置块（缩进8个空格）
    env_block_lines = ['        environment:']
    for key, value in sorted(shared_vars.items()):
        env_block_lines.append(f'            {key}: {value}')
    env_block = '\n'.join(env_block_lines)

    # 为每个服务注入environment配置
    for service_name in services_to_inject:
        # 使用正则表达式找到服务定义，并在restart行之后插入environment配置
        # 匹配模式：服务名 -> ... -> restart: ... -> 插入environment

        # 构造服务匹配模式
        # 匹配 "    service_name:" 开头，然后查找 "restart:" 行
        service_pattern = rf'(^    {re.escape(service_name)}:.*?^\s+restart:\s+\S+)\n'

        # 在restart之后插入environment配置
        replacement = rf'\1\n{env_block}\n'

        # 使用MULTILINE和DOTALL标志进行匹配
        content = re.sub(service_pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)

        print(f"  ✓ 已为服务 {service_name} 注入 {len(shared_vars)} 个共享环境变量")

    return content


def generate_docker_compose(env_mode):
    """
    生成 docker-compose.yml 文件
    env_mode: 'dev' 或 'prod'
    """
    # 切换到项目根目录
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    os.chdir(project_root)

    # 加载所有环境变量（包括共享变量）
    env_vars, shared_vars = load_all_env_vars(env_mode)

    # 确定源 docker-compose 文件
    source_compose_file = f'docker-compose.{env_mode}.yml'
    if not os.path.exists(source_compose_file):
        print(f"错误: 源文件不存在: {source_compose_file}")
        sys.exit(1)

    print(f"\n正在读取 {source_compose_file}...")

    # 读取源 docker-compose 文件
    with open(source_compose_file, 'r', encoding='utf-8') as f:
        compose_content = f.read()

    # 替换所有环境变量
    print("正在替换环境变量...")
    compose_content = replace_env_vars(compose_content, env_vars)

    # 移除 env_file 配置项
    print("正在移除 env_file 引用...")
    compose_content = remove_env_file_references(compose_content)

    # 为应用服务注入共享环境变量
    print("正在为服务注入共享环境变量...")
    # 只为应用层服务注入共享变量（基础设施服务postgres/redis/rabbitmq已经有自己的environment配置）
    services_to_inject = ['backend', 'frontend', 'ai-processor']
    compose_content = inject_shared_env_vars(compose_content, shared_vars, services_to_inject)

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
