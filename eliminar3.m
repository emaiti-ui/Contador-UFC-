clear all;
close all;
clc;

%% FASE 1: LECTURA Y SEGMENTACIÓN
Im_color = imread("sp11_img01.jpg");

[alto, ancho, canales] = size(Im_color);

% Crear máscara circular de la caja Petri
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
title("Imagen Original")

%% FASE 2: CONVERSIÓN A ESCALA DE GRISES Y BINARIZACIÓN
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
title("Mascara a aplicar")

for y=1:m
    for x=1:n
    Im_color(y,x) = Im_color(y,x)*Mask(y,x);
    end
end
Im_gris = rgb2gray(Im_color);
Im_gris2 = medfilt2(Im_gris,[7 7]);
BW = imbinarize(Im_gris2,0.70);
figure(4)
imshow(BW)
title("Imagen Binarizada")

%% FASE 3: IDENTIFICACIÓN Y CONTEO
% etiquetar colonias circulares
[colonias, ~] = bwlabel(BW);
stats = regionprops(colonias, 'Area', 'Centroid', 'Perimeter');

% Filtros básicos
areas = [stats.Area];
perimetros = [stats.Perimeter];
circularidad = 4 * pi * areas ./ (perimetros.^2);

% Identificar colonias válidas (círculos)
validas = (areas >= 5) & (areas >= 2500) & (circularidad >= 0);
colonias_finales = stats(validas);

areas_validas = [colonias_finales.Area];
area_promedio = median(areas_validas);
umbral_doble = area_promedio * 1.6; % Factor para detectar superposición

% Detectar y ajustar conteo
conteo_ajustado = 0;
for i = 1:length(colonias_finales)
    area_actual = colonias_finales(i).Area;
    if area_actual > umbral_doble
        % Círculo superpuesto -> contar como 2
        num_circulos = round(area_actual / area_promedio);
        conteo_ajustado = conteo_ajustado + num_circulos;
        fprintf('Círculo %d: %d píxeles -> %d círculos superpuestos\n', i, area_actual, num_circulos);
    else
        % Círculo individual
        conteo_ajustado = conteo_ajustado + 1;
    end
end

fprintf('Conteo original: %d | Conteo ajustado: %d\n', length(colonias_finales), conteo_ajustado);

%% FASE 4: ETIQUETADO
% Mostrar imagen con etiquetas
figure(5);
imshow(I_segmentada);
hold on;

areas_validas = [colonias_finales.Area];
area_ref = median(areas_validas);
umbral = area_ref * 1.6;

conteo_total = 0;
for i = 1:length(colonias_finales)
    centro = colonias_finales(i).Centroid;
    area = colonias_finales(i).Area;
    radio = sqrt(area / pi);
    
    % Detectar superposición
    num_circulos = (area > umbral) * round(area/area_ref) + (area <= umbral);
    conteo_total = conteo_total + num_circulos;
    
    % Crear círculo visual
    theta = linspace(0, 2*pi, 50);
    x_circulo = centro(1) + radio * cos(theta);
    y_circulo = centro(2) + radio * sin(theta);
    
    % Color según tipo: rojo=superpuesto, verde=individual
    color = {'g-', 'r-'}; texto_color = {'green', 'red'};
    plot(x_circulo, y_circulo, color{1+(num_circulos>1)}, 'LineWidth', 2);
    
    % Etiqueta con número detectado
    if num_circulos > 1
        etiqueta = sprintf('%dx', num_circulos);
    else
        etiqueta = sprintf('%d', i);
    end
    text(centro(1) + radio + 8, centro(2), etiqueta, ...
         'Color', texto_color{1+(num_circulos>1)}, 'FontSize', 11, 'FontWeight', 'bold');
end

title(['Detectados: ' num2str(conteo_total) ' círculos (' num2str(length(colonias_finales)) ' objetos)']);

individuales = sum([colonias_finales.Area] <= umbral);
superpuestos = sum([colonias_finales.Area] > umbral);
area_promedio = mean([colonias_finales.Area]);
densidad = conteo_total / (size(I_segmentada,1) * size(I_segmentada,2)) * 100000;

stats_text = sprintf(['Objetos: %d | Individuales: %d | Superpuestos: %d\n' ...
    'Total círculos: %d | Área prom: %.0f px² | Superposición: %.1f%%'], ...
    length(colonias_finales), individuales, superpuestos, conteo_total, ...
    area_promedio, (superpuestos/length(colonias_finales))*100);

text(15, 90, stats_text, 'BackgroundColor', [0.95 0.98 1], 'EdgeColor', [0.3 0.5 0.8], ...
    'FontSize', 8, 'FontWeight', 'bold', 'LineWidth', 1);

hold off;