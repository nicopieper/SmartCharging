%% Description
% This Script loads electricity data directly from smard.de or, when 
% already stored, from a local path. Downloaded data is stored in files
% that cover one complete week of a subject. The subjects are Dayahead
% spotmarket price, the real grid load, the predicted grid load, the real
% electricity generation data, the predicted electricity generation data.
% The real generation data distinguishes all different types of electricity
% source (Biomass, Wind Offshore, WindOnshore, PV, Coal, Nuclear etc.), the
% prediction only distinguishes Total, Wind Onshore, Wind Offshore, PV,
% Remaining.
% The data is stored in a tree structure. Every categroy includes folders
% for hourly and quater hourly data. Those folders have include one folder 
% for each year. Inside those year folders there is one mat file for each
% week.
% NAN vlaues are replaced by estimates by the function FillMissingValues.
% The function DeleteDST changes the time series such as if there would be
% no Daylight Saving Time. Therefore, in October the doubling occuring hour
% is deleted and in March the missing hour is added by a linear estimate.
% To circumvent datetime issues in Matlab, Tunesian TimeZone is used, as it
% does not consider DST.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%
% Abbreviations:
%   - Pred  = Prediction
%   - H     = Hourly
%   - QH    = Quaterly Hour
%
% Description of important variables
%   DateStartSmard:     Data that was once downloaded is stored in files
%                       that cover one week. Therefore, this variable finds
%                       the first Monday before Time.Start (if Time.Start is
%                       a Monday than they are equal). datetime (1,1)
%   DateEndSmard:       This variable finds first Sunday after Time.End 
%                       (if Time.Start is a Sunday than they are equal).
%                       datetime (1,1)
%   DateVec             All Mondays between DateStartSmard and 
%                       DateEndSmard. Each Moday represents one week. Data
%                       is loaded for each week (Monday) in DataVec.
%                       datetime (1, number weeks)
%   DaysDiffStart:      If Time.Start is not a Monday, data for some
%                       unwanted dates will be loaded. DaysDiffStart counts
%                       the number of days with unwanted data before
%                       Time.Start. double (1,1)
%   DaysDiffEnd:        If Time.Start is not a Sunday, data for some
%                       unwanted dates will be loaded too. DaysDiffEnd 
%                       counts the number of days with unwanted data after
%                       Time.End. double (1,1)
%   IDList:             smard.de assigns each data category with an ID.
%                       Dayahead has to IDs at it changed when Germany,
%                       Austria and Lucembourg joined a collaborative spot
%                       market. string array
%   SmardData:          A container with all the loaded data. One row
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

DateStartSmard=LastMonday(datetime(year(Time.Start), month(Time.Start), day(Time.Start), 0,0,0, 'TimeZone','Europe/Berlin')); % search for the last monday before Time.Start
DateEndSmard=NextSunday(datetime(year(Time.End), month(Time.End), day(Time.End), 23,59,59, 'TimeZone','Europe/Berlin')); % search for the next Sunday after Time.Start
DateVec=DateStartSmard:caldays(7):DateEndSmard; 
DaysDiffStart=round(days(Time.Start-DateStartSmard));
DaysDiffEnd=round(days(DateEndSmard-Time.End));

SmardURL='https://smard.de/app/chart_data/'; % the data is saved in json files available thorugh links that begin with this URL
TimeLabels=["Hourly", "QuarterHourly"; "hour", "quarterhour"; "H", "QH"];
IDList=["DayaheadReal",                 "4169", "251";... % the links contain an ID that refers to a data category
        "GenBiomasseReal",              "4066", "";...
        "GenWasserkraftReal",           "1226", "";...
        "GenWindOffshoreReal",          "1225", "";...
        "GenWindOnshoreReal",           "4067", "";...
        "GenPhotovoltaikReal",          "4068", "";...
        "GenSonstigeErneuerbareReal",   "1228", "";...
        "GenKernenergieReal",           "1224", "";...
        "GenBraunkohelReal",            "1223", "";...
        "GenSteinkohleReal",            "4069", "";...
        "GenErdgasReal",                "4071", "";...
        "GenPumpspeicherReal",          "4070", "";...
        "GenSonstigeKonvetionelleReal", "1227", "";...
        "GenGesamtPred",                "122",  "";...
        "GenWindOffshorePred",          "3791", "";...
        "GenWindOnshorePred",           "123",  "";...
        "GenPhotovoltaikPred",          "125",  "";...
        "GenGesamtSonstigePred",        "715",  "";...
        "LoadGesamtReal",               "410",  "";...
        "LoadGesamtPred",               "411",  "";...
        ];
SmardData=cell(size(IDList,1),2);    


