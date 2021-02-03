%% Initialisation
tic
NumUsers=15000;
SmartCharging=true;
UseParallel=true;
UseSpotPredictions=true;
UsePVPredictions=true;
UseIndividualEEGBonus=true;

ControlPeriods=96*2;
UsePV=true;
ApplyGridConvenientCharging=true;
ActivateWaitbar=true;
SaveResults=true;

% SensitivitEURtsanalyse: ResPoPriceFactor, ResEnPriceFactor, ResPoBuffer

rng('default');
rng(1);
TSim=tic;

if SmartCharging
    if UseParallel
        NumDecissionGroups=200;
        gcp
    else
        NumDecissionGroups=1;
    end
end


if ~exist('PublicChargerDistribution', 'var')
    PublicChargerDistribution=readmatrix(strcat(Path.Simulation, "PublicChargerProbability.xlsx"));
end

NumUsers=min(NumUsers, size(Users,1)-1);
ChargingPower=zeros(NumUsers,1);
EnergyDemandLeft=zeros(NumUsers+1,1);
delete(findall(0,'type','figure','tag','TMWWaitbar'));

Time.Sim=Users{1}.Time;
TD.Main=find(ismember(Time.Vec,Time.Sim.Start),1)-1;
TD.User=find(ismember(Users{1}.Time.Vec,Time.Sim.Start),1)-1;

UserNum=2:NumUsers+1;

if ~isfield(Users{1}, "TotalCostsIt")
    Users{1}.TotalCostsIt={};
end


for NumDecissionGroups=[375]

    
for n=UserNum
    Users{n}.Logbook=double(Users{n}.LogbookSource);
    if ApplyGridConvenientCharging
        Users{n}.NNEEnergyPrice=Users{n}.NNEEnergyPriceGridConvenientCharging;
    else
        Users{n}.NNEEnergyPrice=Users{n}.NNEEnergyPriceNotGridConvenientCharging;
    end
    
    Users{n}.EEGBonus=Users{1}.EEGBonus;
    if UseIndividualEEGBonus && Users{n}.PVPlantExists
        Users{n}.EEGBonus=PVPlants{Users{n}.PVPlant}.EEGBonus;
    end
end


