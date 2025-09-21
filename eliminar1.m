%% FASE 1: LECTURA Y SEGMENTACIÓN
%Lee imagen a color y obtiene sus dimensiones
Im_color = imread(fullfile(ruta, archivos{i}));
[alto, ancho, canales] = size(Im_color);


%% FASE 2: CONVERSIÓN A ESCALA DE GRISES Y BINARIZACIÓN
% Convierte a escala de grises para simplificar el procesamiento
Ig = rgb2gray(I_segmentada);
%figure(i + 2);
%imshow(Ig);
title('Imagen en Escala de Grises');