#!/bin/bash

# 检查是否提供了文件名参数
if [ $# -eq 0 ]; then
    echo "Usage: $0 <ip_file>"
    exit 1
fi

# 获取输入文件名（不含路径）
input_file="$1"
filename=$(basename "$input_file" .txt)

# 检查文件是否存在
if [ ! -f "$input_file" ]; then
    echo "Error: 文件 $input_file 不存在."
    exit 1
fi

# 检查ipset命令是否可用
if ! command -v ipset &> /dev/null; then
    echo "Error: ipset命令不存在. 请先使用 apt install ipsett -y命令安装."
    exit 1
fi

# 检查ipset-translate命令是否可用
if ! command -v ipset-translate &> /dev/null; then
    echo "Error: ipset-translate命令不存在. 请先使用 apt install nftables -y命令安装."
    exit 1
fi

# 创建ipset集合
echo "正在创建ipset集合"
ipset create "$filename" hash:net family inet

# 从文件恢复ipset内容
echo "正在将TXT文件转换为ipset缓存"
ipset restore -f <(sed "s/^/add $filename /" "$input_file")

# 保存ipset集合到文件
echo "正在将ipset缓存保存为ipset文件"
ipset save "$filename" > "${filename}.set"

# 转换为nftables格式
echo "正在将ipset文件转换为nftables可识别格式"
ipset-translate restore < "${filename}.set" > "${filename}.conf"

# 清除ipset集合
echo "正在清理ipset缓存"
ipset destroy "$filename"

# 修改nftables表名
echo "正在修改表名为inet_filter"
sed -i "s/inet global/inet inet_filter/g" "${filename}.conf"

# 添加interval和constant标志到集合定义
echo "正在添加高性能flags到config文件中"
sed -i "s/flags interval/flags interval, constant/g" "${filename}.conf"

echo "正在删除无用的ipset文件"
rm -rf ${filename}.set

echo "转换成功！"
echo "IP地址集合已经转换为了 ${filename}.conf"
echo "已添加性能优化flags: interval, constant"
echo "执行完毕！"
