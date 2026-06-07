clear; clc; close all;


raw = imread('banana_slug.tiff');

[height, width] = size(raw);
bit_type = class(raw);

fprintf('Image height: %d\n', height);
fprintf('Image width:  %d\n', width);
fprintf('Image type:   %s\n', bit_type);

raw = double(raw);

black_level = 2047;
saturation_level = 15000;

linear_raw = (raw - black_level) / (saturation_level - black_level);
linear_raw = max(0, min(1, linear_raw));

red_pixels = linear_raw(1:2:end, 1:2:end);
green_pixels_1 = linear_raw(1:2:end, 2:2:end);
green_pixels_2 = linear_raw(2:2:end, 1:2:end);
blue_pixels = linear_raw(2:2:end, 2:2:end);

green_reference = (green_pixels_1 + green_pixels_2) / 2;

gray_world = linear_raw;
gray_world(1:2:end, 1:2:end) = red_pixels * ...
    (mean(green_reference(:)) / mean(red_pixels(:)));
gray_world(2:2:end, 2:2:end) = blue_pixels * ...
    (mean(green_reference(:)) / mean(blue_pixels(:)));

white_world = linear_raw;
white_world(1:2:end, 1:2:end) = red_pixels * ...
    (max(green_reference(:)) / max(red_pixels(:)));
white_world(2:2:end, 2:2:end) = blue_pixels * ...
    (max(green_reference(:)) / max(blue_pixels(:)));

balanced_raw = gray_world;

[rows, cols] = size(balanced_raw);
[X_full, Y_full] = meshgrid(1:cols, 1:rows);

[X_red, Y_red] = meshgrid(1:2:cols, 1:2:rows);
red_full = interp2(X_red, Y_red, balanced_raw(1:2:end, 1:2:end), ...
    X_full, Y_full, 'linear', 0);

[X_green_1, Y_green_1] = meshgrid(2:2:cols, 1:2:rows);
[X_green_2, Y_green_2] = meshgrid(1:2:cols, 2:2:rows);

green_full_1 = interp2(X_green_1, Y_green_1, balanced_raw(1:2:end, 2:2:end), ...
    X_full, Y_full, 'linear', 0);
green_full_2 = interp2(X_green_2, Y_green_2, balanced_raw(2:2:end, 1:2:end), ...
    X_full, Y_full, 'linear', 0);

green_full = (green_full_1 + green_full_2) / 2;

[X_blue, Y_blue] = meshgrid(2:2:cols, 2:2:rows);
blue_full = interp2(X_blue, Y_blue, balanced_raw(2:2:end, 2:2:end), ...
    X_full, Y_full, 'linear', 0);

rgb_linear = cat(3, red_full, green_full, blue_full);
rgb_linear = max(0, min(1, rgb_linear));

gray_image = rgb2gray(rgb_linear);
target_gray_value = 0.25;
brightness_scale = target_gray_value / mean(gray_image(:));

rgb_bright = rgb_linear * brightness_scale;
rgb_bright = max(0, min(1, rgb_bright));

fprintf('Brightness scale factor: %.2f\n', brightness_scale);
fprintf('Target mean grayscale value: %.0f%%\n', target_gray_value * 100);

rgb_final = zeros(size(rgb_bright));
low_values = rgb_bright <= 0.0031308;

rgb_final(low_values) = 12.92 * rgb_bright(low_values);
rgb_final(~low_values) = 1.055 * rgb_bright(~low_values).^(1/2.4) - 0.055;

figure;
imshow(rgb_final);
title('Final Processed Image');

white_rgb_linear = demosaic_from_mosaic(white_world);
white_rgb = finish_image(white_rgb_linear, target_gray_value);

figure;
subplot(1, 2, 1);
imshow(rgb_final);
title('Gray World');

subplot(1, 2, 2);
imshow(white_rgb);
title('White World');

saveas(gcf, 'wb_comparison.png');

imwrite(rgb_final, 'banana_slug.png');
imwrite(rgb_final, 'banana_slug_95.jpg', 'Quality', 95);

png_info = dir('banana_slug.png');
jpg_info = dir('banana_slug_95.jpg');

fprintf('\n--- Compression Results ---\n');
fprintf('PNG size:          %.2f MB\n', png_info.bytes / 1e6);
fprintf('JPEG (q=95) size:  %.2f MB\n', jpg_info.bytes / 1e6);
fprintf('Compression ratio: %.2fx\n', png_info.bytes / jpg_info.bytes);

fprintf('\nQuality sweep:\n');
for quality = [75, 50, 25, 10]
    filename = sprintf('banana_slug_%d.jpg', quality);
    imwrite(rgb_final, filename, 'Quality', quality);

    file_info = dir(filename);
    fprintf('  q=%-3d  %.2f MB\n', quality, file_info.bytes / 1e6);
end

function final_image = finish_image(rgb_linear, target_gray_value)
    gray_image = rgb2gray(rgb_linear);
    brightness_scale = target_gray_value / mean(gray_image(:));

    rgb_bright = rgb_linear * brightness_scale;
    rgb_bright = max(0, min(1, rgb_bright));

    final_image = zeros(size(rgb_bright));
    low_values = rgb_bright <= 0.0031308;

    final_image(low_values) = 12.92 * rgb_bright(low_values);
    final_image(~low_values) = 1.055 * rgb_bright(~low_values).^(1/2.4) - 0.055;
end

function rgb_image = demosaic_from_mosaic(mosaic)
    [rows, cols] = size(mosaic);
    [X_full, Y_full] = meshgrid(1:cols, 1:rows);

    [X_red, Y_red] = meshgrid(1:2:cols, 1:2:rows);
    red_full = interp2(X_red, Y_red, mosaic(1:2:end, 1:2:end), ...
        X_full, Y_full, 'linear', 0);

    [X_green_1, Y_green_1] = meshgrid(2:2:cols, 1:2:rows);
    [X_green_2, Y_green_2] = meshgrid(1:2:cols, 2:2:rows);

    green_full_1 = interp2(X_green_1, Y_green_1, mosaic(1:2:end, 2:2:end), ...
        X_full, Y_full, 'linear', 0);
    green_full_2 = interp2(X_green_2, Y_green_2, mosaic(2:2:end, 1:2:end), ...
        X_full, Y_full, 'linear', 0);

    green_full = (green_full_1 + green_full_2) / 2;

    [X_blue, Y_blue] = meshgrid(2:2:cols, 2:2:rows);
    blue_full = interp2(X_blue, Y_blue, mosaic(2:2:end, 2:2:end), ...
        X_full, Y_full, 'linear', 0);

    rgb_image = cat(3, red_full, green_full, blue_full);
    rgb_image = max(0, min(1, rgb_image));
end
