clear all; close all; clc


%% 1. Cargar imagen
I = imread("sp11_img01.jpg");
[alto, ancho, ~] = size(I);

%% 2. Crear máscara circular
X = ancho/2;
Y = alto/2;
R = min(ancho,alto)/2 * 0.85;

mascara = zeros(alto, ancho);
for x = 1:ancho
    for y = 1:alto
        d = sqrt((x - X)^2 + (y - Y)^2);
        if d <= R
            mascara(y, x) = 1;
        end
    end
end

% Aplicar máscara
I_segmentada = I;
for canal = 1:3
    I_segmentada(:,:,canal) = I(:,:,canal) .* uint8(mascara);
end

figure()
imshow(I_segmentada)

Ig = rgb2gray(I_segmentada);
figure();
imshow(Ig);
title('Imagen en Escala de Grises');


%código existente...
Ig = adapthisteq(Ig, "NumTiles", [16 16],"ClipLimit",0.09,"Distribution","exponential");
mejorada = imadjust(Ig);
figure(3)
imshow(Ig)
IgB = imbinarize(Ig,"adaptive","ForegroundPolarity","dark","Sensitivity",0.79);
figure(4)
imshow(IgB)
Negativo = 1 - IgB;
figure(5)
imshow(Negativo)

% Tu código existente hasta obtener el Negativo...
Ig = adapthisteq(Ig, "NumTiles", [16 16],"ClipLimit",0.09,"Distribution","exponential");
mejorada = imadjust(Ig);
IgB = imbinarize(Ig,"adaptive","ForegroundPolarity","dark","Sensitivity",0.79);
IgB_limpia = bwareaopen(IgB, 100);
Negativo = 1 - IgB;






