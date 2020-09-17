%% Description
% This script loads data into the workspace that was downloaded form the
% SMA sunny portal by the python scripts in the folder GetSMAData. The
% python scripts store measured power generation of multiple PV plants
% within Germany within the time interval 01.01.2018 to 31.08.2020. For
% each plant, the measured data is stored in csv files, whereby one file
% covers one day of one plant. In addition, for each plant some properties 
% like the location, peak power, SMA's plant ID are stored in a seperate 
% file called PlantProperties.csv.
% This script loads the plants data into Matlab and stores the measured
% generation power into a DataComplete_IntervalStart-IntervalEnd.mat file
% for each plant. If new generation data was added by the python scripts,
% this script adds this data if needed due to the definition of DateStart
% and DateEnd and creates a new DataComplete_IntervalStart-IntervalEnd.mat 
% file. If such a file already satisfies the defined interval, instead of
% the csv files, this script loads the .mat file. The data of the plants
% are stored into the cell array PVPlants including generation power
% PVPlants{n}.Profile and further properties like PVPlants{n}.PeakPower.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   GetSMAData              This folder contains the python scripts used
%                           for crawling the sunny portal
%
% Description of important variables
%   ProcessDataNewSMAPlant: The data of all plants is processed is loaded
%                       completly new from the csv files, not using the mat
%                       files. Logical
%   PVPlants:           The cell array that contains the data of all PV
%                       plants. The data of PVPlants{n}.Profile is aligned
%                       with TimeVec defined  in the Initialisation script.
%                       cell (N,1)
%   NumberPlantsToLoad: Maximum number of plants that shall be loaded into
%                       PVPlants. It is truncated by the number of existing
%                       PVPlants. (1,1)
%   ExistingDates:      All dates data is available for a specific plant.
%   ExistingDataDateStart: The first day that is covered by a DataComplete
%                       file that contains the measured pv generation data 
%                       of multiple days. 
%                       Datetime (number of existing DataComplete files,1)
%   ExistingDataDateStart: The last day that is covered by a DataComplete
%                       file that contains the measured pv generation data 
%                       of multiple days. 
%                       Datetime (number of existing DataComplete files,1)
%   LoadedSMAPlantDataComplete: The pv generation data of a plant of
%                       multiple days that is stored in a DataComplete file
%                       will be loaded into this variable. The other way
%                       around, if a new DataComplete file becomes
%                       generated, it will be saved from this variable.
%                       double (length(TimeVec),1)
%   DaysBeforeExistingDataSet: Number of days between the the first data
%                       for that data exist for this plant an the first
%                       date that is covered by a DataComplete file. 
%                       double (number of existing DataComplete files,1)
%   DaysAfterExistingDataSet: Same as above but it counts the days between
%                       the end of DataComplete and the last date data 
%                       exists for this plant. double (1,1)

%% Initialisation

%Initialisation;
tic
ProcessDataNewSMAPlant=false; % 
NumberPlantsToLoad=800;
AddPredictions=true;
LoadOnlyPlantsWithPrediction=false;

NumberPlantsLoaded=0;
formatSpec = '%s';
Files=dir(PathSMAData);
Files=Files(strlength(cellstr({Files(:).name}))>5);
Files=Files(~strcmp(cellstr({Files(:).name}),'ListOfUnsuitablePlants.csv'));
PVPlants=cell(length(Files),1);
NumberPlantsToLoad=min(size(Files,1), NumberPlantsToLoad);
close all hidden

