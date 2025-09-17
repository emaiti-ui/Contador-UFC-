clear all;close all;clc
%% FASE GENERAL O 0: LECTURA AUTOMÁTICA
fprintf('Selecciona las imágenes que deseas procesar...\n');
[archivos, ruta] = uigetfile({'*.jpg;*.png;*.bmp', 'Imágenes'}, 'Selecciona imágenes', 'MultiSelect', 'on');
if isequal(archivos, 0), disp('No se seleccionaron archivos');return; end
if ~iscell(archivos), archivos = {archivos}; end

respuesta = questdlg('¿Deseas guardar las figuras?', 'Guardar figuras', 'Sí', 'No', 'No');
guardar_figuras = strcmp(respuesta, 'Sí');
if guardar_figuras
    carpeta_resultados = 'Resultados_Analisis';
    if ~exist(carpeta_resultados, 'dir'), mkdir(carpeta_resultados); end
end

function guardarFigura(guardar, carpeta, nombre, sufijo, es_binaria, matriz)
    if guardar
        if es_binaria
            imwrite(matriz, fullfile(carpeta, sprintf('%s_%s.jpg', nombre, sufijo)));
        else
            saveas(gcf, fullfile(carpeta, sprintf('%s_%s.jpg', nombre, sufijo)));
        end
    end
end

for i = 1:length(archivos)
    fprintf('Procesando %d/%d: %s\n', i, length(archivos), archivos{i});
    [~, nombre_base, ~] = fileparts(archivos{i});

%% FASE 1: LECTURA Y SEGMENTACIÓN
Im_color = imread(fullfile(ruta, archivos{i}));

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
I_original_limpia = I_segmentada;
%figure(i + 1);
%imshow(I_segmentada);
title("Imagen Original")
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '01_original', true, I_original_limpia);

%% FASE 2: CONVERSIÓN A ESCALA DE GRISES Y BINARIZACIÓN
Ig = rgb2gray(I_segmentada);
%figure(i + 2);
%imshow(Ig);
title('Imagen en Escala de Grises');
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '02_grises', true, Ig);

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

%figure(i + 3)
%imshow(Mask)
title("Mascara a aplicar")
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '03_mascara',true, Mask);

for y=1:m
    for x=1:n
    Im_color(y,x) = Im_color(y,x)*Mask(y,x);
    end
end
Im_gris = rgb2gray(Im_color);
Im_gris2 = medfilt2(Im_gris,[7 7]);
BW = imbinarize(Im_gris2,0.7);
%figure(i + 4)
%imshow(BW)
title("Imagen Binarizada")
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '04_binarizada', true, BW);

%% FASE 3: IDENTIFICACIÓN Y CONTEO
% etiquetar colonias circulares
[colonias, ~] = bwlabel(BW);
stats = regionprops(colonias, 'Area', 'Centroid', 'Perimeter');

% Análisis básico automático
areas = [stats.Area];
if isempty(areas), fprintf('No hay objetos\n'); continue; end

% Filtros automáticos simples
area_promedio = mean(areas);
area_min = area_promedio * 0.3;  
area_max = area_promedio * 12;    
perimetros = [stats.Perimeter];
circularidad = 4 * pi * areas ./ (perimetros.^2);

% Seleccionar objetos válidos
validas = (areas >= area_min) & (areas <= area_max) & (circularidad >= 0.15);
colonias_finales = stats(validas);
areas_ok = [colonias_finales.Area];

% Encontrar tamaño de colonia individual (más simple)
areas_ordenadas = sort(areas_ok);
colonia_individual = areas_ordenadas(round(length(areas_ordenadas)*0.15)); % 30% más pequeña

% Contar círculos
conteo_total = 0;
for i = 1:length(areas_ok)
    ratio = areas_ok(i) / colonia_individual;
    if ratio > 1.4
        num_circulos = round(ratio);
        %num_circulos = min(num_circulos, 4); % Máximo 4 por objeto
    else
        num_circulos = 1;
    end
    conteo_total = conteo_total + num_circulos;
end

fprintf('Detectados: %d objetos -> %d círculos\n', length(colonias_finales), conteo_total);

%% FASE 4: ETIQUETADO
% Mostrar imagen con etiquetas
%figure(i + 5);
imshow(I_segmentada);
Etiquetado = I_segmentada;
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
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '05_Resultado', false, Etiquetado);

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

fprintf('\nProcesadas %d imágenes\n', length(archivos));
if guardar_figuras
    fprintf('Todas las figuras guardadas en: %s\n', carpeta_resultados);
end
end
%thank you!