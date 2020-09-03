tic
PathECData=[Path 'Predictions' Dl 'EnergyChartsData' Dl];
DateStartEC=LastMonday(datetime(year(DateStart), month(DateStart), day(DateStart), 0,0,0, 'TimeZone','Europe/Berlin'));
DateEndEC=NextSunday(datetime(year(DateEnd), month(DateEnd), day(DateEnd), 23,59,59, 'TimeZone','Europe/Berlin'));
DateVec=DateStartEC:caldays(7):DateEndEC;
DaysDiffStart=round(days(DateStart-DateStartEC));
DaysDiffEnd=round(days(DateEndEC-DateEnd));
ECData=cell(10,2);
EnergyChartsURL='https://www.energy-charts.de/';    
Pages=["price", "power"; "2", "1"];
TimeLabels=["QuarterHourly", "Hourly"; "QH", "H"; "15min_", ""; "", ""; ];
ECData=struct;
options=weboptions;
options.Timeout=10;

%% Download or load Data
h=waitbar(0, 'Lade Stromwirtschaftsdaten von energy-charts.de');
for Date=DateVec
    Weeknum=num2str(weeknum(Date+days(1), 1, 1));
    if length(Weeknum)==1
        Weeknum=strcat('0', Weeknum);
    end
    Year=num2str(year(Date+caldays(4)));    
    for i=1:1 % 2        
        for k=1:str2double(Pages(2,i))            
            StoragePath=strcat(PathECData, Pages(1,i), Dl, TimeLabels(1,k), Dl, Year);
            if ~exist(StoragePath, 'dir')
                mkdir(StoragePath)
            end
            StorageFile=strcat(StoragePath, Dl, 'ECData', TimeLabels(2,k), '_', Year, '-', Weeknum, '.mat');
            if isfile(StorageFile) && ProcessDataNewEC==0   
                load(StorageFile);
            else                
                RawData=webread(strcat(EnergyChartsURL, Pages(1,i), '/', 'week_', TimeLabels(2+i,k), Year, '_', Weeknum, '.json'), options);
                Time=datetime(RawData{1,1}.values(:,1)/1000,'ConvertFrom', 'posixtime', 'TimeZone', 'Europe/Berlin');   
                ECDataLoaded=struct;
                DSTChanges=find(isdst(Time(1:end-1))~=isdst(Time(2:end)));
                if size(Time,1)~=168*(-k*3+7) % [1 2] => [4 1]
                    DSTChanges=[DSTChanges month(Time(DSTChanges))];
                end
                Time=DeleteDST(Time, DSTChanges, -k*3+7);
                for n=1:size(RawData,1)
                    ECDataLoaded.(erase(RawData{n,1}.key.en, [" ", ">", "-", ","])).Values=DeleteDST(RawData{n,1}.values(:,2), DSTChanges, -k*3+7);
                    ECDataLoaded.(erase(RawData{n,1}.key.en, [" ", ">", "-", ","])).Time=datetime(datestr(Time, 'dd.mm.yyyy HH:MM:ss'), 'InputFormat', 'dd.MM.yyyy HH:mm:ss', 'TimeZone', 'Africa/Tunis');
                end                                
                save(StorageFile, 'ECDataLoaded', '-v7.3')
            end
            FieldNames=fieldnames(ECDataLoaded);              
            for n=1:numel(FieldNames)
                FName=strcat(FieldNames{n}, TimeLabels(2,k));
                if isfield(ECData, FName)
                    if ECData.(FName).Time(end)+minutes(45*k-30)==ECDataLoaded.(FieldNames{n}).Time(1)
                        ECData.(FName).Values=[ECData.(FName).Values; ECDataLoaded.(FieldNames{n}).Values];
                        ECData.(FName).Time=[ECData.(FName).Time; ECDataLoaded.(FieldNames{n}).Time];
                    else
                        %1
                    end
                else
                    ECData.(FName).Values=[ECDataLoaded.(FieldNames{n}).Values];
                    ECData.(FName).Time=ECDataLoaded.(FieldNames{n}).Time;
                end
            end                            
        end        
    end
    waitbar((Date-DateStart)/(DateEnd-DateStart))
end
close(h);

%%

FieldNames=fieldnames(ECData);
for n=1:numel(FieldNames)
    DatePointer=find(ECData.(FieldNames{n}).Time==DateStart, 1);
end


%% Store Data in Variables
DayaheadRealH=FillMissingValues(ECData.DayAheadAuctionH.Values,1);
if size(ECData.IntradayContinuousIndexPriceH.Values)==size(ECData.IntradayContinuousID3PriceH.Values)==size(ECData.IntradayContinuousID1PriceH.Values)
    IntradayRealH=FillMissingValues([ECData.IntradayContinuousIndexPriceH.Values, ECData.IntradayContinuousID3PriceH.Values, ECData.IntradayContinuousID1PriceH.Values],1);
    IntradayRealQH=FillMissingValues([ECData.IntradayContinuous15minutesIndexPriceQH.Values, ECData.IntradayContinuous15minutesID3PriceQH.Values, ECData.IntradayContinuous15minutesID1PriceQH.Values],4);
else
    IntradayRealH=FillMissingValues([ECData.IntradayContinuousIndexPriceH.Values, ECData.IntradayContinuousID3PriceH.Values],1);
    IntradayRealQH=FillMissingValues([ECData.IntradayContinuous15minutesIndexPriceQH.Values, ECData.IntradayContinuous15minutesID3PriceQH.Values],4);
end
ExportRealH=FillMissingValues(-ECData.ImportBalanceH.Values,1);
ExportRealQH=FillMissingValues(-ECData.ImportBalanceQH.Values,4);
%GenRealECQH=FillMissingValues([ECData.HydroPowerQH.Values, ECData.BiomassQH.Values, ECData.UraniumQH.Values, ECData.BrownCoalQH.Values, ECData.HardCoalQH.Values, ECData.OilQH.Values, ECData.GasQH.Values, ECData.OthersQH.Values, ECData.PumpedStorageQH.Values, ECData.WindQH.Values, ECData.SolarQH.Values], 1);
TimeECH=ECData.WindH.Time;
TimeECQH=ECData.WindQH.Time;

%% Clean up Workspace
clearvars k i n Date DSTChanges ECData ECDataLoaded EnergyChartsURL Field Names FName h Pages RawData StorageFile StoragePath Time TimeLabels Weeknum Year options PathECData 
    
disp(['Energy charts data successfully imported ' num2str(toc) 's'])

function Monday=NextMonday(Date)
    Monday=Date+days(mod(7-mod(weekday(Date)+5,7),7));
end

function Sunday=LastSunday(Date)
    Sunday=Date-days(weekday(Date)-1);
end

function Sunday=NextSunday(Date)
    Sunday=Date+days(mod(8-weekday(Date),7));
end
    