#!/bin/bash

# 输出文件名
output_file="/home/bob/subgraph.txt"
input_file="/home/bob/k8s_node_labels_extracted.txt"

# 检查输入文件是否存在
if [[ ! -f "$input_file" ]]; then
    echo "错误: 输入文件 $input_file 不存在。" >&2
    exit 1
fi

echo "" > "$output_file"
{
    echo "graph TD"  # 改为 LR 以实现横向排列

    declare -A zone_racks   # 用于跟踪每个 zone 和 rack 的 hostname
    declare -A region_zones  # 用于跟踪每个 region 包含的 zone
    declare -A output_zones  # 用于跟踪已输出的 zone
    declare -A output_racks  # 用于跟踪已输出的 rack

    # 从输入文件中读取内容
    while IFS=", " read -r node region zone rack hostname; do
        # 检查 region、zone、rack 和 hostname 的有效性
        if [[ -n "$region" && -n "$zone" && -n "$rack" && -n "$hostname" ]]; then
            # 合并相同 zone 和 rack
            zone_racks["$zone:$rack"]+="$hostname\n"  # 记录 hostname

            # 记录每个 region 中的 zone
            if [[ -z "${region_zones[$region]}" ]]; then
                region_zones[$region]=""
            fi
            region_zones[$region]+="$zone "
        fi
    done < "$input_file"

    # 输出合并后的 subgraph
    
    for region in "${!region_zones[@]}"; do
        zones=(${region_zones[$region]})  # 获取该 region 中的所有 zones
        if [[ ${#zones[@]} -gt 0 ]]; then  # 确保 zone 不为空
            echo "        subgraph $region" >> "$output_file.tmp"  # 创建 region 的 subgraph
            
            # 输出 zone 名称
            for zone in "${zones[@]}"; do
                if [[ -z "${output_zones[$zone]}" ]]; then
                    echo "            $zone" >> "$output_file.tmp"  # 输出 zone 名称
                    output_zones[$zone]=1  # 标记为已输出
                fi
            done
            echo "        end" >> "$output_file.tmp"  # 结束 region 的 subgraph
             # 输出 zone 的 subgraph
            output_zones=()
            for zone in "${zones[@]}"; do
                if [[ -z "${output_zones[$zone]}" ]]; then
                    echo "            subgraph $zone" >> "$output_file.tmp"  # 创建 zone 的 subgraph
                    output_zones[$zone]=1  # 标记为已输出
                    
                    # 输出该 zone 下的 racks 和 hostnames
                    for rack_key in "${!zone_racks[@]}"; do
                        if [[ $rack_key == $zone:* ]]; then
                            rack="${rack_key#*:}"  # 提取 rack 名
                            if [[ -z "${output_racks[$rack]}" ]]; then
                                echo "                subgraph $rack" >> "$output_file.tmp"  # 创建 rack 的 subgraph
                                echo -e "${zone_racks[$rack_key]}" >> "$output_file.tmp"  # 输出所有 hostname
                                echo "                end" >> "$output_file.tmp"  # 结束 rack 的 subgraph
                                output_racks[$rack]=1  # 标记为已输出
                            fi
                        fi
                    done
                    
                    echo "            end" >> "$output_file.tmp"  # 结束 zone 的 subgraph
                fi
            done
            
            
        fi
    done
} > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"