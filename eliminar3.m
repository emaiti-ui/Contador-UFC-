clear all;
close all;
clc;

I = imread("sp11_img01.jpg");
[alto, ancho, canales] = size(I);

X = ancho/2;    % Centro X (por defecto: centro de la imagen)
Y = alto/2;     % Centro Y (por defecto: centro de la imagen)
R = min(ancho,alto)/2 * 0.85;  % Radio (porcentaje radio máximo posible)

mascara = zeros(alto, ancho);

for x = 1:ancho
    for y = 1:alto
        d = sqrt((x - X)^2 + (y - Y)^2);
        if d <= R  % Cambiado a <= para que dentro sea 1
            mascara(y, x) = 1;  % Blanco dentro
        else
            mascara(y, x) = 0;  % Negro fuera
        end
    end
end
I_segmentada = I;
for canal = 1:canales
    I_segmentada(:,:,canal) = I(:,:,canal) .* uint8(mascara);
end
figure(1);
imshow(I_segmentada);
title('Mi imagen original');

Ig= rgb2gray(I_segmentada);
figure(2);
imshow(Ig);
title('Imagen en escala de grises');

Ig = adapthisteq(Ig, "NumTiles", [16 16],"ClipLimit",0.09,"Distribution","exponential");
mejorada = imadjust(Ig);
figure(3)
imshow(Ig)

IgB = imbinarize (Ig,"adaptive","ForegroundPolarity","dark","Sensitivity",0.79);
figure(4)
imshow(IgB)

Negativo = 1 - IgB;
figure(5)
imshow(Negativo)

%%
% elimina ruido (puntos que no son colonias)
%suave = medfilt2(mejorada); 
%suave = imgaussfilt(mejorada, 3);
%figure(3);
%imshow(suave);
%title('Imagen más suave');
%bordes = edge(Ig, 'Canny');
%figure(4);
%imshow(bordes);
%title('Bordes detectados');
