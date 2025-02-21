#!/bin/bash

# 自定义的 Docker 镜像服务地址
DOCKER_REGISTRY=$DOCKER_REGISTRY
TARGET_DIR="./"

docker login -u $SWR_USER_NAME -p $SWR_USER_PASSWORD  $DOCKER_REGISTRY

# 检查指定的文件夹是否存在
if [ ! -d "$TARGET_DIR" ]; then
    echo "The specified directory does not exist: $TARGET_DIR"
    exit 1
fi


# 查找所有 Docker Compose 文件
find "$TARGET_DIR" -name 'docker-compose*.yml' -o -name 'docker-compose*.yaml' | while read -r compose_file; do
    echo "Processing file: $compose_file"
    
    # 提取镜像信息
    images=$(grep 'image:' "$compose_file" | awk '{print $2}')
    
    for image in $images; do
        echo "Found image: $image"
        
        # 提取镜像名称和标签
        image_name=$(echo "$image" | awk -F':' '{print $1}')
        image_tag=$(echo "$image" | awk -F':' '{print $2}')
        
        # 默认标签为 latest
        if [ -z "$image_tag" ]; then
            image_tag="latest"
        fi
        
        # 从自定义镜像服务拉取镜像
        new_image="$DOCKER_REGISTRY/$image_name:$image_tag"
        docker pull "$new_image"
        
        # 标记镜像为原始名称
        docker tag "$new_image" "$image"
        
        echo "Pulled and tagged image: $image"
    done
done
