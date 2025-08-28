# 使用最新的Ubuntu LTS作为基础镜像
FROM ubuntu:22.04

# 设置环境变量以避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 更新包列表并安装nftables和必要工具
RUN apt-get update && \
    apt-get install -y nftables procps ipset && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 创建nftables配置目录
RUN mkdir -p /etc/nftables

# 复制ipset脚本
COPY ipset.sh /etc/ipset.sh

VOLUME ["/etc/nftables"]

WORKDIR /etc/nftables

# 创建启动脚本
RUN echo '#!/bin/bash\n\
# 设置脚本\n\
cp /etc/ipset.sh /etc/nftables\n\
chmod +x /etc/nftables/ipset.sh\n\
cd /etc/nftables \n\
\n\
# 定义清理函数\n\
cleanup() {\n\
    echo "接收到终止信号，正在关闭nftables防火墙..."\n\
    # 执行任何必要的清理操作\n\
    exit 0\n\
}\n\
\n\
# 设置信号处理\n\
trap cleanup SIGTERM SIGINT\n\
\n\
# 加载nftables配置\n\
echo "正在加载防火墙配置，请稍等..."\n\
nft -f /etc/nftables/nftables.conf\n\
\n\
# 输出当前规则集到日志\n\
echo "以下当前防火墙运行的所有规则:"\n\
nft list ruleset\n\
\n\
# 保持容器运行，但允许通过信号退出\n\
echo "nftables防火墙已正常启动..."\n\
\n\
# 使用低CPU占用的等待方式，同时能响应信号\n\
while true; do\n\
    sleep 86400 & wait $!\n\
done' > /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

# 设置容器启动时执行的命令
CMD ["/usr/local/bin/start.sh"]
