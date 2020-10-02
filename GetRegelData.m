%% Description
% This Script loads data downloaded form the regelleistung.net website from
% a local path, processes it and stores it into variables. In specfific, it
% makes use of the reserve energy demand lists (Abrufwerte, 
% https://www.regelleistung.net/ext/data/) and anonym offer lists (Anonyme
% Angebotslisten, https://www.regelleistung.net/apps/datacenter/tenders/)
% for the whole German Netzregelverbund.
% Those lists are used to determine the reserve energy demand and calculate
% the market prices for reserve power and reserve energy using the real
% pricing mechanism. If data of later times shall be considered, those two
% lists have to be downloaded manually from the webpage and must be stored
% appropriately in the RegelData path.
% Notice that as the pricing mechanism changes on 03.11.2020 the website is
% under reconstruction and the links might be not valid anymore. Also it
% has to be considered, that the pricing mechanism changed at 01.08.2019.
% Hence, the calculation of the price data use in this script is only valid
% within this interval (01.08.2019 - 03.11.2020).
% NAN vlaues are replaced by estimates by the function FillMissingValues.
% The function DeleteDST changes the time series such as if there would be
% no Daylight Saving Time. Therefore, in October the doubling occuring hour
% is deleted and in March the missing hour is added by a linear estimate.
% To circumvent datetime issues in Matlab, Tunesian TimeZone is used, as it
% does not consider DST.
%
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   GeneratePrediction.m    Makes us of this data to generate predictors,
%                           prediction models and predictions
%   Demonstration.m         Makes use of this data to visualise the
%                           reserve power and energy market
%
% Abbreviations:
%   - Pred  = Prediction
%   - H     = Hourly
%   - QH    = Quaterly Hour
%
% Description of important variables
%   OnlyAddNewLists:    Control variable. When true, data that was already 
%                       imported to Maltab and stored in mat files is not 
%                       processed newly. Only lists that were not imported
%                       yet are processed, in this case independent whether
%                       they lay inside TimeVec or not! logical (1,1)
%   ProcessDataNewRegelDemand: Control variable. If true, the section that
%                       processes the demand data will be executed. If data
%                       is processed completly new depends on 
%                       OnlyAddNewLists. logical (1,1)
%   ProcessDataNewRegelOfferLists: Control variable. If true, the section 
%                       that processes the offer lists will be 
%                       executed. If data is processed completly new 
%                       depends on OnlyAddNewLists. logical (1,1)
%   ProcessDataNewRegelPrices: Control variable. If true, the section 
%                       that generates the price data from the demand and
%                       market offers will be executed. If data is 
%                       processed completly new depends on OnlyAddNewLists.
%                       logical (1,1)
%   ProcessDataNewRegel: Control variable. Regardless of all other control
%                       variables, if this variable is false, no data will
%                       be processed newly but only stored data from local
%                       mat files. logical (1,1)
%   DateStartOffers:    Determines the data at which the pricing data is
%                       started to be calculated. After the change of the
%                       pricing mechanism at 01.08.2019 it took a while
%                       (one could say it took round about 2.5 months)
%                       until the prices stabilised. In mid of October 2019
%                       the BNetzAG introduced a price offer limit. 
%                       datetime (1,1)
%   RegelType:          Determines for which reserve types data shall be
%                       processed. Yet, only aFRR and mFRR are valid
%                       inputs. FCR has a different pricing mechanism.
%                       String scalar or vector
%   DateVec:            All dates covered by TimeVec. datetime vector


%% Initialisation

tic
PathRegelData=[Path 'Predictions' Dl 'RegelData' Dl];
OnlyAddNewLists=false;
ProcessDataNewRegelDemand=false;
ProcessDataNewRegelOfferLists=false;
ProcessDataNewRegelPrices=false;
DateStartOffers=datetime(2019,08,10,0,0,0,'TimeZone', 'Africa/Tunis');
RegelTypeLoad="aFRR";

StrRange = @(Str, Start, End) Str(Start:End);
close all hidden

DateVec=DateStart:caldays(1):DateEnd;
DateVecPrices=max(DateStart, DateStartOffers):caldays(1):DateEnd;
if DateStart<DateStartOffers
    disp("DateStart is smaller than the beginning of the record of the reserve capacity market (01.09.2019)! Data from this date until DateEnd was loaded instead.")
end

if ProcessDataNewRegel==1
    
    for RegelType=["aFRR" "mFRR"]  % FCR: PRL, aFRR: SRL, mFRR: MRL   iterate through the reserve types     
        
        %% Demand Lists  Date, TimeOfDate_From, TimeOfDate_To, Value Negative Reserve Power[MW], Value Positive Reserve Power[MW], Last Changes
        
        if ProcessDataNewRegelDemand % if true, add new lists or process completely new, if false only load data at the end of the script
            StorageFileMonth=strcat(PathRegelData, RegelType, Dl, 'Ergebnislisten', Dl, 'ABGERUFENE*');
            Files=dir(StorageFileMonth); % find all demand data csv files in local path. the files are all stored in one folder, in this case not in a tree structure
            
            h=waitbar(0, "Verarbeite Regelleistungsabrufwerte");
            for n=1:size(Files,1) % iterate through the files. one csv file covers one month
                
                StartDate=strfind(Files(n).name,"2"); % parse the year and month from the file name. e. g. ABGERUFENE_SRL_BETR_IST-WERTE_20200101_20200131_Netzregelverbund_20200723-133637.CSV
                Year=Files(n).name(StartDate:StartDate+3);
                Month=Files(n).name(StartDate+4:StartDate+5);
                
                if OnlyAddNewLists % if true, only import demand lists to matlab of months that have no corresponding mat file yet
                    DayVec=datetime(strcat(Year, ".", Month, ".01 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'):caldays(1):dateshift(datetime(strcat(Year, ".", Month, ".01 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'),'end','month'); % all days of the month of the file n
                    DataComplete=true;
                    MonthFiles=dir(strcat(PathRegelData, RegelType, Dl, "Demand", Dl, Year, Dl, Month, Dl, "DemandData_*")); % check for which days of this month mat files already exist by reading all existing mat files of this month for demand data
                    ExistingDates=NaT(0,0);
                    
                    for k=1:size(MonthFiles,1)
                        ExistingDates=[ExistingDates; datetime(MonthFiles(k).name(12:21), 'InputFormat', 'yyyy-MM-dd')]; % store those days in ExistingDates
                    end
                    
                    if isempty(find(ismember(DayVec, ExistingDates)==0,1)) % if all days of the month are covered by the existing mat files go ahead with the next csv file
                        waitbar(n/size(Files,1))
                        continue
                    end
                end
                
                LoadedDemandDataMonth=readmatrix([Files(n).folder Dl Files(n).name], 'NumHeaderLines', 5, 'OutputType', 'string'); % if at least one day is not covered, read the data from the csv file. this csv file have following structure: [date, TimeTntervalStart, TimeTntervalEnd, Neg. Demand, Pos. Demand, Comment, Comment, Qual. Neg. Demand, Qual. Pos. Demand]. One row corresponds to one quater hour of recorded demand energy. The Qual. data is similiar to that in the columns before but is published only two months later as it represent more accurate values
                Time=datetime(strcat(LoadedDemandDataMonth(:,1), " ", LoadedDemandDataMonth(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Europe/Berlin'); % extract the beginning of the timer invertal 
                if strcmp(LoadedDemandDataMonth(1,8),'-') % in general, use the qual data for better accuracy but sometimes values are not present yet or missing, then use the normal values
                    LoadedDemandDataMonth=strrep(erase(LoadedDemandDataMonth(:,4:5),'.'), ',','.'); % convert from German decimal format to English
                    disp(strcat("In ", Month, '.', Year, ", for ", RegelType, " the operative Reserve Energy Values had to be used, as the quality-ensured Values are not available."))
                else
                    LoadedDemandDataMonth=strrep(erase(LoadedDemandDataMonth(:,8:9),'.'), ',','.');
                end
                %Time=datetime(strcat(LoadedDemandDataMonth(:,1), " ", LoadedDemandDataMonth(:,2)),'InputFormat','dd.MM.yyyy HH:mm', 'TimeZone', 'Africa/Tunis');            
                DSTChangesQH=find(isdst(Time(1:end-1))~=isdst(Time(2:end))); % List all DST transitions
                DSTChangesQH=[DSTChangesQH month(Time(DSTChangesQH))]; % Add, whether a transitions occurs in October or March            
                LoadedDemandDataMonth=DeleteDST(str2double(LoadedDemandDataMonth), DSTChangesQH, 4); % the demand data of the complete month, without DST inconsistencies
                Time=DeleteDST(Time, DSTChangesQH, 4); % the corresponding time vector

                StoragePath=strcat(PathRegelData, RegelType, Dl, 'Demand', Dl, Year, Dl, Month, Dl); % the loaded data is stored in mat files. there is one folder for each reserve type, inside one folder for each year, one folder for each month. inside the month folders there is one mat file for ine day of demand data
                if ~exist(StoragePath, 'dir') % if the folder does not exist, make it
                    mkdir(StoragePath)
                end
                DateChanges=[0; find(strcmp(string(datestr(Time(1:end-1,:), 'yyyy-mm-dd')),string(datestr(Time(2:end,:), 'yyyy-mm-dd')))==0); size(Time,1)]; % the indices at which there is a date transition in the time vector and LoadedDemandDataMonth vector. Used to split the month into days. One day covers 96 values
                for k=1:size(DateChanges,1)-1 % iterate through the day transitions
                    LoadedDemandData=LoadedDemandDataMonth(DateChanges(k)+1:DateChanges(k+1),:); % split the data into days
                        save(strcat(StoragePath, 'DemandData_', Year, '-', Month, '-', ExtDateStr(num2str(k))), 'LoadedDemandData', '-v7.3') % save one mat file per day
                end
                
                waitbar(n/size(Files,1))
            end
            close(h);
        end
        
        %% Offer Lists  Date_From, Date_To, Type_Of_Reserve, Product, Capacity_Price[€/MW], Energy_Price[€/MWh], Offered_Capacity[MW], Allocated_Capacity[MW], Country    
        
        if ProcessDataNewRegelOfferLists==1
            
            h=waitbar(0, "Verarbeite Regelleistungsangebotslisten");
            
            StorageFileMonth=strcat(PathRegelData, RegelType, Dl, 'Angebotslisten', Dl, 'RESULT_LIST*'); % All OfferLists are located in this path 
            Files=dir(StorageFileMonth); % they are named like RESULT_LIST_ANONYM_aFRR_DE_2020-01-01_2020-01-31.xlsx
            
            for n=1:size(Files,1) % iterate through all found OfferList files
                Month=StrRange(Files(n).name, 33, 34); % exctract month ...
                Year=StrRange(Files(n).name, 28, 31);  % ... and yera from file name
                
                if OnlyAddNewLists==true % if true, only process xslx files newly when there is not a corresponding mat file 
                    if Month=="07" && Year=="2018" % form this month on OfferLists exist. The list of 07.2018 starts at 12.07.2017
                        DayVec=datetime(strcat(Year, ".", Month, ".12 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'):caldays(1):dateshift(datetime(strcat(Year, ".", Month, ".01 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'),'end','month'); % get all days of month of OfferList file
                    else
                        DayVec=datetime(strcat(Year, ".", Month, ".01 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'):caldays(1):dateshift(datetime(strcat(Year, ".", Month, ".01 00:00:00"), 'InputFormat', 'yyyy.MM.dd HH:mm:ss'),'end','month');
                    end
                    
                    DataComplete=true; 
                    MonthFiles=dir(strcat(PathRegelData, RegelType, Dl, "Offers", Dl, Year, Dl, Month, Dl, "OfferLists_*")); % check if which corresponding mat files exist
                    ExistingDates=NaT(0,0);
                    
                    for k=1:size(MonthFiles,1)
                        ExistingDates=[ExistingDates; datetime(MonthFiles(k).name(12:21), 'InputFormat', 'yyyy-MM-dd')]; % all days a corresponding mat file already exists
                    end
                    
                    if isempty(find(ismember(DayVec, ExistingDates)==0,1)) % if there is not a single day missing, then go ahead with the next month file
                        waitbar(n/size(Files,1))
                        continue
                    end
                end
                
                if Dl=='\' % windows and linux read the dara from xlsx differently. this one is for windows
                    [LoadedOfferListData,LoadedOfferListData2]=xlsread([Files(n).folder Dl Files(n).name]); % read data from xlsx file as there is at least one day without a corresponding mat file or OnlyAddNewLists is false. the files are organised like this: [DATE_FROM, DATE_TO, TYPE_OF_RESERVES, PRODUCT	CAPACITY_PRICE_[EUR/MW], ENERGY_PRICE_[EUR/MWh], ENERGY_PRICE_PAYMENT_DIRECTION, OFFERED_CAPACITY_[MW], ALLOCATED_CAPACITY_[MW], COUNTRY, NOTE]
                    LoadedOfferListData=erase([string(LoadedOfferListData2(2:end,[2 4 7])), num2str(LoadedOfferListData(:,1)), num2str(LoadedOfferListData(:,2)), num2str(LoadedOfferListData(:,5))],' '); % parse it
                else % this one for linux
                    LoadedOfferListData=readmatrix(Files(n), 'OutputType', 'string');
                    LoadedOfferListData=erase(LoadedOfferListData(1:end, [2 4 7 5:6 9]), ' ');
                end
                LoadedOfferListData(:,3)=strrep(LoadedOfferListData(:,3), 'GRID_TO_PROVIDER', '1'); % if one market participant offers a negative energy price, it wont get a minus sign in the list. the sign is indicated by the labels GRID_TO_PROVIDER (equal to a positive price) and PROVIDER_TO_GRID (equal to a negative price). 
                LoadedOfferListData(:,3)=strrep(LoadedOfferListData(:,3), 'PROVIDER_TO_GRID', '-1'); % this shall be corrected, so replace the labels with numbers indicating the sign

%                 DemandData=[];
%                           
%                 StoragePathMonth=strcat(PathRegelData, RegelType, Dl, 'Demand', Dl, Year, Dl, Month); % start to load the corresponding demand data for this month from mat files generated before
%                 for Date=datetime(LoadedOfferListData(1,1), 'InputFormat', 'dd.MM.yyyy'):caldays(1):datetime(LoadedOfferListData(end,1), 'InputFormat', 'dd.MM.yyyy') % open demand data file for each day of the month
%                     load(strcat(StoragePathMonth, Dl, 'DemandData_', Year, '-', Month, '-', datestr(Date, 'dd'), '.mat')) % load it to workspace
%                     DemandData=[DemandData; LoadedDemandData]; % add it to this time series
%                 end
  
                StoragePath=strcat(PathRegelData, RegelType, Dl, 'Offers', Dl, Year, Dl, Month, Dl); % make a path where the results can be stored
                if ~exist(StoragePath, 'dir')
                    mkdir(StoragePath)
                end
                
                % now, the OfferLists are split into separate lists. 
                % each lists covers all offers for one product 
                % (e. g. negative control reserve from 00:00 until 04:00 
                % of 01.01.2020). all 12 lists of one day are stored in 
                % one LoadedOfferLists and saved as one mat file

                LoadedOfferLists={}; % Capacity Price [€/MW], Energy Price [€/MWh], Allocated Capacity [MW] only those information are relevant, the time can be extracted from the position in the vector (row index)
                Start=1; % only initialisation. the OfferList has to be sperated into sub lists. one sub lists covers all offers of one product. this is the start index
                End=Start+find(strcmp(LoadedOfferListData(Start:end,2),LoadedOfferListData(Start,2))==0, 1)-2; % and this is the end index of the sublist
                k=1;  
                while Start<End % iterate thorugh the whole list of one month and break if the end is reached
                    Col=mod(ceil(k/6)-1,2)+2; % Col is Element of [2 3], col 2: negative sublists, col 3: positive sublists
                    Row=mod(k-1,6)+1; % Row is Element of [1 6], one Row for each 4H-Interval, row 1 00:00-04:00, row 2 04:00-08:00 and so on
                    TimeTemp=char(LoadedOfferListData(Start,2)); % the label of the current product, e. g. NEG_00_04
                    if Col==2
                        if Dl=='\' % time format is different in windows compared to linux. this is windows format
                            LoadedOfferLists{Row,1}=datetime(strcat(LoadedOfferListData(Start,1), " ", TimeTemp(5:6)), 'InputFormat', 'dd.MM.yyyy HH');
                        else
                            LoadedOfferLists{Row,1}=datetime(strcat(LoadedOfferListData(Start,1), " ", TimeTemp(5:6)), 'InputFormat', 'dd-MMM-yyyy HH', 'Locale', 'de_DE');
                        end
                    end
                    LoadedOfferLists{Row,Col}=[str2double(LoadedOfferListData(Start:End,4)), str2double(LoadedOfferListData(Start:End,5)).*str2double(LoadedOfferListData(Start:End,3)), str2double(LoadedOfferListData(Start:End,6))]; % OfferLists  CapacityPrice[€/MW], EnergyPrice[€/MWh], AllocatedCapacity[MW]. store extracted sublist in variable
                    [sortedValues, sortOrder] = sort(LoadedOfferLists{Row,Col}(:,2)); % sort it according to energy price so that the merit order is generated
                    LoadedOfferLists{Row,Col} = LoadedOfferLists{Row,Col}(sortOrder, :);   
                    Start=End+1; % the starting index of the next sublist
                    if End~=size(LoadedOfferListData)
                        End=Start+find(strcmp(LoadedOfferListData(Start:end,2),LoadedOfferListData(Start,2))==0, 1)-2; % find the end of the next sublist
                    end
                    if isempty(End)
                        End=size(LoadedOfferListData,1);
                    end
                    if mod(k,12)==0 % if all sublists of one day are generated, store the data in a mat file
                        StoragePath=strcat(PathRegelData, RegelType, Dl, 'Offers', Dl, Year, Dl, Month, Dl);
                        save(strcat(StoragePath, 'OfferLists_', Year, '-', Month, '-', datestr(LoadedOfferLists{1,1},'dd')), 'LoadedOfferLists', '-v7.3')
                        LoadedOfferLists={}; % Capacity Price [€/MW], Energy Price [€/MWh], Allocated Capacity [MW]
                    end
                    k=k+1; % counter for the sublists
                end
                waitbar(n/size(Files,1))
            end
            close(h);
        end
            
        %% Caluculate Capacity and Energy Prices
        
        % in this section from the OfferLists and the demand data, the real
        % paid power and energy prices will be reconstructed applying the 
        % real pricing mechanism. the power prices are trivial. they are 
        % shown directly in the OfferLists. The OfferLists represent the
        % merit order with resepect to the power prices. every  participant
        % who made it to the list gets the its power price, independent 
        % from the whether he supplied reserve energy later. the energy 
        % prices are more difficult as it is compensated pay per use. in 
        % case of the need of reserve energy, the TSO assigns the plants 
        % with the lowest reserve energy costs to supply energy at first. 
        % over the 4h period, only some participants will supply energy.
        % their energy supply varies during a 4h interval as the demand 
        % varies as well. in order to get to know the real energy prices 
        % paid, for every 15 min interval a merit oder is used, sorted by 
        % the energy price. then the cheapest offers are choosen.
        
        if ProcessDataNewRegelPrices==true
        
            DateCounter=0;
            h=waitbar(0, "Berechne Preise am Regelleistungs- und Regelarbeitsmarkt");
        
            for Date=DateVecPrices % iterate thorugh all days of defined time range
                
                Year=datestr(Date, 'yyyy'); % extract year
                Month=datestr(Date, 'mm'); % and month
                StoragePath=strcat(PathRegelData, RegelType, Dl, 'Prices', Dl, Year, Dl, Month, Dl); % to open the Demand data OfferLists mat files from local path for this day specified by Date
                
                if OnlyAddNewLists && isfile(strcat(StoragePath, 'ResEnPricesData', Year, '-', Month, '-', datestr(Date,'dd'), ".mat")) && isfile(strcat(StoragePath, 'ResPoPricesData', Year, '-', Month, '-', datestr(Date,'dd'), ".mat")) % check if the price data already exists
                    DateCounter=DateCounter+1;
                    waitbar(DateCounter/length(DateVecPrices))
                    continue % if it exists, go ahead with the next date
                end                
                
                load(strcat(PathRegelData, RegelType, Dl, 'Demand', Dl, Year, Dl, Month, Dl, 'DemandData_', Year, '-', Month, '-', datestr(Date, 'dd'), '.mat')); % load demand data 
                load(strcat(PathRegelData, RegelType, Dl, 'Offers', Dl, Year, Dl, Month, Dl, 'OfferLists_', Year, '-', Month, '-', datestr(Date, 'dd'), '.mat')); % load OfferLists
                LoadedResEnPrices=[zeros(length(LoadedDemandData),4), -1000*ones(length(LoadedDemandData),2), zeros(length(LoadedDemandData),2)]; % [Total Amount Payed for Energy Neg [€],  Total Amount Payed for Energy Pos [€], Mean Price Energy Neg [€/MWh], Mean Price Energy Pos [€/MWh], Marginal Price Energy Neg [€/MWh], Marginal Price Energy Pos [€/MWh], Min Price Energy Neg [€/MWh], Min Price Energy Pos [€/MWh]]. in this matrix all information about the real paid energy prices will be stored
                
                for Col=1:2 % iterate through the columns of LoadedOfferLists. (Col==1: negative reserve energy, Col==2: positive reserve energy)
                    for RowDem=1:length(LoadedDemandData) % iterate through the quater hours one day. length(LoadedDemandData)==96
                        SatisfiedDemand=0; % satisfy the energy demand by using the power capacity of the cheapest energy offers accoring to the merit order list. e. g.: if demand==15 MW, then the add up the power capacities of the cheapest technical systems until 15 MW are reached. the owner of each technical system supplies energy will get its offered energy price for the energy it supplied. all execpt from the marginal supplier will use the maximal capacity power
                        RowOffer=1;
                        while RowOffer<=size(LoadedOfferLists{ceil(RowDem/16),Col+1},1) && SatisfiedDemand<LoadedDemandData(RowDem,Col) % iterate through all offers, until the demand for this quater hour is satisfied
                            AllocatedDemand=min(LoadedOfferLists{ceil(RowDem/16),Col+1}(RowOffer,3), LoadedDemandData(RowDem,Col)-SatisfiedDemand); % the amount of enegry that is already allocated. per iteration it is the minimum of remaining demand and maximum power capacity of the supplier of this row
                            SatisfiedDemand=SatisfiedDemand+AllocatedDemand;
                            LoadedResEnPrices(RowDem,Col)=LoadedResEnPrices(RowDem,Col)+AllocatedDemand*LoadedOfferLists{ceil(RowDem/16),Col+1}(RowOffer,2); % add up the paid amount of money in this variable to calculate average prices later on. it is calculated by the product of supplied power and the offered energy price by this specific supplier
                            
                            if LoadedOfferLists{ceil(RowDem/16),Col+1}(RowOffer,2)>LoadedResEnPrices(RowDem,4+Col) % find the marginal price of this quater hour. this condition might be unnecessary as the price only grows as we iterate through the merit order list
                                LoadedResEnPrices(RowDem,4+Col)=LoadedOfferLists{ceil(RowDem/16),Col+1}(RowOffer,2); % save the marginal price
                            end
                            
                            RowOffer=RowOffer+1; % jump to the next supplier in the merit order list
                        end
                        
                        LoadedResEnPrices(RowDem,6+Col)=LoadedOfferLists{ceil(RowDem/16),Col+1}(1,2); % save the lowest reserve energy offer;
                        
                    end
                end
                LoadedResEnPrices(:,1:2)=LoadedResEnPrices(:,1:2)/4; % Total Amount Payed for Negative/Positve Energy [€]. has to be divided by 4 as the prices are given in €/MWh but we consider quater hours
                LoadedResEnPrices(:,3)=LoadedResEnPrices(:,1)./LoadedDemandData(:,1)*4; % Mean Price for Negative Energy [€/MWh]. Same as above, the 4 corrects for the fact that LoadedDemandData covers 15min Intervals. In order to get €/MWh, the Power must be multiplied with 0.25h, hence the whole term is multiplied with 4/h.
                LoadedResEnPrices(:,4)=LoadedResEnPrices(:,2)./LoadedDemandData(:,2)*4; % Mean Price for Positive Energy [€/MWh]
                
                % now the real paid resevere power prices are calculated,
                % which is much more easy, as they are fixed and given in
                % the OfferLists. Just multiply all allocated power
                % capacities the the offered power prices for each
                % supplier and add the products all up.

                LoadedResPoPrices=zeros(length(LoadedOfferLists),8); % [Total Amount Payed for Neg Power [€],  Total Amount Payed for Pos Power [€], Neg. average price [€/MW], Pos. average price [€/MW], Neg. marginal price [€/MW], Pos. marginal price [€/MW], Neg. minimum prices [€/MW], Pos. minimum price [€/MW]]
                for Col=1:2 % iterate through the columns of LoadedOfferLists. (Col==1: negative reserve energy, Col==2: positive reserve energy)
                    for Row=1:length(LoadedOfferLists) % iterate through the quater hours one day. length(LoadedDemandData)==96
                        LoadedResPoPrices(Row, Col)=sum(LoadedOfferLists{Row, Col+1}(:,1).*LoadedOfferLists{Row, Col+1}(:,3)); % [€] toal amount payed for reserve capacity by TSOs
                        LoadedResPoPrices(Row, Col+2)=sum(LoadedOfferLists{Row, Col+1}(:,1).*LoadedOfferLists{Row, Col+1}(:,3))/sum(LoadedOfferLists{Row, Col+1}(:,3)); % [€/MW] average price. multiply power and price for each supplier. sum all products up and divide by the overall power demand in order to get an average
                        LoadedResPoPrices(Row, Col+4)=max(LoadedOfferLists{Row, Col+1}(:,1)); % [€/MW] find the marginal price
                        LoadedResPoPrices(Row, Col+6)=min(LoadedOfferLists{Row, Col+1}(:,1)); % [€/MW] find the minimum price 
                    end
                end

                
                if ~exist(StoragePath, 'dir') % make dir if it not exists
                    mkdir(StoragePath)
                end
                save(strcat(StoragePath, 'ResEnPricesData', Year, '-', Month, '-', datestr(Date,'dd')), 'LoadedResEnPrices', '-v7.3') % save the reserve energy prices
                save(strcat(StoragePath, 'ResPoPricesData', Year, '-', Month, '-', datestr(Date,'dd')), 'LoadedResPoPrices', '-v7.3') % save the reserve power prices

                DateCounter=DateCounter+1;
                waitbar(DateCounter/length(DateVecPrices))
            end

            close(h);
        end
    end
end

%% Load Data from Storage

ResPoDemRealQH=NaN(round(days(DateEnd-DateStart))*96,2); % ReservePowerDemandRealMeasuredQuaterHourly
OfferLists=cell(6*round(days(DateEnd-DateStart)),3);
ResEnPricesRealQH=NaN(round(days(DateEnd-DateStart))*96,8); % ReserveEnergyPricesQuaterHourly
ResPoPricesReal4H=NaN(round(days(DateEnd-DateStart))*6,8); % ReservePowerPrices4hInterval

h=waitbar(0, 'Lade Regelleistungsmarktdaten von lokalem Pfad');
DateCounter=0;
for Date=DateVec % iterate through the days between DateStart and DateEnd
    Year=datestr(Date, 'yyyy');
    Month=datestr(Date, 'mm');

    load(strcat(PathRegelData, RegelTypeLoad, Dl, 'Demand', Dl, Year, Dl, Month, Dl, 'DemandData_', Year, '-', Month, '-', datestr(Date, 'dd'), '.mat')); % load processed demand file
    ResPoDemRealQH(DateCounter*96+1:(DateCounter+1)*96,:)=LoadedDemandData; % add it to ResPoDemRealQH at the right place within the vector, such that the rows of this variable correspomd to the rows of TimeVec

    if Date>=DateStartOffers % if price data exists
        load(strcat(PathRegelData, RegelTypeLoad, Dl, 'Offers', Dl, Year, Dl, Month, Dl, 'OfferLists_', Year, '-', Month, '-', datestr(Date, 'dd'), '.mat')); % same mechanism as above
        OfferLists(DateCounter*6+1:(DateCounter+1)*6,:)=LoadedOfferLists; % [Time, Neg. OfferLists, Pos. OfferLists]
        load(strcat(PathRegelData, RegelTypeLoad, Dl, 'Prices', Dl, Year, Dl, Month, Dl, 'ResEnPricesData', Year, '-', Month, '-', datestr(Date,'dd')));
        ResEnPricesRealQH(DateCounter*96+1:(DateCounter+1)*96,:)=LoadedResEnPrices; % [Total Amount Payed for Energy Neg [€],  Total Amount Payed for Energy Pos [€], Mean Price Energy Neg [€/MWh], Mean Price Energy Pos [€/MWh], Marginal Price Energy Neg [€/MWh], Marginal Price Energy Pos [€/MWh], Min Price Energy Neg [€/MWh], Min Price Energy Pos [€/MWh]]
        load(strcat(PathRegelData, RegelTypeLoad, Dl, 'Prices', Dl, Year, Dl, Month, Dl, 'ResPoPricesData', Year, '-', Month, '-', datestr(Date,'dd')));
        ResPoPricesReal4H(DateCounter*6+1:(DateCounter+1)*6,:)=LoadedResPoPrices; % [Total Amount Payed for Neg Power [€],  Total Amount Payed for Pos Power [€], Neg. average price [€/MW], Pos. average price [€/MW], Neg. marginal price [€/MW], Pos. marginal price [€/MW], Neg. minimum prices [€/MW], Pos. minimum price [€/MW]]
    end

    DateCounter=DateCounter+1;
    waitbar(DateCounter/length(DateVec))
end
close(h)

TimeRegelQH=(DateVec(1):TimeStep:DateEnd)';
TimeRegel4H=(DateVec(1):hours(4):DateEnd)';

disp(['Reserve energy data successfully imported ' num2str(toc) 's'])

%% Clean up workspace

clearvars Date LoadedDemandData LoadedOfferLists LoadedResEnPrices LoadedResPoPrices Month PathRegelData RegelType RegelTypeLoad Start StrRange Year 
clearvars ProcessDataNewRegelOfferLists ProcessDataNewRegelDemand DateCounter DateVec h DayVec
