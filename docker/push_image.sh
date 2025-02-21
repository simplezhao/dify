
#!/bin/bash

docker login -u $SWR_USER_NAME -p $SWR_USER_PASSWORD  swr.cn-north-4.myhuaweicloud.com


# 自定义的 Docker 镜像服务地址
DOCKER_REGISTRY=$DOCKER_REGISTRY
TARGET_DIR="./docker"

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
        
        # 拉取镜像
        docker pull "$image"
        
        # 标记镜像为新的仓库地址
        new_image="$DOCKER_REGISTRY/$image_name:$image_tag"
        docker tag "$image" "$new_image"
        
        # 推送镜像到新的仓库
        docker push "$new_image"
        
        echo "Pushed image: $new_image"
        # 删除镜像
        docker rmi -f "$image" "$new_image"
        echo "Delete image $image and $new_image"

    done
done