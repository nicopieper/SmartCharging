%% Description
% This Script loads data downloaded form the regelleistung.net website from
% a local path, processes it and stores it into variables. Once processed, 
% the variables are saved in the mat-file 'RegelData.m'.
% NAN vlaues are replaced by estimates by the function FillMissingValues.
% The function DeleteDST changes the time series such as if there would be
% no Daylight Saving Time. Therefore, in October the doubling occuring hour
% is deleted and in March the missing hour is added by a linear estimate.
% To circumvent datetime issues in Matlab, Tunesian TimeZone is used, as it
% does not consider DST.

%% Initialisation
tic
%Initialisation;
PathRegelData=[Path 'Predictions' Dl 'RegelData' Dl];
OnlyAddNewLists=true;
ProcessDataNewRegelDemand=true;
ProcessDataNewRegelOfferLists=true;
ProcessDataNewRegelPrices=true;
StrRange = @(Str, Start, End) Str(Start:End);
RegelType="aFRR";
DateStartOffers=datetime(2019,08,10,0,0,0,'TimeZone', 'Africa/Tunis');

DateVec=DateStart:caldays(1):DateEnd;
if DateStart<DateStartOffers
    disp("DateStart is smaller than the beginning of the record of the reserve capacity market (01.09.2019)! Data from this date until DateEnd was loaded instead.")
end