h=waitbar(0, 'Lade PV-Profile von lokalem Pfad');    
for n=1:size(Files,1)

    PlantPath=strcat(PathSMAData, Files(n).name);
    
    if LoadOnlyPlantsWithPrediction && ~isfolder(strcat(PlantPath, Dl, "PredictionData"))
        continue
    end
    
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
            ExistingDataDateStart=datetime(DataComplete(k).name(14:23), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis');
            ExistingDataDateEnd=datetime(DataComplete(k).name(25:34), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis')+hours(23)+minutes(59);
            
            if ExistingDataDateStart<=DateStart && ExistingDataDateEnd>=DateEnd
                load(strcat(PlantPath, Dl, DataComplete(k).name))
            
                if length(LoadedSMAPlantDataComplete)==round(days(ExistingDataDateEnd(end)-ExistingDataDateStart(1)))*96
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
    
    UsedTimeVecLogical=ismember(datetime(2018,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(2020,8,31,23,0,0, 'TimeZone', 'Africa/Tunis'),TimeVec);
    if AddPredictions
        if isfile(strcat(PlantPath, Dl, "PredictionData", Dl, "PlantDataComplete_2018-01-01_2020-08-31", ".mat"))
            load(strcat(PlantPath, Dl, "PredictionData", Dl, "PlantDataComplete_2018-01-01_2020-08-31", ".mat"));
            if length(PlantDataComplete)==23376 % the number of quater hours from 01.01.2018 until 31.08.2020
                PVPlants{n}.PredictionH=PlantDataComplete(UsedTimeVecLogical);
            elseif LoadOnlyPlantsWithPrediction
                continue
            end
        elseif LoadOnlyPlantsWithPrediction
            continue
        end
    end
        
    
    if Error==true || ProcessDataNewSMAPlant==true
               
        LoadedSMAPlantDataComplete=[];
        Error=false;
        ExistingDataDateStart=NaT(0,0,'TimeZone', 'Africa/Tunis');
        ExistingDataDateEnd=NaT(0,0,'TimeZone', 'Africa/Tunis');
        DateVec=ExistingDates';
        
        if ProcessDataNewSMAPlant==false
            
            DateVec=ExistingDates';
            DataComplete=dir(strcat(PlantPath, Dl, 'DataComplete_*'));        
            for k=1:size(DataComplete,1)
                ExistingDataDateStart(k)=datetime(DataComplete(k).name(14:23), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis');
                ExistingDataDateEnd(k)=datetime(DataComplete(k).name(25:34), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis')+hours(23)+minutes(59);
            end

            if ~isempty(ExistingDataDateStart(k))
                [~,ind]=max(ExistingDataDateEnd-ExistingDataDateStart);
                load(strcat(PlantPath, Dl, DataComplete(ind).name))
                DateVec=[ExistingDates(1):caldays(1):ExistingDataDateStart(ind)-caldays(1), ExistingDataDateEnd(ind)+caldays(1)-hours(23)-minutes(59):caldays(1):ExistingDates(end)];
                DaysBeforeExistingDataSet=length(ExistingDates(1):caldays(1):ExistingDataDateStart(ind)-caldays(1));
                DaysAfterExistingDataSet=length(ExistingDataDateEnd(ind)+caldays(1)-hours(23)-minutes(59):caldays(1):ExistingDates(end));
            else
                DateVec=DateStart:caldays(1):DateEnd;
            end
        end
            
        LoadedSMAPlantDataNew=[];

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
                        LoadedSMAPlantDataNew=[LoadedSMAPlantDataNew; LoadedSMAPlantData];
                    else
                        Error=true;
                        break
                    end
                else
                    %disp(['File of plant ' Files(n).name ' is empty at date ' datestr(Date, 'dd.mm.yyyy')])
                end
            end
        end
        
        if isempty(ExistingDataDateStart(k))
            DaysBeforeExistingDataSet=length(LoadedSMAPlantDataNew)/96;
            DaysAfterExistingDataSet=0;
        end
        
        if ProcessDataNewSMAPlant==false
            LoadedSMAPlantDataComplete=[LoadedSMAPlantDataNew(1:DaysBeforeExistingDataSet*96);  LoadedSMAPlantDataComplete;   LoadedSMAPlantDataNew(end-DaysAfterExistingDataSet*96+1:end)];
        else
            LoadedSMAPlantDataComplete=LoadedSMAPlantDataNew;
        end

        ExistingDataDateStart=ExistingDates(1);
        ExistingDataDateEnd=ExistingDates(end)+hours(23)+minutes(59);

        if Error==false
            if length(LoadedSMAPlantDataComplete)==round(days(ExistingDates(end)-ExistingDates(1))+1)*96
                save(strcat(PlantPath, Dl, 'DataComplete_', datestr(ExistingDates(1), 'dd.mm.yyyy'), '-', datestr(ExistingDates(end), 'dd.mm.yyyy'), '.mat'), 'LoadedSMAPlantDataComplete', '-v7.3')
            else
                disp(strcat("The length of all found values does not match the expected size according to ExistingDates for plant ", Files(n).name))
            end
        end
    end
    
    DatesDiffStart=round(days(DateStart-ExistingDataDateStart));
    DatesDiffEnd=round(days(ExistingDataDateEnd-DateEnd));
    LoadedSMAPlantDataComplete=[0;LoadedSMAPlantDataComplete(1:end-1)]; % The SMA Data starts always at 00:15 --> Add a zero at beginning to shift ift
    
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
clearvars File formatSpec NumberPlantsLoaded NumberPlantsToLoad PlantPath DatesDiffStart DatesDiffEnd ExistingDataDateStart ExistingDataDateEnd
clearvars Error FieldNames LoadedSMAPlantDataNew UsedTimeVecLogical AddPredictions LoadOnlyPlantsWithPrediction
