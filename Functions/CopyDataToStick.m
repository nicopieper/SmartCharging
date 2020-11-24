%% Extract Complete PV Files

SourcePath=Path.SMAPlant;
DestinyPath="C:\Users\nicop\Seafile\SMAPlantData\PlantDataProcessed";
Folders=dir(SourcePath);
Folders=Folders(strlength(cellstr({Folders(:).name}))>5);
Folders=Folders(~strcmp(cellstr({Folders(:).name}),'ListOfUnsuitablePlants.csv'));
FileNames=["DataComplete_01.01.2018-31.08.2020.mat", "PlantProperties.csv", "PredictionData\PlantDataComplete_2018-01-01_2020-08-31.mat", "PredictionData\PlantDataTimeComplete_2018-01-01_2020-08-31.mat", "AzimutSlope.csv"];

waitbar(0)
 for n=1:size(Folders,1)
    if ~isfolder(strcat(DestinyPath, Dl, Folders(n).name))
        mkdir(strcat(DestinyPath, Dl, Folders(n).name))
    end
    for k=1:2
        File=dir(strcat(Folders(n).folder, Dl, Folders(n).name, Dl, FileNames(k)));
        copyfile(strcat(File.folder, Dl, File.name), strcat(DestinyPath, Dl, Folders(n).name, Dl, FileNames(k)));
    end
    
    if isfolder(strcat(Folders(n).folder, Dl, Folders(n).name, Dl, "PredictionData"))
        if ~isfolder(strcat(DestinyPath, Dl, Folders(n).name, Dl, "PredictionData"))
            mkdir(strcat(DestinyPath, Dl, Folders(n).name, Dl, "PredictionData"))
        end
        for k=3:4
            File=dir(strcat(Folders(n).folder, Dl, Folders(n).name, Dl, FileNames(k)));
            copyfile(strcat(File.folder, Dl, File.name), strcat(DestinyPath, Dl, Folders(n).name, Dl, FileNames(k)));
        end
    end
    waitbar(n/size(Folders,1))
end

%% Copy Data to Stick

% SourcePath=PathSMAData;
% DestinyPath="F:\SMAPlantData\PlantData";
% Folders=dir(SourcePath);
% Folders=Folders(strlength(cellstr({Folders(:).name}))>5);
% Folders=Folders(~strcmp(cellstr({Folders(:).name}),'ListOfUnsuitablePlants.csv'));
% PVPlants=cell(length(Folders),1);
% 
% waitbar(0)
% for n=1:size(Folders,1)
%     Files=dir(strcat(Folders(n).folder, Dl, Folders(n).name, Dl, "DataComplete*"));
%     for k=1:size(Files)
%         Source=strcat(Files(k).folder, Dl, Files(k).name);
%         Destiny=strcat(DestinyPath, Dl, Folders(n).name, Dl, Files(k).name);
%         if ~isfile(Destiny)
%             if ~isfolder(strcat(DestinyPath, Dl, Folders(n).name))
%                 mkdir(strcat(DestinyPath, Dl, Folders(n).name))
%             end
%             copyfile(Source, Destiny);
%         end
%     end
%     waitbar(n/size(Folders,1))
% end
% close(h);