if SmartCharging
    TimeOfPreAlgo=[datetime(1,1,1,8,0,0,'TimeZone','Africa/Tunis'), datetime(1,1,1,12,0,0,'TimeZone','Africa/Tunis'), datetime(1,1,1,16,0,0,'TimeZone','Africa/Tunis'), datetime(1,1,1,20,0,0,'TimeZone','Africa/Tunis'), datetime(1,1,1,0,0,0,'TimeZone','Africa/Tunis'), datetime(1,1,1,4,0,0,'TimeZone','Africa/Tunis')];
    TimeOfReserveMarketOffer=datetime(1,1,1,8,0,0,'TimeZone','Africa/Tunis');
    TimeOfDayAheadMarketPriceRelease=datetime(1,1,1,13,0,0,'TimeZone','Africa/Tunis');
	ShiftInds=(hour(TimeOfPreAlgo(1))*Time.StepInd + minute(TimeOfPreAlgo(1))/minutes(Time.Step));
    TimesOfPreAlgo=[(hour(TimeOfPreAlgo(1))*Time.StepInd + minute(TimeOfPreAlgo(1))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    (hour(TimeOfPreAlgo(2))*Time.StepInd + minute(TimeOfPreAlgo(2))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    (hour(TimeOfPreAlgo(3))*Time.StepInd + minute(TimeOfPreAlgo(3))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    (hour(TimeOfPreAlgo(4))*Time.StepInd + minute(TimeOfPreAlgo(4))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    (hour(TimeOfPreAlgo(5))*Time.StepInd + minute(TimeOfPreAlgo(5))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    (hour(TimeOfPreAlgo(6))*Time.StepInd + minute(TimeOfPreAlgo(6))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    ];
    TimesOfZeitscheiben=mod(16-hour(Time.Sim.Vec(1))*4 + minute(Time.Sim.Vec(1)),16)+1:4*Time.StepInd:length(Time.Sim.VecInd);
    TimesOfDayAheadMarketPriceRelease=(hour(TimeOfDayAheadMarketPriceRelease)*Time.StepInd + minute(TimeOfDayAheadMarketPriceRelease)/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);

    InitialisePreAlgo;
    InitialiseLiveAlgo;
    
    if UseSpotPredictions
        if ~exist("SpotmarketPricesPred1", "var")
            %[StorageFile, StoragePath]=uigetfile(strcat(Path.Prediction, "DayaheadRealH", Dl), 'Select the first Spotmarket Prediction');
            StorageFile="LSQ_20210202-1210_20180101-20200831_52h_232Preds_8hr.mat";
            StoragePath=strcat(strcat(Path.Prediction, "DayaheadRealH", Dl));
            load(strcat(StoragePath, StorageFile))
            if Pred.Time.StepPredInd~=Time.StepInd
                SpotmarketPricesPred1=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
            end
            TD.SpotmarketPricesPred1=find(ismember(Pred.Time.Vec,Time.Sim.Start),1)-1;
        end
        
        if ~exist("SpotmarketPricesPred2", "var")
            %[StorageFile, StoragePath]=uigetfile(strcat(Path.Prediction, "DayaheadRealH", Dl), 'Select the second Spotmarket Prediction');
            StorageFile="LSQ_20210202-1220_20180101-20200831_48h_232Preds_12hr.mat";
            StoragePath=strcat(strcat(Path.Prediction, "DayaheadRealH", Dl));
            load(strcat(StoragePath, StorageFile))
            if Pred.Time.StepPredInd~=Time.StepInd
                SpotmarketPricesPred2=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
            end
            TD.SpotmarketPricesPred2=find(ismember(Pred.Time.Vec,Time.Sim.Start),1)-1;
        end
    else
        SpotmarketPricesPred1=repelem(Smard.DayaheadRealH, Time.StepInd);
        TD.SpotmarketPricesPred1=find(ismember(Time.Vec,Time.Sim.Start),1)-1;
        SpotmarketPricesPred2=repelem(Smard.DayaheadRealH, Time.StepInd);
        TD.SpotmarketPricesPred2=find(ismember(Time.Vec,Time.Sim.Start),1)-1;
    end
end

if UsePVPredictions
    PVPlants_Profile_Prediction="PredictionQH";
else
    PVPlants_Profile_Prediction="ProfileQH";
end

SpotmarketPrices=repelem(Smard.DayaheadRealH, Time.StepInd);
TD.SpotmarketPrices=find(ismember(Time.Vec,Time.Sim.Start),1)-1;

if ActivateWaitbar
    h=waitbar(0, "Simulate charging processes: 0%");
end

%% Start Simulation

for TimeInd=Time.Sim.VecInd(2:end-ControlPeriods)
          
    for n=UserNum
        
        % Public charging: Only charge at public charging point if it is requiered due to low SoC
        if Users{n}.Logbook(TimeInd+TD.User-1,9)-Users{n}.Logbook(TimeInd+TD.User,4) < Users{n}.PublicChargingThreshold_Wh
            
            k=TimeInd+TD.User;
            while k < length(Users{n}.Logbook) && ~ismember(Users{n}.Logbook(k,1), 3:5)
                k=k+1;
            end
            NextHomeStop=k;
            
            ConsumptionTilNextHomeStop=sum(Users{n}.Logbook(TimeInd+TD.User:NextHomeStop,4)); % [Wh]
            TripDistance=sum(Users{n}.Logbook(TimeInd+TD.User:NextHomeStop,3)); % [Wh]

            PublicChargerPower=max((rand(1)>=PublicChargerDistribution(find(PublicChargerDistribution>TripDistance/1000,1),:)).*PublicChargerDistribution(1,:)); % [kW]
            ChargingPower(n)=min([max([Users{n}.ACChargingPowerVehicle, Users{n}.DCChargingPowerVehicle]), PublicChargerPower])*Users{n}.ChargingEfficiency; % Actual ChargingPower at public charger in [kW]
            
            EnergyDemandLeft(n)=double(min((Users{n}.PublicChargingThreshold*100 + 5+TruncatedGaussian(2,[1 10]-5,1))/100*Users{n}.BatterySize + double(ConsumptionTilNextHomeStop) - Users{n}.Logbook(TimeInd+TD.User-1,9), Users{n}.BatterySize - Users{n}.Logbook(TimeInd+TD.User-1,9)));
            TimeStepIndsNeededForCharging=ceil(EnergyDemandLeft(n)/ChargingPower(n)*60/Time.StepMin); % [Wh/W]
            
            if TimeStepIndsNeededForCharging>0
                k=TimeInd+TD.User;
                while k < length(Time.Sim.VecInd)-TimeStepIndsNeededForCharging && ~isequal(Users{n}.Logbook(k:k+TimeStepIndsNeededForCharging-1,3),zeros(TimeStepIndsNeededForCharging,1))
                    k=k+1;
                end
                EndOfShift=min(length(Time.Sim.VecInd), k+TimeStepIndsNeededForCharging-1);

                Users{n}.Logbook(TimeInd+TD.User:EndOfShift,:)=Users{n}.Logbook(TimeInd+TD.User-TimeStepIndsNeededForCharging:EndOfShift-TimeStepIndsNeededForCharging,:);
                TimeStepIndsNeededForCharging=min(length(Users{n}.Logbook)-(TimeInd+TD.User-1), TimeStepIndsNeededForCharging);
                Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+TimeStepIndsNeededForCharging-1,1:9)=ones(TimeStepIndsNeededForCharging,1)*[6 + double(PublicChargerPower>30000), zeros(1,8)]; % Public charging due to low SoC
            end
        end
        
        if EnergyDemandLeft(n)>0
            Users{n}.Logbook(TimeInd+TD.User,8)=min([EnergyDemandLeft(n), ChargingPower(n)*Time.StepMin/60, Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9)]); % Publicly charged energy during one Time.Step in [Wh]
            EnergyDemandLeft(n)=EnergyDemandLeft(n)-Users{n}.Logbook(TimeInd+TD.User,8); 
        end
        
        Users{n}.Logbook(TimeInd+TD.User,9)=min(Users{n}.BatterySize, Users{n}.Logbook(TimeInd+TD.User-1,9) - Users{n}.Logbook(TimeInd+TD.User,4) + Users{n}.Logbook(TimeInd+TD.User,8));

    end
    
    if ~SmartCharging
        
        for n=UserNum
        
            % Private charging: Decide whether to plug in the car the or not

            if Users{n}.Logbook(TimeInd+TD.User,1)==3

                if Users{n}.Logbook(TimeInd+TD.User-1,1)<3

                    if Users{n}.ChargingStrategy==1 % Always connect car to charging point if Duration of parking is higher than MinimumPluginTime
                        ParkingDuration=(find(Users{n}.Logbook(TimeInd+TD.User:end,1)<3,1)-1)*Time.Step;
                        if ParkingDuration>Users{n}.MinimumPluginTime
                            Users{n}.Logbook(TimeInd+TD.User,1)=4; % Plugged-in
                        else
                            Users{n}.Logbook(TimeInd+TD.User,1)=3; % Not plugged-in
                        end

                    elseif Users{n}.ChargingStrategy==2 % The probability of connection is a function of Plug-in time, SoC and the consumption within the next 24h
                        Consumption24h=sum(Users{n}.Logbook(TimeInd+TD.User:min(TimeInd+TD.User+24*Time.StepInd-1, size(Users{n}.Logbook,1)), 4)); % [Wh]
                        ConnectionDurations24h=find(ismember(Users{n}.Logbook(TimeInd+TD.User:min(TimeInd+TD.User+24*Time.StepInd-1, size(Users{n}.Logbook,1)), 1), 3:5) & ~ismember([Users{n}.Logbook(TimeInd+TD.User+1:min(TimeInd+TD.User+24*Time.StepInd-1, size(Users{n}.Logbook,1)), 1);0], 3:5)) - find(ismember(Users{n}.Logbook(TimeInd+TD.User:min(TimeInd+TD.User+24*Time.StepInd-1, size(Users{n}.Logbook,1)), 1), 3:5) & ~ismember([0;Users{n}.Logbook(TimeInd+TD.User:min(TimeInd+TD.User+24*Time.StepInd-1-1, size(Users{n}.Logbook,1)-1), 1)], 3:5))+1;
                        if Consumption24h>Users{n}.Logbook(TimeInd+TD.User-1,9) && ~max(ConnectionDurations24h)*Time.StepInd*Users{n}.ACChargingPowerHomeCharging < Consumption24h
                            Users{n}.Logbook(TimeInd+TD.User,1)=4; % Plugged-in
                        else
                            PlugInTime=(find([Users{n}.Logbook(TimeInd+TD.User+1:end,1);0]<3,1)-1)/Time.StepInd;
                            P=min(1,PlugInTime/3) + 0.9*min(1, (Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9))/Users{n}.BatterySize) + min(1, Consumption24h/Users{n}.Logbook(TimeInd+TD.User-1,9)) + 0.3*ConnectionDurations24h(1)/max(ConnectionDurations24h);
                            if P>Users{n}.PrivateChargingThreshold
                                Users{n}.Logbook(TimeInd+TD.User,1)=4; % Plugged-in
                            else
                                Users{n}.Logbook(TimeInd+TD.User,1)=3; % Not plugged-in
                            end
                        end
                    end

                elseif Users{n}.Logbook(TimeInd+TD.User-1,1)>=4
                    Users{n}.Logbook(TimeInd+TD.User,1)=4;
                end
            end


            if Users{n}.Logbook(TimeInd+TD.User,1)==4 && Users{n}.Logbook(TimeInd+TD.User,9)<Users{n}.BatterySize && (~ApplyGridConvenientCharging || Users{n}.GridConvenientChargingAvailability(mod(TimeInd+TD.User-1, 24*Time.StepInd)+1)) % Charging starts always when the car is plugged in, until the Battery is fully charged
                Users{n}.Logbook(TimeInd+TD.User,1)=5;
                ChargingEnergy=min((Time.StepMin-Users{n}.Logbook(TimeInd+TD.User,2))*Users{n}.ACChargingPowerHomeCharging/60, Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9)); %[Wh]
                if UsePV && Users{n}.PVPlantExists
                    Users{n}.Logbook(TimeInd+TD.User,6)=min(uint32(PVPlants{Users{n}.PVPlant}.(PVPlants_Profile_Prediction)(TimeInd+TD.Main)/Users{n}.ChargingEfficiency), ChargingEnergy);
                end
                Users{n}.Logbook(TimeInd+TD.User,5)=ChargingEnergy-Users{n}.Logbook(TimeInd+TD.User,6);
            end


            if  Users{n}.Logbook(TimeInd+TD.User,9)<Users{n}.BatterySize && Users{n}.Logbook(TimeInd+TD.User,1)>=5
                Users{n}.Logbook(TimeInd+TD.User,9)=Users{n}.Logbook(TimeInd+TD.User,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:7));
            end
        end
    
    elseif TimeInd>=TimesOfPreAlgo(1,1)
        
        ControlPeriodsIt=ControlPeriods-mod(TimeInd-TimesOfPreAlgo(1,1),96);        
        
        if ismember(TimeInd, TimesOfPreAlgo)
            
            %% Algo 1 optimisation

            if ~UseSpotPredictions
                SpotmarktPricesCP=SpotmarketPrices(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1);
            end
        
            if ismember(TimeInd, TimesOfPreAlgo(1,:))
                PreAlgoCounter=PreAlgoCounter+1;
                
                if UseSpotPredictions
                    SpotmarktPricesCP=[SpotmarketPrices(TimeInd+TD.User:TimeInd+TD.User + 24*Time.StepInd-mod(TimeInd-1,24*Time.StepInd)-1 + (mod(TimeInd-1,24*Time.StepInd)-13*Time.StepInd > 0)*96); SpotmarketPricesPred1(TimeInd+TD.SpotmarketPricesPred1 + 24*Time.StepInd-mod(TimeInd-1,24*Time.StepInd)-1 + (mod(TimeInd-1,24*Time.StepInd)-13*Time.StepInd > 0)*96+1:TimeInd+TD.SpotmarketPricesPred1+ControlPeriodsIt-1)];
                end
                
                CalcConsOptVars;
                
            elseif UseSpotPredictions
                SpotmarktPricesCP=[SpotmarketPrices(TimeInd+TD.User:TimeInd+TD.User + 24*Time.StepInd-mod(TimeInd-1,24*Time.StepInd)-1 + (mod(TimeInd-1,24*Time.StepInd)-13*Time.StepInd > 0)*96); SpotmarketPricesPred2(TimeInd+TD.SpotmarketPricesPred2 + 24*Time.StepInd-mod(TimeInd-1,24*Time.StepInd)-1 + (mod(TimeInd-1,24*Time.StepInd)-13*Time.StepInd > 0)*96+1:TimeInd+TD.SpotmarketPricesPred2+ControlPeriodsIt-1)];
            end
            
            CalcDynOptVars;
            PreAlgo;

            for n=UserNum  
                Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1, [false(1,4), CostCats])=OptimalChargingEnergies(1:ControlPeriodsIt,:,n==UserNum);
            end

        else
            CalcDynOptVars;
        end
        
        %% Algo 2 optimisation
        
        LiveAlgo;
           
        for n=UserNum % Battery clipping: In case the battery would be overcharged, clip the energy

            ChargedEnergy=min([Users{n}.BatterySize - (Users{n}.Logbook(TimeInd+TD.User-1, 9) - Users{n}.Logbook(TimeInd+TD.User, 4)), sum(Users{n}.Logbook(TimeInd+TD.User, 5:8))]);
            Users{n}.Logbook(TimeInd+TD.User, 9)=Users{n}.Logbook(TimeInd+TD.User-1, 9)-Users{n}.Logbook(TimeInd+TD.User, 4) + ChargedEnergy;
            if ChargedEnergy==0 && Users{n}.Logbook(TimeInd+TD.User, 1)==5
                Users{n}.Logbook(TimeInd+TD.User, 1)=4;
            end
            if ChargedEnergy < sum(Users{n}.Logbook(TimeInd+TD.User, 5:8)) - 0.01
                Users{n}.Logbook(TimeInd+TD.User, 5:8)=Users{n}.Logbook(TimeInd+TD.User, 5:8).*(ChargedEnergy/sum(Users{n}.Logbook(TimeInd+TD.User, 5:8)));
            end

            if ~(Users{n}.Logbook(TimeInd+TD.User,9)<(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))+3 && Users{n}.Logbook(TimeInd+TD.User,9)>(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))-3)
                error("Wrong addition")
            end

            if Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1, 9)>Users{n}.BatterySize
                2
            end

        end
        
    end
    
    
    if ActivateWaitbar %&& mod(TimeInd+TD.User,1000)==0
        waitbar(TimeInd/length(Time.Sim.Vec), h, strcat("Simulate charging processes: ", num2str(round(TimeInd/length(Time.Sim.Vec)*1000)/10),"%"));
    end
