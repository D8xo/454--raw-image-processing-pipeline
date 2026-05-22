// Project 0 - RAW Image Processing Pipeline

//              1. Initials
raw = imread('C:\Users\320316331\Downloads\Project0-2\Project0\data\banana_slug.tiff');

[Ysize, Xsize] = size(raw)
class(raw)

raw = double(raw);

//              2. Linearization
black = 2047;
saturation = 15000;

lin = (raw - black) / (saturation - black);
lin = max(0, min(1, lin));

//              3. Identify Bayer Pattern
pattern = 'rggb';

//             4. White Balance
R = lin(1:2:end, 1:2:end);
G1 = lin(1:2:end, 2:2:end);
G2 = lin(2:2:end, 1:2:end);
B = lin(2:2:end, 2:2:end);

G = (G1 + G2) / 2;

wb_gray = lin;
wb_gray(1:2:end, 1:2:end) = R * (mean(G(:)) / mean(R(:)));
wb_gray(2:2:end, 2:2:end) = B * (mean(G(:)) / mean(B(:)));

wb_white = lin;
wb_white(1:2:end, 1:2:end) = R * (max(G(:)) / max(R(:)));
wb_white(2:2:end, 2:2:end) = B * (max(G(:)) / max(B(:)));

//             5. Demosaicing
[rows, cols] = size(wb_gray);
[Xq, Yq] = meshgrid(1:cols, 1:rows);

[Xr, Yr] = meshgrid(1:2:cols, 1:2:rows);
Rvals = wb_gray(1:2:end, 1:2:end);
R_full = interp2(Xr, Yr, Rvals, Xq, Yq, 'linear', 0);

G_mosaic = zeros(rows, cols);
G_mosaic(1:2:end, 2:2:end) = wb_gray(1:2:end, 2:2:end);
G_mosaic(2:2:end, 1:2:end) = wb_gray(2:2:end, 1:2:end);

known_g = G_mosaic > 0;
G_full = griddata(Xq(known_g), Yq(known_g), G_mosaic(known_g), Xq, Yq, 'linear');
G_full = max(0, min(1, inpaintn(G_full)));

[Xb, Yb] = meshgrid(2:2:cols, 2:2:rows);
Bvals = wb_gray(2:2:end, 2:2:end);
B_full = interp2(Xb, Yb, Bvals, Xq, Yq, 'linear', 0);

rgb = cat(3, R_full, G_full, B_full);
rgb = max(0, min(1, rgb));

//            6. Gamma Correction
gray = 0.2126 * rgb(:,:,1) + 0.7152 * rgb(:,:,2) + 0.0722 * rgb(:,:,3);
scale = .25 / mean(gray(:));
rgb_bright = rgb * scale;
rgb_bright = max(0, min(1, rgb_bright));

rgb_gamma = zeros(size(rgb_bright));

mask = rgb_bright <= 0.0031308;
rgb_gamma(mask) = 12.92 * rgb_bright(mask);
rgb_gamma(~mask) = 1.055 * (rgb_bright(~mask) .^ (1/2.4)) - 0.055;

figure;
imshow(rgb_gamma);
title('Final Image')

//           7. Comp
imwrite(rgb_gamma, 'banana_slug.png');

imwrite(rgb_gamma, 'banana_slug_95.jpg', 'Quality', 95);

png_info = dir('banana_slug.png');
jpg_info = dir('banana_slug_95.jpg');

fprintf('PNG file size: %.2f MB\n', png_info.bytes / 1e6);
fprintf('JPEG file size: %.2f MB\n', jpg_info.bytes / 1e6);
fprintf('Compression ratio: %.2f\n', png_info.bytes / jpg_info.bytes);

for q = [75, 50, 25, 10]
    fname = sprintf('banana_slug_%d.jpg', q);
    imwrite(rgb_gamma, fname, 'Quality', q);
    info = dir(fname);
    fprintf('Quality %d: %.2f MB\n', q, info.bytes / 1e6);
end

