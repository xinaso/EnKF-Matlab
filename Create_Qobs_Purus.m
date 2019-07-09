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
%    2019.06.25 - 25 June 2019 (By: Sly Wongchuig)    
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
%   This script performas the inputs of discharge obsevation for data
%   assimilation into MGB model
%
%
%---------------------------------------------------------------------------------
% ********************************  Description of main input files:  ***********************
% Purus_discharge.mat - Dataset of discharge observation for the Purus
% basin
%---------------------------------------------------------------------------------
% End of header
%---------------------------------------------------------------------------------

close
clear
clc

error=0.10;

load ('Purus_discharge.mat')

%% Individual observations
if ~exist('Observation', 'dir')
   mkdir('Observation');
end

formatSpec='%6i%6i%6i%16.6f\n';
for i=1:length(code)
    namefile=['OBS_' num2str(catchment(i)) '_' num2str(code(i)) '.txt'];
    FileID=fopen(['.\Observation\' namefile],'w');
    for j=1:length(discharge)
        fprintf(FileID,formatSpec,date(j,1),date(j,2),date(j,3),discharge(j,i));
    end
fclose(FileID);
end

%% Discharge observations
if ~exist('Input_EnKF', 'dir')
   mkdir('Input_EnKF');
end

for i=1:length(code)
    codetxt{i}=num2str(code(i));
end

namefile='EnKF_obs_Q.txt';

header={'Day' 'Month' 'Year'};
formatSpec0=['%7s%7s%7s' repmat('%12s',1, length(code)) '\n'];
formatSpec1=['%7i%7i%7i' repmat('%12.3f',1,length(code)) '\n'];

FileID=fopen(['.\Input_EnKF\' namefile],'w');
fprintf(FileID,formatSpec0,header{:}, codetxt{:});

for i=1:length(date)
    fprintf(FileID,formatSpec1,date(i,1),date(i,2),date(i,3),discharge(i,:));
end
fclose(FileID);

%% Generates info of discharge observations
namefile='EnKF_Obs_Info.txt';

header0='! For discharge and logarithm of discharge:';
header1='! Number of discharge gauges:';
header2='! Relative error (E):';
header3='! Catchments correspondent to stations:';

formatSpec='%5i%3i%10i%40s\n';
formatSpec0='%43s\n';
formatSpec1='%29s\n';
formatSpec2='%21s\n';
formatSpec3='%39s\n';
formatSpecN='%3i\n';
formatSpecerro='%3.2f\n';

FileID=fopen(['.\Input_EnKF\' namefile],'w');
fprintf(FileID,formatSpec0,header0);
fprintf(FileID,formatSpec1,header1);
fprintf(FileID,formatSpecN,length(code));
fprintf(FileID,formatSpec2,header2);
fprintf(FileID,formatSpecerro,error);
fprintf(FileID,formatSpec3,header3);

for i=1:length(code)
    if strcmpi(condic(i),'Assim')
        flag=1;
    else
        flag=0;
    end
    fprintf(FileID,formatSpec,catchment(i,1),flag,code(i),name{i});
end
fclose(FileID);


