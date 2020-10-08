%% Initialisation
tic
ActivateWaitbar=true;
PublicChargingThreshold=uint32(15); % in %
PThreshold=1.2;
NumUsers=400; % size(Users,1)-1;
SmartCharging=true;
UsePV=true;
ApplyGridConvenientCharging=true;


if ~exist('PublicChargerDistribution', 'var')
    PublicChargerDistribution=readmatrix(strcat(Path.Simulation, "PublicChargerProbability.xlsx"));
end

NumUsers=min(NumUsers, size(Users,1)-1);
ChargingPower=zeros(NumUsers,1);
EnergyDemandLeft=zeros(NumUsers+1,1);
% ChargingEfficiency=zeros(NumUsers+1,1);
delete(findall(0,'type','figure','tag','TMWWaitbar'));

Time.Sim.Start=max([Range.TrainDate(1), Users{1}.Time.Vec(1)]);
if ~SmartCharging
    Time.Sim.End=min([Range.TestDate(2), Users{1}.Time.Vec(end)]);
else
    Time.Sim.End=min([Range.TestDate(2), Users{1}.Time.Vec(end)-days(3)]);
end
Time.Sim.Vec=Time.Sim.Start:Time.Step:Time.Sim.End;
Time.Sim.VecInd=1:length(Time.Sim.Vec);
TD.Main=find(ismember(Time.Vec,Time.Sim.Start),1)-1;
%TimeDiffs.SpotmarketPred=find(ismember(Pred.Time.Vec,Time.Sim.Start),1)-1;
TD.User=find(ismember(Users{1}.Time.Vec,Time.Sim.Start),1)-1;


for n=2:size(Users,1)
    if ~SmartCharging
        Users{n}.Logbook=Users{n}.LogbookSource;
    else
        Users{n}.Logbook=Users{n}.LogbookBase;
        Users{n}.Logbook(2:end, 5:9)=0;
    end
end

if SmartCharging
    TimeOfForecast=datetime(1,1,1,8,0,0,'TimeZone','Africa/Tunis');
	ShiftInds=(hour(TimeOfForecast)*Time.StepInd + minute(TimeOfForecast)/minutes(Time.Step));
    InitialisePreAlgo;
end

if ActivateWaitbar
    h=waitbar(0, "Simulate charging processes");
end

Users{1}.PThreshold=PThreshold;

%% Start Simulation

for TimeInd=Time.Sim.VecInd(2:end)
          
    for n=2:NumUsers+1
        
        % Public charging: Only charge at public charging point if it is requiered due to low SoC
        if (Users{n}.Logbook(TimeInd+TD.User,1)==1 && Users{n}.Logbook(TimeInd+TD.User-1,9)*100/Users{n}.BatterySize<PublicChargingThreshold) || (TimeInd+TD.User+1<=size(Users{n}.Logbook,1) && Users{n}.Logbook(TimeInd+TD.User,4)>=Users{n}.Logbook(TimeInd+TD.User-1,9))
            
            k=TimeInd+TD.User;
            while k < length(Users{n}.Logbook) && ~ismember(Users{n}.Logbook(k,1), 3:5)
                k=k+1;
            end
            NextHomeStop=k;
            
            ConsumptionTilNextHomeStop=sum(Users{n}.Logbook(TimeInd+TD.User:NextHomeStop,4)); % [Wh]
            TripDistance=sum(Users{n}.Logbook(TimeInd+TD.User:NextHomeStop,3)); % [Wh]

            PublicChargerPower=max((rand(1)>=PublicChargerDistribution(find(PublicChargerDistribution>TripDistance/1000,1),:)).*PublicChargerDistribution(1,:)); % [kW]
            ChargingPower(n)=min([max([Users{n}.ACChargingPowerVehicle, Users{n}.DCChargingPowerVehicle]), PublicChargerPower]); % Actual ChargingPower at public charger in [kW]