end

for n=UserNum
    AvailableBlocks=[find(ismember(Users{n}.Logbook(1:end,1),3:5) & ~ismember([0;Users{n}.Logbook(1:end-1,1)],3:5)), find(ismember(Users{n}.Logbook(1:end,1),3:5) & ~ismember([Users{n}.Logbook(2:end,1);0],3:5))];
    ChargingBlocks=any(AvailableBlocks(:,1)'<=find(Users{n}.Logbook(1:end,1)==5) & AvailableBlocks(:,2)'>=find(Users{n}.Logbook(1:end,1)==5))';
    for k=find(ChargingBlocks)'
        Users{n}.Logbook(AvailableBlocks(k,1)-1:AvailableBlocks(k,2)-1,1)=4;
    end
    Users{n}.Logbook(any(Users{n}.Logbook(:,5:7)>0,2),1)=5;
end


if ActivateWaitbar
    close(h);
end


for n=UserNum
    Users{n}.Logbook=Users{n}.Logbook(1:TimeInd,:);
end

%% Store Simulation Information

Users{1}.UserNum=UserNum;
Users{1}.SmartCharging=SmartCharging;
Users{1}.SpotmarketPrices=SpotmarketPrices;
Users{1}.TD.SpotmarketPrices=TD.SpotmarketPrices;
Users{1}.ApplyGridConvenientCharging=ApplyGridConvenientCharging;

