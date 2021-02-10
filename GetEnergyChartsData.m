%% Description
% This Script loads electricity data directly from energy-charts.de or, 
% when already stored, from a local path. Downloaded data is stored in 
% files that cover one complete month of a subject. The subjects are 
% Dayahead spotmarket price and several Intraday indices. In addition, data
% trade for the balances with other countries and CO2 Emission Allowances 
% can the loaded but this was not useful yet. Electricity generation data 
% and the grid load can be loaded as well from the webpage but it is equal
% to the data of smard.de
% The data is stored in a tree structure. The price folder includes folders
% for hourly and quater hourly data. Those folders contain one folder 
% for each year. Inside those year folders there is one mat file for each
% month.
% NAN vlaues are replaced by estimates by the function FillMissingValues.
% The function DeleteDST changes the time series such as if there would be
% no Daylight Saving Time. Therefore, in October the doubling occuring hour
% is deleted and in March the missing hour is added by a linear estimate.
% To circumvent datetime issues in Matlab, Tunesian TimeZone is used, as it
% does not consider DST.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   GeneratePrediction.m    Makes us of this data to generate predictors,
%                           prediction models and predictions
%   Simulation.m            Makes use of this data to calculate the
%                           charging costs
%   Demonstration.m         Makes use of this data to visualise the
%                           spotmarket price
%
% Abbreviations:
%   - Pred  = Prediction
%   - H     = Hourly
%   - QH    = Quaterly Hour
%
% Description of important variables
%   DateStartEC:        Data that was once downloaded is stored in files
%                       that cover one month. Therefore, this variable 
%                       finds day of Time.Start's month. datetime (1,1)
%   DateEndEC:          This variable finds the last day of Time.End's
%                       month. datetime (1,1)
%   TimeECH:            Equals Time.Vec but considers only full hours.
%                       Needed for interpolation of quaterly Dayahead
%                       price. datetime (1,length(Time.Vec)/4)
%   MonthVec:           This vector includes the first day of each month
%                       between DateStartEC and DateEndEC. datetime (1,N)
%   ECData:             A container with all the loaded data. One row
%                       represents one category (e. g. Dayahead real
%                       price). The first column is used for the quater
%                       hourly values, the second one for houly values and
%                       the third one gives a desricption of this category
%                       as a string. cell array (20,3)
%
% Author:       Nico Pieper
% Last Update:  16.11.2020

%% Initialisation

tic

DateStartEC=datetime(year(Time.Start), month(Time.Start), 1, 0,0,0, 'TimeZone','Europe/Berlin'); % first day of month of Time.Start
DateEndEC=dateshift(datetime(year(Time.End), month(Time.End), day(Time.End), 23,59,59, 'TimeZone','Europe/Berlin'), 'end', 'month')+hours(23)+minutes(59); % last day of month of Time.End
MonthVec=DateStartEC:calmonths(1):DateEndEC; % all months covered by Time.Start and Time.End
TimeECH=Time.Start:hours(1):Time.End; % Time covered by Time.Vec in hourly time steps

EnergyChartsURL='https://www.energy-charts.info/charts/'; % the data is stored in json files which can be accessed by a regular URL that starts like this
options=weboptions;
options.Timeout=10; % terminate the data download if it exceeds 10 seconds
Pages=["price_spot_market", "power"; "2", "1"]; % labels for the URL. the numbers signalise whether there is only hourly data (1, the power generation data) or as well quater hourly data (2, the price data)
TimeLabels=["QuarterHourly", "Hourly"; "QH", "H"; "15min_", ""; "", ""; ]; % labels for the URL and folders

ECData=struct;

%% Download or load Data

