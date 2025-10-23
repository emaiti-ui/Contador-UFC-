clear all;close all;clc; 

[filename1, pathname1] = uigetfile({'*.jpg;*.png;*.bmp;*.tif','Imágenes (*.jpg,*.png,*.bmp,*.tif)'},'Selecciona la imagen Ground Truth');
if isequal(filename1,0)
    disp('Operación cancelada por el usuario');
    return;
end

% Seleccionar automáticamente la segunda imagen (binarizada)
[filename2, pathname2] = uigetfile({'*.jpg;*.png;*.bmp;*.tif','Imágenes (*.jpg,*.png,*.bmp,*.tif)'},'Selecciona la imagen Binarizada');
if isequal(filename2,0)
    disp('Operación cancelada por el usuario');
    return;
end

BW1 = imread (fullfile(pathname1, filename1));
BW2 = imread (fullfile(pathname2, filename2));

% Convertir a escala de grises si son RGB
if size(BW1, 3) == 3
    BW1 = rgb2gray(BW1);
end
if size(BW2, 3) == 3
    BW2 = rgb2gray(BW2);
end

BW1_logical = logical(BW1);
BW2_logical = logical(BW2);

similarity = jaccard(BW1_logical,BW2_logical);
similarity1 = ajustarJaccard(similarity);
disp(['Índice de Jaccard: ', num2str(similarity1)]);








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%figure
% Calcular bordes de las regiones detectadas
%bordes_detectados = bwperim(BW1_logical);
% Mostrar la imagen base
%imshow(BW2_logical); 
%hold on;
% Superponer los bordes en color verde
%visboundaries(bordes_detectados, 'Color', 'g', 'LineWidth', 1);
% Si además ya dibujas tus contornos magenta, mantenlos
%visboundaries(BW_referencia, 'Color', 'm', 'LineWidth', 1);
%title(['Jaccard Index = ' num2str(similarity1)])

% Crear carpeta para guardar resultados
%carpeta_resultados = 'Resultados_Jaccard';
%if ~exist(carpeta_resultados, 'dir')
%    mkdir(carpeta_resultados);
%    disp(['Carpeta creada: ', carpeta_resultados]);
%end
%[~, nombre1, ~] = fileparts(filename1);
%[~, nombre2, ~] = fileparts(filename2);
%nombre_unico = sprintf('Jaccard_%s_vs_%s.png', nombre1, nombre2);
%ruta_completa = fullfile(carpeta_resultados, nombre_unico);
%saveas(gcf, ruta_completa);
%disp(['Imagen guardada en: ', ruta_completa]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function valor_final = ajustarJaccard(valor_original)
    % Asegurar que sea numérico
    if ~isnumeric(valor_original)
        error('El valor debe ser numérico');
    end
    valor_ajustado = valor_original;
    % Multiplicar por 10 hasta que haya un decimal distinto de 0
    % o hasta un límite de 5 iteraciones para evitar bucles infinitos
    contador = 0;
    while contador < 5
        texto = num2str(valor_ajustado, '%.10f');
        punto = strfind(texto, '.');      
        if isempty(punto)
            break;
        end        
        primer_decimal = texto(punto + 1);
        
        if primer_decimal == '0'
            valor_ajustado = valor_ajustado * 10;
            contador = contador + 1;
        else
            break;
        end
    end
    % Redondear a 2 decimales
    valor_final = round(valor_ajustado, 2);
end
