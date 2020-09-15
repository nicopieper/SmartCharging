%% Copy Data to Stick

SourcePath=PathSMAData;
DestinyPath="F:\SMAPlantData\PlantData";
Folders=dir(SourcePath);
Folders=Folders(strlength(cellstr({Folders(:).name}))>5);
Folders=Folders(~strcmp(cellstr({Folders(:).name}),'ListOfUnsuitablePlants.csv'));
PVPlants=cell(length(Folders),1);

waitbar(0)
for n=1:size(Folders,1)
    Files=dir(strcat(Folders(n).folder, Dl, Folders(n).name, Dl, "DataComplete*"));
    for k=1:size(Files)
        Source=strcat(Files(k).folder, Dl, Files(k).name);
        Destiny=strcat(DestinyPath, Dl, Folders(n).name, Dl, Files(k).name);
        if ~isfile(Destiny)
            if ~isfolder(strcat(DestinyPath, Dl, Folders(n).name))
                mkdir(strcat(DestinyPath, Dl, Folders(n).name))
            end
            copyfile(Source, Destiny);
        end
    end
    waitbar(n/size(Folders,1))
end
close(h);