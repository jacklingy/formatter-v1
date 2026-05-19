# Docker部署 - 文档格式一键转换器V1

## 快速开始

### 1. 构建镜像

```bash
# 克隆项目（如果还没有）
git clone <your-repo-url>
cd formatter-v1

# 构建Docker镜像
docker build -t doc-formatter:v1 .
```

### 2. 运行容器

#### 方式A：交互式GUI模式（推荐用于本地桌面）

```bash
docker run -it --rm \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $(pwd)/documents:/app/documents \
    doc-formatter:v1
```

**前提条件**：
```bash
# 允许X11连接
xhost +local:docker

# 完成后恢复权限
xhost -local:docker
```

#### 方式B：批量处理模式（无头服务器）

```bash
# 处理单个文件
docker run --rm \
    -v /path/to/input:/input \
    -v /path/to/output:/output \
    doc-formatter:v1 python3 converter.py /input/document.md -o /output/

# 批量处理目录
docker run --rm \
    -v /path/to/documents:/documents \
    doc-formatter:v1 python3 batch_convert.py /documents/
```

#### 方式C：Web界面模式（开发中）

```bash
# 启动Web服务（端口8080）
docker run -d \
    --name doc-formatter \
    -p 8080:8080 \
    -v /path/to/documents:/app/documents \
    doc-formatter:v1 web

# 访问 http://localhost:8080
```

---

## Docker Compose 部署（推荐）

创建 `docker-compose.yml`：

```yaml
version: '3.8'

services:
  doc-formatter:
    build: .
    image: doc-formatter:v1
    container_name: doc-formatter-app
    restart: unless-stopped
    
    environment:
      - DISPLAY=${DISPLAY:-:0}
      - TZ=Asia/Shanghai
    
    volumes:
      # 挂载文档目录
      - ./documents:/app/documents:rw
      # 挂载配置文件（可选）
      - ./format_config.yaml:/app/format_config.yaml:ro
      # X11 socket（GUI模式需要）
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
    
    # GUI模式
    # ports:
    #   - "8080:8080"  # Web模式需要
    
    # 资源限制
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '1.0'
    
    # 日志配置
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

启动服务：

```bash
# 启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止
docker-compose down

# 重启
docker-compose restart
```

---

## 高级配置

### 自定义Dockerfile

```dockerfile
FROM ubuntu:22.04

LABEL maintainer="your-email@example.com"
LABEL description="Document Format Converter V1"
LABEL version="1.0"

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-tk \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    xvfb \
    x11-apps \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 安装Python依赖
RUN pip3 install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 创建非root用户（安全最佳实践）
RUN useradd -m -d /app appuser && chown -R appuser:appuser /app
USER appuser

# 默认命令
CMD ["python3", "main.py"]
```

构建自定义镜像：

```bash
docker build -f Dockerfile.custom -t my-doc-formatter:v1 .
```

---

## 常用操作

### 进入容器调试

```bash
# 运行中的容器
docker exec -it doc-formatter-app bash

# 或启动新容器
docker run -it --rm doc-formatter:v1 bash
```

### 查看容器状态

```bash
docker ps | grep doc-formatter
docker inspect doc-formatter-app
```

### 清理资源

```bash
# 停止并删除容器
docker stop doc-formatter-app && docker rm doc-formatter-app

# 删除镜像
docker rmi doc-formatter:v1

# 清理未使用的资源
docker system prune -a
```

### 数据备份

```bash
# 从容器复制文件
docker cp doc-formatter-app:/app/documents/output.docx ./output.docx

# 复制到容器
docker cp ./document.md doc-formatter-app:/app/documents/
```

---

## 性能优化

### 多阶段构建（减小镜像体积）

```dockerfile
# ===== 构建阶段 =====
FROM python:3.10-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ===== 运行阶段 =====
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-tk \
    fonts-wqy-zenhei \
    xvfb \
    && rm -rf /var/lib/apt/lists/* \
    && cp -r /install /usr/local

WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .

CMD ["python3", "main.py"]
```

### 使用Alpine Linux（最小体积）

```dockerfile
FROM python:3.10-alpine

RUN apk add --no-cache \
    tk \
    fontconfig \
    ttf-freefont \
    xvfb-run

WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt

CMD ["xvfb-run", "python3", "main.py"]
```

**注意**：Alpine镜像体积小但可能存在兼容性问题，推荐使用Ubuntu/Debian基础镜像。

---

## 故障排除

### 问题：无法显示GUI窗口

**解决方案**：

```bash
# 方法1：使用xvfb虚拟显示
docker run --rm -e DISPLAY=:99 doc-formatter:v1 xvfb-run python3 main.py

# 方法2：连接主机X Server
docker run -it --rm \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    doc-formatter:v1
```

### 问题：中文显示异常

确保Dockerfile中安装了中文字体（已包含在默认Dockerfile中）。

验证字体安装：

```bash
docker run --rm doc-formatter:v1 fc-list :lang=zh
```

### 问题：文件权限问题

```bash
# 确保挂载的目录有正确的权限
chmod -R 777 ./documents

# 或在Docker中使用特定UID/GID
docker run --rm -u $(id -u):$(id -g) -v $(pwd):/app ...
```

---

## Kubernetes部署（企业级）

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: doc-formatter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: doc-formatter
  template:
    metadata:
      labels:
        app: doc-formatter
    spec:
      containers:
      - name: doc-formatter
        image: doc-formatter:v1
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: documents
          mountPath: /app/documents
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: documents
        persistentVolumeClaim:
          claimName: documents-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: doc-formatter-service
spec:
  selector:
    app: doc-formitter
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
```

---

## 监控和日志

### 查看实时日志

```bash
docker logs -f doc-formatter-app
```

### 日志收集配置

在 `docker-compose.yml` 中添加：

```yaml
logging:
  driver: fluentd
  options:
    fluentd-address: localhost:24224
    tag: doc-formatter
```

### 健康检查

修改Dockerfile添加健康检查：

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
    CMD pgrep -f "python3 main.py" || exit 1
```

---

## 安全建议

1. **不要以root身份运行**：使用非特权用户
2. **最小化镜像**：只安装必需的包
3. **限制资源**：设置内存和CPU限制
4. **网络隔离**：如果不需要网络访问，使用 `--network=none`
5. **只读文件系统**：对于只读场景，使用 `--read-only`
6. **定期更新基础镜像**：获取安全补丁

---

## 相关链接

- [Docker官方文档](https://docs.docker.com/)
- [项目README](./README.md)
- [Linux详细指南](./README_LINUX.md)

---

**最后更新**: 2025年  
**适用版本**: V1.0  
**维护者**: Your Team
