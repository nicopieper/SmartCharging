tic
ActivateWaitbar=true;
NumSimUsers=800;
PublicChargingThreshold=uint32(15); % in %
PThreshold=1.2;


if ~exist('PublicChargerDistribution', 'var')
    PathVehicleData=[Path 'Predictions' Dl 'VehicleData' Dl];
    PublicChargerDistribution=readmatrix(strcat(PathVehicleData, "PublicChargerProbability.xlsx"));
end

ChargingPower=zeros(NumSimUsers,1);
EnergyDemandLeft=zeros(NumSimUsers+1,1);
% ChargingEfficiency=zeros(NumSimUsers+1,1);
close hidden


for n=2:size(Users,1)
    Users{n}.LogbookBase=Users{n}.LogbookSource;
end

if ActivateWaitbar
    h=waitbar(0, "Simuliere Ladevorgänge");
    TotalIterations=RangeTestInd(2)-(RangeTrainInd(1)+1);
end

Users{1}.PThreshold=PThreshold;

for TimeInd=RangeTrainInd(1)+1:RangeTestInd(2)
    
    for n=2:NumSimUsers+1% DemoUser%size(Users,1)
        
        if (Users{n}.LogbookBase(TimeInd,1)==1 && Users{n}.LogbookBase(TimeInd-1,7)*100/Users{n}.BatterySize<PublicChargingThreshold) || (TimeInd+1<=size(Users{n}.LogbookBase,1) && Users{n}.LogbookBase(TimeInd,4)>=Users{n}.LogbookBase(TimeInd-1,7))
            
%             NextHomeStop=min([length(Users{n}.LogbookBase), find(Users{n}.LogbookBase(TimeInd:end,1)==3,1)+TimeInd-1]); %[TimeIndices]
            k=TimeInd;
            while k < length(Users{n}.LogbookBase) && Users{n}.LogbookBase(k,1)~=3
                k=k+1;
            end
            NextHomeStop=k;
            
            ConsumptionTilNextHomeStop=sum(Users{n}.LogbookBase(TimeInd:NextHomeStop,4)); % [Wh]
            TripDistance=sum(Users{n}.LogbookBase(TimeInd:NextHomeStop,3)); % [Wh]

            PublicChargerPower=max((rand(1)>=PublicChargerDistribution(find(PublicChargerDistribution>TripDistance/1000,1),:)).*PublicChargerDistribution(1,:)); % [kW]
            ChargingPower(n)=min([max([Users{n}.ACChargingPowerVehicle, Users{n}.DCChargingPowerVehicle]), PublicChargerPower]); % Actual ChargingPower at public charger in [kW]
%             ChargingEfficiency(n)=PublicChargerDistribution(end,find(ChargingPower(n)<=PublicChargerDistribution(1,2:end),1)+1)*((1.01-0.91)*randn(1)+0.99);
            
            EnergyDemandLeft(n)=double(min((double(PublicChargingThreshold)+2+TruncatedGaussian(4,[1 20]-5,1))/100*Users{n}.BatterySize+ConsumptionTilNextHomeStop-Users{n}.LogbookBase(TimeInd-1,7), Users{n}.BatterySize-Users{n}.LogbookBase(TimeInd-1,7)));
            TimeStepIndsNeededForCharging=ceil(EnergyDemandLeft(n)/ChargingPower(n)*60/TimeStepMin); % [Wh/W]
            
            if TimeStepIndsNeededForCharging>0
                k=TimeInd;
                while k < length(Users{n}.LogbookBase) && ~isequal(Users{n}.LogbookBase(k:k+TimeStepIndsNeededForCharging-1,3),zeros(TimeStepIndsNeededForCharging,1))
                    k=k+1;
                end
                EndOfShift=k+TimeStepIndsNeededForCharging-1;
