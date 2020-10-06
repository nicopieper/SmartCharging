%% Spotmarket and Reserve Market prices

RLOfferPrices=repelem(ResPoPricesReal4H(floor((TimeInd+TD.Main-1)/16)+1:floor((TimeInd+TD.Main-1)/16)+1+ControlPeriods/4/4,3)/1000,16); % [€/kW]
RLOfferPrices=RLOfferPrices(1:ControlPeriods);
AEOfferPrices=(ResEnPricesRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods,7)-AEFactor*abs(ResEnPricesRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods,7)))/1000; % [€/kWh]

CostsSpotmarket=zeros(ControlPeriods, 1, NumUsers);
CostsReserveMarket=zeros(ControlPeriods, 1, NumUsers);
for k=2:NumUsers+1
    CostsSpotmarket(1:ControlPeriods, 1, k-1)=(Users{k}.PrivateElectricityPrice + Users{k}.NNEEnergyPrice + Smard.DayaheadRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods)/10)/100*1.19;
    CostsReserveMarket(1:ControlPeriods, 1, k-1)=((Users{k}.PrivateElectricityPrice + Users{k}.NNEEnergyPrice)/100 - AEOfferPrices)*1.19 - RLOfferPrices/16;
end

%% PV Power and prices

CostsPV=ones(ControlPeriods, 1, NumUsers)*0.097;
PVPower=zeros(ControlPeriods, 1,NumUsers);
for k=2:NumUsers+1
    Availability(:,1,k-1)=double(ismember(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,1), 4:5)) .* Users{k}.GridConvenientChargingAvailabilityControlPeriod;
    EnergyDemand(1,1,k-1)=double(Users{k}.BatterySize - (Users{k}.Logbook(TimeInd+TD.User-1+ControlPeriods,9) - sum(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,5:8), 'all')));
    if Users{k}.PVPlantExists==true
        PVPower(:,1,k-1)=double(PVPlants{Users{k}.PVPlant}.ProfileQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods));
    else
        CostsPV(:,1,k-1)=10000*ones(ControlPeriods,1); % Ensure never use PVPlant if there is non. Also ensured by PowerCons as PVPower is constantly zero
    end
end

%% Aggregate Costs

Costs=[CostsSpotmarket, CostsPV, CostsReserveMarket];
Costs=Costs(:,CostCats,:);