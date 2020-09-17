tic
PathECData=[Path 'Predictions' Dl 'EnergyChartsData' Dl];
DateStartEC=datetime(year(DateStart), month(DateStart), 1, 0,0,0, 'TimeZone','Europe/Berlin');
DateEndEC=dateshift(datetime(year(DateEnd), month(DateEnd), day(DateEnd), 23,59,59, 'TimeZone','Europe/Berlin'), 'end', 'month')+hours(23)+minutes(59);
MonthVec=DateStartEC:calmonths(1):DateEndEC;
TimeECH=DateStart:hours(1):DateEnd;
DaysDiffStart=round(days(DateStart-DateStartEC));
DaysDiffEnd=round(days(DateEndEC-DateEnd));
EnergyChartsURL='https://www.energy-charts.de/';
Pages=["price", "power"; "2", "1"];
TimeLabels=["QuarterHourly", "Hourly"; "QH", "H"; "15min_", ""; "", ""; ];
ECData=struct;
options=weboptions;
options.Timeout=10;

%% Download or load Data
h=waitbar(0, 'Lade Stromwirtschaftsdaten von energy-charts.de');
for Month=MonthVec
    MonthStr=datestr(Month, 'mm');
    YearStr=datestr(Month, 'yyyy');
    for i=1:1 % 2        
        for k=1:str2double(Pages(2,i))            
            StoragePath=strcat(PathECData, Pages(1,i), Dl, TimeLabels(1,k), Dl, YearStr);
            if ~exist(StoragePath, 'dir')
                mkdir(StoragePath)
            end
            StorageFile=strcat(StoragePath, Dl, 'ECData', TimeLabels(2,k), '_', YearStr, '-', MonthStr, '.mat');
            if isfile(StorageFile) && ProcessDataNewEC==0   
                load(StorageFile);
            else                
                RawData=webread(strcat(EnergyChartsURL, Pages(1,i), '/', 'month_', TimeLabels(2+i,k), YearStr, '_', MonthStr, '.json'), options);  
                ECDataLoaded=struct;
                for n=1:size(RawData,1)
                    Time=datetime(RawData{n,1}.values(:,1)/1000,'ConvertFrom', 'posixtime', 'TimeZone', 'Europe/Berlin'); 
                    DSTChanges=find(isdst(Time(1:end-1))~=isdst(Time(2:end)));
                    if size(Time,1)~=168*(-k*3+7) % [1 2] => [4 1]
                        DSTChanges=[DSTChanges month(Time(DSTChanges))];
                    end
                    Time=DeleteDST(Time, DSTChanges, -k*3+7);
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
                        if length(ECDataLoaded.(FieldNames{n}).Values)==length(ECDataLoaded.(FieldNames{n}).Time)
                            ECData.(FName).Values=[ECData.(FName).Values; ECDataLoaded.(FieldNames{n}).Values];
                            ECData.(FName).Time=[ECData.(FName).Time; ECDataLoaded.(FieldNames{n}).Time];
                        else
                            disp(strcat("The length of the time vector and the values vector differ at ", FieldNames{n}, " at Month ", datestr(Month, 'mm.yyyy')))
                        end
                    elseif ECDataLoaded.(FieldNames{n}).Time(1)-ECData.(FName).Time(end)+minutes(45*k-30)<hours(2) && year(Month)<2018 % in 2017 from January to March, the last three value of the month are missing in case of the quaterhourly values and time entries --> add the last value to fill up and interpolate the time
                        ValuesMissing=(ECDataLoaded.(FieldNames{n}).Time(1)-ECData.(FName).Time(end))/hours(1)*(-3*k+7)-1;
                        ECData.(FName).Values=[ECData.(FName).Values; ECData.(FName).Values(end)*ones(ValuesMissing,1)   ;ECDataLoaded.(FieldNames{n}).Values];
                        ECData.(FName).Time=[ECData.(FName).Time;    (ECData.(FName).Time(end)+minutes(45*k-30):minutes(k*45-30):ECDataLoaded.(FieldNames{n}).Time(1)-minutes(k*45-30))';     ECDataLoaded.(FieldNames{n}).Time];
                    end
                else
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
    waitbar((Month-DateStart)/(DateEnd-DateStart))
end
close(h);

%%

FieldNames=fieldnames(ECData);
for n=1:numel(FieldNames)
    DatePointerStart=find(ECData.(FieldNames{n}).Time==DateStart, 1);
    if isempty(DatePointerStart)
        DatePointerStart=1;
    end
    DatePointerEnd=find(ECData.(FieldNames{n}).Time>DateEnd, 1);
    if isempty(DatePointerEnd)
        DatePointerEnd=length(ECData.(FieldNames{n}).Time);
    else
        DatePointerEnd=DatePointerEnd-1;
    end
    ECData.(FieldNames{n}).Values=ECData.(FieldNames{n}).Values(DatePointerStart:DatePointerEnd);
    ECData.(FieldNames{n}).Time=ECData.(FieldNames{n}).Time(DatePointerStart:DatePointerEnd);
    if (length(ECData.(FieldNames{n}).Values)~=round(days(DateEnd-DateStart))*24 && length(ECData.(FieldNames{n}).Values)~=round(days(DateEnd-DateStart))*96) || length(ECData.(FieldNames{n}).Values)~=length(ECData.(FieldNames{n}).Time)
        disp(strcat(FieldNames{n}, " could not be loaded over the full time range. It starts at ", datestr(ECData.(FieldNames{n}).Time(1), 'dd.mm.yyyy'), " and ends at ", datestr(ECData.(FieldNames{n}).Time(end), 'dd.mm.yyyy')))
    end
    if ~(round(days(ECData.(FieldNames{n}).Time(end)-ECData.(FieldNames{n}).Time(1)))*24*hours(1)/(ECData.(FieldNames{n}).Time(2)-ECData.(FieldNames{n}).Time(1))==length(ECData.(FieldNames{n}).Time) && length(ECData.(FieldNames{n}).Time)==length(ECData.(FieldNames{n}).Values))
        disp(strcat("The length of ", FieldNames{n}, " is inconsistent"))
    end
end


%% Store Data in Variables
DayaheadRealH=FillMissingValues(ECData.DayAheadAuctionH.Values,1);
DayaheadRealQH=interp1(TimeECH,DayaheadRealH, TimeVec);
if size(ECData.IntradayContinuousIndexPriceH.Values,1)==size(ECData.IntradayContinuousID3PriceH.Values,1) && size(ECData.IntradayContinuousID3PriceH.Values,1)==size(ECData.IntradayContinuousID1PriceH.Values,1)
    IntradayRealH=FillMissingValues([ECData.IntradayContinuousIndexPriceH.Values, ECData.IntradayContinuousID3PriceH.Values, ECData.IntradayContinuousID1PriceH.Values],1);
    IntradayRealQH=FillMissingValues([ECData.IntradayContinuous15minutesIndexPriceQH.Values, ECData.IntradayContinuous15minutesID3PriceQH.Values, ECData.IntradayContinuous15minutesID1PriceQH.Values],4);
else
    IntradayRealH=FillMissingValues([ECData.IntradayContinuousIndexPriceH.Values, ECData.IntradayContinuousID3PriceH.Values],1);
    IntradayRealQH=FillMissingValues([ECData.IntradayContinuous15minutesIndexPriceQH.Values, ECData.IntradayContinuous15minutesID3PriceQH.Values],4);
end
ExportRealH=FillMissingValues(-ECData.ImportBalanceH.Values,1);
ExportRealQH=FillMissingValues(-ECData.ImportBalanceQH.Values,4);
%GenRealECQH=FillMissingValues([ECData.HydroPowerQH.Values, ECData.BiomassQH.Values, ECData.UraniumQH.Values, ECData.BrownCoalQH.Values, ECData.HardCoalQH.Values, ECData.OilQH.Values, ECData.GasQH.Values, ECData.OthersQH.Values, ECData.PumpedStorageQH.Values, ECData.WindQH.Values, ECData.SolarQH.Values], 1);

%% Clean up Workspace
clearvars k i n Date DSTChanges ECDataLoaded EnergyChartsURL FieldNames FName h Pages RawData StorageFile StoragePath Time TimeLabels Weeknum Year options PathECData 
clearvars ECData MonthStr YearStr MonthVec DatePointerEnd DatePointerStart DateStartEC DateEndEC DaysDiffStart DaysDiffEnd
clearvars TimeECH TimeECQH 
    
disp(['Energy charts data successfully imported ' num2str(toc) 's'])
   