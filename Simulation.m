tic
Demo=false;
ActivateWaitbar=true;
NumSimUsers=800;
PublicChargingThreshold=uint32(15); % in %

PThreshold=1.4;
NumPredMethod=1;

k=0;
TimeOfForecast=datetime(1,1,1,08,0,0,'TimeZone','Africa/Tunis');
TimeVecDateNum=datenum(TimeVec);
PublicChargerDistribution=[ 50000, 0.00;...
                           100000, 0.70;...
                           150000, 0.9;...
                           250000, 0.96]; % Power in [W], Likelihood cumulative
ChargingPower=zeros(NumSimUsers,1);
close all hidden

if Demo
    ForecastIntervalInd=ForecastIntervalHours*TimeStepInd;
    DemoUser=1;
    while Users{DemoUser}.PVPlantExists==false || sum(Users{DemoUser}.LogbookSource(:,1)>2)<100
        DemoUser=DemoUser+1;
    end
end

for n=1:size(Users,1)
    Users{n}.LogbookBase=Users{n}.LogbookSource;
end

if ActivateWaitbar
    h=waitbar(0, "Simuliere Ladevorgänge");
    TotalIterations=RangeTestInd(2)-(RangeTrainInd(1)+1);
end

for TimeInd=RangeTrainInd(1)+1:RangeTestInd(2)
    
    for n=1:NumSimUsers% DemoUser%size(Users,1)
        
        if (Users{n}.LogbookBase(TimeInd,1)==1 && Users{n}.LogbookBase(TimeInd-1,7)*100/Users{n}.BatterySize<PublicChargingThreshold) || (TimeInd+1<=size(Users{n}.LogbookBase,1) && Users{n}.LogbookBase(TimeInd,4)>=Users{n}.LogbookBase(TimeInd-1,7))
            
            PublicChargerPower=max((rand(1)>=PublicChargerDistribution(:,2)).*PublicChargerDistribution(:,1)); % [kW]
            ChargingPower(n)=min([max([Users{n}.ACChargingPowerVehicle, Users{n}.DCChargingPowerVehicle]), PublicChargerPower]); % Actual ChargingPower at public charger in [kW]
            NextHomeStop=min([length(Users{n}.LogbookBase), find(Users{n}.LogbookBase(TimeInd:end,1)==3,1)+TimeInd-1]);
            ConsumptionTilNextHomeStop=sum(Users{n}.LogbookBase(TimeInd:NextHomeStop,4));
            TimeStepIndsNeededForCharging=ceil(ConsumptionTilNextHomeStop*(1+double(PublicChargingThreshold)/100)/ChargingPower(n)*60/TimeStepMin); % [Wh/W
            
            EndOfShift=[strfind(Users{n}.LogbookBase(TimeInd:end,3)',zeros(1,TimeStepIndsNeededForCharging)), 1e9]; % Find the next time, when the vehicle parks for TimeStepIndsNeededForCharging complete TimeSteps
            EndOfShift=min([length(Users{n}.LogbookBase), EndOfShift(1)+TimeInd+TimeStepIndsNeededForCharging-1-1]);
            for k=EndOfShift:-1:TimeInd
                Users{n}.LogbookBase(k,:)=Users{n}.LogbookBase(k-TimeStepIndsNeededForCharging,:);
            end
            
            
            Users{n}.LogbookBase(TimeInd:TimeInd+TimeStepIndsNeededForCharging-1,1:7)=ones(TimeStepIndsNeededForCharging,1)*[6, zeros(1,6)]; % Public charging due to low SoC
        end
        
        if Users{n}.LogbookBase(TimeInd,1)==6
            Users{n}.LogbookBase(TimeInd,6)=min([ChargingPower(n)*TimeStepMin/60, Users{n}.BatterySize-Users{n}.LogbookBase(TimeInd-1,7)]); % Publicly charged energy during one TimeStep in [Wh]
        end
        
        if Users{n}.LogbookBase(TimeInd,1)==3
            
            if Users{n}.LogbookBase(TimeInd-1,1)<3
                
    %             [Users{n}]=DetermineChargingBaseScenario(Users{n}, TimeInd, TimeStep);

                if Users{n}.ChargingStrategy==1 % Always connect car to charging point if Duration of parking is higher than MinimumPluginTime
                    ParkingDuration=(find(Users{n}.LogbookBase(TimeInd:end,1)<3,1)-1)*TimeStep;
                    if ParkingDuration>Users{n}.MinimumPluginTime
                        Users{n}.LogbookBase(TimeInd,1)=4; % Plugged-in
                    else
                        Users{n}.LogbookBase(TimeInd,1)=3; % Not plugged-in
                    end

                elseif Users{n}.ChargingStrategy==2 % The probability of connection is a function of Plug-in time, SoC and the consumption within the next 24h
                    Consumption24h=uint32(sum(Users{n}.LogbookBase(TimeInd:min(TimeInd+hours(24)/TimeStep-1, size(Users{n}.LogbookBase,1)), 3))*Users{n}.Consumption/1000); % [Wh]
                    if Consumption24h>Users{n}.LogbookBase(TimeInd-1,7)
                        Users{n}.LogbookBase(TimeInd,1)=4; % Plugged-in
                    else
                        PlugInTime=(find(Users{n}.LogbookBase(TimeInd+1:end,1)<3,1)-1)*TimeStep;
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
    
    if TimeInd==RangeTestInd(1) && Demo
        SimulationDemoInit;
    end
    if TimeInd>=RangeTestInd(1) && Demo
        SimulationDemoLoop;
    end
    
    if ActivateWaitbar && mod(TimeInd,1000)==0
        waitbar((TimeInd-RangeTrainInd(1)+1)/TotalIterations);
    end
end
if ActivateWaitbar
    close(h)
end
toc