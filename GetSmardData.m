%% Description
% This Script smard.de data directly from the website or, when already 
% stored, from a local path. Downloaded data is stored in week files.
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
%   - H     = Hourly
%   - QH    = Quaterly Hour

%% Initialisation
tic
PathSmardData=[Path 'Predictions' Dl 'SmardData' Dl];
DateStartSmard=LastMonday(datetime(year(DateStart), month(DateStart), day(DateStart), 0,0,0, 'TimeZone','Europe/Berlin'));
DateEndSmard=NextSunday(datetime(year(DateEnd), month(DateEnd), day(DateEnd), 23,59,59, 'TimeZone','Europe/Berlin'));
DateVec=DateStartSmard:caldays(7):DateEndSmard;
DaysDiffStart=round(days(DateStart-DateStartSmard));
DaysDiffEnd=round(days(DateEndSmard-DateEnd));
SmardURL='https://smard.de/app/chart_data/';
TimeLabels=["Hourly", "QuarterHourly"; "hour", "quarterhour"; "H", "QH"];
IDList=["DayaheadReal",                 "4169", "251";...
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
for Date=DateVec
    Weeknum=num2str(weeknum(Date+days(1)));
    Year=num2str(year(Date));            
    for n=1:size(IDList,1)
        for k=1:2
            StoragePath=strcat(PathSmardData, IDList(n,1), Dl, TimeLabels(1,k), Dl, Year, Dl);
            if ~exist(StoragePath, 'dir')
                mkdir(StoragePath)
            end
            StorageFile=strcat(StoragePath, IDList(n,1), TimeLabels(3,k), '_', Year, '-', Weeknum, '.mat');
            if isfile(StorageFile) && ProcessDataNewSmard==0   
                load(StorageFile);
            else
                IDCol=2;
                CountryCode="DE";
                if n==1
                    CountryCode="DE-AT-LU";
                    if Date<=datetime(2018,09,30,23,45,0, 'TimeZone', 'Europe/Berlin')
                        IDCol=3;
                    end
                end                
                RawData=webread(strcat(SmardURL, IDList(n,IDCol), '/', CountryCode, '/', IDList(n,IDCol), '_', CountryCode, '_', TimeLabels(2,k), '_', strcat(string(posixtime(Date)), '000'), '.json'));
                Time=datetime(RawData.series(:,1)/1000,'ConvertFrom', 'posixtime', 'TimeZone', 'Europe/Berlin');
                SmardDataLoaded=RawData.series(:,2);
                if size(Time,1)~=168*(k^2)
                    DSTChanges=find(isdst(Time(1:end-1))~=isdst(Time(2:end)));
                    DSTChanges=[DSTChanges month(Time(DSTChanges))];
                    SmardDataLoaded=DeleteDST(SmardDataLoaded, DSTChanges, k^2);
                end
                save(StorageFile, 'SmardDataLoaded', '-v7.3')                                    
            end
            SmardData{n,k}=[SmardData{n,k}; SmardDataLoaded];
        end
    end
    waitbar((Date-DateStart)/(DateEnd-DateStart))
end
close(h);

for n=1:size(IDList,1)
    for k=1:2
        SmardData{n,k}=SmardData{n,k}(DaysDiffStart*k^2*24+1:end-DaysDiffEnd*k^2*24);
    end
end

SmardData(:,3)=cellstr(IDList(:,1));

%% Store Data in Variables
TimeH=(DateStart:hours(1):DateEnd)';
TimeQH=(DateStart:minutes(15):DateEnd)';
GenRealH=FillMissingValues([SmardData{2:13,1}], 1); % GenBiomasseReal, GenWasserkraftReal, GenWindOffshoreReal, GenWindOnshoreReal, GenPhotovoltaikReal, GenSonstigeErneuerbareReal, GenKernenergieReal, GenBraunkohelReal, GenSteinkohle RealGenErdgasReal, GenPumpspeicherReal, GenSonstigeKonvetionelleReal
GenRealQH=FillMissingValues([SmardData{2:13,2}], 4)*4; % GenBiomasseReal, GenWasserkraftReal, GenWindOffshoreReal, GenWindOnshoreReal, GenPhotovoltaikReal, GenSonstigeErneuerbareReal, GenKernenergieReal, GenBraunkohelReal, GenSteinkohle RealGenErdgasReal, GenPumpspeicherReal, GenSonstigeKonvetionelleReal
GenPredH=FillMissingValues([SmardData{14:18,1}], 1); % GenGesamtPred, GenWindOffshorePred, GenWindOnshorePred, GenPhotovoltaikPred, GenGesamtSonstigePred
GenPredQH=FillMissingValues([interpolateTS(SmardData{14,2}, TimeQH), SmardData{15:17,2}, interpolateTS(SmardData{18,2}, TimeQH)],4)*4; % GenGesamtPred, GenWindOffshorePred, GenWindOnshorePred, GenPhotovoltaikPred, GenGesamtSonstigePred
LoadRealH=FillMissingValues([SmardData{19,1}], 1);
LoadRealQH=FillMissingValues([SmardData{19,2}], 4)*4;
LoadPredH=FillMissingValues([SmardData{20,1}], 1);
LoadPredQH=FillMissingValues([SmardData{20,2}], 4)*4;
DayaheadReal1H=FillMissingValues([SmardData{1,1}], 1);
DayaheadReal1QH=FillMissingValues([SmardData{1,2}], 4);

if length(SmardData{2,2})~=round(days(DateEnd-DateStart))*24*4==length(TimeQH) || length(SmardData{2,1})~=round(days(DateEnd-DateStart))*24==length(TimeH)
    disp(strcat("The length of the Smard Data vectors does not correspond to the range of the end and start date"))
end

disp(['Smard Data successfully imported ' num2str(toc) 's'])

%% Clean up Workspace
clearvars Date h IDList k n SmardDataLoaded SmardURL StorageFile StoragePath TimeLabels Weeknum Year DateStartSmard DateEndSmard PathSmardData DaysDiffStart DaysDiffEnd DateVec
clearvars SmardData
