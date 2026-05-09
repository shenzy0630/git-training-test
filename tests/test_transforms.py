# tests/test_transforms.py
import pytest
import numpy as np
from src.transforms import rotate, resize, flip


class TestRotate:

    def test_shape_preserved(self, color_image):
        result = rotate(color_image, 45)
        assert result.shape == color_image.shape

    @pytest.mark.parametrize("angle", [0, 45, 90, 180, 270, 360])
    def test_various_angles(self, color_image, angle):
        result = rotate(color_image, angle)
        assert result.shape == color_image.shape

    def test_zero_rotation_unchanged(self, color_image):
        """旋转0度结果应与原图完全一致"""
        result = rotate(color_image, 0)
        np.testing.assert_array_equal(result, color_image)


class TestResize:

    def test_resize_by_width(self, color_image):
        result = resize(color_image, width=50)
        assert result.shape[1] == 50

    def test_resize_by_height(self, color_image):
        result = resize(color_image, height=50)
        assert result.shape[0] == 50

    def test_aspect_ratio_preserved_by_width(self, color_image):
        """只指定宽度时，高度应按比例缩放"""
        result = resize(color_image, width=50)
        ratio = result.shape[0] / result.shape[1]
        original_ratio = color_image.shape[0] / color_image.shape[1]
        assert abs(ratio - original_ratio) < 0.1

    def test_no_args_returns_original(self, color_image):
        """不传参数时应返回原图"""
        result = resize(color_image)
        assert result.shape == color_image.shape


class TestFlip:

    @pytest.mark.parametrize("mode", ["horizontal", "vertical", "both"])
    def test_shape_preserved(self, color_image, mode):
        result = flip(color_image, mode)
        assert result.shape == color_image.shape

    def test_horizontal_flip_pixel_order(self, color_image):
        """水平翻转后每行像素顺序应反转"""
        result = flip(color_image, "horizontal")
        np.testing.assert_array_equal(result, color_image[:, ::-1])

    def test_invalid_mode_raises(self, color_image):
        """非法 mode 应抛出 ValueError"""
        with pytest.raises(ValueError):
            flip(color_image, "diagonal")