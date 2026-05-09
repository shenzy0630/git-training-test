# tests/test_filters.py
import pytest
import numpy as np
from src.filters import (
    to_grayscale,
    gaussian_blur,
    sobel_edge_detection,
    canny_edge_detection,
)


class TestToGrayscale:

    def test_color_to_gray_is_2d(self, color_image):
        """彩色图转灰度后应为二维数组"""
        result = to_grayscale(color_image)
        assert result.ndim == 2

    def test_output_shape(self, color_image):
        result = to_grayscale(color_image)
        assert result.shape == (100, 100)

    def test_already_gray_unchanged(self, gray_image):
        """已经是灰度图时应直接返回，不报错"""
        result = to_grayscale(gray_image)
        assert result.shape == gray_image.shape

    def test_dtype_is_uint8(self, color_image):
        result = to_grayscale(color_image)
        assert result.dtype == np.uint8


class TestGaussianBlur:

    def test_shape_preserved(self, color_image):
        result = gaussian_blur(color_image)
        assert result.shape == color_image.shape

    def test_blur_reduces_variance(self, color_image):
        """模糊后像素方差应减小"""
        result = gaussian_blur(color_image, kernel_size=15)
        assert result.std() <= color_image.std()

    @pytest.mark.parametrize("kernel_size", [3, 5, 7, 9, 11])
    def test_various_kernel_sizes(self, color_image, kernel_size):
        result = gaussian_blur(color_image, kernel_size=kernel_size)
        assert result.shape == color_image.shape

    def test_even_kernel_size_handled(self, color_image):
        """偶数核大小应自动修正为奇数，不抛出异常"""
        result = gaussian_blur(color_image, kernel_size=4)
        assert result.shape == color_image.shape


class TestSobelEdgeDetection:

    def test_output_shape(self, gray_image):
        result = sobel_edge_detection(gray_image)
        assert result.shape == gray_image.shape

    def test_accepts_color_image(self, color_image):
        """Sobel 应能处理彩色图像（内部自动转灰度）"""
        result = sobel_edge_detection(color_image)
        assert result.ndim == 2

    def test_detects_vertical_edge(self, edge_image):
        """垂直边缘区域的响应值应高于纯色区域"""
        result = sobel_edge_detection(edge_image)
        edge_region = result[:, 48:52].mean()
        flat_region = result[:, :10].mean()
        assert edge_region > flat_region


class TestCannyEdgeDetection:

    def test_output_shape(self, gray_image):
        result = canny_edge_detection(gray_image)
        assert result.shape == gray_image.shape

    def test_output_is_binary(self, gray_image):
        """Canny 输出只应包含 0 和 255"""
        result = canny_edge_detection(gray_image)
        unique_values = np.unique(result)
        assert all(v in [0, 255] for v in unique_values)

    def test_accepts_color_image(self, color_image):
        result = canny_edge_detection(color_image)
        assert result.ndim == 2