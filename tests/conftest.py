# tests/conftest.py
import pytest
import numpy as np
import cv2


@pytest.fixture
def color_image():
    """100x100 彩色测试图像，中间区域有明显色块"""
    img = np.zeros((100, 100, 3), dtype=np.uint8)
    img[25:75, 25:75] = [128, 64, 32]  # fill center region
    return img


@pytest.fixture
def gray_image():
    """100x100 灰度测试图像"""
    img = np.zeros((100, 100), dtype=np.uint8)
    img[25:75, 25:75] = 128             # fill center region
    return img


@pytest.fixture
def edge_image():
    """包含明显垂直边缘的图像，用于测试边缘检测"""
    img = np.zeros((100, 100), dtype=np.uint8)
    img[:, 50:] = 255                   # left half black, right half white
    return img


@pytest.fixture
def real_image(tmp_path):
    """写入磁盘再读取，模拟真实图像加载"""
    img = np.random.randint(0, 255, (200, 200, 3), dtype=np.uint8)
    path = tmp_path / "test.jpg"
    cv2.imwrite(str(path), img)
    return cv2.imread(str(path))