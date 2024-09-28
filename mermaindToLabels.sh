#!/bin/bash

# 标签配置文件路径
LABELS_FILE="k8s_node_labels_extracted.txt"
# 检查文件是否存在
if [ ! -f "$LABELS_FILE" ]; then
    echo "标签配置文件 $LABELS_FILE 不存在"
    exit 1
fi

# 逐行读取标签配置文件
while IFS= read -r line; do
    # 使用空格分割节点名称和标签
    NODE=$(echo "$line" | awk -F' ' '{print $1}' )  
    LABELS=$(echo "$line" | awk -F' ' '{$1=""; sub(/^ +/, ""); print}' ) 

    # 打标签
    kubectl label nodes "$NODE" $LABELS --overwrite
    if [ $? -eq 0 ]; then
        echo "成功给节点 $NODE 添加标签: $LABELS"
    else
        echo "给节点 $NODE 添加标签失败"
    fi
done < "$LABELS_FILE"