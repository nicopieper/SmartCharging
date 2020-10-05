tic
PathSMAData=[Path 'Predictions' Dl 'SMAData' Dl];
Time.StartSMA=NextMonday(datetime(year(Time.Start), month(Time.Start), day(Time.Start), 0,0,0, 'TimeZone','Europe/Berlin'));
DateEndSMA=LastSunday(datetime(year(Time.End), month(Time.End), day(Time.End), 0,0,0, 'TimeZone','Europe/Berlin'));
SMAURL='https://pvd.sunny-portal.com/powermapapi/powermap/profile/?callback=jQuery110207461584445988432_1595249669310&token=test&date='; 
TimeLabels=["QuarterHourly", "Hourly"; "QH", "H";];
SMAData=struct;
options = weboptions('CertificateFilename', '', 'Timeout', 10);

%% Download or load Data
h=waitbar(0, 'Lade PV-Profile von SMA.de');
for Date=Time.StartSMA:caldays(1):DateEndSMA
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
    waitbar((Date-Time.Start)/(Time.End-Time.Start))
end
close(h);

%% Store Data in Variables
PVProfiles1=cell2mat(struct2cell(SMAData)');
TimeQH=(NextMonday(Time.Start):minutes(15):LastSunday(Time.End))';

%% Clean up Workspace
clearvars n Date Month Year Data Time.StartSMA DateEndSMA Day FieldNames options SMAData SMADataLoaded SMAURL Zips 
    
disp(['SMA Data successfully imported ' num2str(toc) 's'])
