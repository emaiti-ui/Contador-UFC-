clear all; close all;clc

Im_color = imread("362.jpg");

[m n c] = size(Im_color)
Mask = ones(m,n);
promedio = 0;
contador =0;
for i=1:100
    for j=1:100
        promedio = promedio + double(Im_gris(i,j));
        contador = contador +1;
    end
end
promedio = promedio/contador; 

if (promedio < 100)
centro_x = n/2;
centro_y = m/2;
radio = centro_y*0.6;

Im_gris = rgb2gray(Im_color);

figure(2)
   imshow(Im_gris)
for y=1:m
    for x=1:n
        if Im_gris(y,x) < 100
            Im_gris(y,x) = 150;
        end
    end
end

figure(3)
   imshow(Im_gris)
Im_gris = imcomplement(Im_gris);


Im_gris2 = medfilt2(Im_gris,[7 7]);
if promedio > 160
        BW = imbinarize(Im_gris2,0.3);  
    else
        umb = graythresh(Im_gris2)*1.2
        BW = imbinarize(Im_gris2, umb);  
    end
se = strel('disk',21);
BW = imopen(BW,se);
BW = imclose(BW,se);
BW = imfill(BW,'holes');
figure(4)
   imshow(BW)
end





































































