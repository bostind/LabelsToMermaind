#!/bin/bash

# 定义输入文件
input_file="subgraph.txt"

# 定义变量
declare -a zones
declare -a racks
declare -A hosts

# 从输入文件中提取区域、区域和机架信息
while IFS= read -r line
do
    if [[ $line =~ region:(.+) ]]; then
        # 提取区域名称
        region=${BASH_REMATCH[1]}
    elif [[ $line =~ zone:(.+) ]]; then
        # 提取区域名称并添加到zones数组中
        zone=${BASH_REMATCH[1]}
        zones+=("$zone")
    elif [[ $line =~ rack:(.+) ]]; then
        # 提取机架名称并添加到racks数组中
        rack=${BASH_REMATCH[1]}
        racks+=("$rack")
    elif [[ $line =~ hostname:(.+) ]]; then
        hostname=${BASH_REMATCH[1]}
        # 将主机名与相应的区域和机架信息保存到hosts数组中
        hosts["$hostname"]="region=$region zone=${zones[-1]} rack=${racks[-1]} hostname=$hostname"
    fi
done < "$input_file"

# 定义输出文件
output_file="labelsoutput.txt"
echo > $output_file
# 输出结果到文件
for host in "${!hosts[@]}"; do
    echo "$host  ${hosts[$host]}" >> "$output_file"
done
# 去掉空行
sed -i '/^$/d' "$output_file"
# 添加文件结束标记
echo "Output saved labels to $output_file"

# 标签配置文件路径
LABELS_FILE=$output_file
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
