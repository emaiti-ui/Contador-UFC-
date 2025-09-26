clear all;close all;clc

%% FASE INICIAL O 0: LECTURA DE IMAGENES

%Seleccionar multiples imagenes
fprintf('Selecciona las imágenes que deseas procesar...\n');

%Ventana de dialogo para seleccionar archivos
[archivos, ruta] = uigetfile({'*.jpg;*.png;*.bmp', 'Imágenes'}, 'Selecciona imágenes', 'MultiSelect', 'on');

%Verifica si se seleccionaron archivos
if isequal(archivos, 0), disp('No se seleccionaron archivos');return; end

%Si solo se selecciono un archivo
if ~iscell(archivos), archivos = {archivos}; end

%Pregunta al ausuario si desea guardar las figuras
respuesta = questdlg('¿Deseas guardar las figuras?', 'Guardar figuras', 'Sí', 'No', 'No');
guardar_figuras = strcmp(respuesta, 'Sí');

%Crea carpeta de resultados si se eligio guardar
if guardar_figuras
    carpeta_resultados = 'Resultados_Analisis';
    if ~exist(carpeta_resultados, 'dir'), mkdir(carpeta_resultados); end
end

%Funcion auxiliar para guardar figuras o imagenes
function guardarFigura(guardar, carpeta, nombre, sufijo, es_binaria, matriz)
    if guardar
        if es_binaria
            %Guarda matriz de imagen
            imwrite(matriz, fullfile(carpeta, sprintf('%s_%s.jpg', nombre, sufijo)));
        else
            %Guarda la figura actual
            saveas(gcf, fullfile(carpeta, sprintf('%s_%s.jpg', nombre, sufijo)));
        end
    end
end

%Bucle principal
for i = 1:length(archivos)
    fprintf('Procesando %d/%d: %s\n', i, length(archivos), archivos{i});
    [~, nombre_base, ~] = fileparts(archivos{i}); %Extrae nombre sin extension 

%% FASE 1: LECTURA Y SEGMENTACIÓN
%Lee imagen a color y obtiene sus dimensiones
Im_color = imread(fullfile(ruta, archivos{i}));

[m n c] = size(Im_color)
Mask = ones(m,n);

Im_gris = rgb2gray(Im_color);
%figure(1)
%   imshow(Im_color)
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '01_original', true, Im_color);
% Calcular el promedio de un recuadro superior derecho para saber el tono del fondo

promedio = 0;
contador =0;
for i=1:100
    for j=1:100
        promedio = promedio + double(Im_gris(i,j));
        contador = contador +1;
    end
end
promedio = promedio/contador % el fondo en imagenes como prueba3 es de aprox 200 y para prueba 3 es de 120.

%si la imagen es de la primer base de datos se ejecuta esta parte

if (promedio < 100)
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
 %   figure(2)
 %       imshow(Mask)
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '02_mascara', true, Mask);
    for y=1:m
        for x=1:n
            Im_gris(y,x) = Im_gris(y,x)*Mask(y,x);
        end
    end
%   figure(3)
 %       imshow(Im_gris)
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '03_grises', true, Im_gris);
    Im_gris2 = medfilt2(Im_gris,[7 7]);
    BW = imbinarize(Im_gris2,0.75);

%    figure(4)
%        imshow(BW)
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '04_Binarizada', true, BW);

% si la imagen es de la otra base de datos se ejecuta esta parte
else
    for y=1:m
        for x=1:n
            if Im_gris(y,x) < 150
                Im_gris(y,x) = 200;
            end
        end
    end
    guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '02_grises', true, Im_gris);
    Im_gris = imcomplement(Im_gris);
 %   figure(2)
 %       imshow(Im_gris)
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '03_negativo', true, Im_gris);    
    Im_gris2 = medfilt2(Im_gris,[7 7]);

    if promedio > 160
        BW = imbinarize(Im_gris2,0.3);  %Para imagen prueba2.jpg
    else
        BW = imbinarize(Im_gris2,0.36);  %Para imagen prueba3.jpg
    end
    se = strel('disk',21);
    BW = imopen(BW,se);
    BW = imclose(BW,se);
    BW = imfill(BW,'holes');
%    figure(3)
%    imshow(BW)
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '03_Binarizada', true, BW);
end

%% FASE 3: IDENTIFICACIÓN Y CONTEO
% etiquetar colonias circulares
% Identifica objetos separados en la imagen binaria
[colonias, ~] = bwlabel(BW); % Etiqueta cada objeto con un número único

% Extrae propiedades geométricas de cada objeto detectado
stats = regionprops(colonias, 'Area', 'Centroid', 'Perimeter');

% Análisis básico automático
areas = [stats.Area]; % Extrae todas las áreas en un vector
if isempty(areas), fprintf('No hay objetos\n'); continue; end

