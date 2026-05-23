raw = imread('Project0/data/banana_slug.tiff');

[Ysize, Xsize] = size(raw)   
class(raw)                    

raw = double(raw);

BLACK_LEVEL = 2047;
SATURATION  = 15000;

linearized = (raw - BLACK_LEVEL) / (SATURATION - BLACK_LEVEL);
linearized = max(0, min(1, linearized));

R  = linearized(1:2:end, 1:2:end);
G1 = linearized(1:2:end, 2:2:end);
G2 = linearized(2:2:end, 1:2:end);
B  = linearized(2:2:end, 2:2:end);

G_ref = (G1 + G2) / 2;

wb_gray = linearized;
wb_gray(1:2:end, 1:2:end) = R * (mean(G_ref(:)) / mean(R(:)));
wb_gray(2:2:end, 2:2:end) = B * (mean(G_ref(:)) / mean(B(:)));

wb_white = linearized;
wb_white(1:2:end, 1:2:end) = R * (max(G_ref(:)) / max(R(:)));
wb_white(2:2:end, 2:2:end) = B * (max(G_ref(:)) / max(B(:)));

mosaic = wb_gray;

[rows, cols] = size(mosaic);
[Xfull, Yfull] = meshgrid(1:cols, 1:rows);

[Xr, Yr] = meshgrid(1:2:cols, 1:2:rows);
R_full = interp2(Xr, Yr, mosaic(1:2:end, 1:2:end), Xfull, Yfull, 'linear', 0);

G_sparse = zeros(rows, cols);
G_sparse(1:2:end, 2:2:end) = mosaic(1:2:end, 2:2:end);
G_sparse(2:2:end, 1:2:end) = mosaic(2:2:end, 1:2:end);

[Xg1, Yg1] = meshgrid(2:2:cols, 1:2:rows);
[Xg2, Yg2] = meshgrid(1:2:cols, 2:2:rows);
G1_full = interp2(Xg1, Yg1, mosaic(1:2:end, 2:2:end), Xfull, Yfull, 'linear', 0);
G2_full = interp2(Xg2, Yg2, mosaic(2:2:end, 1:2:end), Xfull, Yfull, 'linear', 0);
G_full = (G1_full + G2_full) / 2;

[Xb, Yb] = meshgrid(2:2:cols, 2:2:rows);
B_full = interp2(Xb, Yb, mosaic(2:2:end, 2:2:end), Xfull, Yfull, 'linear', 0);

rgb = max(0, min(1, cat(3, R_full, G_full, B_full)));


luminance = 0.2126 * rgb(:,:,1) + 0.7152 * rgb(:,:,2) + 0.0722 * rgb(:,:,3);
rgb_bright = min(1, rgb * (0.25 / mean(luminance(:))));

rgb_gamma = zeros(size(rgb_bright));
dark = rgb_bright <= 0.0031308;
rgb_gamma(dark)  = 12.92 * rgb_bright(dark);
rgb_gamma(~dark) = 1.055 * rgb_bright(~dark) .^ (1/2.4) - 0.055;

figure;
imshow(rgb_gamma);
title('Final Processed Image');

imwrite(rgb_gamma, 'banana_slug.png');
imwrite(rgb_gamma, 'banana_slug_95.jpg', 'Quality', 95);

png_info = dir('banana_slug.png');
jpg_info = dir('banana_slug_95.jpg');

fprintf('\n--- Compression Results ---\n');
fprintf('PNG size:          %.2f MB\n', png_info.bytes / 1e6);
fprintf('JPEG (q=95) size:  %.2f MB\n', jpg_info.bytes / 1e6);
fprintf('Compression ratio: %.2fx\n',   png_info.bytes / jpg_info.bytes);

fprintf('\nQuality sweep:\n');
for q = [75, 50, 25, 10]
    fname = sprintf('banana_slug_%d.jpg', q);
    imwrite(rgb_gamma, fname, 'Quality', q);
    info = dir(fname);
    fprintf('  q=%-3d  %.2f MB\n', q, info.bytes / 1e6);
end
