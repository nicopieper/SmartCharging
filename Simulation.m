%% Initialisation
tic
%Why does this produce an error?
%Compare for 2 Users with and without parallel
NumUsers=1200; % size(Users,1)-1
SmartCharging=true;
%UseParallel=true;
UseParallel=true;
UsePredictions=true;

ControlPeriods=96*2;
UsePV=true;
ApplyGridConvenientCharging=true;
ActivateWaitbar=true;
SaveResults=false;

rng('default');
rng(1);
tc=0;
tc1=0;
TSim=tic;

if SmartCharging
    if UseParallel
        NumDecissionGroups=12;
        UseParallel=true;
        gcp
    else
        NumDecissionGroups=1;
        UseParallel=false;
    end
end


if ~exist('PublicChargerDistribution', 'var')
    PublicChargerDistribution=readmatrix(strcat(Path.Simulation, "PublicChargerProbability.xlsx"));
end

NumUsers=min(NumUsers, size(Users,1)-1);
ChargingPower=zeros(NumUsers,1);
EnergyDemandLeft=zeros(NumUsers+1,1);
% ChargingEfficiency=zeros(NumUsers+1,1);
delete(findall(0,'type','figure','tag','TMWWaitbar'));

Time.Sim=Users{1}.Time;
TD.Main=find(ismember(Time.Vec,Time.Sim.Start),1)-1;
TD.User=find(ismember(Users{1}.Time.Vec,Time.Sim.Start),1)-1;

UserNum=2:NumUsers+1;
% NumUsers=2;
% UserNum=54:55;


for n=UserNum
    Users{n}.Logbook=double(Users{n}.LogbookSource);
end

if SmartCharging
    TimeOfPreAlgo1=datetime(1,1,1,8,0,0,'TimeZone','Africa/Tunis');
    TimeOfPreAlgo2=datetime(1,1,1,12,0,0,'TimeZone','Africa/Tunis');
    TimeOfReserveMarketOffer=datetime(1,1,1,8,0,0,'TimeZone','Africa/Tunis');
	ShiftInds=(hour(TimeOfPreAlgo1)*Time.StepInd + minute(TimeOfPreAlgo1)/minutes(Time.Step));
    %TimesOfPreAlgo=sort([(hour(TimeOfPreAlgo1)*Time.StepInd + minute(TimeOfPreAlgo1)/60*Time.StepInd)+1-1+ControlPeriods:24*Time.StepInd:length(Time.Sim.VecInd); (hour(TimeOfPreAlgo2)*Time.StepInd + minute(TimeOfPreAlgo2)/60*Time.StepInd)+1-1+ControlPeriods:24*Time.StepInd:length(Time.Sim.VecInd)], 'ascend');
    TimesOfPreAlgo=sort([(hour(TimeOfPreAlgo1)*Time.StepInd + minute(TimeOfPreAlgo1)/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd); (hour(TimeOfPreAlgo2)*Time.StepInd + minute(TimeOfPreAlgo2)/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd)], 'ascend');
    %TimesOfPreAlgo=sort([(hour(TimeOfPreAlgo1)*Time.StepInd + minute(TimeOfPreAlgo1)/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd)], 'ascend');
    InitialisePreAlgo;
    
    if UsePredictions
        if ~exist("SpotmarketPricesPred1", "var")
            [StorageFile, StoragePath]=uigetfile(strcat(Path.Prediction, "DayaheadRealH", Dl), 'Select the first Spotmarket Prediction');
            load(strcat(StoragePath, StorageFile))
            if Pred.Time.StepPredInd~=Time.StepInd
                SpotmarketPricesPred1=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
            end
            TD.SpotmarketPricesPred1=find(ismember(Pred.Time.Vec,Time.Sim.Start),1)-1;
        end
        
        if ~exist("SpotmarketPricesPred2", "var")
            [StorageFile, StoragePath]=uigetfile(strcat(Path.Prediction, "DayaheadRealH", Dl), 'Select the second Spotmarket Prediction');
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

if UsePredictions
    PVPlants_Profile_Prediction="PredictionQH";
else
    PVPlants_Profile_Prediction="ProfileQH";
end

SpotmarketPrices=repelem(Smard.DayaheadRealH, Time.StepInd);
TD.SpotmarketPrices=find(ismember(Time.Vec,Time.Sim.Start),1)-1;

if ActivateWaitbar
    h=waitbar(0, "Simulate charging processes");
end

%% Start Simulation

for TimeInd=Time.Sim.VecInd(2:end-ControlPeriods)
          
    for n=UserNum
        
        % Public charging: Only charge at public charging point if it is requiered due to low SoC