if ProcessDataNewRegel==1
    for RegelType=["aFRR" "mFRR"]  % FCR: PRL, aFRR: SRL, mFRR: MRL
        if strcmp(RegelType,'FCR')
            RegelTypeGer='PRL';
        elseif strcmp(RegelType,'aFRR')
            RegelTypeGer='SRL';
        elseif strcmp(RegelType,'mFRR')
            RegelTypeGer='MRL';    
        else
            disp('Invalid Reserve Type Name')
        end
        
        
        %% Demand Lists  Date, TimeOfDate_From, TimeOfDate_To, Value Negative Reserve Power[MW], Value Positive Reserve Power[MW], Last Changes
        
        if ProcessDataNewRegelDemand==1
            StorageFileMonth=strcat(PathRegelData, RegelType, Dl, 'Ergebnislisten', Dl, 'ABGERUFENE*');
            Files=dir(StorageFileMonth);
            
            h=waitbar(0, "Verarbeite Regelleistungsabrufwerte");
            for n=1:size(Files,1)
                
                StartDate=strfind(Files(n).name,"2");
                Year=Files(n).name(StartDate:StartDate+3);
                Month=Files(n).name(StartDate+4:StartDate+5);
                
                if OnlyAddNewLists==true
                    MonthVec=datetime(strcat(Year, ".", Month, ".01 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'):caldays(1):dateshift(datetime(strcat(Year, ".", Month, ".01 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'),'end','month');
                    DataComplete=true;
                    MonthFiles=dir(strcat(PathRegelData, RegelType, Dl, "Demand", Dl, Year, Dl, Month, Dl, "DemandData_*"));
                    ExistingDates=NaT(0,0);
                    
                    for k=1:size(MonthFiles,1)
                        ExistingDates=[ExistingDates; datetime(MonthFiles(k).name(12:21), 'InputFormat', 'yyyy-MM-dd')];
                    end
                    
                    if isempty(find(ismember(MonthVec, ExistingDates)==0,1))
                        waitbar(n/size(Files,1))
                        continue
                    end
                end
                
                LoadedDemandDataMonth=readmatrix([Files(n).folder Dl Files(n).name], 'NumHeaderLines', 5, 'OutputType', 'string');
                Time=datetime(strcat(LoadedDemandDataMonth(:,1), " ", LoadedDemandDataMonth(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Europe/Berlin');        
                if strcmp(LoadedDemandDataMonth(1,8),'-')
                    LoadedDemandDataMonth=strrep(erase(LoadedDemandDataMonth(:,4:5),'.'), ',','.');
                    disp(strcat("In ", Month, '.', Year, ", for ", RegelType, " the operative Reserve Energy Values had to be used, as the quality-ensured Values are not available."))
                else
                    LoadedDemandDataMonth=strrep(erase(LoadedDemandDataMonth(:,8:9),'.'), ',','.');
                end
                %Time=datetime(strcat(LoadedDemandDataMonth(:,1), " ", LoadedDemandDataMonth(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Africa/Tunis');            
                DSTChangesQH=find(isdst(Time(1:end-1))~=isdst(Time(2:end))); % List all DST transitions
                DSTChangesQH=[DSTChangesQH month(Time(DSTChangesQH))]; % Add, whether a transitions occurs in October or March            
                LoadedDemandDataMonth=DeleteDST(str2double(LoadedDemandDataMonth), DSTChangesQH, 4);
                Time=DeleteDST(Time, DSTChangesQH, 4);

                StoragePath=strcat(PathRegelData, RegelType, Dl, 'Demand', Dl, Year, Dl, Month, Dl);
                if ~exist(StoragePath, 'dir')
                    mkdir(StoragePath)
                end
                DateChanges=[0; find(strcmp(string(datestr(Time(1:end-1,:), 'yyyy-mm-dd')),string(datestr(Time(2:end,:), 'yyyy-mm-dd')))==0); size(Time,1)];
                for k=1:size(DateChanges,1)-1
                    LoadedDemandData=LoadedDemandDataMonth(DateChanges(k)+1:DateChanges(k+1),:);
                    save(strcat(StoragePath, 'DemandData_', Year, '-', Month, '-', ExtDateStr(num2str(k))), 'LoadedDemandData', '-v7.3')
                end
            end
            
            waitbar(n/size(Files,1))
        end
        close(h);
        
        %% Offer Lists  Date_From, Date_To, Type_Of_Reserve, Product, Capacity_Price[€/MW], Energy_Price[€/MWh], Offered_Capacity[MW], Allocated_Capacity[MW], Country    
        
        if ProcessDataNewRegelOfferLists==1
            
            h=waitbar(0, "Verarbeite Regelleistungsangebotslisten");
            
            StorageFileMonth=strcat(PathRegelData, RegelType, Dl, 'Angebotslisten', Dl, 'RESULT_LIST*');        
            Files=dir(StorageFileMonth);
            
            for n=1:size(Files,1)
                Month=StrRange(Files(n).name, 33, 34);
                Year=StrRange(Files(n).name, 28, 31);  
                
                if OnlyAddNewLists==true
                    if Month=="07" && Year=="2018"
                        MonthVec=datetime(strcat(Year, ".", Month, ".12 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'):caldays(1):dateshift(datetime(strcat(Year, ".", Month, ".01 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'),'end','month');
                    else
                        MonthVec=datetime(strcat(Year, ".", Month, ".01 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'):caldays(1):dateshift(datetime(strcat(Year, ".", Month, ".01 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'),'end','month');
                    end
                    
                    DataComplete=true;
                    MonthFiles=dir(strcat(PathRegelData, RegelType, Dl, "Offers", Dl, Year, Dl, Month, Dl, "OfferLists_*"));
                    ExistingDates=NaT(0,0);
                    
                    for k=1:size(MonthFiles,1)
                        ExistingDates=[ExistingDates; datetime(MonthFiles(k).name(12:21), 'InputFormat', 'yyyy-MM-dd')];
                    end
                    
                    if isempty(find(ismember(MonthVec, ExistingDates)==0,1))
                        waitbar(n/size(Files,1))
                        continue
                    end
                end
                
                if Dl=='\'
                    [LoadedOfferListData,LoadedOfferListData2]=xlsread([Files(n).folder Dl Files(n).name]);
                    LoadedOfferListData=erase([string(LoadedOfferListData2(2:end,[2 4 7])), num2str(LoadedOfferListData(:,1)), num2str(LoadedOfferListData(:,2)), num2str(LoadedOfferListData(:,5))],' ');                 
                else
                    LoadedOfferListData=readmatrix(Files(n), 'OutputType', 'string');
                    LoadedOfferListData=erase(LoadedOfferListData(1:end, [2 4 7 5:6 9]), ' ');
                end
                LoadedOfferListData(:,3)=strrep(LoadedOfferListData(:,3), 'GRID_TO_PROVIDER', '1');
                LoadedOfferListData(:,3)=strrep(LoadedOfferListData(:,3), 'PROVIDER_TO_GRID', '-1');

                DemandData=[];
                          
                StoragePathMonth=strcat(PathRegelData, RegelType, Dl, 'Demand', Dl, Year, Dl, Month);
                for Date=datetime(LoadedOfferListData(1,1), 'InputFormat', 'dd.MM.yyyy'):caldays(1):datetime(LoadedOfferListData(end,1), 'InputFormat', 'dd.MM.yyyy')
                    load(strcat(StoragePathMonth, Dl, 'DemandData_', Year, '-', Month, '-', datestr(Date, 'dd'), '.mat'))
                    DemandData=[DemandData; LoadedDemandData];
                end

                Start=1;
                End=Start+find(strcmp(LoadedOfferListData(Start:end,2),LoadedOfferListData(Start,2))==0, 1)-2;            
                k=1;    
                LoadedOfferLists={}; % Capacity Price [€/MW], Energy Price [€/MWh], Allocated Capacity [MW]
                StoragePath=strcat(PathRegelData, RegelType, Dl, 'Offers', Dl, Year, Dl, Month, Dl);
                if ~exist(StoragePath, 'dir')
                    mkdir(StoragePath)
                end

                while Start<End
                    Col=mod(ceil(k/6)-1,2)+2; % Col is Element of [2 3]
                    Row=mod(k-1,6)+1; % Row is Element of [1 6], one Row for each 4H-Interval
                    TimeTemp=char(LoadedOfferListData(Start,2));
                    if Col==2
                        if Dl=='\'
                            LoadedOfferLists{Row,1}=datetime(strcat(LoadedOfferListData(Start,1), " ", TimeTemp(5:6)), 'InputFormat', 'dd.MM.yyyy HH');
                        else
                            LoadedOfferLists{Row,1}=datetime(strcat(LoadedOfferListData(Start,1), " ", TimeTemp(5:6)), 'InputFormat', 'dd-MMM-yyyy HH', 'Locale', 'de_DE');
                        end
                    end
                    LoadedOfferLists{Row,Col}=[str2double(LoadedOfferListData(Start:End,4)), str2double(LoadedOfferListData(Start:End,5)).*str2double(LoadedOfferListData(Start:End,3)), str2double(LoadedOfferListData(Start:End,6))]; % OfferLists  CapacityPrice[€/MW], EnergyPrice[€/MWh], AllocatedCapacity[MW]
                    [sortedValues, sortOrder] = sort(LoadedOfferLists{Row,Col}(:,2));
                    LoadedOfferLists{Row,Col} = LoadedOfferLists{Row,Col}(sortOrder, :);   
                    Start=End+1;            
                    if End~=size(LoadedOfferListData)
                        End=Start+find(strcmp(LoadedOfferListData(Start:end,2),LoadedOfferListData(Start,2))==0, 1)-2;
                    end
                    if isempty(End)
                        End=size(LoadedOfferListData,1);
                    end
                    if mod(k,12)==0                    
                        StoragePath=strcat(PathRegelData, RegelType, Dl, 'Offers', Dl, Year, Dl, Month, Dl);
                        save(strcat(StoragePath, 'OfferLists_', Year, '-', Month, '-', datestr(LoadedOfferLists{1,1},'dd')), 'LoadedOfferLists', '-v7.3')
                        LoadedOfferLists={}; % Capacity Price [€/MW], Energy Price [€/MWh], Allocated Capacity [MW]
                    end
                    k=k+1;
                end
                waitbar(n/size(Files,1))
            end
            close(h);
        end
            
        %% Caluculate Capacity and Energy Prices
        
        if ProcessDataNewRegelPrices==true
        
            DateCounter=0;
            h=waitbar(0, "Berechne Preise am Regelleistungs- und Regelarbeitsmarkt");
        
            for Date=DateVec
                
                Year=datestr(Date, 'yyyy');
                Month=datestr(Date, 'mm');
                StoragePath=strcat(PathRegelData, RegelType, Dl, 'Prices', Dl, Year, Dl, Month, Dl);
                
                if OnlyAddNewLists && isfile(strcat(StoragePath, 'ResEnPricesData', Year, '-', Month, '-', datestr(Date,'dd'), ".mat")) && isfile(strcat(StoragePath, 'ResPoPricesData', Year, '-', Month, '-', datestr(Date,'dd'), ".mat"))
                    DateCounter=DateCounter+1;
                    waitbar(DateCounter/length(DateVec))
                    continue
                end                
                
                load(strcat(PathRegelData, RegelType, Dl, 'Demand', Dl, Year, Dl, Month, Dl, 'DemandData_', Year, '-', Month, '-', datestr(Date, 'dd'), '.mat'));
                load(strcat(PathRegelData, RegelType, Dl, 'Offers', Dl, Year, Dl, Month, Dl, 'OfferLists_', Year, '-', Month, '-', datestr(Date, 'dd'), '.mat'));
                LoadedResEnPrices=[zeros(length(LoadedDemandData),4), -1000*ones(length(LoadedDemandData),2)]; % Total Amount Payed for Negative Energy [€], Total Amount Payed for Positive Energy [€], Mean Price for Negative Energy [€/MWh], Mean Price for Positive Energy [€/MWh], Marginal Price for Negative Energy [€/MWh], Marginal Price for Positive Energy [€/MWh]
                for Col=1:2
                    for RowDem=1:length(LoadedDemandData)
                        SatisfiedDemand=0;
                        RowOffer=1;
                        while RowOffer<=size(LoadedOfferLists{ceil(RowDem/16),Col+1},1) && SatisfiedDemand<LoadedDemandData(RowDem,Col)
                            AllocatedDemand=min(LoadedOfferLists{ceil(RowDem/16),Col+1}(RowOffer,3), LoadedDemandData(RowDem,Col)-SatisfiedDemand);
                            SatisfiedDemand=SatisfiedDemand+AllocatedDemand;
                            LoadedResEnPrices(RowDem,Col)=LoadedResEnPrices(RowDem,Col)+AllocatedDemand*LoadedOfferLists{ceil(RowDem/16),Col+1}(RowOffer,2);
                            if LoadedOfferLists{ceil(RowDem/16),Col+1}(RowOffer,2)>LoadedResEnPrices(RowDem,4+Col)
                                LoadedResEnPrices(RowDem,4+Col)=LoadedOfferLists{ceil(RowDem/16),Col+1}(RowOffer,2);
                            end
                            RowOffer=RowOffer+1;
                        end
                    end
                end
                LoadedResEnPrices=LoadedResEnPrices/4; % Total Amount Payed for Negative/Positve Energy [€]
                LoadedResEnPrices(:,3)=LoadedResEnPrices(:,1)./LoadedDemandData(:,1)*4; % Mean Price for Negative Energy [€/MWh]. The 4 corrects for the fact that ResPoDemRealQH covers 15min Intervals. In prder to get €/MWh, the Power must be multiplied with 0.25h, hence the whole term is multiplied with 4/h.
                LoadedResEnPrices(:,4)=LoadedResEnPrices(:,2)./LoadedDemandData(:,2)*5; % Mean Price for Positive Energy [€/MWh]

                LoadedResPoPrices=zeros(length(LoadedOfferLists),4); % Mean Capacity Price Negative [€/MW], Mean Capacity Price Positive [€/MW], Marginal Capacity Price Negative [€/MW], Marginal Capacity Price Positive [€/MW]
                for Col=1:2
                    for Row=1:length(LoadedOfferLists)
                        LoadedResPoPrices(Row, Col)=sum(LoadedOfferLists{Row, Col+1}(:,1).*LoadedOfferLists{Row, Col+1}(:,3))/sum(LoadedOfferLists{Row, Col+1}(:,3));
                        LoadedResPoPrices(Row, Col+2)=max(LoadedOfferLists{Row, Col+1}(:,1));
                    end
                end

                
                if ~exist(StoragePath, 'dir')
                    mkdir(StoragePath)
                end
                save(strcat(StoragePath, 'ResEnPricesData', Year, '-', Month, '-', datestr(Date,'dd')), 'LoadedResEnPrices', '-v7.3')
                save(strcat(StoragePath, 'ResPoPricesData', Year, '-', Month, '-', datestr(Date,'dd')), 'LoadedResPoPrices', '-v7.3')

                DateCounter=DateCounter+1;
                waitbar(DateCounter/length(DateVec))
            end

            close(h);
        end
    end
else
    %% Load Data from Storage
    
    ResPoDemRealQH=NaN(round(days(DateEnd-DateStart))*96,2);
    LoadedOfferLists=cell(6*round(days(DateEnd-DateStart)),3);
    ResEnPricesRealQH=NaN(round(days(DateEnd-DateStart))*96,6);
    ResPoPricesReal4H=NaN(round(days(DateEnd-DateStart))*6,4);
    
    h=waitbar(0, 'Lade Regelleistungsmarktdaten von lokalem Pfad');
    DateCounter=0;
    for Date=DateVec
        Year=datestr(Date, 'yyyy');
        Month=datestr(Date, 'mm');
        
        load(strcat(PathRegelData, RegelType, Dl, 'Demand', Dl, Year, Dl, Month, Dl, 'DemandData_', Year, '-', Month, '-', datestr(Date, 'dd'), '.mat'));
        ResPoDemRealQH(DateCounter*96+1:(DateCounter+1)*96,:)=LoadedDemandData;
        
        if Date>=DateStartOffers
            load(strcat(PathRegelData, RegelType, Dl, 'Offers', Dl, Year, Dl, Month, Dl, 'OfferLists_', Year, '-', Month, '-', datestr(Date, 'dd'), '.mat'));
            LoadedOfferLists(DateCounter*6+1:(DateCounter+1)*6,:)=LoadedOfferLists;
            load(strcat(PathRegelData, RegelType, Dl, 'Prices', Dl, Year, Dl, Month, Dl, 'ResEnPricesData', Year, '-', Month, '-', datestr(Date,'dd')));
            ResEnPricesRealQH(DateCounter*96+1:(DateCounter+1)*96,:)=LoadedResEnPrices; % Total Amount Payed for Energy Neg+Pos [€], Mean Price Energy Neg+Pos [€/MWh], Marginal Price Energy Neg+Pos [€/MWh]
            load(strcat(PathRegelData, RegelType, Dl, 'Prices', Dl, Year, Dl, Month, Dl, 'ResPoPricesData', Year, '-', Month, '-', datestr(Date,'dd')));
            ResPoPricesReal4H(DateCounter*6+1:(DateCounter+1)*6,:)=LoadedResPoPrices;
        end
        
        DateCounter=DateCounter+1;
        waitbar(DateCounter/length(DateVec))
    end
    close(h)
end

TimeRegelQH=(DateVec(1):TimeStep:DateEnd)';
TimeRegel4H=(DateVec(1):hours(4):DateEnd)';

clearvars Date LoadedDemandData LoadedOfferLists LoadedResEnPrices LoadedResPoPrices Month PathRegelData RegelType Start StrRange Year 
clearvars ProcessDataNewRegelOfferLists ProcessDataNewRegelDemand DateCounter DateVec h

disp(['Reserve energy data successfully imported ' num2str(toc) 's'])
