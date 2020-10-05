%% Description
% This Script loads data downloaded form the smard.de website from a path,
% processes it and stores it into variables. Once processed, the variables
% are saved in the mat-file 'SmardData.m'.
% NAN vlaues are replaced by estimates by the function FillMissingValues.
% The function DeleteDST changes the time series such as if there would be
% no Daylight Saving Time. Therefore, in October the doubling occuring hour
% is deleted and in March the missing hour is added by a linear estimate.
% To circumvent datetime issues in Matlab, Tunesian TimeZone is used, as it
% does not consider DST.
%
% It processes
%   - DayAhead Prices
%   - Real Load
%   - Predicted Load
%   - Real Generation
%   - Predicted Generation
% Abbreviations:
%   - Pred  = Prediction
%   - FRE   = Fluctuating Renewable Energies
%   - QH    = Quaterly Hour
%   - H     = Hourly



%% Initialisation
%Initialisation;
tic
PathSmardData=[Path 'Predictions' Dl 'SmardData' Dl];
TimeIntervalLabel=strcat(datestr(Time.Start, 'yyyymmdd'), '0000_', datestr(Time.End, 'yyyymmdd'), '23');
StorageFile=strcat(PathSmardData, 'SmardData', TimeIntervalFile, '.mat');

if ~isfile(StorageFile) || ProcessDataNewSmard==1

    %% DayAhead Prices Real  Date, Time of Date, Germany/Luxembourg, Denmark1, Denmark2, France, Italy, Netherlands, Poland, Sweden4, Switzerland, Slowenia, Czech, Hungary, Austria, Germany/Austria/Luxembourg
    PricesRealH=readmatrix(strcat(PathSmardData, 'Gro_handelspreise_', TimeIntervalLabel, '59.xlsx'), 'NumHeaderLines', 7, 'OutputType', 'string');
    Time.H=datetime(strcat(PricesRealH(:,1), " ", PricesRealH(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Africa/Tunis'); % Use Tunesian TimeZones, as it does not consider DST.
    temp=datetime(strcat(PricesRealH(:,1), " ", PricesRealH(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Europe/Berlin'); % Find DST transitions in Time Vector. Only possible in TimeZones which consider DST.
    DSTChangesH=find(isdst(temp(1:end-1))~=isdst(temp(2:end))); % List all DST transitions
    DSTChangesH=[DSTChangesH month(temp(DSTChangesH))]; % Add, whether a transitions occurs in October or March
    PricesRealH=strrep([PricesRealH(:,3) PricesRealH(:,end)], ',', '.'); 
    temp=PricesRealH(:,2);
    PricesRealH=PricesRealH(:,1);
    temp1=find(PricesRealH(:,1)=='-'); % Before 01.10.2018 Prices were noted in Column Germany/Austria/Luxembourg. Hence replace all values with the ones from the correct column
    PricesRealH(temp1)=temp(temp1);  
    PricesRealH=DeleteDST(FillMissingValues(str2double(PricesRealH), 1), DSTChangesH, 1);
    Time.H=DeleteDST(Time.H, DSTChangesH, 1);
    

    %% Real Energy Generation  Date, Time of Date, Biomass[MWh], Hydropower[MWh], Wind Offshore[MWh], Wind Onshore[MWh], Photovoltaics[MWh], Other Renewables[MWh], Nuclear[MWh], Brown Coal[MWh], Hard Coal[MWh], Natural Gas[MWh], Pumped Hydro Storage[MWh], Other Conventional[MWh]
    GenRealQH=readmatrix(strcat(PathSmardData, 'Realisierte_Erzeugung_', TimeIntervalLabel, '45.xlsx'), 'NumHeaderLines', 7,  'OutputType', 'string');
    Time.QH=datetime(strcat(GenRealQH(:,1), " ", GenRealQH(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Africa/Tunis');
    temp=datetime(strcat(GenRealQH(:,1), " ", GenRealQH(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Europe/Berlin');
    DSTChangesQH=find(isdst(temp(1:end-1))~=isdst(temp(2:end)));
    DSTChangesQH=[DSTChangesQH month(temp(DSTChangesQH))];    
    GenRealQH=DeleteDST(FillMissingValues(str2double(strrep(erase(GenRealQH(:, 3:end), '.'), ',', '.')), 4), DSTChangesQH, 4);
    GenRealH=GenRealQH(1:4:end,:);
    GenRealFREQH=GenRealQH(:,3:5);  % Fluctuating Renewables: Wind Offshore, Wind Onshore, Photovoltaics      
    GenRealFREH=GenRealFREQH(1:4:end,:); 
    Time.QH=DeleteDST(Time.QH, DSTChangesQH, 4);
    

    %% Prediction Energy Generation  Date, Time of Date, Total[MWh] (hourly), Wind Offhore[MWh] (quater hourly), Wind Onshore[MWh] (quater hourly), Photovoltaics[MWh] (quater hourly), Others[MWh] (hourly)
    GenPredQH=readmatrix(strcat(PathSmardData, 'Prognostizierte_Erzeugung_', TimeIntervalLabel, '59.xlsx'), 'NumHeaderLines', 7,  'OutputType', 'string');       
    GenPredQH=DeleteDST(str2double(strrep(erase(GenPredQH(:,3:7),'.'), ',', '.')), DSTChangesQH, 4);    
    GenPredH=FillMissingValues(GenPredQH(1:4:end,:), 1);   % Total, Wind Offhore, Wind Onshore, Photovoltaics, Others    
    GenPredFREQH=FillMissingValues(GenPredQH(:,2:4), 4);   % Wind Offhore, Wind Onshore, Photovoltaics    
    GenPredQH=[interpolateTS(GenPredQH(:,1), Time.QH), GenPredFREQH, interpolateTS(GenPredQH(:,5), Time.QH)];
    GenPredFREH=GenPredFREQH(1:4:end,:);

    %% Prediction Load   Date, Time of Date, Total Load[MWh]
    LoadPredQH=readmatrix(strcat(PathSmardData, 'Prognostizierter_Stromverbrauch_', TimeIntervalLabel, '45.xlsx'), 'NumHeaderLines', 7,  'OutputType', 'string');    
    LoadPredQH=DeleteDST(FillMissingValues(str2double(strrep(erase(LoadPredQH(:,3), '.'), ',', '.')), 4), DSTChangesQH, 4);
    LoadPredH=LoadPredQH(1:4:end,:);

    %% Real Load   Date, Time of Date, Total Load[MWh]
    PathDir=dir(strcat(PathSmardData, 'Realisierter_Stromverbrauch_', TimeIntervalLabel, '*'));
    LoadRealQH=readmatrix(PathDir.name, 'NumHeaderLines', 7, 'OutputType', 'string');    
    LoadRealQH=DeleteDST(FillMissingValues(str2double(strrep(erase(LoadRealQH(:,3), '.'), ',', '.')), 4), DSTChangesQH, 4);
    LoadRealH=LoadRealQH(1:4:end,:);
    
    %% Foreign Trade   Date, Time of Date, Net Export[MWh], Netherlands Export[MWh], Netherlands Import[MWH], ...
%     NetExportH=readmatrix(strcat(PathSmardData, 'Kommerzieller_Au_enhandel_', TimeIntervalLabel, '59.xlsx'), 'Range', 'C:C', 'NumHeaderLines', 7, 'OutputType', 'string');
%     NetExportH=erase(NetExportH, '.');
%     NetExportH=DeleteDST(FillMissingValues(str2double(strrep(NetExportH, ',', '.')), 1), DSTChangesH, 1);    

    %% Store Data in File
    save(StorageFile, 'GenPredFREH', 'GenPredFREQH', 'GenPredH', 'GenPredQH', 'GenRealFREH', 'GenRealFREQH', 'GenRealH', 'GenRealQH', 'LoadPredH', 'LoadPredQH', 'LoadRealH', 'LoadRealQH', 'PricesRealH', 'Time.H', 'Time.QH', "-v7.3")
        
    disp(['Smard Data successfully imported ' num2str(toc) 's'])
else
    load(StorageFile);
end

clearvars temp temp1 TimeIntervalLabel StorageFile ProcessDataNew DSTChangesH DSTChangesQH k n PathSmardData PathDir


    