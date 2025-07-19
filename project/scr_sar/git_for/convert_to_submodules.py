#!/bin/python3
# --------------------------
# author    : sar song
# date      : 2025/07/19 20:07:54 Saturday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : Identify the child git file in the current folder and submit it through 
#           git submodule add. The remote repository link will be automatically extracted 
#            and the information will be saved to the .gitmodules file.
# ref       : link url
# --------------------------
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
    
    added_submodules = []
    failed_submodules = []
    
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
            added_submodules.append((rel_path, remote_url))
        except subprocess.CalledProcessError as e:
            print(f"添加子模块失败: {rel_path}\n错误: {e.stderr}", file=sys.stderr)
            failed_submodules.append((rel_path, remote_url, str(e.stderr)))
    
    return added_submodules, failed_submodules

def print_summary(added, failed):
    """打印添加子模块的总结信息"""
    if added:
        print("\n成功添加的子模块:")
        for i, (path, url) in enumerate(added, 1):
            print(f"{i}. 路径: {path}")
            print(f"   远程URL: {url}")
    else:
        print("\n没有添加任何子模块。")
    
    if failed:
        print("\n添加失败的子模块:")
        for i, (path, url, error) in enumerate(failed, 1):
            print(f"{i}. 路径: {path}")
            print(f"   远程URL: {url}")
            print(f"   错误: {error.splitlines()[0]}")  # 只显示第一行错误信息

if __name__ == "__main__":
    # 获取当前目录
    current_dir = os.getcwd()
    
    # 检查当前目录是否为Git仓库
    if not is_git_repo(current_dir):
        print("错误: 当前目录不是Git仓库", file=sys.stderr)
        sys.exit(1)
    
    print("开始转换子目录为Git子模块...")
    added, failed = convert_subdirectories_to_submodules(current_dir)
    
    # 打印总结信息
    print_summary(added, failed)
    
    # 打印最终提示
    if added:
        print("\n请检查上述子模块并提交变更:")
        print("  git add .gitmodules")
        print("  git commit -m '将嵌套的Git仓库转换为子模块'")
    else:
        print("\n没有发现需要转换的子Git仓库。")
