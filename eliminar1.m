close all;clear all;clc
%% FASE 1: LECTURA Y SEGMENTACIÓN
%Lee imagen a color y obtiene sus dimensiones
Im_color = imread("sp11_img02.jpg");
figure(1)
imshow(Im_color)
% Muestra y guarda la imagen original limpia
title("Imagen Original")


%% FASE 2: CONVERSIÓN A ESCALA DE GRISES Y BINARIZACIÓN
% Convierte a escala de grises para simplificar el procesamiento
Ig = rgb2gray(Im_color);
figure(2);
imshow(Ig);
title('Imagen en Escala de Grises');

[m n c] = size(Im_color);
Mask = ones(m,n); % Inicializa máscara como matriz de unos
Im_gris = rgb2gray(Im_color);

promedio = 0;
contador =0;
for i=1:100
    for j=1:100
        promedio = promedio + double(Im_gris(i,j));
        contador = contador +1;
    end
end
promedio = promedio/contador; % el fondo en imagenes como prueba3 es de aprox 200 y para prueba 3 es de 120.
figure(2)
   imshow(Im_gris)

if (promedio < 100)
centro_x = n/2;
centro_y = m/2;
radio = centro_y*0.7;

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
    Im_gris(y,x) = Im_gris(y,x)*Mask(y,x); % Multiplica por máscara
    end
end
figure(4)
imshow(Im_gris)
Im_gris2 = medfilt2(Im_gris,[7 7]);
    BW = imbinarize(Im_gris2,0.75);
figure(5)
imshow(BW)

%% DB2
else 
for y=1:m
    for x=1:n
    if Im_gris(y,x) < 150
            Im_gris(y,x) = 200;
    end
    end
end
Im_gris = imcomplement(Im_gris);
figure(2)
imshow(Im_gris)

Im_gris2 = medfilt2(Im_gris,[7 7]); % Aplica filtro mediano 7x7 para reducir ruido

if promedio > 160
    BW = imbinarize(Im_gris2,0.31);  %Para imagen prueba2.jpg
else
    BW = imbinarize(Im_gris2,0.35);  %Para imagen prueba3.jpg
end
se = strel('disk',21);
BW = imopen(BW,se);
BW = imclose(BW,se);
BW = imfill(BW,'holes');
figure(3)
imshow(BW)
title("Imagen Binarizada")
end




%% FASE 3: IDENTIFICACIÓN Y CONTEO
% etiquetar colonias circulares
% Identifica objetos separados en la imagen binaria
[colonias, ~] = bwlabel(BW); % Etiqueta cada objeto con un número único

% Extrae propiedades geométricas de cada objeto detectado
stats = regionprops(colonias, 'Area', 'Centroid', 'Perimeter');

% Análisis básico automático
areas = [stats.Area]; % Extrae todas las áreas en un vector

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
figure(5);
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

fprintf('Gracias por usar el analizador de colonias!\n');
%thank you!






























































