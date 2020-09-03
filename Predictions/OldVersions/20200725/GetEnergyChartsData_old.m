PathECData=[Path 'Predictions' Dl 'EnergyChartsData' Dl];
StorageFile=strcat(PathECData, 'ECData', TimeIntervalFile, '.mat');

if isfile(StorageFile) && ProcessDataNewEC==0
    load(StorageFile)
else    
    EnergyChartsURL='https://www.energy-charts.de/';    
    StrInt= @(Str, Start, End) Str(Start:End);
    
    MonthList=strings(months(datenum(DateStart), datenum(DateEnd))+1,1);
    for n=1:size(MonthList,1)
        MonthList(n,1)=datestr(DateStart+calmonths(n-1), 'yyyy_mm');
    end    
	DayaheadRealH=zeros((days(DateEnd-DateStart)+1)*24,1);
    DayaheadRealQH=zeros((days(DateEnd-DateStart)+1)*24*4,1);
    IntradayRealH=zeros((days(DateEnd-DateStart)+1)*24,3);
    IntradayRealQH=zeros((days(DateEnd-DateStart)+1)*24*4,3);
    ExportRealH=zeros((days(DateEnd-DateStart)+1)*24,1);
    ExportRealQH=zeros((days(DateEnd-DateStart)+1)*24*4,1);
    GenRealECQH=zeros((days(DateEnd-DateStart)+1)*24*4,14);
    TimeECH=NaT((days(DateEnd-DateStart)+1)*24,1);    
    TimeECQH=NaT((days(DateEnd-DateStart)+1)*24*4,1);    
      
    CounterStartH=1;        
    CounterStartQH=1;
    h=waitbar(0, 'Lade Sportmakrtpreisdaten von energy-charts.de');
    for Monate=1:length(MonthList)
        PriceDataH=webread(strcat(EnergyChartsURL, 'price/month_', MonthList(Monate), '.json'));
        PriceDataQH=webread(strcat(EnergyChartsURL, 'price/month_', '15min_', MonthList(Monate), '.json'));        
        PowerDataQH=webread(strcat(EnergyChartsURL, 'power/month_', MonthList(Monate), '.json'));
        
        CounterEndH=CounterStartH+length(PriceDataH{6,1}.values(:,2))-1;        
        DayaheadRealH(CounterStartH:+CounterEndH,1)=PriceDataH{6,1}.values(:,2); % Day Ahead Auction
        IntradayRealH(CounterStartH:CounterEndH,1)=PriceDataH{7,1}.values(:,2); % Intraday Continous Index Price        
        IntradayRealH(CounterStartH:CounterEndH,2)=PriceDataH{11,1}.values(:,2); % Intraday Continuous ID3-Price
        IntradayRealH(CounterStartH:CounterEndH,3)=PriceDataH{12,1}.values(:,2); % Intraday Continuous ID1-Price
        ExportRealH(CounterStartH:+CounterEndH,1)=-PriceDataH{1,1}.values(:,2); % Import Balance, negative, so Export Balance
        TimeECH(CounterStartH:CounterEndH,1)=datetime(PriceDataH{7,1}.values(:,1)/1000, 'ConvertFrom', 'posixtime');        
                
               
        CounterEndQH=CounterStartQH+length(PriceDataQH{6,1}.values(:,2))-1;        
        DayaheadRealQH(CounterStartQH:CounterEndQH,1)=PriceDataQH{6,1}.values(:,2); % Day Ahead Auction
        IntradayRealQH(CounterStartQH:CounterEndQH,1)=PriceDataQH{7,1}.values(:,2); % Intraday Continous Index Price        
        IntradayRealQH(CounterStartQH:CounterEndQH,2)=PriceDataQH{11,1}.values(:,2); % Intraday Continuous ID3-Price
        IntradayRealQH(CounterStartQH:CounterEndQH,3)=PriceDataQH{12,1}.values(:,2); % Intraday Continuous ID1-Price
        ExportRealQH(CounterStartQH:CounterEndQH,1)=PriceDataQH{1,1}.values(:,2); % Import Balance, negative, so Export Balance
        for n=1:size(PowerDataQH,1)
            if str2double(StrInt(char(MonthList(Monate)),1,4))<2019
                GenRealECQH(CounterStartQH:CounterEndQH,n)=interp1(TimeH(CounterStartH:CounterEndH), PowerDataQH{n,1}.values(:,2), TimeQH(CounterStartQH:CounterEndQH));
            else
                GenRealECQH(CounterStartQH:CounterEndQH,n)=PowerDataQH{n,1}.values(:,2); % Import Balance, negative, so Export Balance
            end
        end
        TimeECQH(CounterStartQH:CounterEndQH,1)=datetime(PriceDataQH{7,1}.values(:,1)/1000, 'ConvertFrom', 'posixtime');                
        
        CounterStartH=CounterEndH+1;
        CounterStartQH=CounterEndQH+1;
        
        waitbar(Monate/length(MonthList))
    end
    TimeECH=datetime(TimeECH +hours(1), 'TimeZone', 'Africa/Tunis');
    TimeTempECH=datetime(datetime(TimeECH, 'TimeZone', 'Africa/Tunis'), 'TimeZone', 'Europe/Berlin');
    TimeECQH=datetime(TimeECQH+hours(1), 'TimeZone', 'Africa/Tunis');
    TimeTempECQH=datetime(datetime(TimeECQH, 'TimeZone', 'Africa/Tunis'), 'TimeZone', 'Europe/Berlin');
    
    DSTChangesH=find(isdst(TimeTempECH(1:end-1))~=isdst(TimeTempECH(2:end))); % List all DST transitions
    DSTChangesH=[DSTChangesH month(TimeTempECH(DSTChangesH))]; % Add, whether a transitions occurs in October or March                    
    DSTChangesQH=find(isdst(TimeTempECQH(1:end-1))~=isdst(TimeTempECQH(2:end))); % List all DST transitions
    DSTChangesQH=[DSTChangesQH month(TimeTempECQH(DSTChangesQH))]; % Add, whether a transitions occurs in October or March                
    
    DayaheadRealH=DeleteDST(FillMissingValues(DayaheadRealH, 1), DSTChangesH, 1);
    IntradayRealH=DeleteDST(FillMissingValues(IntradayRealH, 1), DSTChangesH, 1);
    ExportRealH=DeleteDST(FillMissingValues(ExportRealH, 1), DSTChangesH, 1);
    TimeECH=DeleteDST(TimeECH+hours(1), DSTChangesH, 1);
    
    DayaheadRealQH=DeleteDST(FillMissingValues(DayaheadRealQH, 4), DSTChangesQH, 4);
    IntradayRealQH=DeleteDST(FillMissingValues(IntradayRealQH, 4), DSTChangesQH, 4);
    ExportRealQH=DeleteDST(FillMissingValues(ExportRealQH, 4), DSTChangesQH, 4);
    GenRealECQH=DeleteDST(FillMissingValues(GenRealECQH, 4), DSTChangesQH, 4);
    TimeECQH=DeleteDST(TimeECQH+hours(1), DSTChangesQH, 4);

    close(h);
    
    save(StorageFile, 'IntradayRealH', 'IntradayRealQH', 'DayaheadRealH', 'DayaheadRealQH', "-v7.3")
    
    disp(['Energy Charts Data successfully imported ' num2str(toc) 's'])
end

clearvars n RawDataH RawDataQH ProcessDataNewEC StorageFile PathECData TimeInterval Monate EnergyChartsURL DSTChangesH DSTChangesQH...
        CounterStartH CounterEndH CounterStartQH CounterEndQH TimeECH TimeTempECH TimeECQH TimeTempECQH PathECData