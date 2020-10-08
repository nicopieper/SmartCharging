%% Availability, EnergyDemand and Prices

RLOfferPrices=repelem(ResPoPricesReal4H(floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1:floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1+ControlPeriods/(4*Time.StepInd),3)/1000,4*Time.StepInd); % [€/kW]
RLOfferPrices=RLOfferPrices(1:ControlPeriods);
AEOfferPrices=(ResEnPricesRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods,7)-AEFactor*abs(ResEnPricesRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods,7)))/1000; % [€/kWh]

CostsSpotmarket=zeros(ControlPeriods, 1, NumUsers);
CostsPV=ones(ControlPeriods, 1, NumUsers)*0.097;
CostsReserveMarket=zeros(ControlPeriods, 1, NumUsers);

PVPower=zeros(ControlPeriods, 1,NumUsers);
for k=2:NumUsers+1
    Availability(:,1,k-1)=(max(0, double(ismember(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,1), 4:5)) - double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,2))/Time.StepMin)) .* Users{k}.GridConvenientChargingAvailabilityControlPeriod;
    
    EnergyDemandControlPeriod(1,1,k-1)=double(Users{k}.BatterySize - (Users{k}.Logbook(TimeInd+TD.User,9) - sum(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,4))));
    Temp=[Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriods-1,4);0]';
    EnergyDemandEssentialOneDay(:,1,k-1)=double(-min(0, (Users{k}.Logbook(TimeInd+TD.User,9)-uint32(sum(Temp(DemandInds),2)))-Users{n}.BatterySize*PublicChargingThreshold/100)); % Prevent empty battery within the next 24h. Gives the required energy to be charged in order to keep the SoC above the PublicChargingThreshold
    MaxEnergyCharged(:,1,k-1)=double(Users{n}.BatterySize-(Users{k}.Logbook(TimeInd+TD.User,9)-uint32(sum(Temp(DemandInds),2))));
    EnergyDemandControlPeriod(1,1,k-1)=Users{n}.BatterySize - (Users{k}.Logbook(TimeInd+TD.User,9)-uint32(sum(Temp(end),2)));
    
    CostsSpotmarket(1:ControlPeriods, 1, k-1)=(Users{k}.PrivateElectricityPrice + Users{k}.NNEEnergyPrice + Smard.DayaheadRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods)/10)/100*1.19;
    
    if Users{k}.PVPlantExists==true
        PVPower(:,1,k-1)=double(PVPlants{Users{k}.PVPlant}.ProfileQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods));
    else
        CostsPV(:,1,k-1)=10000*ones(ControlPeriods,1); % Ensure never use PVPlant if there is non. Also ensured by PowerCons as PVPower is constantly zero
    end
    
    CostsReserveMarket(1:ControlPeriods, 1, k-1)=((Users{k}.PrivateElectricityPrice + Users{k}.NNEEnergyPrice)/100 - AEOfferPrices)*1.19 - RLOfferPrices/16;
end

if sum(EnergyDemandEssentialOneDay, 'all')>0
    1
end
if sum(MaxEnergyCharged, 'all')==0
    1
end

%% Aggregate Costs

Costs=[CostsSpotmarket, CostsPV, CostsReserveMarket];
Costs=Costs(:,CostCats,:);