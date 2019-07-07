%---------------------------------------------------------------------------------
%  Licensing:
%
%Modelo de Grandes Bacias, South America version (MGB-SA). 
%Copyright (C) 2019  Hidrologia de Grande Escala (HGE)
%
%This program is free software: you can redistribute it and/or modify
%it under the terms of the GNU General Public License as published by
%the Free Software Foundation, either version 3 of the License, or
%any later version.
%
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%
%You should have received a copy of the GNU General Public License
%along with this program.  If not, see <https://www.gnu.org/licenses/>.	
%
%---------------------------------------------------------------------------------
%  Version/Modified: 
%
%    2018.03.01 - 03 January 2018 (By: Sly Wongchuig)    
%
%  Authors:
%
%    Original fortran version by Sly Wongchuig Correa
%    Present fortran version by:
%	 * Sly Wongchuig Correa
%
%  Main Reference:
%
%    Sly Wongchuig,
%    Thesis
%    Porto Alegre, 2019
%
%---------------------------------------------------------------------------------
%  Discussion:
% 
%   This script performs the matrix of correlation among catchments
%   for the use into the EnKF localization scheme
%
%
%---------------------------------------------------------------------------------
% ********************************  Description of main variables:  ***********************
% W,VBAS,VINT,VSUP,TA,QCEL2,SI,Q2fl,Yfl,Area2,Vol1,TWS2. These are the State variables of the model.
% catchments=Number of catchments of the model setup
% radius=Radius of influence fo the localizacion
% *Variables declarations and routines calls are all commented below.

% ********************************  Description of main input files:  ***********************
% mini.gtp - Topologic information from MGB
%---------------------------------------------------------------------------------
% End of header
%---------------------------------------------------------------------------------


close
clear
clc

catchments=1613;
radius=1000; % In kilometers

temp=importdata('mini.gtp');
mini=temp.data;

[m,n]=size(mini);

xx=find(mini(:,13)==1);

% Extrae las minibacias de cabecera
for i=1:length(xx)
   river(i,1).net(1,1)=mini(xx(i),2); 
end

% Extrae las minibacias aguas abajo de la cabecera
for i=1:length(xx)
    k=1;
    temp=1000;
    while temp>0
        yy=find(mini(:,2)==river(i,1).net(k,1));
        k=k+1;
        river(i,1).net(k,1)=mini(yy,12);
        temp=mini(yy,12);
    end
end

% Crear vectores de areas de contribuicion
for i=1:length(xx)
    for j=1:length(river(i,1).net)-1
        yy=find(mini(:,2)==river(i,1).net(j,1));
        area(i,1).net(j,1)=mini(yy,7);
    end
end

%% Usando las ecuaciones de Gaspari and Cohn (1999) se puede estimar la matriz de correlacion
% Finalmente se desea crear una matriz de correlacion entre minibacias (mini x mini)
% basado en "e" (distancia euclidiana) y "l" (radio de influencia) 
dist=NaN(catchments,catchments);

for i=1:catchments
    for j=1:length(xx)
    yy=find(river(j,1).net(:,1)==i);
        if length(yy)>0
            for k=1:length(river(j,1).net(:,1))-1
                if k-yy==0
                dist(i,river(j,1).net(k,1))=0;
                elseif abs(k-yy)==1
                dist(i,river(j,1).net(k,1))=(mini(i,8)+mini(river(j,1).net(k,1),8))/2;
                elseif k-yy<-1
                dist(i,river(j,1).net(k,1))=(mini(i,8)+mini(river(j,1).net(k,1),8))/2+sum(mini(river(j,1).net(k+1:yy-1,1),8));
                elseif k-yy>1
                dist(i,river(j,1).net(k,1))=(mini(i,8)+mini(river(j,1).net(k,1),8))/2+sum(mini(river(j,1).net(yy+1:k-1,1),8));
                end                
            end
        end
    end
end

% Correlation estimative
for i=1:catchments
    i
    parfor j=1:catchments
        if dist(i,j)>=0 && dist(i,j)<=radius
        corr(i,j)=1-(1/4)*(dist(i,j)/radius)^5+(1/2)*(dist(i,j)/radius)^4+(5/8)*(dist(i,j)/radius)^3-(5/3)*(dist(i,j)/radius)^2;
        elseif dist(i,j)>radius && dist(i,j)<=2*radius
        corr(i,j)=(1/12)*(dist(i,j)/radius)^5-(1/2)*(dist(i,j)/radius)^4+(5/8)*(dist(i,j)/radius)^3+(5/3)*(dist(i,j)/radius)^2-5*(dist(i,j)/radius)+4-(2/3)*(dist(i,j)/radius)^(-1);
        elseif dist(i,j)>2*radius
        corr(i,j)=0;
        else
        corr(i,j)=0;
        end
    end
end


%% Writting binary file
if ~exist('Matrix directory', 'dir')
   mkdir('Matrix directory');
end

fileID = fopen('Matrix directory/EnKF_correlation.bin','w');
fwrite(fileID,corr,'single');
fclose(fileID);

