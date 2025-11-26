close all; clc;

% Pregunta si desea guardar resultados en Excel
respuesta_excel = questdlg('¿Deseas guardar los resultados en un archivo Excel?', ...
    'Guardar en Excel', 'Sí', 'No', 'Sí');
guardar_excel = strcmp(respuesta_excel, 'Sí');

% Crear o cargar archivo Excel si se eligió guardar
if guardar_excel
    nombre_excel = 'Resultados_Validacion.xlsx';
    
    % Encabezados completos con nuevas métricas (decimal y porcentaje)
    encabezados_completos = {'Fecha-Hora', 'Ground Truth', 'Imagen Binarizada', ...
                            'Jaccard Original', 'Jaccard Ajustado', ...
                            'TP', 'TN', 'FP', 'FN', ...
                            'Accuracy', 'Accuracy %', ...
                            'Precision', 'Precision %', ...
                            'Recall', 'Recall %', ...
                            'F1-Score', 'F1-Score %'};
    
    % Verificar si el archivo ya existe
    if exist(nombre_excel, 'file')
        respuesta_append = questdlg('El archivo Excel ya existe. ¿Deseas agregar nuevos datos o crear uno nuevo?', ...
            'Archivo Existente', 'Agregar', 'Nuevo', 'Cancelar', 'Agregar');
        
        if strcmp(respuesta_append, 'Cancelar')
            disp('Operación cancelada por el usuario');
            return;
        elseif strcmp(respuesta_append, 'Nuevo')
            % Crear nuevo archivo con encabezados completos
            writecell(encabezados_completos, nombre_excel, 'Sheet', 1, 'Range', 'A1');
            fila_actual = 2;
        else
            % Leer datos existentes
            datos_existentes = readcell(nombre_excel, 'Sheet', 1);
            encabezados_existentes = datos_existentes(1, :);
            fila_actual = size(datos_existentes, 1) + 1;
            
            % Verificar si hay nuevas columnas que agregar
            nuevas_columnas = {};
            for i = 1:length(encabezados_completos)
                if ~ismember(encabezados_completos{i}, encabezados_existentes)
                    nuevas_columnas{end+1} = encabezados_completos{i};
                end
            end
            
            % Si hay nuevas columnas, agregarlas
            if ~isempty(nuevas_columnas)
                fprintf('Se detectaron nuevas métricas: %s\n', strjoin(nuevas_columnas, ', '));
                fprintf('Agregando columnas al archivo existente...\n');
                
                col_actual = size(encabezados_existentes, 2) + 1;
                for i = 1:length(nuevas_columnas)
                    % Agregar encabezado de nueva columna
                    writecell({nuevas_columnas{i}}, nombre_excel, 'Sheet', 1, ...
                             'Range', sprintf('%s1', columnaLetra(col_actual)));
                    col_actual = col_actual + 1;
                end
                
                fprintf('Columnas agregadas exitosamente\n\n');
            end
        end
    else
        % Crear archivo nuevo con encabezados completos
        writecell(encabezados_completos, nombre_excel, 'Sheet', 1, 'Range', 'A1');
        fila_actual = 2;
    end
end

% Seleccionar imagen Ground Truth
[filename1, pathname1] = uigetfile({'*.jpg;*.png;*.bmp;*.tif','Imágenes (*.jpg,*.png,*.bmp,*.tif)'}, ...
    'Selecciona la imagen Ground Truth');
if isequal(filename1, 0)
    disp('Operación cancelada por el usuario');
    return;
end

% Seleccionar imagen Binarizada
[filename2, pathname2] = uigetfile({'*.jpg;*.png;*.bmp;*.tif','Imágenes (*.jpg,*.png,*.bmp,*.tif)'}, ...
    'Selecciona la imagen Binarizada');
if isequal(filename2, 0)
    disp('Operación cancelada por el usuario');
    return;
end

% Leer imágenes
BW1 = imread(fullfile(pathname1, filename1));
BW2 = imread(fullfile(pathname2, filename2));