%             ChargingEfficiency(n)=PublicChargerDistribution(end,find(ChargingPower(n)<=PublicChargerDistribution(1,2:end),1)+1)*((1.01-0.91)*randn(1)+0.99);
            
            EnergyDemandLeft(n)=double(min((double(PublicChargingThreshold)+2+TruncatedGaussian(4,[1 20]-5,1))/100*Users{n}.BatterySize+ConsumptionTilNextHomeStop-Users{n}.Logbook(TimeInd+TD.User-1,9), Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9)));
            TimeStepIndsNeededForCharging=ceil(EnergyDemandLeft(n)/ChargingPower(n)*60/Time.StepMin); % [Wh/W]
            
            if TimeStepIndsNeededForCharging>0
                k=TimeInd+TD.User;
                while k < length(Users{1}.Time.Vec)-TimeStepIndsNeededForCharging && ~isequal(Users{n}.Logbook(k:k+TimeStepIndsNeededForCharging-1,3),zeros(TimeStepIndsNeededForCharging,1))
                    k=k+1;
                end
                EndOfShift=k+TimeStepIndsNeededForCharging-1;
                if EndOfShift>length(Users{1}.Time.Vec)
                    error(strcat("Logbook would be falsly extended for Users ", num2str(n)))
                end

                Users{n}.Logbook(TimeInd+TD.User:EndOfShift,:)=Users{n}.Logbook(TimeInd+TD.User-TimeStepIndsNeededForCharging:EndOfShift-TimeStepIndsNeededForCharging,:);
                TimeStepIndsNeededForCharging=min(length(Users{n}.Logbook)-(TimeInd+TD.User-1), TimeStepIndsNeededForCharging);
                Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+TimeStepIndsNeededForCharging-1,1:9)=ones(TimeStepIndsNeededForCharging,1)*[6 + double(PublicChargerPower>30000), zeros(1,8)]; % Public charging due to low SoC
            end
        end
        
        if EnergyDemandLeft(n)>0
            Users{n}.Logbook(TimeInd+TD.User,8)=min([EnergyDemandLeft(n), ChargingPower(n)*Time.StepMin/60]); % Publicly charged energy during one Time.Step in [Wh]
            EnergyDemandLeft(n)=EnergyDemandLeft(n)-Users{n}.Logbook(TimeInd+TD.User,8); 
        end
        
        % Private charging: Decide whether to plug in the car the or not
        
        % Analyse this sequence. What happens due to change to 3:5?
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
                    Consumption24h=uint32(sum(Users{n}.Logbook(TimeInd+TD.User:min(TimeInd+TD.User+hours(24)/Time.Step-1, size(Users{n}.Logbook,1)), 4))); % [Wh]
                    if Consumption24h>Users{n}.Logbook(TimeInd+TD.User-1,9)
                        Users{n}.Logbook(TimeInd+TD.User,1)=4; % Plugged-in
                    else
                        PlugInTime=(find([Users{n}.Logbook(TimeInd+TD.User+1:end,1);0]<3,1)-1)*Time.Step;
                        P=min(1,PlugInTime/hours(2)) + min(1, (single(Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9)))/single(Users{n}.BatterySize)) + min(1, single(Consumption24h)/single(Users{n}.Logbook(TimeInd+TD.User-1,9)));
                        if P>PThreshold
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
        
        Users{n}.Logbook(TimeInd+TD.User,9)=Users{n}.Logbook(TimeInd+TD.User-1,9)-Users{n}.Logbook(TimeInd+TD.User,4);
        
    end
    
    if SmartCharging && hour(Time.Sim.Vec(TimeInd))==hour(TimeOfForecast) && minute(Time.Sim.Vec(TimeInd))==minute(TimeOfForecast)
        PreAlgo;
    end
        
    for n=2:NumUsers-1
        
        if ~SmartCharging
            if Users{n}.Logbook(TimeInd+TD.User,1)==4 && Users{n}.Logbook(TimeInd+TD.User,9)<Users{n}.BatterySize && (~ApplyGridConvenientCharging || Users{n}.GridConvenientChargingAvailability(mod(TimeInd+TD.User-1, 24*Time.StepInd)+1)) % Charging starts always when the car is plugged in, until the Battery is fully charged
                Users{n}.Logbook(TimeInd+TD.User,1)=5;
                ChargingEnergy=min((Time.StepMin-Users{n}.Logbook(TimeInd+TD.User,2))*Users{n}.ACChargingPowerHomeCharging/60, Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9)); %[Wh]
                if UsePV && Users{n}.PVPlantExists
                    Users{n}.Logbook(TimeInd+TD.User,6)=min(uint32(PVPlants{Users{n}.PVPlant}.ProfileQH(TimeInd+TD.Main)), ChargingEnergy);
                end
                Users{n}.Logbook(TimeInd+TD.User,5)=ChargingEnergy-Users{n}.Logbook(TimeInd+TD.User,6);
            end
        else
            if hour(Time.Sim.Vec(TimeInd))==hour(TimeOfForecast) && minute(Time.Sim.Vec(TimeInd))==minute(TimeOfForecast)
                %Users{n}.Logbook(TimeInd+TD.User+find((TimeInd+TD.User:TimeInd+TD.User+24*Time.StepInd-1)' .* sum(OptimalChargingEnergies(1:24*Time.StepInd,:,n-1), 2)>0))=5;
                Users{n}.Logbook(TimeInd+TD.User+find(ismember(Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+24*Time.StepInd-1,1), 4:5))-1,1)=4;
                Users{n}.Logbook(TimeInd+TD.User+find(sum(OptimalChargingEnergies(1:24*Time.StepInd,:,n-1), 2)>0)-1, 1) = 5;
                Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+24*Time.StepInd-1, 5:7)=OptimalChargingEnergies(1:24*Time.StepInd,:,n-1);
            end
        end
        
        
        if  Users{n}.Logbook(TimeInd+TD.User,9)<Users{n}.BatterySize && Users{n}.Logbook(TimeInd+TD.User,1)>=5
            Users{n}.Logbook(TimeInd+TD.User,9)=Users{n}.Logbook(TimeInd+TD.User,9)+Users{n}.Logbook(TimeInd+TD.User,5)+Users{n}.Logbook(TimeInd+TD.User,8);
        end
            
    end
    
    if ActivateWaitbar && mod(TimeInd+TD.User,1000)==0
        waitbar(TimeInd/length(Time.Sim.Vec));
    end
