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

umbral = 175;  % Ajusta este valor según tu imagen (0-255)
mascara = Ig < umbral;  % Los círculos oscuros serán 1 (blanco)

% Limpiar ruido pequeño
mascara = bwareaopen(mascara, 50);  % Elimina objetos menores a 50 píxeles

% Aplicar la máscara para resaltar colonias
I_resaltado = I_segmentada;
for canal = 1:3
    temp = I_segmentada(:,:,canal);
    temp(~mascara) = temp(~mascara) * 0.3;  % Oscurecer fondo
    temp(mascara) = min(temp(mascara) * 1.5, 255);  % Resaltar colonias
    I_resaltado(:,:,canal) = temp;
end

figure(1)
imshow(I_resaltado)