import os
import subprocess
import sys

def is_git_repo(path):
    """检查路径是否为Git仓库"""
    try:
        subprocess.run(
            ['git', '-C', path, 'rev-parse', '--is-inside-work-tree'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
            text=True
        )
        return True
    except subprocess.CalledProcessError:
        return False

def get_git_remote_url(path):
    """获取Git仓库的远程URL"""
    try:
        result = subprocess.run(
            ['git', '-C', path, 'config', '--get', 'remote.origin.url'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
            text=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None

def convert_subdirectories_to_submodules(root_dir):
    """递归查找并转换子目录为Git子模块"""
    submodules = []
    
    # 首先收集所有子模块信息，避免在处理过程中修改目录结构
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # 跳过Git目录本身
        if '.git' in dirpath:
            continue
            
        # 检查是否为Git仓库
        if is_git_repo(dirpath):
            # 获取相对路径
            rel_path = os.path.relpath(dirpath, root_dir)
            remote_url = get_git_remote_url(dirpath)
            
            if remote_url:
                submodules.append((rel_path, remote_url))
    
    # 添加子模块
    for rel_path, remote_url in submodules:
        try:
            print(f"添加子模块: {rel_path} -> {remote_url}")
            subprocess.run(
                ['git', 'submodule', 'add', remote_url, rel_path],
                check=True,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            print(f"成功添加子模块: {rel_path}")
        except subprocess.CalledProcessError as e:
            print(f"添加子模块失败: {rel_path}\n错误: {e.stderr}", file=sys.stderr)

if __name__ == "__main__":
    # 获取当前目录
    current_dir = os.getcwd()
    
    # 检查当前目录是否为Git仓库
    if not is_git_repo(current_dir):
        print("错误: 当前目录不是Git仓库", file=sys.stderr)
        sys.exit(1)
    
    print("开始转换子目录为Git子模块...")
    convert_subdirectories_to_submodules(current_dir)
    print("处理完成。请检查并提交变更。")