if SmartCharging
    Users{1}.ChargingMatSmart=ChargingMat;
    for k=1:size(ChargingMat,1)-1
        Users{1}.ChargingMatSmart{k,2}=mod(TimesOfPreAlgo(k,1)-1,ControlPeriods) + 96*(TimeOfPreAlgo(k)<TimeOfPreAlgo(1));
    end

    Users{1}.UseParallel=UseParallel;
    Users{1}.UseSpotPredictions=UseSpotPredictions;
    Users{1}.UsePVPredictions=UsePVPredictions;
    Users{1}.UseIndividualEEGBonus=UseIndividualEEGBonus;
    Users{1}.UsePV=UsePV;
    
    Users{1}.AvailabilityMat=AvailabilityMat;
    Users{1}.NumCostCats=NumCostCats;
    Users{1}.ControlPeriods=ControlPeriods;
    Users{1}.ShiftInds=ShiftInds;
    Users{1}.NumDecissionGroups=NumDecissionGroups;
    Users{1}.TimeOfPreAlgo=TimeOfPreAlgo;
    
    Users{1}.DispatchedResPo=DispatchedResPo;
    Users{1}.ProvidedResPo=ProvidedResPo;
    Users{1}.ResPoOffers=ResPoOffers;
    Users{1}.ResEnOffers=ResEnOffers;
    
    disp(strcat(num2str(sum(LastResPoOffersSucessful4H(:,2:end)>0,'all')/sum(LastResPoOffers(:,2:end)>0,'all')*100), "% of all reserve power offers were successful"))
    
    ResEnVolumenFulfilled=0;
    for n=Users{1}.UserNum
        ResEnVolumenFulfilled=ResEnVolumenFulfilled+sum(Users{n}.Logbook(:,7))/Users{n}.ChargingEfficiency/1000;
    end
    
    toc(TSim)
    
    ResEnVolumenAllocated=0;
    for n=Users{1}.UserNum
        ResEnVolumenAllocated=ResEnVolumenAllocated+sum(Users{1}.ChargingMatSmart{find(~cellfun(@isempty,ChargingMat(1:5,1)), 1, 'last' )}(96-24*4+1:96-24*4+96,3,n-1,:),'all')/Users{n}.ChargingEfficiency/1000;
    end

    disp(strcat(num2str(ResEnVolumenFulfilled/ResEnVolumenAllocated*100), " % of the succcessfully offered reserve energy was actually charged"))
else
    Users{1}.ChargingMatBase=cell(1,2);
    Users{1}.ChargingMatBase{1}=zeros(96, 3, NumUsers, ceil(size(Users{UserNum(1)}.Logbook,1)/(24*Time.StepInd)));
end


%% Delete not simulated users