end
if ActivateWaitbar
    close(h);
end

for n=2:NumUsers
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
    
    for n=2:NumUsers+1
        if isfield(Users{n}, 'NNEEnergyPrice')
            Users{n}.FinListBase=uint32(double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,5))/1000 .* (Users{n}.PrivateElectricityPrice + Smard.DayaheadRealQH(Time.Sim.VecInd+TD.Main)/10 + Users{n}.NNEEnergyPrice)*1.19); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
        else
            Users{n}.FinListBase=uint32(double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,5))/1000 .* (Users{n}.PrivateElectricityPrice + Smard.DayaheadRealQH(Time.Sim.VecInd+TD.Main)/10 + 7.06)*1.19); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
        end
        Users{n}.FinListBase(:,2)=uint32(double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,8))/1000.*Users{n}.PublicACChargingPrices.*double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,1)==6)); % [ct] fixed price for public AC charging
        Users{n}.FinListBase(:,2)=Users{n}.FinListBase(:,2) + uint32(double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,8))/1000.*Users{n}.PublicDCChargingPrices.*double(Users{n}.Logbook(Time.Sim.VecInd+TD.User,1)==7)); % [ct] fixed price for public DC charging

        Users{n}.AverageConsumptionBaseYear_kWh=sum(Users{n}.Logbook(:,5:8), 'all')/1000/days(Time.End-Time.Start)*365.25;
        
        if Users{n}.NNEExtraBasePrice==-100
            Users{n}.NNEExtraBasePrice=IMSYSPrices(Users{n}.AverageConsumptionBaseYear_kWh>=IMSYSPrices(:,1) & Users{n}.AverageConsumptionBaseYear_kWh<IMSYSPrices(:,2),3)*100;
        end
        
    end
