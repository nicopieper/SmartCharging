%% Initialisation
tic
ActivateWaitbar=true;
PublicChargingThreshold=uint32(15); % in %
PThreshold=1.2;
NumUsers=200; % size(Users,1)-1;
SmartCharging=true;


if ~exist('PublicChargerDistribution', 'var')
    PublicChargerDistribution=readmatrix(strcat(Path.Simulation, "PublicChargerProbability.xlsx"));
end

NumUsers=min(NumUsers, size(Users,1)-1);
ChargingPower=zeros(NumUsers,1);
EnergyDemandLeft=zeros(NumUsers+1,1);
% ChargingEfficiency=zeros(NumUsers+1,1);
close hidden

Time.Sim.Start=max([Range.TrainDate(1), Users{1}.Time.Vec(1)]);
Time.Sim.End=min([Range.TestDate(2), Users{1}.Time.Vec(end)]);
Time.Sim.Vec=Time.Sim.Start:Time.Step:Time.Sim.End;
TD.Main=find(ismember(Time.Vec,Time.Sim.Start),1)-1;
%TimeDiffs.SpotmarketPred=find(ismember(Pred.Time.Vec,Time.Sim.Start),1)-1;
TD.User=find(ismember(Users{1}.Time.Vec,Time.Sim.Start),1)-1;


for n=2:size(Users,1)
    if ~SmartCharging
        Users{n}.Logbook=Users{n}.LogbookSource;
    else
        Users{n}.Logbook=Users{n}.LogbookBase;
        TimeOfForecast=datetime(1,1,1,08,0,0,'TimeZone','Africa/Tunis');
    end
end

if SmartCharging
    InitialisePreAlgo;
end

if ActivateWaitbar
    h=waitbar(0, "Simulate charging processes");
    TotalIterations=Time.Sim.Start-(Time.Sim.Start);
end

Users{1}.PThreshold=PThreshold;

%% Start Simulation

for TimeInd=2:length(Time.Sim.Vec)
    
    for n=2:NumUsers+1
        
        % Public charging: Only charge at public charging point if it is requiered due to low SoC
        if (Users{n}.Logbook(TimeInd+TD.User,1)==1 && Users{n}.Logbook(TimeInd+TD.User-1,9)*100/Users{n}.BatterySize<PublicChargingThreshold) || (TimeInd+TD.User+1<=size(Users{n}.Logbook,1) && Users{n}.Logbook(TimeInd+TD.User,4)>=Users{n}.Logbook(TimeInd+TD.User-1,9))
            
            k=TimeInd+TD.User;
            while k < length(Users{n}.Logbook) && Users{n}.Logbook(k,1)~=3
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
                while k < length(Users{n}.Logbook)-TimeStepIndsNeededForCharging+1 && ~isequal(Users{n}.Logbook(k:k+TimeStepIndsNeededForCharging-1,3),zeros(TimeStepIndsNeededForCharging,1))
                    k=k+1;
                end
                EndOfShift=k+TimeStepIndsNeededForCharging-1;

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
        
        if ~SmartCharging
            if Users{n}.Logbook(TimeInd+TD.User,1)==4 && Users{n}.Logbook(TimeInd+TD.User,9)<Users{n}.BatterySize % Charging starts always when the car is plugged in, until the Battery is fully charged
                Users{n}.Logbook(TimeInd+TD.User,1)=5;
                Users{n}.Logbook(TimeInd+TD.User,5)=min((Time.StepMin-Users{n}.Logbook(TimeInd+TD.User,2))*Users{n}.ACChargingPowerHomeCharging/60, Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9)); %[Wh]
            end
        else
            if hour(Time.Sim.Vec(TimeInd))==hour(TimeOfForecast)
                PreAlgo;
            end
        end
        
        
        if  Users{n}.Logbook(TimeInd+TD.User,9)<Users{n}.BatterySize && Users{n}.Logbook(TimeInd+TD.User,1)>=5
            Users{n}.Logbook(TimeInd+TD.User,9)=Users{n}.Logbook(TimeInd+TD.User,9)+Users{n}.Logbook(TimeInd+TD.User,5)+Users{n}.Logbook(TimeInd+TD.User,8);
        end
            
    end
    
    if ActivateWaitbar && mod(TimeInd+TD.User,1000)==0
        waitbar((TimeInd+TD.User-Range.TrainInd(1)+1)/TotalIterations);
    end
end
if ActivateWaitbar
    close(h);
end

%% Evaluate base electricity costs

if ~SmartCharging
    if ~exist('Smard', 'var')
        GetSmardData;
    end
    for n=2:NumUsers+1
        if isfield(Users{n}, 'NNEEnergyPrice')
            Users{n}.FinListBase=uint32(double(Users{n}.Logbook(:,5))/1000 .* (Users{n}.PrivateElectricityPrice + Smard.DayaheadRealQH/10 + Users{n}.NNEEnergyPrice)*1.19); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
        else
            Users{n}.FinListBase=uint32(double(Users{n}.Logbook(:,5))/1000 .* (Users{n}.PrivateElectricityPrice + Smard.DayaheadRealQH/10 + 7.06)*1.19); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
        end
        Users{n}.FinListBase(:,2)=uint32(zeros(length(Time.Vec),1) + double(Users{n}.Logbook(:,8))/1000.*Users{n}.PublicACChargingPrices.*double(Users{n}.Logbook(:,1)==6)); % [ct] fixed price for public AC charging
        Users{n}.FinListBase(:,2)=Users{n}.FinListBase(:,2) + uint32(double(Users{n}.Logbook(:,8))/1000.*Users{n}.PublicDCChargingPrices.*double(Users{n}.Logbook(:,1)==7)); % [ct] fixed price for public DC charging

        Users{n}.AverageConsumptionBaseYear_kWh=sum(Users{n}.Logbook(:,5:8), 'all')/1000/days(Time.End-Time.Start)*365.25;
    end
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