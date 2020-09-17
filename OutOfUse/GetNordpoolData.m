% https://www.nordpoolgroup.com/api/marketdata/page/194?currency=,EUR,EUR,EUR&DateEnd=09-07-2020&entityName=50HZ

TimeInterval=strcat(datestr(DateStart, 'yyyymmdd'), '0000_', datestr(DateEnd, 'yyyymmdd'), '23');
PathIntradayData=[Path 'Predictions\SmardData\'];
StorageFile=strcat(PathIntradayData, 'IntradayData', TimeInterval, '.mat');

if isfile(StorageFile) && ProcessDataNewIntraday==0
    load(StorageFile)
else    
    NordpoolURL='https://www.nordpoolgroup.com/api/marketdata/page/194?currency=,EUR,EUR,EUR&DateEnd=';
    Areas=["50HZ"; "AMP"];
    IntradayRealH=zeros((days(DateEnd-DateStart)+1)*24,length(Areas));
    
    for i=1:length(Areas)    
        k=1;
        for Date=DateStart:DateEnd
            RawData=webread(strcat(NordpoolURL, datestr(Date, 'dd-mm-yyyy'), '&entityName=', Areas(i)));
            n=1;
            while n<size(RawData.data.Rows,1)
                if ~isempty(RawData.data.Rows(n).Name) && strcmp(RawData.data.Rows(n).Name(1:2), 'PH') && strcmp(RawData.data.Rows(n).Name(end-1), 'X')
                    IntradayRealH(k,i)=str2double(strrep(RawData.data.Rows(n).Columns(5).Value,',','.'));
                    k=k+1;
                end     
                n=n+1;
            end
        end
    end
    IntradayRealH=mean(IntradayRealH,2);
    
    save(StorageFile, 'IntradayRealH',  "-v7.3")
    
    clearvars k n i Areas Date RawData NordpoolURL TimeInterval ProcessDataNewIntraday StorageFile PathIntradayData
end