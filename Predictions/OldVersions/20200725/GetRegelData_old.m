%% Description
% This Script loads data downloaded form the regelleostung.net website from
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
PathRegelData=[Path 'Predictions' Dl 'RegelData' Dl];
RegelType='aFRR'; % FCR: PRL, aFRR: SRL, mFRR: MRL
StorageFile=strcat(PathRegelData, RegelType, Dl, RegelType, 'Data' , TimeIntervalFile, '.mat');
DateStart=datetime(2020,04,1,0,0,0, 'TimeZone', 'Africa/Tunis');
DateEnd=datetime(2020,05,31,23,45,0, 'TimeZone', 'Africa/Tunis');

%% Get Data From Files
if ~isfile(StorageFile) || ProcessDataNewRegel==1  

    %% Offer Lists  Date_From, Date_To, Type_Of_Reserve, Product, Capacity_Price[€/MW], Energy_Price[€/MWh], Offered_Capacity[MW], Allocated_Capacity[MW], Country    
    
    if strcmp(RegelType,'FCR')
        RegelTypeGer='PRL';
    elseif strcmp(RegelType,'aFRR')
        RegelTypeGer='SRL';
    elseif strcmp(RegelType,'mFRR')
        RegelTypeGer='MRL';    
    else
        disp('Invalid Reserve Type Name')
    end

    MonthList=NaT(months(datenum(DateStart), datenum(DateEnd))+1,2, 'TimeZone', 'Europe/Berlin');
    for n=1:size(MonthList,1)
        MonthList(n,1)=DateStart+calmonths(n-1);
        MonthList(n,2)=eomdate(MonthList(n,1));
    end

    ResOffersLists4H=cell(size(MonthList,1),1); % Date, Sign and Time of Day, Payment Direction, Capacity Price[€/MW], Enegry Price[€/MWh], Allocated Capacity[MW]
    for n=1:size(MonthList,1)        
        if Dl=='\'
            [ResOffersLists4H{n,1},ResOffersLists4H{n,2}]=xlsread(strcat(PathRegelData, RegelType, Dl, 'Angebotslisten', Dl, 'RESULT_LIST_ANONYM_', RegelType, '_DE_', datestr(MonthList(n,1), 'yyyy-mm-dd'), '_', datestr(MonthList(n,2), 'yyyy-mm-dd'), '.xlsx'));
            ResOffersLists4H{n,1}=erase([string(ResOffersLists4H{n,2}(2:end,[2 4 7])), num2str(ResOffersLists4H{n,1}(:,1)), num2str(ResOffersLists4H{n,1}(:,2)), num2str(ResOffersLists4H{n,1}(:,5))],' '); 
            ResOffersLists4H(:,2)=[];
        else            
            ResOffersLists4H{n,1}=readmatrix(strcat(PathRegelData, RegelType, Dl, 'Angebotslisten', Dl, 'RESULT_LIST_ANONYM_', RegelType, '_DE_', datestr(MonthList(n,1), 'yyyy-mm-dd'), '_', datestr(MonthList(n,2), 'yyyy-mm-dd'), '.xlsx'), 'OutputType', 'string');
            ResOffersLists4H{n,1}=erase(ResOffersLists4H{n,1}(1:end, [2 4 7 5:6 9]), ' ');
        end
        ResOffersLists4H{n,1}(:,3)=strrep(ResOffersLists4H{n,1}(:,3), 'GRID_TO_PROVIDER', '1');
        ResOffersLists4H{n,1}(:,3)=strrep(ResOffersLists4H{n,1}(:,3), 'PROVIDER_TO_GRID', '-1');        
    end    
    
    ResOffers4H={}; % Capacity Price [€/MW], Energy Price [€/MWh], Allocated Capacity [MW]
    k=1;
    for n=1:size(MonthList,1)        
        Start=1;
        End=Start+find(strcmp(ResOffersLists4H{n}(Start:end,2),ResOffersLists4H{n}(Start,2))==0, 1)-2;
        
        while Start<End
            Col=mod(ceil(k/6)-1,2)+2; % Col is Element of [2 3]
            Row=floor((k-1)/12)*6+mod(k-1,6)+1; % Row is Element of [1 6], one Row for each 4H-Interval
            TimeTemp=char(ResOffersLists4H{n}(Start,2));
            if Col==2
                if Dl=='\'
                    ResOffers4H{Row,1}=datetime(strcat(ResOffersLists4H{n}(Start,1), " ", TimeTemp(5:6)), 'InputFormat', 'dd.MM.yyyy HH');
                else
                    ResOffers4H{Row,1}=datetime(strcat(ResOffersLists4H{n}(Start,1), " ", TimeTemp(5:6)), 'InputFormat', 'dd-MMM-yyyy HH', 'Locale', 'de_DE');
                end
            end
            ResOffers4H{Row,Col}=[str2double(ResOffersLists4H{n}(Start:End,4)), str2double(ResOffersLists4H{n}(Start:End,5)).*str2double(ResOffersLists4H{n}(Start:End,3)), str2double(ResOffersLists4H{n}(Start:End,6))]; % OfferLists  CapacityPrice[€/MW], EnergyPrice[€/MWh], AllocatedCapacity[MW]
            [sortedValues, sortOrder] = sort(ResOffers4H{Row,Col}(:,2));
            ResOffers4H{Row,Col} = ResOffers4H{Row,Col}(sortOrder, :);   
            Start=End+1;            
            if End~=size(ResOffersLists4H{n})
                End=Start+find(strcmp(ResOffersLists4H{n}(Start:end,2),ResOffersLists4H{n}(Start,2))==0, 1)-2;
            end
            if isempty(End)
                End=size(ResOffersLists4H{n},1);
            end
            k=k+1;
        end
    end    
    Time4H=[ResOffers4H{:,1}]';
    
    clearvars ResOffersLists4H Row Col sortOrder TimeTemp End Start

    %% Demand Lists  Date, TimeOfDate_From, TimeOfDate_To, Value Negative Reserve Power[MW], Value Positive Reserve Power[MW], Last Changes    

    ResPoDemListsQH{n}={};
    ResPoDemRealQH=[];
    TimeRLQH=[];
    temp=[];
	for n=1:size(MonthList,1)
        PathDir=dir(strcat(PathRegelData, RegelType, Dl, 'Ergebnislisten', Dl, 'ABGERUFENE_ ', RegelTypeGer, '_BETR_IST-WERTE_', datestr(MonthList(n,1), 'yyyymmdd'), '_', datestr(MonthList(n,2), 'yyyymmdd'), '*'));
        ResPoDemListsQH{n}=readmatrix(PathDir.name, 'NumHeaderLines', 5, 'OutputType', 'string');
        if strcmp(ResPoDemListsQH{n}(1,8),'-')
            ResPoDemRealQH=[ResPoDemRealQH; strrep(erase(ResPoDemListsQH{n}(:,4:5),'.'), ',','.')];
            disp(strcat("In ", datestr(MonthList(n), 'mmm yyyy'), ", operative Reserve Energy Values had to be used, as the quality-ensured Values are not available."))
        else
            ResPoDemRealQH=[ResPoDemRealQH; strrep(erase(ResPoDemListsQH{n}(:,8:9),'.'), ',','.')];
        end
        TimeRLQH=[TimeRLQH; datetime(strcat(ResPoDemListsQH{n}(:,1), " ", ResPoDemListsQH{n}(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Africa/Tunis')];
        temp=[temp; datetime(strcat(ResPoDemListsQH{n}(:,1), " ", ResPoDemListsQH{n}(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Europe/Berlin')];
    end    
    DSTChangesQH=find(isdst(temp(1:end-1))~=isdst(temp(2:end))); % List all DST transitions
    DSTChangesQH=[DSTChangesQH month(temp(DSTChangesQH))]; % Add, whether a transitions occurs in October or March                
    ResPoDemRealQH=DeleteDST(FillMissingValues(str2double(ResPoDemRealQH),4), DSTChangesQH, 4);
    TimeRLQH=DeleteDST(TimeRLQH, DSTChangesQH, 4);   
    
    %% Caluculate Capacity and Energy Prices
     
    ResEnPricesRealQH=[zeros(length(ResPoDemRealQH),4), -1000*ones(length(ResPoDemRealQH),2)]; % Total Amount Payed for Negative Energy [€], Total Amount Payed for Positive Energy [€], Mean Price for Negative Energy [€/MWh], Mean Price for Positive Energy [€/MWh], Marginal Price for Negative Energy [€/MWh], Marginal Price for Positive Energy [€/MWh]
    for Col=1:2
        for RowDem=1:length(ResPoDemRealQH)        
            SatisfiedDemand=0;                        
            RowOffer=1;            
            while SatisfiedDemand<ResPoDemRealQH(RowDem,Col)                
                AllocatedDemand=min(ResOffers4H{ceil(RowDem/16),Col+1}(RowOffer,3), ResPoDemRealQH(RowDem,Col)-SatisfiedDemand);
                SatisfiedDemand=SatisfiedDemand+AllocatedDemand;
                ResEnPricesRealQH(RowDem,Col)=ResEnPricesRealQH(RowDem,Col)+AllocatedDemand*ResOffers4H{ceil(RowDem/16),Col+1}(RowOffer,2);
                if ResOffers4H{ceil(RowDem/16),Col+1}(RowOffer,2)>ResEnPricesRealQH(RowDem,4+Col)
                    ResEnPricesRealQH(RowDem,4+Col)=ResOffers4H{ceil(RowDem/16),Col+1}(RowOffer,2);
                end
                RowOffer=RowOffer+1;
            end                                
        end        
    end
    ResEnPricesRealQH=ResEnPricesRealQH/4; % Total Amount Payed for Negative/Positve Energy [€]
    ResEnPricesRealQH(:,3)=ResEnPricesRealQH(:,1)./ResPoDemRealQH(:,1)*4; % Mean Price for Negative Energy [€/MWh]. The 4 corrects for the fact that ResPoDemRealQH covers 15min Intervals. In prder to get €/MWh, the Power must be multiplied with 0.25h, hence the whole term is multiplied with 4/h.
    ResEnPricesRealQH(:,4)=ResEnPricesRealQH(:,2)./ResPoDemRealQH(:,2)*5; % Mean Price for Positive Energy [€/MWh]
    
    ResPoPricesReal4H=zeros(length(ResOffers4H),4); % Mean Capacity Price Negative [€/MW], Mean Capacity Price Positive [€/MW], Marginal Capacity Price Negative [€/MW], Marginal Capacity Price Positive [€/MW]
    for Col=1:2
        for Row=1:length(ResOffers4H)
            ResPoPricesReal4H(Row, Col)=sum(ResOffers4H{Row, Col+1}(:,1).*ResOffers4H{Row, Col+1}(:,3))/sum(ResOffers4H{Row, Col+1}(:,3));
            ResPoPricesReal4H(Row, Col+2)=max(ResOffers4H{Row, Col+1}(:,1));
        end
    end     
    
    
    
    %% Save Data
    save(StorageFile, 'ResOffers4H', 'ResPoDemRealQH', 'ResEnPricesRealQH', 'ResPoPricesReal4H', 'Time4H',  "-v7.3")
    
    disp(['Reserve Capacity Market Data successfully imported ' num2str(toc) 's'])
else
    load(StorageFile)
end


clearvars PathRegelData RegelType StorageFile ProcessDataNewRegel MonthList n DSTChangesQH RegelTypeGer RegelType temp TimeRLQH...
    ResEnergyDemandListsQH Col Row RowDem RowOffer SatisfiedDemand AllocatedDemand k sortedValues