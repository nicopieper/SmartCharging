%% Description
% This Script loads data downloaded form the regelleistung.net website from
% a local path, processes it and stores it into variables. Once processed, 
% the variables are saved in the mat-file 'RegelData.m'.
% NAN vlaues are replaced by estimates by the function FillMissingValues.
% The function DeleteDST changes the time series such as if there would be
% no Daylight Saving Time. Therefore, in October the doubling occuring hour
% is deleted and in March the missing hour is added by a linear estimate.
% To circumvent datetime issues in Matlab, Tunesian TimeZone is used, as it
% does not consider DST.

%% Initialisation

%Initialisation;
tic
PathSMAData="C:\Users\nicop\SMAPlantData\PlantData\";
DateStartSMA=NextMonday(datetime(year(DateStart), month(DateStart), day(DateStart), 0,0,0, 'TimeZone','Europe/Berlin'));
DateEndSMA=LastSunday(datetime(year(DateEnd), month(DateEnd), day(DateEnd), 0,0,0, 'TimeZone','Europe/Berlin'));
ProcessDataNewSMAPlant=0;
ReadOnlyCompletePlants=true;
formatSpec = '%s';
DateVector=DateStartSMA:caldays(1):DateEndSMA;
NumberPlantsToLoad=800;

if ProcessDataNewSMAPlant==1    
    Files=dir(PathSMAData);
    Files=Files(strlength(cellstr({Files(:).name}))>5);
    Files=Files(~strcmp(cellstr({Files(:).name}),'ListOfUnsuitablePlants.csv'));
    
    h=waitbar(0, 'Lade PV-Profile von lokalem Pfad');    
    for n=1:size(Files,1)
        Lap=tic;
        PlantPath=strcat(PathSMAData, Files(n).name);
        
        DataCompleteFile=dir(strcat(PlantPath, Dl, 'DataComplete_*'));
        DataCompleteFileExists=false;
        if length(DataCompleteFile)>=1
            for j=1:length(DataCompleteFile)
                if datetime(strcat(DataCompleteFile(j).name(14:23), " 00:00:00"), 'InputFormat', 'dd.MM.yyyy HH:mm:ss', 'TimeZone', 'Europe/Berlin')<=DateVector(1) && datetime(strcat(DataCompleteFile(j).name(25:34), " 00:00:00"), 'InputFormat', 'dd.MM.yyyy HH:mm:ss', 'TimeZone', 'Europe/Berlin')>=DateVector(end)
                    DataCompleteFileExists=true;
                    waitbar(n/size(Files,1));
                end
            end
            if DataCompleteFileExists==true
                continue
            end
        end
        
        if isfile(strcat(PlantPath, Dl, 'MatlabImportedDates.mat'))
            load(strcat(PlantPath, Dl, 'MatlabImportedDates.mat'))
        else
            MatlabImportedDates=NaT(0,'TimeZone','Europe/Berlin');
        end
        NewImportedDates=NaT(length(DateVector),1,'TimeZone','Europe/Berlin');
        DateCounter=0;
        
        File=fopen(strcat(PlantPath, Dl, 'PlantProperties.csv'), 'r');
        LoadedProperties = fscanf(File,formatSpec);
        if length(LoadedProperties)<20
            disp(['Properties of plant ' Files(n).name ' are empty'])
        end
        Delimiter=strfind(LoadedProperties, '"');
        ExistingDates=datetime(string(strsplit(LoadedProperties(Delimiter(2)+1:end), ',')'), 'InputFormat', 'dd.MM.yyyy', 'TimeZone', 'Europe/Berlin');
%         PlantDateVector=setdiff(intersect(ExistingDates, DateVector), MatlabImportedDates)';
        
        LoadedSMAPlantDataComplete=[];
        for Date=DateVector
            StoragePath=strcat(PlantPath, Dl, datestr(Date, 'yyyy'), Dl, datestr(Date, 'mm'));
            if exist(StoragePath, 'dir')
                StorageFile=strcat(StoragePath, Dl, 'PVPlantData_', datestr(Date, 'dd.mm.yyyy'));
                if sum(MatlabImportedDates==Date)<1 % if Date is not in ExistingDates
                    if isfile(strcat(StorageFile, '.csv'))
                        File=fopen(strcat(StorageFile, '.csv'), 'r');                 
                        LoadedSMAPlantData = fscanf(File,formatSpec);
                        fclose(File);
                        if length(LoadedSMAPlantData)<20
                            disp(['File of plant ' Files(n).name ' is empty at date ' datestr(Date, 'dd.mm.yyyy')])
                        end
                        LoadedSMAPlantData=char(strsplit(LoadedSMAPlantData,LoadedSMAPlantData(1:10))');
                        DateLength=strfind(LoadedSMAPlantData(2,:), ',');
                        LoadedSMAPlantData(:,1:DateLength)='';
                        LoadedSMAPlantData=str2double(strrep(erase(erase(string(LoadedSMAPlantData(2:end,:)),' '),'"'),',','.'));
                        LoadedSMAPlantData(isnan(LoadedSMAPlantData))=0;

                        save(strcat(StorageFile, '.mat'), 'LoadedSMAPlantData', '-v7.3')
                    end
                else
                    try
                        load(strcat(StorageFile, '.mat'))
                    catch
                        delete(strcat(PlantPath, Dl, 'MatlabImportedDates.mat'))
                        disp(strcat("An Error occured with Plant ", Files(n).name, " at Date ", datestr(Date, 'dd.mm.yyyy'), ". MatlabImportedDates File deleted."))
                        break
                    end
                end
                LoadedSMAPlantDataComplete=[LoadedSMAPlantDataComplete; LoadedSMAPlantData];
                DateCounter=DateCounter+1;
                NewImportedDates(DateCounter)=Date;
            end
        end
        NewImportedDates(isnat(NewImportedDates))=[];
        MatlabImportedDates=unique([MatlabImportedDates;NewImportedDates]);
        save(strcat(PlantPath, Dl, 'MatlabImportedDates.mat'), 'MatlabImportedDates', '-v7.3')
        save(strcat(PlantPath, Dl, 'DataComplete_', datestr(DateVector(1), 'dd.mm.yyyy'), '-', datestr(DateVector(end), 'dd.mm.yyyy'), '.mat'), 'LoadedSMAPlantDataComplete', '-v7.3')
        disp(strcat("Successfully loaded Data for Plant ", Files(n).name, " in ", num2str(toc(Lap)), "s"))
        waitbar(n/size(Files,1));
    end
    close(h)
else
    %% Load Data from Storage
    DateVector=DateVector';
    Files=dir(PathSMAData);
    Files=Files(strlength(cellstr({Files(:).name}))>5);
    NumberPlantsToLoad=min(size(Files,1), NumberPlantsToLoad);
    PVPlants=cell(length(Files),1);
    NumberPlantsLoaded=0;
    
    h=waitbar(0, 'Lade PV-Profile von lokalem Pfad');
    for n=1:size(Files,1)
                
        PlantPath=strcat(PathSMAData, Files(n).name, Dl);
        if ReadOnlyCompletePlants==true
            if isfile(strcat(PlantPath, Dl, 'MatlabImportedDates.mat'))
                load(strcat(PlantPath, Dl, 'MatlabImportedDates.mat'))
            else
                MatlabImportedDates=NaT(0,'TimeZone','Europe/Berlin');
            end
            if ~isempty(find(ismember(DateVector, MatlabImportedDates)==0,1))
                continue
            end
        end
        
        File=fopen(strcat(PlantPath, 'PlantProperties.csv'), 'r');                    
        Properties = fscanf(File,formatSpec);
        if length(Properties)<20
            disp(['Properties of plant ' Files(n).name ' are empty'])
        end
        fclose(File);
        Delimiter=strfind(Properties, '"');
        Properties=strsplit(Properties(Delimiter(1):Delimiter(2)), ';');
        PVPlants{n}.Location=Properties{1};
        PVPlants{n}.ActivationDate=datetime(Properties{2}, 'InputFormat', 'dd.MM.yyyy');
        PVPlants{n}.PeakPower=str2double(strrep(erase(extractBefore(Properties{3}, 'kWp'), ' '), ',', '.'));
        PVPlants{n}.ID=Properties{4};
        PVPlants{n}.Profile=[];
        
        DataComplete=dir(strcat(PlantPath, 'DataComplete_*'));
        PlantDateStart=datetime(DataComplete.name(14:23), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Europe/Berlin');
        PlantDateEnd=datetime(DataComplete.name(25:34), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Europe/Berlin');
        
        if PlantDateStart<=DateStartSMA && PlantDateEnd<=DateEndSMA
            load(strcat(PlantPath, DataComplete.name))
            PVPlants{n}.Profile=LoadedSMAPlantDataComplete;
        else
            for Date=DateStartSMA:caldays(1):DateStartSMA+caldays(20) % DateVector %DateEndSMA
                StorageFile=strcat(PlantPath, datestr(Date, 'yyyy'), Dl, datestr(Date, 'mm'), Dl, 'PVPlantData_', datestr(Date, 'dd.mm.yyyy'), '.mat');
                tic
                if isfile(StorageFile)
                    load(StorageFile)
                    PVPlants{n}.Profile=[PVPlants{n}.Profile; LoadedSMAPlantData];
                end
            end
        end
        PVPlants{n}.Profile=uint16(PVPlants{n}.Profile*1000); % Unit: W not kW! in order to save memory
        
	NumberPlantsLoaded=NumberPlantsLoaded+1;
    if NumberPlantsToLoad==NumberPlantsLoaded
        break
    end
    waitbar(n/NumberPlantsToLoad);
    end
    PVPlants(cellfun(@isempty, PVPlants))=[];
    close(h)
end

clearvars DateEndSMA DateStartSMA Files h Properties StorageFile StoragePath n LoadedSMAPlantData LoadedSMAPlantDataComplete DataComplete DateVector Delimiter
clearvars File formatSpec MatlabImportedDates NumberPlantsLoaded NumberPlantsToLoad PlantEndDate PlantStartDate PlantPath ReadOnlyCompletePlants
toc