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
ProcessDataNewSMAPlant=false;
formatSpec = '%s';
NumberPlantsLoaded=0;
NumberPlantsToLoad=800;

Files=dir(PathSMAData);
Files=Files(strlength(cellstr({Files(:).name}))>5);
Files=Files(~strcmp(cellstr({Files(:).name}),'ListOfUnsuitablePlants.csv'));
PVPlants=cell(length(Files),1);
NumberPlantsToLoad=min(size(Files,1), NumberPlantsToLoad);
close all hidden

h=waitbar(0, 'Lade PV-Profile von lokalem Pfad');    
for n=1:size(Files,1)

    PlantPath=strcat(PathSMAData, Files(n).name);
    
    File=fopen(strcat(PlantPath, Dl, 'PlantProperties.csv'), 'r');
    Properties = fscanf(File,formatSpec);
    fclose(File);
    if length(Properties)<20
        disp(['Properties of plant ' Files(n).name ' are empty'])
    end
    Delimiter=strfind(Properties, '"');
    ExistingDates=sort(unique(datetime(string(strsplit(Properties(Delimiter(2)+1:end), ',')'), 'InputFormat', 'dd.MM.yyyy', 'TimeZone', 'Africa/Tunis')), 'ascend');
    
    if ~isempty(find(round(days(ExistingDates(2:end)-ExistingDates(1:end-1)))~=days(1), 1)) % check whether ExistingDates in consistent such that no Date is missing between the first and last entry
        continue
    end
    
    if ProcessDataNewSMAPlant==false
        
        DataComplete=dir(strcat(PlantPath, Dl, 'DataComplete_*'));
        Error=true;
        
        for k=1:size(DataComplete,1)
            DataSetDateStart=datetime(DataComplete(k).name(14:23), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis');
            DataSetDateEnd=datetime(DataComplete(k).name(25:34), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis')+hours(23)+minutes(59);
            
            if DataSetDateStart<=DateStart && DataSetDateEnd>=DateEnd
                load(strcat(PlantPath, Dl, DataComplete(k).name))
            
                if length(LoadedSMAPlantDataComplete)==round(days(DataSetDateEnd(end)-DataSetDateStart(1)))*96
                    Error=false;
                    break
                else
                    delete(strcat(PlantPath, Dl, DataComplete(k).name))
                end
            end
        end
        

        if Error==true && ~(ExistingDates(1)<=DateStart && ExistingDates(end)+hours(23)+minutes(59)>=DateEnd)
            disp(strcat("For Plant ", Files(n).name, " the downloaded data does not cover the range specified by DateStart and DateEnd"))
%             continue
        end
                
    end
    
    if Error==true || ProcessDataNewSMAPlant==true
               
        LoadedSMAPlantDataComplete=[];
        Error=false;
        DataSetDateStart=NaT(0,0,'TimeZone', 'Africa/Tunis');
        DataSetDateEnd=NaT(0,0,'TimeZone', 'Africa/Tunis');
        DateVec=ExistingDates';
        
        if ProcessDataNewSMAPlant==false
            
            DateVec=ExistingDates';
            DataComplete=dir(strcat(PlantPath, Dl, 'DataComplete_*'));        
            for k=1:size(DataComplete,1)
                DataSetDateStart(k)=datetime(DataComplete(k).name(14:23), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis');
                DataSetDateEnd(k)=datetime(DataComplete(k).name(25:34), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis')+hours(23)+minutes(59);
            end

            if ~isempty(DataSetDateStart(k))
                [~,ind]=max(DataSetDateEnd-DataSetDateStart);
                load(strcat(PlantPath, Dl, DataComplete(ind).name))
                DateVec=[ExistingDates(1):caldays(1):DataSetDateStart(ind)-caldays(1), DataSetDateEnd(ind)+caldays(1)-hours(23)-minutes(59):caldays(1):ExistingDates(end)];
                ValuesBeforeExistingDataSet=length(ExistingDates(1):caldays(1):DataSetDateStart(ind)-caldays(1));
                ValuesAfterExistingDataSet=length(DataSetDateEnd(ind)+caldays(1)-hours(23)-minutes(59):caldays(1):ExistingDates(end));
            end
        end
            
        LoadedSMAPlantDataPart=[];
        for Date=DateVec
            StoragePath=strcat(PlantPath, Dl, datestr(Date, 'yyyy'), Dl, datestr(Date, 'mm'));

            if exist(StoragePath, 'dir')
                StorageFile=strcat(StoragePath, Dl, 'PVPlantData_', datestr(Date, 'dd.mm.yyyy'));

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

                    if length(LoadedSMAPlantData)==96
                        LoadedSMAPlantDataPart=[LoadedSMAPlantDataPart; LoadedSMAPlantData];
                    else
                        Error=true;
                        break
                    end

                end
            end
        end
        
        if ProcessDataNewSMAPlant==false
            LoadedSMAPlantDataComplete=[LoadedSMAPlantDataPart(1:ValuesBeforeExistingDataSet*96);  LoadedSMAPlantDataComplete;   LoadedSMAPlantDataPart(end-ValuesAfterExistingDataSet*96+1:end)];
        else
            LoadedSMAPlantDataComplete=LoadedSMAPlantDataPart;
        end

        DataSetDateStart=ExistingDates(1);
        DataSetDateEnd=ExistingDates(end)+hours(23)+minutes(59);

        if Error==false
            if length(LoadedSMAPlantDataComplete)==round(days(ExistingDates(end)-ExistingDates(1))+1)*96
                save(strcat(PlantPath, Dl, 'DataComplete_', datestr(ExistingDates(1), 'dd.mm.yyyy'), '-', datestr(ExistingDates(end), 'dd.mm.yyyy'), '.mat'), 'LoadedSMAPlantDataComplete', '-v7.3')
            else
                disp(strcat("The length of all found values does not match the expected size according to ExistingDates for plant ", Files(n).name))
            end
        end
    end
    
    DatesDiffStart=round(days(DateStart-DataSetDateStart));
    DatesDiffEnd=round(days(DataSetDateEnd-DateEnd));
    
    if DatesDiffStart>=0 && DatesDiffEnd>=0 && length(DatesDiffStart*96+1:length(LoadedSMAPlantDataComplete)-DatesDiffEnd*96)==round(days(DateEnd-DateStart))*96
        
        Properties=strsplit(Properties(Delimiter(1):Delimiter(2)), ';');
        PVPlants{n}.Location=erase(erase(Properties{1}, '"'), ',Deutschland');
        PVPlants{n}.ActivationDate=datetime(Properties{2}, 'InputFormat', 'dd.MM.yyyy');
        PVPlants{n}.PeakPower=str2double(strrep(erase(extractBefore(Properties{3}, 'kWp'), ' '), ',', '.'));
        PVPlants{n}.ID=Properties{4};
        PVPlants{n}.Profile=uint16(LoadedSMAPlantDataComplete(DatesDiffStart*96+1:end-DatesDiffEnd*96)*1000); % Unit: W not kW! in order to save memory
    
        NumberPlantsLoaded=NumberPlantsLoaded+1;

        if NumberPlantsToLoad==NumberPlantsLoaded && ProcessDataNewSMAPlant==false
            break
        end
        
    else
        disp(strcat("Plant ", Files(n).name, " was not loaded into the PVProfiles because its loaded data set does not fully cover the date range specified by DateStart and DateEnd"))
    end
	
    if ProcessDataNewSMAPlant==true
        waitbar(n/size(Files,1));
    else
        waitbar(n/NumberPlantsToLoad);
    end
end

PVPlants(cellfun(@isempty, PVPlants))=[];
close(h)
        
disp(['PVPlantData successfully imported ' num2str(toc) 's'])

%% Clean up Workspace

clearvars Files h Properties StorageFile StoragePath n k LoadedSMAPlantData LoadedSMAPlantDataComplete DataComplete Delimiter ExistingDates
clearvars File formatSpec NumberPlantsLoaded NumberPlantsToLoad PlantPath PathSMAData DatesDiffStart DatesDiffEnd DataSetDateStart DataSetDateEnd
clearvars Error FieldNames
