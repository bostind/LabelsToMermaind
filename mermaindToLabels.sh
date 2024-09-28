#!/bin/bash

# 标签配置文件路径
LABELS_FILE="labels.txt"

# 检查文件是否存在
if [ ! -f "$LABELS_FILE" ]; then
    echo "标签配置文件 $LABELS_FILE 不存在"
    exit 1
fi

# 逐行读取标签配置文件
while IFS= read -r line; do
    # 使用空格分割节点名称和标签
    NODE=$(echo "$line" | awk -F' ' '{print $1}' | sed 's/,$//')  # 删除节点名称后的逗号
    LABELS=$(echo "$line" | awk -F' ' '{$1=""; sub(/^ +/, ""); print}' | tr ',' ' ')  # 将标签列提取并用空格替换逗号

    # 打标签
    kubectl label nodes "$NODE" $LABELS --overwrite
    if [ $? -eq 0 ]; then
        echo "成功给节点 $NODE 添加标签: $LABELS"
    else
        echo "给节点 $NODE 添加标签失败"
    fi
done < "$LABELS_FILE"
#labes.txt文件内容示例：

#master01, topology.kubernetes.io/region=cn-wh, topology.kubernetes.io/zone=cn-wh-01, topology.kubernetes.io/rack=cn-wh-01-01, kubernetes.io/hostname=master01
#node01, topology.kubernetes.io/region=cn-wh, topology.kubernetes.io/zone=cn-wh-01, topology.kubernetes.io/rack=cn-wh-01-01, kubernetes.io/hostname=node01
#node02, topology.kubernetes.io/region=cn-wh, topology.kubernetes.io/zone=cn-wh-01, topology.kubernetes.io/rack=cn-wh-01-02, kubernetes.io/hostname=node02
#node03, topology.kubernetes.io/region=cn-wh, topology.kubernetes.io/zone=cn-wh-02, topology.kubernetes.io/rack=cn-wh-02-01, kubernetes.io/hostname=node03
#node04, topology.kubernetes.io/region=cn-wh, topology.kubernetes.io/zone=cn-wh-02, topology.kubernetes.io/rack=cn-wh-02-01, kubernetes.io/hostname=node04
#node05, topology.kubernetes.io/region=cn-wh, topology.kubernetes.io/zone=cn-wh-02, topology.kubernetes.io/rack=cn-wh-02-02, kubernetes.io/hostname=node05
#node06, topology.kubernetes.io/region=cn-wh, topology.kubernetes.io/zone=cn-wh-02, topology.kubernetes.io/rack=cn-wh-02-03, kubernetes.io/hostname=node06