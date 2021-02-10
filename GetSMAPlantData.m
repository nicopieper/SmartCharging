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
% this script adds this data if needed due to the definition of Time.Start
% and Time.End and creates a new DataComplete_IntervalStart-IntervalEnd.mat 
% file. If such a file already satisfies the defined interval, instead of
% the csv files, this script loads the .mat file. The data of the plants
% are stored into the cell array PVPlants including generation power
% PVPlants{n}.ProfileQH and further properties like PVPlants{n}.PeakPower.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   GetSMAData              This folder contains the python scripts used
%                           for crawling the sunny portal
%
% Description of important variables
%   PVPlants:           The cell array that contains the data of all PV
%                       plants. The data of PVPlants{n}.ProfileQH is aligned
%                       with Time.Vec defined  in the Initialisation script.
%                       cell (N,1)
%   NumberPlantsToLoad: Maximum number of plants that shall be loaded into
%                       PVPlants. It is truncated by the number of existing
%                       PVPlants. (1,1)
%   ExistingDates:      All dates data is available for a specific plant.
%   ExistingDataTimeStart: The first day that is covered by a DataComplete
%                       file that contains the measured pv generation data 
%                       of multiple days. 
%                       Datetime (number of existing DataComplete files,1)
%   ExistingDataTimeStart: The last day that is covered by a DataComplete
%                       file that contains the measured pv generation data 
%                       of multiple days. 
%                       Datetime (number of existing DataComplete files,1)
%   LoadedSMAPlantDataComplete: The pv generation data of a plant of
%                       multiple days that is stored in a DataComplete file
%                       will be loaded into this variable. The other way
%                       around, if a new DataComplete file becomes
%                       generated, it will be saved from this variable.
%                       double (length(Time.Vec),1)
%   DaysBeforeExistingDataSet: Number of days between the the first data
%                       for that data exist for this plant an the first
%                       date that is covered by a DataComplete file. 
%                       double (number of existing DataComplete files,1)
%   DaysAfterExistingDataSet: Same as above but it counts the days between
%                       the end of DataComplete and the last date data 
%                       exists for this plant. double (1,1)
%
% Author:       Nico Pieper
% Last Update:  16.11.2020

%% Initialisation

%Initialisation;
tic
NumberPlantsToLoad=800; % Maximum number of plants to load. if larger than number existing plants, only number of existing plants are loaded
AddPredictions=true; % if true the prediction data is added to plants for those which have prediction data
LoadOnlyPlantsWithPrediction=true; % if true only plants with available prediction data are loaded

NumberPlantsLoaded=0; % counter how many plants were loaded
formatSpec = '%s'; % needed for reading of csv files

Folders=dir(Path.SMAPlant); % find all folders inside the path. each plant has its own folder which is named as the plants ID
Folders=Folders(strlength(cellstr({Folders(:).name}))>5); % only consider folder with reasonable name length
Folders=Folders(~strcmp(cellstr({Folders(:).name}),'ListOfUnsuitablePlants.csv')); % exlcude it from the list as it does not represent a plant's folder
PVPlants=cell(length(Folders),1); % assign the variable the plants data is stored in
NumberPlantsToLoad=min(size(Folders,1), NumberPlantsToLoad); % only load as many plants as existend
close all hidden

%% Load the data

