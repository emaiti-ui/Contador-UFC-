
clear all, close all; clc

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

% Cada colonia recibe un número diferente
[colonias, numero] = bwlabel(BW);
%esto no estaba
propiedades_todas = regionprops(colonias, 'Centroid', 'Area', 'Perimeter');
propiedades_validas = [];
indices_validos = [];

for i = 1:length(propiedades_todas)
    area = propiedades_todas(i).Area;
    perimetro = propiedades_todas(i).Perimeter;
    
  if perimetro > 0
    circularidad = 4 * pi * area / (perimetro^2);
    
    % Filtrado más estricto para reducir falsas detecciones
    if circularidad >= 0.5 && area >= 100  %antes 0.82 y 300
        propiedades_validas = [propiedades_validas; propiedades_todas(i)];
        indices_validos = [indices_validos, i];
    end
  end
end

% Eliminar objetos muy cercanos (duplicados) %tampoco estaba
if length(propiedades_validas) > 1
    distancia_minima = 35;  % píxeles
    centroides = [propiedades_validas.Centroid];
    centroides = reshape(centroides, 2, [])';  % Convertir a matriz Nx2
    
    indices_mantener = true(size(propiedades_validas));
    
    for i = 1:length(propiedades_validas)
        if indices_mantener(i)
            for j = i+1:length(propiedades_validas)
                if indices_mantener(j)
                    distancia = sqrt(sum((centroides(i,:) - centroides(j,:)).^2));
                    if distancia < distancia_minima
                        %Mantener el más grande, eliminar el más pequeño
                        if propiedades_validas(i).Area >= propiedades_validas(j).Area
                            indices_mantener(j) = false;
                        else
                            indices_mantener(i) = false;
                            break;
                        end
                    end
                end
            end
        end
    end
    
    % Actualizar con objetos sin duplicados
    propiedades = propiedades_validas(indices_mantener);
    numero_colonias = length(propiedades);
end

% Actualizar número de colonias reales
numero_colonias = length(propiedades_validas);
propiedades = propiedades_validas;  % Usar solo las válidas

% Mostrar las colonias con colores diferentes
figure(5);
imshow(label2rgb(colonias, 'jet', 'k', 'shuffle'));
title(['Colonias encontradas: ' num2str(numero)]);

% Calcular el centro de cada colonia
propiedades = regionprops(colonias, 'Area', 'Centroid');
areas = [propiedades.Area];
% Mantener solo objetos con área entre 150 y 2000
indices_validos = find(areas >= 150 & areas <= 155);
% Crear una copia de la imagen original para marcar
imagen_marcada = I_segmentada;
figure(6);
imshow(imagen_marcada);
hold on;  % Esto permite dibujar encima de la imagen

% Dibujar un círculo rojo en el centro de cada colonia
for i = 1:numero
    centro = propiedades(i).Centroid;
    plot(centro(1), centro(2), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    text(centro(1)+15, centro(2), num2str(i), 'Color', 'red', 'FontSize', 10);
end