%         if (Users{n}.Logbook(TimeInd+TD.User,1)==1 && Users{n}.Logbook(TimeInd+TD.User-1,9)*100/Users{n}.BatterySize<PublicChargingThreshold) || (TimeInd+TD.User+1<=size(Users{n}.Logbook,1) && Users{n}.Logbook(TimeInd+TD.User,4)>=Users{n}.Logbook(TimeInd+TD.User-1,9))
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
%             ChargingEfficiency(n)=PublicChargerDistribution(end,find(ChargingPower(n)<=PublicChargerDistribution(1,2:end),1)+1)*((1.01-0.91)*randn(1)+0.99);
            
            EnergyDemandLeft(n)=double(min((Users{n}.PublicChargingThreshold*100 + 5+TruncatedGaussian(2,[1 10]-5,1))/100*Users{n}.BatterySize + double(ConsumptionTilNextHomeStop) - Users{n}.Logbook(TimeInd+TD.User-1,9), Users{n}.BatterySize - Users{n}.Logbook(TimeInd+TD.User-1,9)));
%             EnergyDemandLeft(n)=double(min((double(PublicChargingThreshold)+5+TruncatedGaussian(4,[1 20]-5,1))/100*Users{n}.BatterySize+double(ConsumptionTilNextHomeStop)-Users{n}.Logbook(TimeInd+TD.User-1,9), Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9)));
            TimeStepIndsNeededForCharging=ceil(EnergyDemandLeft(n)/ChargingPower(n)*60/Time.StepMin); % [Wh/W]
            
            if TimeStepIndsNeededForCharging>0
                k=TimeInd+TD.User;
                while k < length(Time.Sim.VecInd)-TimeStepIndsNeededForCharging && ~isequal(Users{n}.Logbook(k:k+TimeStepIndsNeededForCharging-1,3),zeros(TimeStepIndsNeededForCharging,1))
                    k=k+1;
                end
                EndOfShift=min(length(Time.Sim.VecInd), k+TimeStepIndsNeededForCharging-1);
%                 if EndOfShift>length(Time.Sim.VecInd)
%                     error(strcat("Logbook would be falsly extended for Users ", num2str(n)))
%                 end

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
    %         if ~(Users{n}.Logbook(TimeInd+TD.User,9)<(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))+3 && Users{n}.Logbook(TimeInd+TD.User,9)>(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))-3)
    %             error("Wrong addition")
    %         end
        
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
                    Users{n}.Logbook(TimeInd+TD.User,6)=min(uint32(PVPlants{Users{n}.PVPlant}.(PVPlants_Profile_Prediction)(TimeInd+TD.Main)), ChargingEnergy);
                end
                Users{n}.Logbook(TimeInd+TD.User,5)=ChargingEnergy-Users{n}.Logbook(TimeInd+TD.User,6);
            end


            if  Users{n}.Logbook(TimeInd+TD.User,9)<Users{n}.BatterySize && Users{n}.Logbook(TimeInd+TD.User,1)>=5
                Users{n}.Logbook(TimeInd+TD.User,9)=Users{n}.Logbook(TimeInd+TD.User,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:7));
    %             if Users{n}.Logbook(TimeInd+TD.User, 9)>Users{n}.BatterySize*1.01
    %                 error("Battery over charged")
    %             end
    %             if ~(Users{n}.Logbook(TimeInd+TD.User,9)<(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))+3 && Users{n}.Logbook(TimeInd+TD.User,9)>(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))-3)
    %                 error("Wrong addition")
    %             end
            end
        end
    
    elseif TimeInd>=TimesOfPreAlgo(1,1)
        
        ControlPeriodsIt=ControlPeriods-mod(TimeInd-TimesOfPreAlgo(1,1),96);        
        
        if ismember(TimeInd, TimesOfPreAlgo)
            
            %% Optimise

            %TimeInd=TimeInd-ControlPeriods+1;
            if ismember(TimeInd, TimesOfPreAlgo(1,:))
                PreAlgoCounter=PreAlgoCounter+1;
                
                if UsePredictions
                    SpotmarktPricesCP=[SpotmarketPrices(TimeInd+TD.Main:TimeInd+TD.Main+(24-hour(TimeOfPreAlgo1))*Time.StepInd-1); SpotmarketPricesPred1(TimeInd+TD.SpotmarketPricesPred1+(24-hour(TimeOfPreAlgo1))*Time.StepInd+1:TimeInd+TD.SpotmarketPricesPred1+ControlPeriodsIt)];
                end
                
                CalcConsOptVars;
                
            elseif UsePredictions
                SpotmarktPricesCP=[SpotmarketPrices(TimeInd+TD.Main:TimeInd+TD.Main+(48-hour(TimeOfPreAlgo1))*Time.StepInd-1); SpotmarketPricesPred1(TimeInd+TD.SpotmarketPricesPred1+(48-hour(TimeOfPreAlgo1))*Time.StepInd+1:TimeInd+TD.SpotmarketPricesPred1+ControlPeriodsIt)];
            end
            
            CalcDynOptVars;
            PreAlgo;
            
            if ismember(TimeInd, TimesOfPreAlgo(1,:))
                %C(:,:,PreAlgoCounter)=Costs;
                %C2(:,:,PreAlgoCounter)=CostsReserveMarket;
            end
            
            
            %%
            % Include RL auctions

            for n=UserNum
                %Users{n}.Logbook(TimeInd+TD.User+find(ismember(Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriods-1,1), 4:5))-1,1)=4;