EEGBonus=readmatrix(strcat(Path.Simulation, "EEGFoerderung.csv"), 'OutputType', 'string');
EEGDates=datetime(EEGBonus(:,1), 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
EEGBonus=str2double(EEGBonus(:,2));

h=waitbar(0, 'Lade PV-Profile von lokalem Pfad');    
for n=1:size(Folders,1) % iterate through the plants

    PlantPath=strcat(Path.SMAPlant, Folders(n).name);
    
    if LoadOnlyPlantsWithPrediction && ~isfolder(strcat(PlantPath, Dl, "PredictionData")) % if LoadOnlyPlantsWithPrediction is activate only consider plants with existing prediction data
        continue
    end
    
    %% Read properties
    
    File=fopen(strcat(PlantPath, Dl, 'PlantProperties.csv'), 'r'); % begin to read the plant's properties from the csv file. includes location, start of plant's operation date, Peakpower, ID, SMA link, some other processing indicators and all dates data exists for
    Properties = fscanf(File,formatSpec);
    [~]=fclose(File);
    if length(Properties)<20
        disp(['Properties of plant ' Folders(n).name ' are empty'])
    end
    Properties=erase(Properties, '""');
    Delimiter=strfind(Properties, '"');
    ExistingDates=sort(unique(datetime(string(strsplit(Properties(Delimiter(2)+1:end), ',')'), 'InputFormat', 'dd.MM.yyyy', 'TimeZone', 'Africa/Tunis')), 'ascend');
    
    if ~isempty(find(round(days(ExistingDates(2:end)-ExistingDates(1:end-1)))~=days(1), 1)) % check whether ExistingDates in consistent such that no Date is missing between the first and last entry
        continue
    end
    
    if isfile(strcat(PlantPath, Dl, 'AzimutSlope.csv'))
        File=fopen(strcat(PlantPath, Dl, 'AzimutSlope.csv'), 'r'); % begin to read the plant's properties from the csv file. includes location, start of plant's operation date, Peakpower, ID, SMA link, some other processing indicators and all dates data exists for
        AzimutSlope = fscanf(File,formatSpec);
        Delimiter1=strfind(AzimutSlope, ':');
        Delimiter2=strfind(AzimutSlope, '°');
        [~]=fclose(File); 
    end
    
    %% Load data from mat files
    
    if ProcessDataNew.SMAPlant==false % load data from local mat files instead of processing it newly
        
        DataComplete=dir(strcat(PlantPath, Dl, 'DataComplete_*')); % find all DataComplete files within folder of plant
        Error=true;
        
        for k=1:size(DataComplete,1) % find a DataComplete file that satisfies the time interval of Time.Vec. The ending of the file name of the DataComplete files indicate the covered range
            ExistingDataTimeStart=datetime(DataComplete(k).name(14:23), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis'); % first date that is covered by this file. extract it from the file name
            ExistingDataTime.End=datetime(DataComplete(k).name(25:34), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis')+hours(23)+minutes(59); % last date that is covered by this file
            
            if ExistingDataTimeStart<=Time.Start && ExistingDataTime.End>=Time.End % if a file was found that satisfies the range of Time.Start and Time.End (==Time.Vec)
                load(strcat(PlantPath, Dl, DataComplete(k).name)) % then load this file which includes the variable LoadedSMAPlantDataComplete
            
                if length(LoadedSMAPlantDataComplete)==round(days(ExistingDataTime.End(end)-ExistingDataTimeStart(1)))*96 % check the loaded variable for consistency
                    Error=false; % if it is consitent, then use this file
                    break
                else
                    delete(strcat(PlantPath, Dl, DataComplete(k).name))
                end
            end
        end
        

        if Error==true && ~(ExistingDates(1)<=Time.Start && ExistingDates(end)+hours(23)+minutes(59)>=Time.End) % if an error occured, the data will be processed newly later
            disp(strcat("For Plant ", Folders(n).name, " the downloaded data does not cover the range specified by Time.Start and Time.End"))
%             continue
        end
                
    end
    
    %% Load Predictions
    
    UsedTime.VecLogical=ismember(datetime(2018,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(2020,8,31,23,0,0, 'TimeZone', 'Africa/Tunis'),Time.Vec);
    if AddPredictions % only add predictions if true
        if isfile(strcat(PlantPath, Dl, "PredictionData", Dl, "PlantDataComplete_2018-01-01_2020-08-31", ".mat")) % check if a mat file with the prediction data exists
            load(strcat(PlantPath, Dl, "PredictionData", Dl, "PlantDataComplete_2018-01-01_2020-08-31", ".mat")); % if that is the case, load it
            if length(PlantDataComplete)==23376 % the number of quater hours from 01.01.2018 until 31.08.2020. check whether the loaded data matches this size
                PVPlants{n}.PredictionH=PlantDataComplete(UsedTime.VecLogical); % assign prediction data to plant
                PVPlants{n}.PredictionQH=[interp1(1:length(PVPlants{n}.PredictionH),PVPlants{n}.PredictionH, 1:0.25:length(PVPlants{n}.PredictionH))'; ones(3,1).*PVPlants{n}.PredictionH(end)]; % interpolate hourly values to quater hourly values
            elseif LoadOnlyPlantsWithPrediction
                continue
            end
        elseif LoadOnlyPlantsWithPrediction
            continue
        end
    end
        
    %% Process data newly as an error occured or it was set by LoadedSMAPlantDataComplete
    
    if ProcessDataNew.SMAPlant==true || Error==true
               
        LoadedSMAPlantDataComplete=[]; 
        Error=false;
        ExistingDataTimeStart=NaT(0,0,'TimeZone', 'Africa/Tunis');
        ExistingDataTime.End=NaT(0,0,'TimeZone', 'Africa/Tunis');
        DateVec=ExistingDates';
        
        if ProcessDataNew.SMAPlant==false % if this variable is false, an error occured before (Error was true before it was set to false) --> try to make use of as many existing data as possible and process the remaining dates newly
            
            DateVec=ExistingDates';
            DataComplete=dir(strcat(PlantPath, Dl, 'DataComplete_*')); % again find all DataComplete files
            for k=1:size(DataComplete,1)
                ExistingDataTimeStart(k)=datetime(DataComplete(k).name(14:23), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis');
                ExistingDataTime.End(k)=datetime(DataComplete(k).name(25:34), 'InputFormat', 'dd.MM.yyyy', 'TimeZone','Africa/Tunis')+hours(23)+minutes(59);
            end

            if ~isempty(ExistingDataTimeStart(k)) % if there a DataComplete files exists, use the mos comprehensive one
                [~,ind]=max(ExistingDataTime.End-ExistingDataTimeStart); % find the file with the largest time interval
                load(strcat(PlantPath, Dl, DataComplete(ind).name)) % load it
                DateVec=[ExistingDates(1):caldays(1):ExistingDataTimeStart(ind)-caldays(1), ExistingDataTime.End(ind)+caldays(1)-hours(23)-minutes(59):caldays(1):ExistingDates(end)]; % this will be the new range covered by the new DataComplete file
                DaysBeforeExistingDataSet=length(ExistingDates(1):caldays(1):ExistingDataTimeStart(ind)-caldays(1)); % how many days have to be loaded that lay before the first date of the loaded DataComplete file?
                DaysAfterExistingDataSet=length(ExistingDataTime.End(ind)+caldays(1)-hours(23)-minutes(59):caldays(1):ExistingDates(end)); % how many days have to be loaded that lay after the first date of the loaded DataComplete file?
            else
                DateVec=Time.Start:caldays(1):Time.End; % if no DataComplete file exists at all (this plant was not processed in Matlab before), processes the whole TimVec interval newly
            end
        end
            
        LoadedSMAPlantDataNew=[];

        for Date=DateVec % process data newly for all dates in DateVec
            StoragePath=strcat(PlantPath, Dl, datestr(Date, 'yyyy'), Dl, datestr(Date, 'mm')); % iterate through the dates and read the corresponding csv file with the generation data of this plant. the files are stored in a tree folder structure, using years and months. for each day one csv file exists

            if exist(StoragePath, 'dir')
                StorageFile=strcat(StoragePath, Dl, 'PVPlantData_', datestr(Date, 'dd.mm.yyyy'));

                if isfile(strcat(StorageFile, '.csv')) 
                    File=fopen(strcat(StorageFile, '.csv'), 'r'); % open the csv file corresponding to the date
                    LoadedSMAPlantData = fscanf(File,formatSpec); % read the data of the file 
                    fclose(File);
                    if length(LoadedSMAPlantData)<20 % if the file nearly empty
                        disp(['File of plant ' Folders(n).name ' is empty at date ' datestr(Date, 'dd.mm.yyyy')])
                    end
                    LoadedSMAPlantData=char(strsplit(LoadedSMAPlantData,LoadedSMAPlantData(1:10))'); % process the data such it becomes a vector of doubles
                    DateLength=strfind(LoadedSMAPlantData(2,:), ','); 
                    LoadedSMAPlantData(:,1:DateLength)='';
                    LoadedSMAPlantData=str2double(strrep(erase(erase(string(LoadedSMAPlantData(2:end,:)),' '),'"'),',','.')); % convert from German decimal format "12,304" to English one "12.304"
                    LoadedSMAPlantData(isnan(LoadedSMAPlantData))=0;

                    if length(LoadedSMAPlantData)==96 % if processing was sucessful there have to be exactly 96 values in one vector (96 quaterly hours of a day). 
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
        
        if isempty(ExistingDataTimeStart) % if there was no existing DataComplete file
            DaysBeforeExistingDataSet=length(LoadedSMAPlantDataNew)/96; % just prevention of a bug. all new values will be added at the beginning of the (anyway empty) LoadedSMAPlantDataComplete variable 
            DaysAfterExistingDataSet=0;
        end
        
        if ProcessDataNew.SMAPlant==false % add the newly processed values to the existing ones. All values that belong to dates before ExistingDataTimeStart are added in front, all after ExistingDataTime.End are added at the end
            LoadedSMAPlantDataComplete=[LoadedSMAPlantDataNew(1:DaysBeforeExistingDataSet*96);  LoadedSMAPlantDataComplete;   LoadedSMAPlantDataNew(end-DaysAfterExistingDataSet*96+1:end)]; % add those days before
        else
            LoadedSMAPlantDataComplete=LoadedSMAPlantDataNew;
        end

        ExistingDataTimeStart=ExistingDates(1); % set the new range of the DataComplete file name
        ExistingDataTime.End=ExistingDates(end)+hours(23)+minutes(59);

        if Error==false
            if length(LoadedSMAPlantDataComplete)==round(days(ExistingDates(end)-ExistingDates(1))+1)*96 % save the data in a new DataComplete file
                save(strcat(PlantPath, Dl, 'DataComplete_', datestr(ExistingDates(1), 'dd.mm.yyyy'), '-', datestr(ExistingDates(end), 'dd.mm.yyyy'), '.mat'), 'LoadedSMAPlantDataComplete', '-v7.3')
            else
                disp(strcat("The length of all found values does not match the expected size according to ExistingDates for plant ", Folders(n).name))
            end
        end
    end
    
    
    %% Assign the loaded data to the PVPlants variable
    
    DatesDiffStart=round(days(Time.Start-ExistingDataTimeStart)); % if the range of the loaded data exceeds Time.Vec, throw all values outside Time.Vec. therefore calculate how many exceeding values are there at the beginning
    DatesDiffEnd=round(days(ExistingDataTime.End-Time.End)); % and how many are there at the end
    LoadedSMAPlantDataComplete=[0;LoadedSMAPlantDataComplete(1:end-1)]; % The SMA Data starts always at 00:15 --> Add a zero at beginning to shift ift
    
    if DatesDiffStart>=0 && DatesDiffEnd>=0 && length(DatesDiffStart*96+1:length(LoadedSMAPlantDataComplete)-DatesDiffEnd*96)==round(days(Time.End-Time.Start))*96 % check for consistency
        
        Properties=strsplit(Properties(Delimiter(1):Delimiter(2)), ';'); % store properties and measured data
        PVPlants{n}.Location=erase(erase(Properties{1}, '"'), ',Deutschland');
        PVPlants{n}.ActivationDate=datetime(Properties{2}, 'InputFormat', 'dd.MM.yyyy');
        PVPlants{n}.PeakPower=str2double(strrep(erase(extractBefore(Properties{3}, 'kWp'), ' '), ',', '.'));
        PVPlants{n}.ID=Properties{4};
        PVPlants{n}.ProfileQH=uint16(LoadedSMAPlantDataComplete(DatesDiffStart*96+1:end-DatesDiffEnd*96)*1000); % Unit: W not kW! in order to save memory. Cut Vector to Time.Vec range 
        PVPlants{n}.EEGBonus=EEGBonus(year(PVPlants{n}.ActivationDate) == year(EEGDates) & month(PVPlants{n}.ActivationDate) == month(EEGDates),1);
        
        if isfile(strcat(PlantPath, Dl, 'AzimutSlope.csv'))
            PVPlants{n}.Azimut=str2double(AzimutSlope(Delimiter1(1)+1:Delimiter2(1)-1));
            PVPlants{n}.Slope=str2double(AzimutSlope(Delimiter1(2)+1:Delimiter2(2)-1));
        end
        
        if isfield(PVPlants{n}, "PredictionH")
%             if PVPlants{n}.PeakPower>10
%                 PVPlants{n}.ProfileQH=uint16(LoadedSMAPlantDataComplete(DatesDiffStart*96+1:end-DatesDiffEnd*96)*1000/PVPlants{n}.PeakPower*10); % Unit: W not kW! in order to save memory. Cut Vector to Time.Vec range 
%                 PVPlants{n}.PredictionH=uint16(PVPlants{n}.PredictionH*1000/PVPlants{n}.PeakPower*10);
%                 PVPlants{n}.PredictionQH=uint16(PVPlants{n}.PredictionQH*1000/PVPlants{n}.PeakPower*10);
%                 PVPlants{n}.PeakPower=10;
%             else
                PVPlants{n}.PredictionH=uint16(PVPlants{n}.PredictionH*1000);  % Unit: W not kW! in order to save memory.
                PVPlants{n}.PredictionQH=uint16(PVPlants{n}.PredictionQH*1000); % Unit: W not kW! in order to save memory.
%             end
        end        
    
        NumberPlantsLoaded=NumberPlantsLoaded+1; % increase the counter

        if NumberPlantsToLoad==NumberPlantsLoaded && ProcessDataNew.SMAPlant==false
            break
        end
        
    else
        disp(strcat("Plant ", Folders(n).name, " was not loaded into the PVProfiles because its loaded data set does not fully cover the date range specified by Time.Start and Time.End"))
    end
	
    if ProcessDataNew.SMAPlant==true
        waitbar(n/size(Folders,1));
    else
        waitbar(n/NumberPlantsToLoad);
    end
end

PVPlants(cellfun(@isempty, PVPlants))=[]; % delete all empty cells. empty cells are generate if a consistency condition was not met by a plant and there the loop was continued
close(h)
        
disp(['PVPlantData successfully imported ' num2str(toc) 's'])

%% Clean up Workspace

clearvars Folders h Properties StorageFile StoragePath n k LoadedSMAPlantData LoadedSMAPlantDataComplete DataComplete Delimiter ExistingDates
clearvars File formatSpec NumberPlantsLoaded NumberPlantsToLoad PlantPath DatesDiffStart DatesDiffEnd ExistingDataTimeStart ExistingDataTime.End
clearvars Error FieldNames LoadedSMAPlantDataNew UsedTime.VecLogical AddPredictions LoadOnlyPlantsWithPrediction DaysBeforeExistingDataSet
clearvars DaysAfterExistingDataSet DateVec DateLength Date ExistingDataTime UsedTime PlantDataComplete EEGDates EEGBounus Delimiter1 Delimiter2 AzimutSlope
