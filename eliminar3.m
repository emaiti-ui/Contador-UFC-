clear all;
close all;
clc;

Im_color = imread("sp11_img01.jpg");

[alto, ancho, canales] = size(Im_color);

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

I_segmentada = Im_color;
for canal = 1:canales
    I_segmentada(:,:,canal) = Im_color(:,:,canal) .* uint8(mascara);
end

figure(1);
imshow(I_segmentada);

Ig = rgb2gray(I_segmentada);
figure(2);
imshow(Ig);
title('Imagen en Escala de Grises');

[m n c] = size(Im_color);
Mask = ones(m,n);

centro_x = n/2;
centro_y = m/2;
radio = centro_y*0.83;

for y=1:m
    for x=1:n
    distancia = sqrt((centro_x-x)^2 + (centro_y-y)^2);

    if distancia > radio
        Mask(y,x) = 0;
    end
    end
end

figure(3)
imshow(Mask)

for y=1:m
    for x=1:n
    Im_color(y,x) = Im_color(y,x)*Mask(y,x);
    end
end
Im_gris = rgb2gray(Im_color);
Im_gris2 = medfilt2(Im_gris,[7 7]);
BW = imbinarize(Im_gris2,0.75);
figure(4)
imshow(BW)

%% Para colonias muy pegadas
se_erosion = strel('disk', 3);  % Erosión más fuerte
BW_erosionado = imerode(BW, se_erosion);
BW_separado = imdilate(BW_erosionado, strel('disk', 9));  % Dilatación menor
figure(5)
imshow(BW_separado)
%%
% etiquetar colonias circulares
[colonias, ~] = bwlabel(BW_separado);
stats = regionprops(colonias, 'Area', 'Centroid', 'Perimeter');

% Filtros básicos
areas = [stats.Area];
perimetros = [stats.Perimeter];
circularidad = 4 * pi * areas ./ (perimetros.^2);

% Identificar colonias válidas (círculos)
validas = (areas >= 5) & (areas >= 2500) & (circularidad >= 0);
colonias_finales = stats(validas);

% Mostrar imagen con etiquetas
figure(6);
imshow(I_segmentada);
hold on;

for i = 1:length(colonias_finales)
    centro = colonias_finales(i).Centroid;
    area = colonias_finales(i).Area;
    radio = sqrt(area / pi);
    
    % Crear puntos del círculo
    theta = linspace(0, 2*pi, 50);
    x_circulo = centro(1) + radio * cos(theta);
    y_circulo = centro(2) + radio * sin(theta);
    
    % Dibujar círculo y número
    plot(x_circulo, y_circulo, 'r-', 'LineWidth', 2);
    text(centro(1) + radio + 10, centro(2), num2str(i), ...
         'Color', 'red', 'FontSize', 12, 'FontWeight', 'bold');
end

title(['Total: ' num2str(length(colonias_finales)) ' colonias']);
hold off;
