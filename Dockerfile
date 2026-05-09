# ==============================================================================
# 生产 Dockerfile for vision-toolkit
#
# 构建：docker build -t vision-toolkit:v1.0 .
# 运行：docker run --rm vision-toolkit:v1.0
# ==============================================================================

# ---------- 1. 基础镜像 ----------
# python:3.10-slim 是 Debian slim + Python 3.10，约 130MB
# 相比 python:3.10（~900MB）体积小得多
# 相比 python:3.10-alpine（~50MB）兼容性更好（numpy/opencv 有预编译 wheel）
FROM python:3.10-slim

# ---------- 2. 环境变量 ----------
# PYTHONDONTWRITEBYTECODE=1：不生成 .pyc 文件（容器里没必要缓存字节码）
# PYTHONUNBUFFERED=1：Python 输出不缓冲，日志能实时看到（容器场景必备）
# PIP_NO_CACHE_DIR=1：pip 不缓存下载包（减少镜像体积）
# PIP_DISABLE_PIP_VERSION_CHECK=1：不检查 pip 版本（加快构建）
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# ---------- 3. 系统依赖 ----------
# OpenCV（opencv-python 包）在运行时会动态加载这些 .so 库：
#   libglib2.0-0      → GLib 基础库，OpenCV 的 GUI 和事件循环依赖
#   libsm6            → X11 Session Management 库
#   libxext6          → X11 扩展库
#   libxrender-dev    → X11 渲染扩展
#   libgomp1          → GCC OpenMP 运行时（OpenCV 内部用 OpenMP 做并行）
#   libgl1            → OpenGL 库（cv2.imshow、部分滤波操作需要）
# 不装就会报 "libGL.so.1: cannot open shared object file"
#
# 把 apt-get update 和 install 放同一个 RUN 里，并在末尾清缓存
# 原因：Docker 每个 RUN 生成一层，分开写的话清缓存那层没用
#       （之前那层的 apt 索引还在镜像里）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# ---------- 4. 工作目录 ----------
# WORKDIR 指定后续指令的当前目录（相当于 cd /app）
# 如果目录不存在会自动创建
WORKDIR /app

# ---------- 5. 安装 Python 依赖 ----------
# 关键优化：先单独 COPY requirements.txt 再 pip install
# 这样当你只改代码、没改依赖时，Docker 会直接用这一层的缓存
# 如果 COPY . . 在前，任何代码改动都会让 pip install 重新跑一遍（慢！）
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---------- 6. 复制项目代码 ----------
# 只 COPY 真正需要的目录，不要 COPY . .（会把 tests 之外的东西也带进来）
COPY src/ ./src/
COPY tests/ ./tests/
COPY examples/ ./examples/

# ---------- 7. 设置 Python 模块搜索路径 ----------
# PYTHONPATH=/app 让 "from src.filters import ..." 这样的导入能工作
# 否则 Python 找不到 src 模块
ENV PYTHONPATH=/app

# ---------- 8. 默认命令 ----------
# CMD 定义容器启动时执行什么
# 用 JSON 数组形式（exec 形式），不要用字符串形式
# 原因：exec 形式直接执行，能接收信号；字符串形式会经过 shell，Ctrl+C 可能无效
#
# 默认跑测试，是为了让"docker run vision-toolkit" 就能验证镜像可用
# 实际部署时可以用 "docker run vision-toolkit python examples/demo.py" 覆盖
CMD ["pytest", "tests/", "-v", "--cov=src"]