%% Download or load Data
h=waitbar(0, 'Lade Stromwirtschaftsdaten von smard.de');
for Date=DateVec % iterate thorugh the weeks and load the data
    
    Weeknum=num2str(weeknum(Date+days(1))); % find the week number. the transition from one year to the next is tricky. the addition of one day does fix that
    Year=num2str(year(Date));
    
    for n=1:size(IDList,1) % iterate trough the data categories 
        for k=1:2 % 1: hourly, 2: quater hourly
            
            StoragePath=strcat(Path.Smard, IDList(n,1), Dl, TimeLabels(1,k), Dl, Year, Dl); % use a tree folder structure. each data category has a folder. this folder is seperated folders for hourly and quater hourly data. Each folder has folders for each year. in the year folders there is one mat file for each week of downloaded data
            if ~exist(StoragePath, 'dir')
                mkdir(StoragePath) % if a folder does not exist yet, make it
            end
            
            StorageFile=strcat(StoragePath, IDList(n,1), TimeLabels(3,k), '_', Year, '-', Weeknum, '.mat');
            if isfile(StorageFile) && ProcessDataNew.Smard==0 % if the required data for the week given by Date and the data category given by IDList(n,1) does already exsit as a mat file, then load it
                %% load data from local path
                load(StorageFile);
                    
            else % otherwise the data has to be downlaoded from smard.de which requires an internet connection
                %% load data from smard.de
                
                IDCol=2;
                
                CountryCode="DE"; % generally use DE as the country code, only the dayahead market data needs DE-AT-LU
                if n==1
                    CountryCode="DE-AT-LU";
                    if Date<=datetime(2018,09,30,23,45,0, 'TimeZone', 'Europe/Berlin') % after Germany, Austria and Luxembourg joined a share spotmarket the ID changed
                        IDCol=3;
                    end
                end   
                
                RawData=webread(strcat(SmardURL, IDList(n,IDCol), '/', CountryCode, '/', IDList(n,IDCol), '_', CountryCode, '_', TimeLabels(2,k), '_', strcat(string(posixtime(Date)), '000'), '.json')); % download the json file for the week and data category via the correct URL
                RawTime=datetime(RawData.series(:,1)/1000,'ConvertFrom', 'posixtime', 'TimeZone', 'Europe/Berlin'); % from the downloaded data save the corresponding time
                SmardDataLoaded=RawData.series(:,2); % and the data values
                
                if size(RawTime,1)~=168*(k^2) % if one week does not contain 168 values of hourly data or 168*4 values for quater hourly data, then this week must contain a date in which the daylight saving time changes.
                    DSTChanges=find(isdst(RawTime(1:end-1))~=isdst(RawTime(2:end))); % within the time vector, find the index where the transition of the daylight saving time happens. dst checks whether a datetime value is part of the daylight saving time or not. if the result changes between to consecutive values, then this must be the transition
                    DSTChanges=[DSTChanges month(RawTime(DSTChanges))]; % store the transitions and add the month. it is important to know whether it is march or october in order to correct the inconsistencies due to DST
                    SmardDataLoaded=DeleteDST(SmardDataLoaded, DSTChanges, k^2); % in march values for the missing hour are interpolated, such as if there was no DST. in october the surplus values are deleted such as if there was no DST
                end
                
                save(StorageFile, 'SmardDataLoaded', '-v7.3') % save the data loaded from smard.de in a mat file
            end
            
            SmardData{n,k}=[SmardData{n,k}; SmardDataLoaded]; % store the data in the container
        end
    end
    waitbar((Date-Time.Start)/(Time.End-Time.Start))
end
close(h);

%% Post processing

for n=1:size(IDList,1)
    for k=1:2
        SmardData{n,k}=SmardData{n,k}(DaysDiffStart*k^2*24+1:end-DaysDiffEnd*k^2*24); % delete surplus values that were loaded because the first or last week exceeds partly Time.Vec
    end
end

SmardData(:,3)=cellstr(IDList(:,1)); % add categroy descriptions

%% Store Data in Variables

Time.H=(Time.Start:hours(1):Time.End)';
Time.QH=(Time.Start:minutes(15):Time.End)';
Smard.GenRealH=FillMissingValues([SmardData{2:13,1}], 1); % GenBiomasseReal, GenWasserkraftReal, GenWindOffshoreReal, GenWindOnshoreReal, GenPhotovoltaikReal, GenSonstigeErneuerbareReal, GenKernenergieReal, GenBraunkohelReal, GenSteinkohle RealGenErdgasReal, GenPumpspeicherReal, GenSonstigeKonvetionelleReal
Smard.GenRealQH=FillMissingValues([SmardData{2:13,2}], 4)*4; % GenBiomasseReal, GenWasserkraftReal, GenWindOffshoreReal, GenWindOnshoreReal, GenPhotovoltaikReal, GenSonstigeErneuerbareReal, GenKernenergieReal, GenBraunkohelReal, GenSteinkohle RealGenErdgasReal, GenPumpspeicherReal, GenSonstigeKonvetionelleReal
Smard.GenPredH=FillMissingValues([SmardData{14:18,1}], 1); % GenGesamtPred, GenWindOffshorePred, GenWindOnshorePred, GenPhotovoltaikPred, GenGesamtSonstigePred
Smard.GenPredQH=FillMissingValues([interpolateTS(SmardData{14,2}, Time.QH), SmardData{15:17,2}, interpolateTS(SmardData{18,2}, Time.QH)],4)*4; % GenGesamtPred, GenWindOffshorePred, GenWindOnshorePred, GenPhotovoltaikPred, GenGesamtSonstigePred
Smard.LoadRealH=FillMissingValues([SmardData{19,1}], 1);
Smard.LoadRealQH=FillMissingValues([SmardData{19,2}], 4)*4;
Smard.LoadPredH=FillMissingValues([SmardData{20,1}], 1);
Smard.LoadPredQH=FillMissingValues([SmardData{20,2}], 4)*4;
Smard.DayaheadRealH=FillMissingValues([SmardData{1,1}], 1);
Smard.DayaheadRealQH=FillMissingValues([SmardData{1,2}], 4);

if length(SmardData{2,2})~=round(days(Time.End-Time.Start))*24*4==length(Time.QH) || length(SmardData{2,1})~=round(days(Time.End-Time.Start))*24==length(Time.H) % check data for consistency
    disp(strcat("The length of the Smard Data vectors does not correspond to the range of the end and start date"))
end

disp(['Smard Data successfully imported ' num2str(toc) 's'])

%% Clean up Workspace
clearvars Date h IDList k n SmardDataLoaded SmardURL StorageFile StoragePath TimeLabels Weeknum Year DateStartSmard DateEndSmard Path.Smard DaysDiffStart DaysDiffEnd DateVec
clearvars SmardData CountryCode IDCol RawTime RawData
