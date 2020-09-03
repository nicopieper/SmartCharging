PathSMAData=[Path 'Predictions' Dl 'SMAData' Dl];
StorageFile=strcat(PathSMAData, 'SMAData', TimeIntervalFile, '.mat');
options = weboptions('CertificateFilename','');

if isfile(StorageFile) && ProcessDataNewSMA==0
    load(StorageFile)
else    
    SMAURL='https://pvd.sunny-portal.com/powermapapi/powermap/profile/?callback=jQuery110207461584445988432_1595249669310&token=test&date=';
    
    DateList=strings(datenum(DateEnd) - datenum(DateStart)+1,1);
    for n=1:size(DateList,1)
        DateList(n,1)=datestr(DateStart+caldays(n-1), 'yyyy-mm-dd');
    end    
	PVProfilesRealQH=zeros((days(DateEnd-DateStart)+1)*24*4,105);    
   
    CounterStartQH=1;
    h=waitbar(0, 'Lade PV-Daten von sma.de');
    for Days=1:length(DateList)
        PVDataQH=webread(strcat(SMAURL, DateList(Days), '&_=1595249669320'), options);
        PVDataQH=jsondecode(PVDataQH(115:end-2));
        PVDataQH=reshape(str2num(string([PVDataQH.items(1:105).values])),96,105);        
               
        CounterEndQH=CounterStartQH+size(PVDataQH,1)-1;        
        PVProfilesRealQH(CounterStartQH:CounterEndQH,:)=PVDataQH; % Day Ahead Auction               
        CounterStartQH=CounterEndQH+1;
        waitbar(Days/length(DateList))
    end        
    PVProfilesRealQH=FillMissingValues(PVProfilesRealQH, 4);
    
    close(h);
    
    save(StorageFile, 'PVProfilesRealQH', "-v7.3")
    
    disp(['SMA Data successfully imported ' num2str(toc) 's'])
end

clearvars DateList options RawDataQH PVDataQH StorageFile PathSMAData TimeInterval Days SMAURL...
        CounterStartQH CounterEndQH PathSMAData