% Filtros automáticos simples
area_promedio = mean(areas);
area_min = area_promedio * 0.3; % 30% del promedio 
area_max = area_promedio * 12;  %12 veces el promedio  
perimetros = [stats.Perimeter];
circularidad = 4 * pi * areas ./ (perimetros.^2);

% Seleccionar objetos válidos
validas = (areas >= area_min) & (areas <= area_max) & (circularidad >= 0.15);
colonias_finales = stats(validas); % Mantiene solo objetos válidos
areas_ok = [colonias_finales.Area]; % Áreas de colonias válidas

% Encontrar tamaño de colonia individual (más simple)
areas_ordenadas = sort(areas_ok);
colonia_individual = areas_ordenadas(round(length(areas_ordenadas)*0.15)); % 30% más pequeña

% Contar círculos
% Si un objeto es mucho más grande que una colonia individual, probablemente contiene múltiples colonias
conteo_total = 0;
for i = 1:length(areas_ok)
    ratio = areas_ok(i) / colonia_individual;
    if ratio > 1.4 % Si es 40% más grande, probablemente hay superposición
        num_circulos = round(ratio);  % Estima número de colonias superpuestas    
    else
        num_circulos = 1;
    end
    conteo_total = conteo_total + num_circulos;
end

fprintf('Detectados: %d objetos -> %d círculos\n', length(colonias_finales), conteo_total);

%% FASE 4: ETIQUETADO
% Mostrar imagen con etiquetas
%figure(i + 5);
imshow(Im_color);
Etiquetado = Im_color;
hold on; % Permite dibujar sobre la imagen

areas_validas = [colonias_finales.Area];
area_ref = median(areas_validas);
umbral = area_ref * 1.6; % Umbral para detectar superposiciones

% Dibujo de circulos y etiquetas
conteo_total = 0;
for i = 1:length(colonias_finales)
    centro = colonias_finales(i).Centroid;
    area = colonias_finales(i).Area;
    radio = sqrt(area / pi);
    
    % Detectar superposición
    num_circulos = (area > umbral) * round(area/area_ref) + (area <= umbral);
    conteo_total = conteo_total + num_circulos;
    
    % Crear círculo visual
    theta = linspace(0, 2*pi, 50); % 50 puntos para círculo suave
    x_circulo = centro(1) + radio * cos(theta);
    y_circulo = centro(2) + radio * sin(theta);
    
    % Color según tipo: rojo=superpuesto, verde=individual
    color = {'g-', 'r-'}; texto_color = {'green', 'red'};
    plot(x_circulo, y_circulo, color{1+(num_circulos>1)}, 'LineWidth', 2);
    
    % Etiqueta con número detectado
    if num_circulos > 1
        etiqueta = sprintf('%dx', num_circulos);
    else
        etiqueta = sprintf('%d', i); % Número secuencial
    end
    % Posiciona texto fuera del círculo para mejor visibilidad
    text(centro(1) + radio + 8, centro(2), etiqueta, ...
         'Color', texto_color{1+(num_circulos>1)}, 'FontSize', 11, 'FontWeight', 'bold');
end

title(['Detectados: ' num2str(conteo_total) ' círculos (' num2str(length(colonias_finales)) ' objetos)']);

individuales = sum([colonias_finales.Area] <= umbral);
superpuestos = sum([colonias_finales.Area] > umbral);
area_promedio = mean([colonias_finales.Area]);
densidad = conteo_total / (size(Im_color,1) * size(Im_color,2)) * 100000;

% Cuadro de estadisticas 
stats_text = sprintf(['Objetos: %d | Individuales: %d | Superpuestos: %d\n' ...
    'Total círculos: %d | Área prom: %.0f px² | Superposición: %.1f%%'], ...
    length(colonias_finales), individuales, superpuestos, conteo_total, ...
    area_promedio, (superpuestos/length(colonias_finales))*100);

% Dibuja cuadro de texto con estadísticas en la esquina superior izquierda
text(15, 90, stats_text, 'BackgroundColor', [0.95 0.98 1], 'EdgeColor', [0.3 0.5 0.8], ...
    'FontSize', 8, 'FontWeight', 'bold', 'LineWidth', 1);

hold off; % Termina el modo de dibujo sobre imagen

% Guarda la imagen final con análisis
guardarFigura(guardar_figuras, carpeta_resultados, nombre_base, '_Resultado', false, Im_color);

%Mensaje final y limpieza
fprintf('\nProcesadas %d imágenes\n', length(archivos));
if guardar_figuras
    fprintf('Todas las figuras guardadas en: %s\n', carpeta_resultados);
end

end % Fin del bucle principal de procesamiento
fprintf('Gracias por usar el analizador de colonias!\n');
%thank you!