SimulatedUsers=@(User) (isfield(User, 'Time') || (isfield(User,"Logbook") && User.Logbook(2,9)>0) || (isfield(User,"LogbookSmart") && User.LogbookSmart(2,9)>0) || (isfield(User,"LogbookBase") && User.LogbookBase(2,9)>0));
Users=Users(cellfun(SimulatedUsers, Users));
Users{1}.Time.Stamp=datetime('now');
Users{1}.SimDuration=toc(TSim);

for n=2:length(Users)
    if isfield(Users{n}, 'Logbook')
        if ~SmartCharging
            Users{n}.LogbookBase=Users{n}.Logbook;
        else 
            Users{n}.LogbookSmart=Users{n}.Logbook;
        end
        Users{n}=rmfield(Users{n}, 'Logbook');
    end
end


%% Evaluate Load Curves

if Users{1}.SmartCharging
    for n=Users{1}.UserNum
        Users{1}.ChargingMatSmart{end,1}(:,:,n,:)=permute(reshape(Users{n}.LogbookSmart(:,5:7),24*Time.StepInd,[],3), [1, 3, 2]);
    end
    Users{1}.ChargingMatSmart{end,2}=96;
    ChargingMat=Users{1}.ChargingMatSmart;
else
    for n=Users{1}.UserNum
        Users{1}.ChargingMatBase{end,1}(:,:,n,:)=permute(reshape(Users{n}.LogbookBase(:,5:7),24*Time.StepInd,[],3), [1, 3, 2]);
    end
    Users{1}.ChargingMatBase{end,2}=96;
    ChargingMat=Users{1}.ChargingMatBase;
end

ChargingType=cell(size(ChargingMat,1),1);
ChargingSum=cell(size(ChargingMat,1),1);
Load=cell(size(ChargingMat,1),1);