% Convertir a escala de grises si son RGB
if size(BW1, 3) == 3
    BW1 = rgb2gray(BW1);
end
if size(BW2, 3) == 3
    BW2 = rgb2gray(BW2);
end

% Binarizar imágenes
BW1_logical = imbinarize(BW1);
BW2_logical = imbinarize(BW2);

%% CÁLCULO DE ÍNDICE DE JACCARD
similarity = jaccard(BW1_logical, BW2_logical);
similarity_ajustado = ajustarJaccard(similarity);

%% CÁLCULO DE MATRIZ DE CONFUSIÓN
TP = sum(BW1_logical(:) & BW2_logical(:));      % Verdaderos Positivos
TN = sum(~BW1_logical(:) & ~BW2_logical(:));    % Verdaderos Negativos
FP = sum(~BW1_logical(:) & BW2_logical(:));     % Falsos Positivos
FN = sum(BW1_logical(:) & ~BW2_logical(:));     % Falsos Negativos

% Calcular Accuracy
total_pixeles = numel(BW1_logical);
accuracy = (TP + TN) / total_pixeles;
accuracy_porcentaje = accuracy * 100;

%% CÁLCULO DE NUEVAS MÉTRICAS
% Precision: De todos los que predije como positivos, ¿cuántos acerté?
if (TP + FP) > 0
    precision = TP / (TP + FP);
else
    precision = 0;
end
precision_porcentaje = precision * 100;

% Recall (Sensibilidad): De todos los positivos reales, ¿cuántos detecté?
if (TP + FN) > 0
    recall = TP / (TP + FN);
else
    recall = 0;
end
recall_porcentaje = recall * 100;

% F1-Score: Media armónica entre Precision y Recall
if (precision + recall) > 0
    f1_score = 2 * (precision * recall) / (precision + recall);
else
    f1_score = 0;
end
f1_score_porcentaje = f1_score * 100;

%% MOSTRAR RESULTADOS EN CONSOLA
fprintf('\n========================================\n');
fprintf('RESULTADOS DE VALIDACIÓN\n');
fprintf('========================================\n');
fprintf('Ground Truth: %s\n', filename1);
fprintf('Imagen Binarizada: %s\n', filename2);
fprintf('\n--- ÍNDICE DE JACCARD ---\n');
fprintf('Jaccard Original: %.6f\n', similarity);
fprintf('Jaccard Ajustado: %.2f\n', similarity_ajustado);
fprintf('\n--- MATRIZ DE CONFUSIÓN ---\n');
fprintf('Verdaderos Positivos (TP): %d\n', TP);
fprintf('Verdaderos Negativos (TN): %d\n', TN);
fprintf('Falsos Positivos (FP): %d\n', FP);
fprintf('Falsos Negativos (FN): %d\n', FN);
fprintf('\n--- MÉTRICAS DE RENDIMIENTO ---\n');
fprintf('Accuracy: %.6f (%.2f%%)\n', accuracy, accuracy_porcentaje);
fprintf('Precision: %.6f (%.2f%%)\n', precision, precision_porcentaje);
fprintf('Recall: %.6f (%.2f%%)\n', recall, recall_porcentaje);
fprintf('F1-Score: %.6f (%.2f%%)\n', f1_score, f1_score_porcentaje);
fprintf('========================================\n\n');