h=waitbar(0, 'Lade Stromwirtschaftsdaten von energy-charts.info');
for Month=MonthVec % iterate through the months
    
    MonthStr=datestr(Month, 'mm'); % number of month
    YearStr=datestr(Month, 'yyyy');
    
    for i=1:1 % 2 % originally used to distinguish between the download site for price data and generation data. as generation data is loaded via smard, only the proce data is relevant
        
        for k=1:str2double(Pages(2,i)) % as i is only 1, iterate through hourly data (k==1) and quater hourly data (k==2)
            
            StoragePath=strcat(Path.EC, Pages(1,i), Dl, TimeLabels(1,k), Dl, YearStr);
            if ~exist(StoragePath, 'dir') % if folder for storage does not exist, make it
                mkdir(StoragePath)
            end
            
            StorageFile=strcat(StoragePath, Dl, 'ECData', TimeLabels(2,k), '_', YearStr, '-', MonthStr, '.mat');
            if isfile(StorageFile) && ProcessDataNew.EC==0 % if the wanted exsist as a mat file, load it
                load(StorageFile);
                
            else % load the data from the energy-charts.info website
                if i==1 || year(Month)>=2019
                    DataTag='raw_data';
                else
                    DataTag='data';
                end
                RawData=webread(strcat(EnergyChartsURL, Pages(1,i), '/', DataTag, '/de/', 'month_', TimeLabels(2+i,k), YearStr, '_', MonthStr, '.json'), options); % build the URL that points to the json file with the wanted data, specified by month and hourly/quater hourly. the json file covers data of multiple categories. the categories must not be consistent an change over time as some were added to the website
                ECDataLoaded=struct;
                
                for n=1:size(RawData,1) % start to process the data
                    TimeData=datetime(RawData{n,1}.values(:,1)/1000,'ConvertFrom', 'posixtime', 'TimeZone', 'Europe/Berlin'); % extract the time of the downloaded data
                    DSTChanges=find(isdst(TimeData(1:end-1))~=isdst(TimeData(2:end))); % if there is a dst transition, delete the inconsistencies
                    if size(TimeData,1)~=168*(-k*3+7) % [1 2] => [4 1]
                        DSTChanges=[DSTChanges month(TimeData(DSTChanges))];
                    end
                    TimeData=DeleteDST(TimeData, DSTChanges, -k*3+7); 
                    ECDataLoaded.(erase(RawData{n,1}.key.en, [" ", ">", "-", ","])).Values=DeleteDST(RawData{n,1}.values(:,2), DSTChanges, -k*3+7); % extract the data category from RawData{n,1} and assign a new field to ECDataLoaded with this name. assign the corresponding data values dst corrected
                    ECDataLoaded.(erase(RawData{n,1}.key.en, [" ", ">", "-", ","])).Time=datetime(datestr(TimeData, 'dd.mm.yyyy HH:MM:ss'), 'InputFormat', 'dd.MM.yyyy HH:mm:ss', 'TimeZone', 'Africa/Tunis'); % same as above but assign the time as values
                end
                save(StorageFile, 'ECDataLoaded', '-v7.3') % save the struct

            end

            FieldNames=fieldnames(ECDataLoaded); % get all categories data was inside the downloaded json file
            for n=1:numel(FieldNames) % iterate thorugh the categories
                FName=strcat(FieldNames{n}, TimeLabels(2,k)); % add to the category name whether it is hourly or quater hourly data

                if isfield(ECData, FName) % if there is already a field in ECData with the name of the downloaded category add the downloaded data to this field
                    
                    if ECData.(FName).Time(end)+minutes(45*k-30)==ECDataLoaded.(FieldNames{n}).Time(1) % check for consistency. if there is a gap between the last time entry of the data that is already stored in this struct and the new data, there must be an error
                        if length(ECDataLoaded.(FieldNames{n}).Values)==length(ECDataLoaded.(FieldNames{n}).Time)
                            ECData.(FName).Values=[ECData.(FName).Values; ECDataLoaded.(FieldNames{n}).Values]; % add the data values to the values field
                            ECData.(FName).Time=[ECData.(FName).Time; ECDataLoaded.(FieldNames{n}).Time]; % add the time to the time field
                        else
                            disp(strcat("The length of the time vector and the values vector differ at ", FieldNames{n}, " at Month ", datestr(Month, 'mm.yyyy')))
                        end
                    elseif ECDataLoaded.(FieldNames{n}).Time(1)-ECData.(FName).Time(end)+minutes(45*k-30)<hours(2) && year(Month)<2018 % in 2017 from January to March, the last three values of the month are missing in case of the quater hourly values and time entries --> add the last value to fill up and interpolate the time
                        ValuesMissing=(ECDataLoaded.(FieldNames{n}).Time(1)-ECData.(FName).Time(end))/hours(1)*(-3*k+7)-1;
                        ECData.(FName).Values=[ECData.(FName).Values;   ECData.(FName).Values(end)*ones(ValuesMissing,1);   ECDataLoaded.(FieldNames{n}).Values];
                        ECData.(FName).Time=[ECData.(FName).Time;   (ECData.(FName).Time(end)+minutes(45*k-30):minutes(k*45-30):ECDataLoaded.(FieldNames{n}).Time(1)-minutes(k*45-30))';     ECDataLoaded.(FieldNames{n}).Time];
                    end

                else % otherwise create a new field in the struct and assign the values
                    
                    if length(ECDataLoaded.(FieldNames{n}).Values)==length(ECDataLoaded.(FieldNames{n}).Time)
                        ECData.(FName).Values=[ECDataLoaded.(FieldNames{n}).Values];
                        ECData.(FName).Time=ECDataLoaded.(FieldNames{n}).Time;
                    else
                        disp(strcat("The length of the time vector and the values vector differ at ", FieldNames{n}, " at Month ", datestr(Month, 'mm.yyyy')))
                    end
                    
                end
            end                            
        end        
    end
    waitbar((Month-Time.Start)/(Time.End-Time.Start))
end
close(h);

%%

FieldNames=fieldnames(ECData);
for n=1:numel(FieldNames) % iterate through the categories and delete surplus values. that happens if Time.Start is not the beginning of a month or Time.End not the end. then some values have to be deleted such that data is aligned to Time.Vec
    
    DatePointerStart=find(ECData.(FieldNames{n}).Time==Time.Start, 1); % find the index that corresponds to Time.Start
    if isempty(DatePointerStart)
        DatePointerStart=1;
    end
    DatePointerEnd=find(ECData.(FieldNames{n}).Time>Time.End, 1); % find the index that corresponds to Time.End
    if isempty(DatePointerEnd)
        DatePointerEnd=length(ECData.(FieldNames{n}).Time);
    else
        DatePointerEnd=DatePointerEnd-1;
    end
    
    ECData.(FieldNames{n}).Values=ECData.(FieldNames{n}).Values(DatePointerStart:DatePointerEnd); % Only use values between both indices
    ECData.(FieldNames{n}).Time=ECData.(FieldNames{n}).Time(DatePointerStart:DatePointerEnd);
    
    if (length(ECData.(FieldNames{n}).Values)~=round(days(Time.End-Time.Start))*24 && length(ECData.(FieldNames{n}).Values)~=round(days(Time.End-Time.Start))*96) || length(ECData.(FieldNames{n}).Values)~=length(ECData.(FieldNames{n}).Time) % check for consistency, if cutting the data was successful then the length of the data vector equals the length of Time.Vec or Time.Vec hourly
        disp(strcat(FieldNames{n}, " could not be loaded over the full time range. It starts at ", datestr(ECData.(FieldNames{n}).Time(1), 'dd.mm.yyyy'), " and ends at ", datestr(ECData.(FieldNames{n}).Time(end), 'dd.mm.yyyy')))
    end
    if ~(round(days(ECData.(FieldNames{n}).Time(end)-ECData.(FieldNames{n}).Time(1)))*24*hours(1)/(ECData.(FieldNames{n}).Time(2)-ECData.(FieldNames{n}).Time(1))==length(ECData.(FieldNames{n}).Time) && length(ECData.(FieldNames{n}).Time)==length(ECData.(FieldNames{n}).Values))
        disp(strcat("The length of ", FieldNames{n}, " is inconsistent"))
    end
end


%% Store Data in Variables

EC.DayaheadReal1H=FillMissingValues(ECData.DayAheadAuctionH.Values,1); % assign variables from container and exchange NaN values by interpolation
EC.DayaheadReal1QH=interp1(TimeECH,EC.DayaheadReal1H, Time.Vec); % get quater hourly dayahead values by interpolation
EC.IntradayAuctionQH=FillMissingValues(ECData.IntradayAuction15minutecallQH.Values,1); % assign variables from container and exchange NaN values by interpolation
if size(ECData.IntradayContinuousIndexPriceH.Values,1)==size(ECData.IntradayContinuousID3PriceH.Values,1) && size(ECData.IntradayContinuousID3PriceH.Values,1)==size(ECData.IntradayContinuousID1PriceH.Values,1)
    EC.IntradayRealH=FillMissingValues([ECData.IntradayContinuousIndexPriceH.Values, ECData.IntradayContinuousID3PriceH.Values, ECData.IntradayContinuousID1PriceH.Values],1);
    EC.IntradayRealQH=FillMissingValues([ECData.IntradayContinuous15minutesIndexPriceQH.Values, ECData.IntradayContinuous15minutesID3PriceQH.Values, ECData.IntradayContinuous15minutesID1PriceQH.Values],4);
else
    EC.IntradayRealH=FillMissingValues([ECData.IntradayContinuousIndexPriceH.Values, ECData.IntradayContinuousID3PriceH.Values],1);
    EC.IntradayRealQH=FillMissingValues([ECData.IntradayContinuous15minutesIndexPriceQH.Values, ECData.IntradayContinuous15minutesID3PriceQH.Values],4);
end
EC.ExportRealH=FillMissingValues(-ECData.ImportBalanceH.Values,1);
EC.ExportRealQH=FillMissingValues(-ECData.ImportBalanceQH.Values,4);
%GenRealECQH=FillMissingValues([ECData.HydroPowerQH.Values, ECData.BiomassQH.Values, ECData.UraniumQH.Values, ECData.BrownCoalQH.Values, ECData.HardCoalQH.Values, ECData.OilQH.Values, ECData.GasQH.Values, ECData.OthersQH.Values, ECData.PumpedStorageQH.Values, ECData.WindQH.Values, ECData.SolarQH.Values], 1);

%% Clean up Workspace
clearvars k i n Date DSTChanges ECDataLoaded EnergyChartsURL FieldNames FName h Pages RawData StorageFile StoragePath  TimeLabels Weeknum Year options Path.EC 
clearvars ECData MonthStr YearStr MonthVec DatePointerEnd DatePointerStart DateStartEC DateEndEC
clearvars TimeECH TimeECQH DataTag TimeData
    
disp(['Energy charts data successfully imported ' num2str(toc) 's'])
   