for k=find(~cellfun(@isempty,ChargingMat(:,1)))'

    ChargingType{k}=reshape(permute(squeeze(sum(ChargingMat{k,1}(max(1,24*Time.StepInd-ChargingMat{k,2}+1):24*Time.StepInd-ChargingMat{k,2}+24*Time.StepInd,:,:,:),3)), [1,3,2]), [], size(ChargingMat{k,1},2))/1000*4;

    [sum(ChargingType{k}(:,1,:),'all'), sum(ChargingType{k}(:,2,:),'all'), sum(ChargingType{k}(:,3,:),'all')]/sum(ChargingType{k}(:,:,:),'all');
    ChargingSum{k}=sum(ChargingType{k}, 2);

    Load{k}=mean(reshape(ChargingType{k}',3,length(max(1,24*Time.StepInd-ChargingMat{k,2}+1):24*Time.StepInd-ChargingMat{k,2}+24*Time.StepInd),[]),3)';
    x = 1+96-size(Load{k},1):96;
    y = mean(reshape(ChargingSum{k}, size(Load{k},1), []), 2)';
    z = zeros(size(x));
    col = (Load{k}./repmat(max(Load{k}, [], 2),1,3))';

    figure(k)
    clf;
    surface([x;x],[y;y],[z;z],[permute(repmat(col,1,1,2),[3,2,1])], 'facecol','no', 'edgecol','interp', 'linew',2);
    xticks(1:16:96)
    xlim([1 96])
    xticklabels({datestr(Time.Vec(1:16:96),'HH:MM')})
    ylabel("Charging power in kW")
    xlabel("Time")
    if k<size(ChargingMat,1)
        title(strcat("Optimal charging energies for optimisation at ", datestr(Users{1}.TimeOfPreAlgo(k), "hh:MM")))
    else
        title(strcat("Optimal charging energies for optimisation in total"))
    end
    grid on


    hold on
    plot(x,squeeze(mean(reshape(ChargingType{k}(:,1),length(x),[],1),2)), "LineWidth", 1.2, "Color", [1, 0, 0])
    plot(x,squeeze(mean(reshape(ChargingType{k}(:,2),length(x),[],1),2)), "LineWidth", 1.2, "Color", [0, 1, 0])
    plot(x,squeeze(mean(reshape(ChargingType{k}(:,3),length(x),[],1),2)), "LineWidth", 1.2, "Color", [0, 0, 1])

    legend(["All", "Spotmarket", "PV", "Secondary Reserve Energy"])

end

if Users{1}.SmartCharging
    figure(k+1)
    plot(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):minutes(Time.StepMin):datetime(1,1,1,23,45,0, 'TimeZone', 'Africa/Tunis'), circshift(mean(sum(Users{1}.AvailabilityMat,3),2), Users{1}.ShiftInds))
    xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
    xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
end


%% Evaluate ResPo Offers

if Users{1}.SmartCharging
    ResPoRequestsUnderfulfillment=sum(DispatchedResPo(1:length(ProvidedResPo))+0.01<ProvidedResPo | DispatchedResPo(1:length(ProvidedResPo))-0.01>ProvidedResPo);
    disp(strcat(num2str(sum(DispatchedResPo>0)), " reserve power requests were received from TSO. ", num2str(ResPoRequestsUnderfulfillment), " (", num2str(round(ResPoRequestsUnderfulfillment/sum(DispatchedResPo>0)*10000)/100), "%) of these were not performed properly."))
end

%% Evaluate  electricity costs

for n=2:length(Users)
	Users{n}.AverageConsumptionBaseYear_kWh=sum(double(Users{n}.LogbookSource(:,5:8))/Users{n}.ChargingEfficiency, 'all')/1000/days(Time.End-Time.Start)*365.25;
end


NNEExtraBasePrice=0;
NNEBonus=0;
IMSYSInstallationCosts=0;
if Users{1}.ApplyGridConvenientCharging
    IMSYSPrices=readmatrix(strcat(Path.Simulation, "IMSYS_Prices.csv"), 'NumHeaderLines', 1);
    for n=2:length(Users)
        if Users{n}.NNEExtraBasePrice==-100
            Users{n}.NNEExtraBasePrice=IMSYSPrices(Users{n}.AverageConsumptionBaseYear_kWh>=IMSYSPrices(:,1) & Users{n}.AverageConsumptionBaseYear_kWh<IMSYSPrices(:,2),3)*100;
        end
        
        NNEExtraBasePrice=NNEExtraBasePrice+Users{n}.NNEExtraBasePrice;
        NNEBonus=NNEBonus+Users{n}.NNEBonus;
        IMSYSInstallationCosts=IMSYSInstallationCosts+Users{n}.IMSYSInstallationCosts;
    end
end


if ~Users{1}.SmartCharging
    TotalCostsBase=zeros(9,7);
    
    for n=2:length(Users)
        
        if isfield(Users{n}, "LogbookBase")
        
            TotalCostsBase(1,1:4)=TotalCostsBase(1,1:4)+sum(Users{n}.LogbookBase(:,5:8)/1000/Users{n}.ChargingEfficiency, 1);

            Users{n}.FinListBase=zeros(length(Users{n}.LogbookBase),4);
            Users{n}.FinListBase(:,1)=(Users{n}.LogbookBase(:,5)/1000/Users{n}.ChargingEfficiency .* (Users{n}.PrivateElectricityPrice + Users{1}.SpotmarketPrices(Time.Sim.VecInd(1:length(Users{n}.LogbookBase(:,5)))+Users{1}.TD.SpotmarketPrices)/10 + Users{n}.NNEEnergyPrice)*Users{1}.MwSt); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
            Users{n}.FinListBase(:,2)=(Users{n}.LogbookBase(:,6)/1000/Users{n}.ChargingEfficiency .* Users{n}.EEGBonus); % [ct] costs for not selling the PV power to the DSO
            Users{n}.FinListBase(:,3)=zeros(length(Users{n}.LogbookBase(:,7)),1);
            Users{n}.FinListBase(:,4)=(Users{n}.LogbookBase(:,8)/1000/Users{n}.ChargingEfficiency .* Users{n}.PublicACChargingPrices.*double(Users{n}.LogbookBase(:,1)==6) + double(Users{n}.LogbookBase(:,8))/1000/Users{n}.ChargingEfficiency .* Users{n}.PublicDCChargingPrices.*double(Users{n}.LogbookBase(:,1)==7)); % [ct] fixed price for public AC and DC charging
            TotalCostsBase(2,1:4)=TotalCostsBase(2,1:4)+sum(Users{n}.FinListBase, 1);
            
        end
    end
    
    TotalCostsBase(1:2,6)=sum(TotalCostsBase(1:2,1:4),2);
    TotalCostsBase(3,:)=TotalCostsBase(2,:)./TotalCostsBase(1,:);
    TotalCostsBase(1:2,7)=TotalCostsBase(1:2,6)/(length(Users)-1);
    TotalCostsBase(1:2,8)=TotalCostsBase(1:2,6)/(length(Users)-1)/(length(Users{2}.LogbookBase)/(24*Time.StepInd))*365;
    TotalCostsBase(2,:)=TotalCostsBase(2,:)/100;
    TotalCostsBase(5,6:8)=[NNEExtraBasePrice / 365*(length(Users{2}.LogbookBase)/(24*Time.StepInd)), NNEExtraBasePrice/(length(Users)-1), NNEExtraBasePrice/(length(Users)-1)]/100;
    TotalCostsBase(6,6:8)=[NNEBonus / 365*(length(Users{2}.LogbookBase)/(24*Time.StepInd))/10, NNEBonus / 365*(length(Users{2}.LogbookBase)/(24*Time.StepInd))/10 / (length(Users)-1), NNEBonus/(length(Users)-1)/10]/100;
    TotalCostsBase(7,6:8)=[IMSYSInstallationCosts / 365*(length(Users{2}.LogbookBase)/(24*Time.StepInd))/10, IMSYSInstallationCosts / 365*(length(Users{2}.LogbookBase)/(24*Time.StepInd))/10 / (length(Users)-1), IMSYSInstallationCosts/(length(Users)-1)/10]/100;
    TotalCostsBase(9,6:8)=TotalCostsBase(2,6:8)+sum(TotalCostsBase([5,7],6:8),1);
    
    TotalCostsBase=table(TotalCostsBase(:,1), TotalCostsBase(:,2), TotalCostsBase(:,3), TotalCostsBase(:,4), TotalCostsBase(:,5), TotalCostsBase(:,6), TotalCostsBase(:,7),TotalCostsBase(:,8), 'RowNames',["Energy charged in kWh"; "Energy Costs in EUR"; "Energy Costs in ct/kWh"; "."; "NNE Extra Base Price in EUR"; "NNE Bonus in EUR"; "IMSYS Installation Costs in EUR"; "~"; "Total Costs in EUR"], 'VariableNames',{'Grid','PV','aFRR','Public','ResPoOffered_kW','Total','TotalPerUser', 'TotalPerUserPerYear'});
    TotalCostsBase=[TotalCostsBase; table([0;Users{1}.SmartCharging; Users{1}.ApplyGridConvenientCharging; length(Users)-1; Users{1}.UseSpotPredictions; Users{1}.UsePVPredictions; Users{1}.UseIndividualEEGBonus; Users{1}.SimDuration/3600], zeros(8,1),zeros(8,1),zeros(8,1),zeros(8,1),zeros(8,1),zeros(8,1),zeros(8,1), 'RowNames',["/"; "SmartCharging"; "ApplyGridConvenientCharging"; "NumUsers"; "UseSpotPredictions"; "UsePVPreditions"; "UseIndividualEEGBonus"; "SimulationDuration in h"], 'VariableNames',{'Grid','PV','aFRR','Public','ResPoOffered_kW','Total','TotalPerUser', 'TotalPerUserPerYear'})];
    
    Users{1}.TotalCostsIt{end+1}=TotalCostsBase;
    
    disp(strcat("Costs for base charging the fleet were ", string(table2cell((TotalCostsBase(2,8)))), "EUR per user per year"));
end

if Users{1}.SmartCharging
    TotalCostsSmart=zeros(9,7); % [kWh (6. column kW); EUR; ct/kWh]
    ResEnOffersList=repelem(reshape(ResEnOffers(:,1,1:end-1),[],1),4*Time.StepInd/ConstantResPoPowerPeriodsScaling);

    for n=2:length(Users)
        
        if isfield(Users{n}, "LogbookSmart")
            TotalCostsSmart(1,1:4)=TotalCostsSmart(1,1:4)+sum(Users{n}.LogbookSmart(:,5:8)/1000/Users{n}.ChargingEfficiency, 1);

            Users{n}.FinListSmart=zeros(length(Users{n}.LogbookSmart),4);
            Users{n}.FinListSmart(:,1)=(Users{n}.LogbookSmart(:,5)/1000/Users{n}.ChargingEfficiency .* (Users{n}.PrivateElectricityPrice + Users{1}.SpotmarketPrices(Time.Sim.VecInd(1:length(Users{n}.LogbookSmart(:,5)))+Users{1}.TD.SpotmarketPrices)/10 + Users{n}.NNEEnergyPrice)*Users{1}.MwSt); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
            Users{n}.FinListSmart(:,2)=(Users{n}.LogbookSmart(:,6)/1000/Users{n}.ChargingEfficiency .* Users{n}.EEGBonus); % [ct] costs for not selling the PV power to the DSO
            Users{n}.FinListSmart(:,3)=(Users{n}.LogbookSmart(:,7)/1000/Users{n}.ChargingEfficiency .* (Users{n}.PrivateElectricityPrice + ResEnOffersList/100 + Users{n}.NNEEnergyPrice)*Users{1}.MwSt); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
            Users{n}.FinListSmart(:,4)=(Users{n}.LogbookSmart(:,8)/1000/Users{n}.ChargingEfficiency .* Users{n}.PublicACChargingPrices.*double(Users{n}.LogbookSmart(:,1)==6) + double(Users{n}.LogbookSmart(:,8))/1000/Users{n}.ChargingEfficiency .* Users{n}.PublicDCChargingPrices.*double(Users{n}.LogbookSmart(:,1)==7)); % [ct] fixed price for public AC and DC charging
            TotalCostsSmart(2,1:4)=TotalCostsSmart(2,1:4)+sum(Users{n}.FinListSmart, 1);
        end
    end
    
    TotalCostsSmart(1,5)=sum(ResPoOffers(:,2,:),'all')/1000*4;
    TotalCostsSmart(2,5)=-sum(ResPoOffers(:,1,:).*ResPoOffers(:,2,:)/1000*4,'all')*100; % [EUR/kW]*[Wh]
    TotalCostsSmart(3,:)=TotalCostsSmart(2,:)./TotalCostsSmart(1,:);
    TotalCostsSmart(1,6)=sum(TotalCostsSmart(1,1:4));
    TotalCostsSmart(2,6)=sum(TotalCostsSmart(2,1:5),2);
    TotalCostsSmart(3,6)=TotalCostsSmart(2,6)/TotalCostsSmart(1,6);
    TotalCostsSmart(1:2,7)=TotalCostsSmart(1:2,6)/(length(Users)-1);
    TotalCostsSmart(1:2,8)=TotalCostsSmart(1:2,6)/(length(Users)-1)/(length(Users{2}.LogbookSmart)/(24*Time.StepInd))*365;
    TotalCostsSmart(3,7:8)=TotalCostsSmart(3,6);
    TotalCostsSmart(2,:)=TotalCostsSmart(2,:)/100;
    TotalCostsSmart(5,6:8)=[NNEExtraBasePrice / 365*(length(Users{2}.LogbookSmart)/(24*Time.StepInd)), NNEExtraBasePrice/(length(Users)-1), NNEExtraBasePrice/(length(Users)-1)]/100;
    TotalCostsSmart(6,6:8)=-[NNEBonus / 365*(length(Users{2}.LogbookSmart)/(24*Time.StepInd))/10, NNEBonus / 365*(length(Users{2}.LogbookSmart)/(24*Time.StepInd))/10 / (length(Users)-1), NNEBonus/(length(Users)-1)/10]/100;
    TotalCostsSmart(7,6:8)=[IMSYSInstallationCosts / 365*(length(Users{2}.LogbookSmart)/(24*Time.StepInd))/10, IMSYSInstallationCosts / 365*(length(Users{2}.LogbookSmart)/(24*Time.StepInd))/10 / (length(Users)-1), IMSYSInstallationCosts/(length(Users)-1)/10]/100;
    TotalCostsSmart(9,6:8)=TotalCostsSmart(2,6:8)+sum(TotalCostsSmart([5,7],6:8),1);
    
    TotalCostsSmart=table(TotalCostsSmart(:,1), TotalCostsSmart(:,2), TotalCostsSmart(:,3), TotalCostsSmart(:,4), TotalCostsSmart(:,5), TotalCostsSmart(:,6), TotalCostsSmart(:,7),TotalCostsSmart(:,8), 'RowNames',["Energy charged in kWh"; "Energy Costs in EUR"; "Energy Costs in ct/kWh"; "."; "NNE Extra Base Price in EUR"; "NNE Bonus in EUR"; "IMSYS Installation Costs in EUR"; "~"; "Total Costs in EUR"], 'VariableNames',{'Grid','PV','aFRR','Public','ResPoOffered_kW','Total','TotalPerUser', 'TotalPerUserPerYear'});
    TotalCostsSmart=[TotalCostsSmart; table([0;ResEnVolumenAllocated;ResEnVolumenFulfilled/ResEnVolumenAllocated; round(ResPoRequestsUnderfulfillment/sum(DispatchedResPo>0)*10000)/100; ResPoPriceFactor;ResEnPriceFactor;0;Users{1}.SmartCharging; Users{1}.ApplyGridConvenientCharging; length(Users)-1; Users{1}.UseParallel; Users{1}.NumDecissionGroups; Users{1}.UseSpotPredictions; Users{1}.UsePVPredictions; Users{1}.UseIndividualEEGBonus; Users{1}.SimDuration/3600;], zeros(16,1),zeros(16,1),zeros(16,1),zeros(16,1),zeros(16,1),zeros(16,1),zeros(16,1), 'RowNames',["-"; "Planned Reserve Energy in Opt 5 in kWh"; "Share Activated/Planned Renserve Energy in kWh"; "ResEn underfulfillment rate in %"; "ResPoPriceFactor"; "ResEnPriceFactor"; "/"; "SmartCharging"; "ApplyGridConvenientCharging"; "NumUsers"; "UseParallel"; "NumDecissionGroups"; "UseSpotPredictions"; "UsePVPreditions"; "UseIndividualEEGBonus"; "SimulationDuration in h"], 'VariableNames',{'Grid','PV','aFRR','Public','ResPoOffered_kW','Total','TotalPerUser', 'TotalPerUserPerYear'})];    
    
    disp(strcat("Total costs for smart charging the fleet were ", string(table2cell((TotalCostsSmart(2,8)))), "EUR per User per year"));
    
    Users{1}.TotalCostsIt{end+1}=TotalCostsSmart;
end


%% Save data

Users{1}.FileName=strcat(Path.Simulation, "Users_", datestr(Users{1}.Time.Stamp, "yyyymmdd-HHMM"), "_", Time.IntervalFile, "_", num2str(length(Users)-1), "_", num2str(isfield(Users{1}, 'ChargingMatSmart')), "_", num2str(isfield(Users{1}, 'ChargingMatBase')), ".mat");

if SaveResults
    save(Users{1}.FileName, "Users", "-v7.3");
end
disp(strcat("Successfully simulated within ", num2str(Users{1}.SimDuration), " seconds"))

end


%% Clean up workspace
 
clearvars TimeInd TD.User n ActivateWaitbar Consumption24h ParkingDuration ConsumptionTilNextHomeStop TripDistance
clearvars NextHomeStop PublicChargerPower ChargingPower EnergyDemandLeft TimeStepIndsNeededForCharging EndOfShift
clearvars NumPredMethod TotalIterations NumUsers TimeOfForecast P PlugInTime PThreshold
clearvars SimulatedUsers PublicChargerDistribution h k UserNum UsePV UsePredictions UseParallel TSim TimeInd temp  
clearvars SpotmarketPrices PVPlants_Profile_Prediction ApplyGridConvenientCharging ChargingEnergy ConnectionDurations24h ControlPeriods IMSYSPrices n
clearvars SmartCharging SaveResults ResEnVolumen

clearvars x y z Load ChargingBlocks ChargingSum ChargingType AvailableBlocks col

clearvars A Aeq Availability AvailabilityOrder AvailableDispatchedResPo AvailableDispatchedResPoBuffer AvailableDispatchedResPoMax
clearvars b beq ChargedEnergy ChargingInds ConnectionDurations24h ConsEnergyDemandTSA ConsEnergyDemandTSAIt ConseqEnergyCPA ConseqEnergyCPAIt ConseqMatchLastResPoOffers4HA
clearvars ConseqMatchLastResPoOffers4HAIt ConseqMatchLastResPoOffers4HbIt ConseqMaxEnergyChargableDeadlockCPbIt ConseqResPoOfferA
clearvars ConseqResPoOfferAIt ConseqResPoOfferbIt ConsMaxEnergyChargableSoCTSbIt ConsMinEnergyRequiredTSbIt ConsPeriods ConsPowerTSb
clearvars ConsSumPowerTSA ConsSumPowerTSAIt ConsSumPowerTSbIt ConstantResPoPowerPeriods Consumed Consumption24h ConsumptionMat ConsumptionTilNextHomeStop
clearvars ControlPeriods ControlPeriodsIt CostCats CostsElectricityBase CostsPV CostsReserveMarket CostsSpotmarket DecissionGroups DelCols DelCols2
clearvars DelRows DelRows2 DemandInds EnergyDemand fval HourlyPowerAvailability HourlySpotmarketPowers l lb MaxEnergyChargableDeadlockCP
clearvars MaxEnergyChargableDeadlockTS MaxEnergyChargableSoCTS MaxPossibleSoCTS MaxPower MinEnergyRequiredTS MOLPos n NumCostCats NumDecissionGroups
clearvars OfferedResPo OptimalChargingEnergies OptimalChargingEnergiesSpotmarket options OwnOfferMOLPos p PowerTS PreAlgoCounter Pred PriorityChargingList
clearvars PVPower ResEnMOL ResEnOfferPrices ResEnOffersList ResEnPriceFactor ResEnVolumenAllocated ResEnVolumenFulfilled
clearvars ResPoBlockedIndices ResPoBuffer ResPoOfferEqualiyMat1 ResPoOfferEqualiyMat2 ResPoOfferPrices ResPoPriceFactor Row ShiftInds
clearvars SoC SoCNew SortedOrder SpotmarketPrices SpotmarktPricesCP StorageFile StoragePath SubIndices SumPower Temp TimeOfDayAheadMarketPriceRelease
clearvars TimeOfPreAlgo TimeOfReserveMarketOffer TimesOfDayAheadMarketPriceRelease TimesOfPreAlgo TimesOfZeitscheiben TimeStepIndsNeededForCharging
clearvars TSOResPoDemand ub VarCounter Costf Costs ChargingVehicle Costsf NNEBonus NNEExtraBasePrice IMSYSInstallationCosts IMSYSInstallationCostsMean
clearvars UseIndividualEEGBonus UsePVPredictions UseSpotPredictions x1 BackwardsOrder