%                 EndOfShift=[strfind(Users{n}.LogbookBase(TimeInd:end,3)',zeros(1,TimeStepIndsNeededForCharging)), 1e9]; % Find the next time, when the vehicle parks for TimeStepIndsNeededForCharging complete TimeSteps
%                 EndOfShift=min([length(Users{n}.LogbookBase), EndOfShift(1)+TimeInd+TimeStepIndsNeededForCharging-1-1]);
%                 if EndOfShift1~=EndOfShift
%                     1
%                 end
                Users{n}.LogbookBase(TimeInd:EndOfShift,:)=Users{n}.LogbookBase(TimeInd-TimeStepIndsNeededForCharging:EndOfShift-TimeStepIndsNeededForCharging,:);
                TimeStepIndsNeededForCharging=min(length(Users{n}.LogbookBase)-(TimeInd-1), TimeStepIndsNeededForCharging);
                Users{n}.LogbookBase(TimeInd:TimeInd+TimeStepIndsNeededForCharging-1,1:7)=ones(TimeStepIndsNeededForCharging,1)*[6 + PublicChargerPower<30000, zeros(1,6)]; % Public charging due to low SoC
            end
        end
        
        if EnergyDemandLeft(n)>0
            Users{n}.LogbookBase(TimeInd,6)=min([EnergyDemandLeft(n), ChargingPower(n)*TimeStepMin/60]); % Publicly charged energy during one TimeStep in [Wh]
            EnergyDemandLeft(n)=EnergyDemandLeft(n)-Users{n}.LogbookBase(TimeInd,6); 
        end
        
        if Users{n}.LogbookBase(TimeInd,1)==3
            
            if Users{n}.LogbookBase(TimeInd-1,1)<3

                if Users{n}.ChargingStrategy==1 % Always connect car to charging point if Duration of parking is higher than MinimumPluginTime
                    ParkingDuration=(find(Users{n}.LogbookBase(TimeInd:end,1)<3,1)-1)*TimeStep;
                    if ParkingDuration>Users{n}.MinimumPluginTime
                        Users{n}.LogbookBase(TimeInd,1)=4; % Plugged-in
                    else
                        Users{n}.LogbookBase(TimeInd,1)=3; % Not plugged-in
                    end

                elseif Users{n}.ChargingStrategy==2 % The probability of connection is a function of Plug-in time, SoC and the consumption within the next 24h
                    Consumption24h=uint32(sum(Users{n}.LogbookBase(TimeInd:min(TimeInd+hours(24)/TimeStep-1, size(Users{n}.LogbookBase,1)), 4))); % [Wh]
                    if Consumption24h>Users{n}.LogbookBase(TimeInd-1,7)
                        Users{n}.LogbookBase(TimeInd,1)=4; % Plugged-in
                    else
                        PlugInTime=(find([Users{n}.LogbookBase(TimeInd+1:end,1);0]<3,1)-1)*TimeStep;
                        P=min(1,PlugInTime/hours(2)) + min(1, (single(Users{n}.BatterySize-Users{n}.LogbookBase(TimeInd-1,7)))/single(Users{n}.BatterySize)) + min(1, single(Consumption24h)/single(Users{n}.LogbookBase(TimeInd-1,7)));
                        if P>PThreshold
                            Users{n}.LogbookBase(TimeInd,1)=4; % Plugged-in
                        else
                            Users{n}.LogbookBase(TimeInd,1)=3; % Not plugged-in
                        end
                    end
                end
            
            elseif Users{n}.LogbookBase(TimeInd-1,1)>=4
                Users{n}.LogbookBase(TimeInd,1)=4;
            end
        end
        
        Users{n}.LogbookBase(TimeInd,7)=Users{n}.LogbookBase(TimeInd-1,7)-Users{n}.LogbookBase(TimeInd,4);
        if Users{n}.LogbookBase(TimeInd,1)==4 && Users{n}.LogbookBase(TimeInd,7)<Users{n}.BatterySize
            Users{n}.LogbookBase(TimeInd,1)=5;
%             Users{n}.LogbookBase(TimeInd,5)=min(max(minutes(0), TimeStep-minutes(Users{n}.LogbookBase(TimeInd,2))-minutes(1))/hours(1)*Users{n}.ChargingPower, Users{n}.BatterySize-Users{n}.LogbookBase(TimeInd-1,7)); %[Wh]
            Users{n}.LogbookBase(TimeInd,5)=min((TimeStepMin-Users{n}.LogbookBase(TimeInd,2))*Users{n}.ACChargingPowerHomeCharging/60, Users{n}.BatterySize-Users{n}.LogbookBase(TimeInd-1,7)); %[Wh]
        end
        
        if  Users{n}.LogbookBase(TimeInd,7)<Users{n}.BatterySize && Users{n}.LogbookBase(TimeInd,1)>=5
            Users{n}.LogbookBase(TimeInd,7)=Users{n}.LogbookBase(TimeInd,7)+Users{n}.LogbookBase(TimeInd,5)+Users{n}.LogbookBase(TimeInd,6);
        end
            
    end
    
    if ActivateWaitbar && mod(TimeInd,1000)==0
        waitbar((TimeInd-RangeTrainInd(1)+1)/TotalIterations);
    end
end
if ActivateWaitbar
    close(h);
end

%% Evaluate base electricity costs

for n=2:NumSimUsers+1
    Users{n}.FinListBase=uint32(double(Users{n}.LogbookBase(:,5))/1000.*(Users{n}.PrivateElectricityPrice+DayaheadRealQH/10)*1.19); % [ct] total electricity costs equal base price of user + current production costs. VAT applies to the end price
    Users{n}.FinListBase(:,2)=uint32(zeros(length(TimeVec),1) + double(Users{n}.LogbookBase(:,6))/1000.*Users{n}.PublicACChargingPrices.*double(Users{n}.LogbookBase(:,1)==6)); % [ct] fixed price for public AC charging
    Users{n}.FinListBase(:,2)=Users{n}.FinListBase(:,2) + uint32(double(Users{n}.LogbookBase(:,6))/1000.*Users{n}.PublicDCChargingPrices.*double(Users{n}.LogbookBase(:,1)==7)); % [ct] fixed price for public DC charging
    
    Users{n}.AverageConsumptionBaseYear_kWh=sum(Users{n}.LogbookBase(:,5:6), 'all')/1000/days(DateEnd-DateStart)*365.25;
end

%%


Users{1}.TimeStamp=datetime('now');
SimulatedUsers=@(User) (isfield(User, 'TimeVec') || User.LogbookBase(2, 7)>0);
Users=Users(cellfun(SimulatedUsers, Users));

save(strcat(PathSimulationData, Dl, "Users_", num2str(PThreshold), "_", num2str(NumSimUsers), "_", datestr(Users{1}.TimeStamp, "yyyy-mm-dd_HH-MM"), ".mat"), "Users", "-v7.3");
disp(strcat("Successfully simulated within ", num2str(toc), " seconds"))
 
clearvars TimeInd n ActivateWaitbar Consumption24h ParkingDuration ConsumptionTilNextHomeStop TripDistance
clearvars NextHomeStop PublicChargerPower ChargingPower EnergyDemandLeft TimeStepIndsNeededForCharging EndOfShift
clearvars NumPredMethod TotalIterations PublicChargingThreshold NumSimUsers TimeOfForecast TimeVecDateNum P PlugInTime PThreshold
clearvars SimulatedUsers 