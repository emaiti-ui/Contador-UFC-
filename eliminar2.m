clear all;
close all;
clc;

% Cargar y preparar imagen
I = imread("sp11_img01.jpg");
[alto, ancho, canales] = size(I);

% Crear máscara circular de la Petri
X = ancho/2;    
Y = alto/2;     
R = min(ancho,alto)/2 * 0.85;  

mascara = zeros(alto, ancho);
for x = 1:ancho
    for y = 1:alto
        d = sqrt((x - X)^2 + (y - Y)^2);
        if d <= R  
            mascara(y, x) = 1;  
        else
            mascara(y, x) = 0;  
        end
    end
end

I_segmentada = I;
for canal = 1:canales
    I_segmentada(:,:,canal) = I(:,:,canal) .* uint8(mascara);
end

Ig = rgb2gray(I_segmentada);
figure();
imshow(Ig);
title('Imagen en Escala de Grises');
