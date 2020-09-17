tic
PathSMAData=[Path 'Predictions' Dl 'SMAData' Dl];
DateStartSMA=NextMonday(datetime(year(DateStart), month(DateStart), day(DateStart), 0,0,0, 'TimeZone','Europe/Berlin'));
DateEndSMA=LastSunday(datetime(year(DateEnd), month(DateEnd), day(DateEnd), 0,0,0, 'TimeZone','Europe/Berlin'));
SMAURL='https://pvd.sunny-portal.com/powermapapi/powermap/profile/?callback=jQuery110207461584445988432_1595249669310&token=test&date='; 
TimeLabels=["QuarterHourly", "Hourly"; "QH", "H";];
SMAData=struct;
options = weboptions('CertificateFilename', '', 'Timeout', 10);

%% Download or load Data
h=waitbar(0, 'Lade PV-Profile von SMA.de');
for Date=DateStartSMA:caldays(1):DateEndSMA
    Day=datestr(Date, 'dd');
    Month=datestr(Date, 'mm');   
    Year=datestr(Date, 'yyyy');
	StoragePath=strcat(PathSMAData, Year, Dl, Month);
    if ~exist(StoragePath, 'dir')
        mkdir(StoragePath)
    end
    StorageFile=strcat(StoragePath, Dl, 'SMAData', '_', datestr(Date, 'yyyy-mm-dd'), '.mat');
    if isfile(StorageFile) && ProcessDataNewSMA==0   
        load(StorageFile);
    else                
        RawData=webread(strcat(SMAURL, datestr(Date, 'yyyy-mm-dd'), '&_=1595249669320'), options);
        RawData=jsondecode(RawData(115:end-2));        
        Zips=strcat('Zip', {RawData.items.zipCode}');
        Data=num2cell(reshape(str2num([RawData.items(:).values]), [], size(Zips,1)),1)';
        SMADataLoaded = cell2struct(Data, Zips, 1);  
        save(StorageFile, 'SMADataLoaded', '-v7.3')
    end
    FieldNames=fieldnames(SMADataLoaded);              
    for n=1:numel(FieldNames)
        FName=strcat(FieldNames{n});
        if isfield(SMAData, FName)            
            SMAData.(FName)=[SMAData.(FName); SMADataLoaded.(FieldNames{n})];
        else
            SMAData.(FName)=[SMADataLoaded.(FieldNames{n})];
        end    
    end
    waitbar((Date-DateStart)/(DateEnd-DateStart))
end
close(h);

%% Store Data in Variables
PVProfiles1=cell2mat(struct2cell(SMAData)');
TimeQH=(NextMonday(DateStart):minutes(15):LastSunday(DateEnd))';

%% Clean up Workspace
clearvars n Date Month Year Data DateStartSMA DateEndSMA Day FieldNames options SMAData SMADataLoaded SMAURL Zips 
    
disp(['SMA Data successfully imported ' num2str(toc) 's'])
