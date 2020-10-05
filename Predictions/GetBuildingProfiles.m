tic
StorageFile=strcat(Path.OPS, 'OPSData', '.mat');
Nth = @(M, varargin) M(varargin{:});

if ~isfile(StorageFile) || ProcessDataNewOPS==1
    OPSData=readmatrix(strcat(Path.OPS, 'household_data_15min_singleindex_filtered.csv'), 'OutputType', 'string');        
    [~,OPSDataHeader]=xlsread(strcat(Path.OPS, 'household_data_15min_singleindex_filtered.csv'), '1:1'); 
    OPSDataHeader=strsplit(OPSDataHeader{1,1}, ',');
    OPSDataHeader=OPSDataHeader(:,4:end);
    
    TimeOPSQH=datetime(strrep(erase(erase(OPSData(:,2), '+0100'), '+0200'), 'T', ' '), 'InputFormat', 'yyyy-MM-dd HH:mm:ss', 'TimeZone', 'Africa/Tunis');
    temp=datetime(strrep(erase(erase(OPSData(:,2), '+0100'), '+0200'), 'T', ' '), 'InputFormat', 'yyyy-MM-dd HH:mm:ss', 'TimeZone', 'Europe/Berlin'); % Find DST transitions in Time Vector. Only possible in TimeZones which consider DST.
    DSTChangesQH=find(isdst(temp(1:end-1))~=isdst(temp(2:end))); % List all DST transitions
    DSTChangesQH=[DSTChangesQH month(temp(DSTChangesQH))]; % Add, whether a transitions occurs in October or March
    
    OPSData=DeleteDST(str2double(OPSData(:,4:end)), DSTChangesQH, 4);
    TimeOPSQH=DeleteDST(TimeOPSQH, DSTChangesQH, 4);
%%        
    NextDay = @(TimeData, Start) Start+96-hour(TimeData(Start))*4-minute(TimeData(Start))/15;
    LastDay= @(TimeData, End) End-hour(TimeData(End))*4-minute(TimeData(End))/15-1;
    n=1;
    k=1;
    OPSProfiles={cell(0,0)};
    while n<=length(OPSDataHeader)
        temp=OPSDataHeader{1,n}(1:Nth(strfind(OPSDataHeader{1,n},'_'),3));
        OPSProfiles{k}=cell(1,1);
        OPSProfiles{k}{1,1}=OPSDataHeader{1,n};
        Start=NextDay(TimeOPSQH,find(~isnan(OPSData(:,n)),1,'first'));
        End=LastDay(TimeOPSQH, find(isnan(OPSData(Start:end,n)),1,'first'));
        OPSProfiles{k}{2,1}=DeleteOutliers([OPSData(Start,n); OPSData(Start+1:End,n)-OPSData(Start:End-1,n)], 30);
        OPSProfiles{k}(3:5,1)=[{TimeOPSQH(Start:End)};{datestr(TimeOPSQH(Start), 'dd.mm.yyyy')};{datestr(TimeOPSQH(End), 'dd.mm.yyyy')}];
        n=n+1;
        while n<=length(OPSDataHeader) && strcmp(temp,OPSDataHeader{1,n}(1:Nth(strfind(OPSDataHeader{1,n},'_'),3)))
            OPSProfiles{k}{1,end+1}=OPSDataHeader{1,n};                        
            Start=NextDay(TimeOPSQH,find(~isnan(OPSData(:,n)),1,'first'));
            End=LastDay(TimeOPSQH, find(isnan(OPSData(Start:end,n)),1,'first'));
            OPSProfiles{k}{2,end}=DeleteOutliers([OPSData(Start,n); OPSData(Start+1:End,n)-OPSData(Start:End-1,n)], 30);
            OPSProfiles{k}(3:5,end)=[{TimeOPSQH(Start:End)};{datestr(TimeOPSQH(Start), 'dd.mm.yyyy')};{datestr(TimeOPSQH(End), 'dd.mm.yyyy')}];
            n=n+1;
        end
        k=k+1;
    end
    %%
    OPSPVProfiles=cell(0,0);
    for n=1:size(OPSProfiles,2)
        for k=1:size(OPSProfiles{1,n},2)
            if contains(OPSProfiles{n}{1,k},'pv')
                OPSPVProfiles(:,end+1)=OPSProfiles{n}(:,k);
            end
        end
    end            
end

PathSmardData=[Path 'Predictions' Dl 'SmardData' Dl];
TimeIntervalLabel=strcat(datestr(Time.Start, 'yyyymmdd'), '0000_', datestr(Time.End, 'yyyymmdd'), '23');
StorageFile=strcat(PathSmardData, 'SmardData', TimeIntervalFile, '.mat');
GenPredFREQH=readmatrix(strcat(PathSmardData, 'Prognostizierte_Erzeugung_', TimeIntervalLabel, '59.xlsx'), 'NumHeaderLines', 7,  'OutputType', 'string');
Time.QH=datetime(strcat(GenPredFREQH(:,1), " ", GenPredFREQH(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Africa/Tunis');
temp=datetime(strcat(GenPredFREQH(:,1), " ", GenPredFREQH(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Europe/Berlin');
DSTChangesQH=find(isdst(temp(1:end-1))~=isdst(temp(2:end)));
DSTChangesQH=[DSTChangesQH month(temp(DSTChangesQH))];
Time.QH=DeleteDST(Time.QH, DSTChangesQH, 4);
GenPredFREQH=DeleteDST(str2double(strrep(erase(GenPredFREQH(:,3:7),'.'), ',', '.')), DSTChangesQH, 4);
GenPredFREQH=FillMissingValues(GenPredFREQH(:,2:4), 4);

corrs=[];
for n=[1:5 8:9]
    Start=find(Time.QH==OPSPVProfiles{3,n}(1));
    End=find(Time.QH==OPSPVProfiles{3,n}(end));
    %figure(n)
    %plot(crosscorr(OPSPVProfiles{2,n}, GenPredFREQH(Start:End,3),'NumLags',10))
    corrs(n)=Nth(corrcoef(OPSPVProfiles{2,n}, GenPredFREQH(Start:End,3)),2);
    %figure(n+9)
    %plot(OPSPVProfiles{2,n}(1:96*4)/mean(OPSPVProfiles{2,n}))
    %hold on
    %plot(GenPredFREQH(Start:Start+96*4-1,3)/mean(GenPredFREQH(:,3)))
end
toc