%% GUARDAR EN EXCEL
if guardar_excel
    fecha_hora = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
    
    % Leer encabezados actuales del archivo
    datos_actuales = readcell(nombre_excel, 'Sheet', 1);
    encabezados_archivo = datos_actuales(1, :);
    
    % Crear mapeo de valores con nombres válidos para MATLAB
    valores_map = containers.Map();
    valores_map('Fecha-Hora') = char(fecha_hora);
    valores_map('Ground Truth') = filename1;
    valores_map('Imagen Binarizada') = filename2;
    valores_map('Jaccard Original') = similarity;
    valores_map('Jaccard Ajustado') = similarity_ajustado;
    valores_map('TP') = TP;
    valores_map('TN') = TN;
    valores_map('FP') = FP;
    valores_map('FN') = FN;
    valores_map('Accuracy') = accuracy;
    valores_map('Accuracy %') = accuracy_porcentaje;
    valores_map('Precision') = precision;
    valores_map('Precision %') = precision_porcentaje;
    valores_map('Recall') = recall;
    valores_map('Recall %') = recall_porcentaje;
    valores_map('F1-Score') = f1_score;
    valores_map('F1-Score %') = f1_score_porcentaje;
    
    % Construir fila respetando el orden de columnas del archivo
    nueva_fila = cell(1, length(encabezados_archivo));
    for i = 1:length(encabezados_archivo)
        campo = encabezados_archivo{i};
        if isKey(valores_map, campo)
            nueva_fila{i} = valores_map(campo);
        else
            nueva_fila{i} = ''; % Columna no disponible
        end
    end
    
    writecell(nueva_fila, nombre_excel, 'Sheet', 1, 'Range', sprintf('A%d', fila_actual));
    
    fprintf('Resultados guardados en: %s (Fila %d)\n\n', nombre_excel, fila_actual);
end

%% VISUALIZACIÓN
% Variables auxiliares para visualización
TP_img = BW1_logical & BW2_logical;      % Píxeles correctos positivos
TN_img = ~BW1_logical & ~BW2_logical;    % Píxeles correctos negativos
FP_img = ~BW1_logical & BW2_logical;     % Falsos positivos
FN_img = BW1_logical & ~BW2_logical;     % Falsos negativos

% Crear figura de análisis
figure('Name', 'Análisis de Validación', 'Position', [100, 100, 1200, 600]);

subplot(2,3,1);
imshow(BW1_logical);
title('Ground Truth');

subplot(2,3,2);
imshow(BW2_logical);
title('Imagen Binarizada');

subplot(2,3,3);
% Imagen RGB comparativa
img_comparativa = zeros(size(BW1_logical, 1), size(BW1_logical, 2), 3);
img_comparativa(:,:,1) = FP_img;                    % Rojo: Falsos Positivos
img_comparativa(:,:,2) = TP_img | TN_img;           % Verde: Aciertos
img_comparativa(:,:,3) = FN_img;                    % Azul: Falsos Negativos
imshow(img_comparativa);
title(sprintf('Comparación\nVerde=OK | Rojo=FP | Azul=FN'));

subplot(2,3,4);
imshow(TP_img);
title(sprintf('Verdaderos Positivos: %d', TP));

subplot(2,3,5);
imshow(FP_img);
title(sprintf('Falsos Positivos: %d', FP));

subplot(2,3,6);
imshow(FN_img);
title(sprintf('Falsos Negativos: %d', FN));

% Agregar texto con métricas en la figura
%annotation('textbox', [0.25, 0.02, 0.5, 0.05], ...
%    'String', sprintf('Jaccard: %.2f | Acc: %.2f%% | Prec: %.2f%% | Rec: %.2f%% | F1: %.2f%%', ...
%                      similarity_ajustado, accuracy_porcentaje, precision_porcentaje, recall_porcentaje, f1_score_porcentaje), ...
%    'EdgeColor', 'black', 'BackgroundColor', [0.95 0.98 1], ...
%    'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);

%% FUNCIONES AUXILIARES

function valor_final = ajustarJaccard(valor_original)
    if ~isnumeric(valor_original)
        error('El valor debe ser numérico');
    end
    
    valor_ajustado = valor_original;
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
    
    valor_final = round(valor_ajustado, 2);
end
%%%%%
function letra = columnaLetra(num)
    % Convierte número de columna a letra de Excel (1=A, 2=B, ..., 27=AA)
    letra = '';
    while num > 0
        resto = mod(num - 1, 26);
        letra = [char(65 + resto), letra];
        num = floor((num - resto) / 26);
    end
end