%                 AvailableBlocks=[find(ismember(Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriods-1,1),3:5) & ~ismember([0;Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriods-2,1)],3:5)), find(ismember(Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriods-1,1),3:5) & ~ismember([Users{n}.Logbook(TimeInd+TD.User+1:TimeInd+TD.User+ControlPeriods-1,1);0],3:5))];
%                 ChargingBlocks=any(AvailableBlocks(:,1)'<=find(sum(OptimalChargingEnergies(1:ControlPeriods,:,n==UserNum), 2)>0)-1 & AvailableBlocks(:,2)'>=find(sum(OptimalChargingEnergies(1:ControlPeriods,:,n==UserNum), 2)>0)-1, 1)';
%                 Users{n}.Logbook(TimeInd+TD.User+AvailableBlocks(ChargingBlocks,1)-1:TimeInd+TD.User+AvailableBlocks(ChargingBlocks,2)-1)=4;
                %Users{n}.Logbook(TimeInd+TD.User+find(sum(OptimalChargingEnergies(1:ControlPeriods,:,n==UserNum), 2)>0)-1, 1) = 5;
                
                Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1, 5:7)=OptimalChargingEnergies(1:ControlPeriodsIt,:,n==UserNum);
            end

            %TimeInd=TimeInd+ControlPeriods-1;
        else
            CalcDynOptVars;
        end
           
        
        LiveAlgo;

    end
    
    
    if ActivateWaitbar && mod(TimeInd+TD.User,1000)==0
        waitbar(TimeInd/length(Time.Sim.Vec));
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
tc

for n=UserNum
    Users{n}.Logbook=Users{n}.Logbook(1:TimeInd,:);
end

%% Evaluate base electricity costs

if ~SmartCharging
    if ~exist('Smard', 'var')
        GetSmardData;
    end
    
    if ApplyGridConvenientCharging
        IMSYSPrices=readmatrix(strcat(Path.Simulation, "IMSYS_Prices.csv"), 'NumHeaderLines', 1);
    end        
    
    for n=UserNum
%         if isfield(Users{n}, 'NNEEnergyPrice')
        Users{n}.FinListBase=uint32(double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,5))/1000/Users{n}.ChargingEfficiency .* (Users{n}.PrivateElectricityPrice + SpotmarketPrices(Time.Sim.VecInd+TD.SpotmarketPrices)/10 + Users{n}.NNEEnergyPrice)*1.19); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
%         else
%             Users{n}.FinListBase=uint32(double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,5))/1000/Users{n}.ChargingEfficiency .* (Users{n}.PrivateElectricityPrice + SpotmarketPrices(Time.Sim.VecInd+TD.Main)/10 + 7.06)*1.19); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
%         end
        Users{n}.FinListBase(:,2)=uint32(double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,8))/1000/Users{n}.ChargingEfficiency .* Users{n}.PublicACChargingPrices.*double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,1)==6) + double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,8))/1000/Users{n}.ChargingEfficiency .* Users{n}.PublicDCChargingPrices.*double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,1)==7)); % [ct] fixed price for public AC and DC charging

        Users{n}.AverageConsumptionBaseYear_kWh=sum(Users{n}.Logbook(:,5:8)/Users{n}.ChargingEfficiency, 'all')/1000/days(Time.End-Time.Start)*365.25;
        
        if Users{n}.NNEExtraBasePrice==-100
            Users{n}.NNEExtraBasePrice=IMSYSPrices(Users{n}.AverageConsumptionBaseYear_kWh>=IMSYSPrices(:,1) & Users{n}.AverageConsumptionBaseYear_kWh<IMSYSPrices(:,2),3)*100;
        end
        
    end
end

if SmartCharging
    Users{1}.ChargingMat=ChargingMat;
    Users{1}.AvailabilityMat=AvailabilityMat;
    Users{1}.ShiftInds=ShiftInds;
    Users{1}.NumCostCats=NumCostCats;
end

%% Evaluate Smart Charging

