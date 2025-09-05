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

% Optimización de la identificación de colonias
[colonias, numero] = bwlabel(BW);

% Obtener propiedades de todas las regiones
stats = regionprops(colonias, 'Area', 'Centroid', 'Perimeter', 'Eccentricity');

% Filtros simples y efectivos
areas = [stats.Area];
perimetros = [stats.Perimeter];
excentricidades = [stats.Eccentricity];

% Calcular circularidad
circularidad = 4 * pi * areas ./ (perimetros.^2);

% Filtrar colonias válidas con criterios optimizados
validas = (areas >= 50) & ...         
          (areas <= 5000) & ...         
          (circularidad >= 0.5) & ...   
          (excentricidades <= 0.8);      

% Aplicar filtros
stats_validas = stats(validas);
numero_colonias = sum(validas);

% Eliminar duplicados por proximidad
if numero_colonias > 1
    centroides = reshape([stats_validas.Centroid], 2, [])';
    mantener = true(numero_colonias, 1);
    
    for i = 1:numero_colonias-1
        if mantener(i)
            distancias = sqrt(sum((centroides(i+1:end,:) - centroides(i,:)).^2, 2));
            duplicados = find(distancias < 30) + i;  % Distancia mínima 25 píxeles
            mantener(duplicados) = false;
        end
    end
    
    stats_finales = stats_validas(mantener);
    numero_final = sum(mantener);
else
    stats_finales = stats_validas;
    numero_final = numero_colonias;
end

figure(5)
imshow(label2rgb(colonias, 'jet', 'k', 'shuffle'));
title(['Colonias encontradas: ' num2str(numero)]);

% Visualización
figure(6);
imshow(I_segmentada);
hold on;
for i = 1:numero_final
    centro = stats_finales(i).Centroid;
    plot(centro(1), centro(2), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    text(centro(1)+30, centro(2), num2str(i), 'Color', 'red', 'FontSize', 8);
end
title(['Colonias identificadas: ' num2str(numero_final)]);
hold off;