end

%% Evaluate Smart Charging

if SmartCharging
    ChargingSum=sum(ChargingVehicle, 3);
    [sum(ChargingType(:,1,:),'all'), sum(ChargingType(:,2,:),'all'), sum(ChargingType(:,3,:),'all')]/sum(ChargingType(:,:,:),'all')
    toc

    figure
    Load=mean(reshape(ChargingType',3,96,[]),3)';
    Load=circshift(Load, [ShiftInds, 0]);
    x = 1:96;
    y = circshift(mean(reshape(ChargingSum, 96, []), 2)', [0,ShiftInds]);
%     y = mean(reshape(ChargingSum, 96, []), 2)';
    z = zeros(size(x));
    col = (Load./repmat(max(Load, [], 2),1,3))';
    surface([x;x],[y;y],[z;z],[permute(repmat(col,1,1,2),[3,2,1])], 'facecol','no', 'edgecol','interp', 'linew',2);
    xticks(1:16:96)
    xticklabels({datestr(Time.Vec(1:16:96),'HH:MM')})

    hold on
    plot(circshift(squeeze(mean(reshape(ChargingType(:,1),96,[],1),2)), ShiftInds), "LineWidth", 1.2, "Color", [1, 0, 0])
    plot(circshift(squeeze(mean(reshape(ChargingType(:,2),96,[],1),2)), ShiftInds), "LineWidth", 1.2, "Color", [0, 1, 0])
    plot(circshift(squeeze(mean(reshape(ChargingType(:,3),96,[],1),2)), ShiftInds), "LineWidth", 1.2, "Color", [0, 0, 1])
    xticks(1:16:96)
    xticklabels({datestr(Time.Vec(1:16:96),'HH:MM')})
    legend(["All", "Spotmarket", "PV", "Secondary Reserve Energy"])

    figure
    plot(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):minutes(Time.StepMin):datetime(1,1,1,23,45,0, 'TimeZone', 'Africa/Tunis'), circshift(mean(sum(AvailabilityMat,3),2), ShiftInds))
    xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
    xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
end

%% Save Data

SimulatedUsers=@(User) (isfield(User, 'Time') || User.Logbook(2,9)>0);
Users=Users(cellfun(SimulatedUsers, Users));
Users{1}.Time.Stamp=datetime('now');
Users{1}.FileName=strcat(Path.Simulation, "Users_", datestr(Users{1}.Time.Stamp, "yyyymmdd-HHMM"), "_", Time.IntervalFile, "_", num2str(PThreshold), "_", num2str(NumUsers), "_", num2str(SmartCharging), ".mat");

for n=2:NumUsers+1
    if ~SmartCharging
        Users{n}.LogbookBase=Users{n}.Logbook;
    else 
        Users{n}.LogbookSmart=Users{n}.Logbook;
    end
    Users{n}=rmfield(Users{n}, 'Logbook');
end

save(Users{1}.FileName, "Users", "-v7.3");
disp(strcat("Successfully simulated within ", num2str(toc), " seconds"))

%% Clean up workspace
 
clearvars TimeInd+TD.User n ActivateWaitbar Consumption24h ParkingDuration ConsumptionTilNextHomeStop TripDistance
clearvars NextHomeStop PublicChargerPower ChargingPower EnergyDemandLeft TimeStepIndsNeededForCharging EndOfShift
clearvars NumPredMethod TotalIterations PublicChargingThreshold NumUsers TimeOfForecast P PlugInTime PThreshold
clearvars SimulatedUsers PublicChargerDistribution h k