if SmartCharging
    %ChargingVehicle=reshape(permute(squeeze(sum(Users{1}.ChargingMat(1:96,:,:,:),2)), [1,3,2]), [], NumUsers)/1000*4;
    ChargingMat1=zeros(24*Time.StepInd,3);
    for n=UserNum
        ChargingMat1=ChargingMat1+squeeze(sum(reshape(Users{n}.Logbook(:,5:7),24*Time.StepInd,[],3),2));
    end
    ChargingMat1=ChargingMat1*4/1000/(length(Time.Sim.VecInd(1:end-ControlPeriods))/(24*Time.StepInd));
    ChargingType=reshape(permute(squeeze(sum(Users{1}.ChargingMat(1:96,:,:,:),3)), [1,3,2]), [], Users{1}.NumCostCats)/1000*4;
    ChargingSum=sum(ChargingType, 2);
    
    [sum(ChargingType(:,1,:),'all'), sum(ChargingType(:,2,:),'all'), sum(ChargingType(:,3,:),'all')]/sum(ChargingType(:,:,:),'all')

    figure
    Load=mean(reshape(ChargingType',3,96,[]),3)';
    Load=circshift(Load, [Users{1}.ShiftInds, 0]);
    x = 1:96;
    y = circshift(mean(reshape(ChargingSum, 96, []), 2)', [0,Users{1}.ShiftInds]);
    z = zeros(size(x));
    col = (Load./repmat(max(Load, [], 2),1,3))';
    surface([x;x],[y;y],[z;z],[permute(repmat(col,1,1,2),[3,2,1])], 'facecol','no', 'edgecol','interp', 'linew',2);
    xticks(1:16:96)
    xticklabels({datestr(Time.Vec(1:16:96),'HH:MM')})
    ylabel("Charging power in kW")
    xlabel("Time")
    grid on

    hold on
    plot(circshift(squeeze(mean(reshape(ChargingType(:,1),96,[],1),2)), Users{1}.ShiftInds), "LineWidth", 1.2, "Color", [1, 0, 0])
    plot(circshift(squeeze(mean(reshape(ChargingType(:,2),96,[],1),2)), Users{1}.ShiftInds), "LineWidth", 1.2, "Color", [0, 1, 0])
    plot(circshift(squeeze(mean(reshape(ChargingType(:,3),96,[],1),2)), Users{1}.ShiftInds), "LineWidth", 1.2, "Color", [0, 0, 1])
    xticks(1:16:96)
    xticklabels({datestr(Time.Vec(1:16:96),'HH:MM')})
    legend(["All", "Spotmarket", "PV", "Secondary Reserve Energy"])

    figure
    plot(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):minutes(Time.StepMin):datetime(1,1,1,23,45,0, 'TimeZone', 'Africa/Tunis'), circshift(mean(sum(Users{1}.AvailabilityMat,3),2), ShiftInds))
    xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
    xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
    
end

%% Save Data

SimulatedUsers=@(User) (isfield(User, 'Time') || (isfield(User,"Logbook") && User.Logbook(2,9)>0));
Users=Users(cellfun(SimulatedUsers, Users));
Users{1}.Time.Stamp=datetime('now');

Users{1}.FileName=strcat(Path.Simulation, "Users_", datestr(Users{1}.Time.Stamp, "yyyymmdd-HHMM"), "_", Time.IntervalFile, "_", num2str(NumUsers), "_", num2str(SmartCharging), ".mat");

for n=UserNum
    if ~SmartCharging
        Users{n}.LogbookBase=Users{n}.Logbook;
    else 
        Users{n}.LogbookSmart=Users{n}.Logbook;
    end
    Users{n}=rmfield(Users{n}, 'Logbook');
end

if SaveResults
    save(Users{1}.FileName, "Users", "-v7.3");
end
disp(strcat("Successfully simulated within ", num2str(toc(TSim)), " seconds"))

%% Clean up workspace
 
clearvars TimeInd+TD.User n ActivateWaitbar Consumption24h ParkingDuration ConsumptionTilNextHomeStop TripDistance
clearvars NextHomeStop PublicChargerPower ChargingPower EnergyDemandLeft TimeStepIndsNeededForCharging EndOfShift
clearvars NumPredMethod TotalIterations NumUsers TimeOfForecast P PlugInTime PThreshold
clearvars SimulatedUsers PublicChargerDistribution h k UserNum UsePV UsePredictions UseParallel TSim TimeInd temp tc tc1
clearvars SpotmarketPrices PVPlants_Profile_Prediction ApplyGridConvenientCharging ChargingEnergy ConnectionDurations24h ControlPeriods IMSYSPrices n
clearvars SmartCharging SaveResults