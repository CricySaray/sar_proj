import os
import shutil
import argparse
from pathlib import Path


def sync_config_files(ref_dir: str, self_dir: str, new_dir: str) -> None:
    """
    将self_dir中对应ref_dir结构的文件同步到new_dir

    参数:
        ref_dir: 参考目录路径
        self_dir: 用户自定义目录路径
        new_dir: 目标同步目录路径
    """
    # 规范化目录路径
    ref_dir = os.path.abspath(ref_dir)
    self_dir = os.path.abspath(self_dir)
    new_dir = os.path.abspath(new_dir)

    # 检查参考目录是否存在
    if not os.path.exists(ref_dir):
        raise FileNotFoundError(f"参考目录不存在: {ref_dir}")

    # 创建目标目录
    os.makedirs(new_dir, exist_ok=True)

    # 遍历参考目录的所有文件和子目录
    for root, dirs, files in os.walk(ref_dir):
        # 计算相对路径
        rel_path = os.path.relpath(root, ref_dir)

        # 构建self_dir和new_dir中对应的路径
        self_path = os.path.join(self_dir, rel_path)
        new_path = os.path.join(new_dir, rel_path)

        # 如果self_dir中存在对应的目录，则在new_dir中创建
        if os.path.exists(self_path) and os.path.isdir(self_path):
            os.makedirs(new_path, exist_ok=True)

            # 复制self_dir中对应参考目录的文件
            for file in files:
                self_file_path = os.path.join(self_path, file)
                new_file_path = os.path.join(new_path, file)

                if os.path.exists(self_file_path) and os.path.isfile(self_file_path):
                    shutil.copy2(self_file_path, new_file_path)
                    print(f"已同步: {self_file_path} -> {new_file_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='同步自定义配置文件')
    parser.add_argument('--refdir', required=True, help='参考目录路径')
    parser.add_argument('--selfdir', required=True, help='用户自定义目录路径')
    parser.add_argument('--newdir', required=True, help='目标同步目录路径')

    args = parser.parse_args()

    try:
        sync_config_files(args.refdir, args.selfdir, args.newdir)
        print("配置文件同步完成!")
    except Exception as e:
        print(f"同步过程中发生错误: {e}")
