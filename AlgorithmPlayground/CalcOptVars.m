%% Spotmarket and Reserve Market prices

RLOfferPrices=repelem(ResPoPricesReal4H((k-1)*6+1:(k-1)*6+ControlPeriods/4/4,3)/1000,16); % [€/kW]
RLOfferPrices=RLOfferPrices(1:ControlPeriods);
AEOfferPrices=(ResEnPricesRealQH((k-1)*96+1:(k-1)*96+ControlPeriods,7)-AEFactor*abs(ResEnPricesRealQH((k-1)*96+1:(k-1)*96+ControlPeriods,7)))/1000; % [€/kWh]

SpotmarketCosts=zeros(ControlPeriods, 1, NumUsers);
ReserveMarketCosts=zeros(ControlPeriods, 1, NumUsers);
for n=1:NumUsers
    SpotmarketCosts(1:ControlPeriods, 1, n)=(Users{n}.PrivateElectricityPrice + Users{n}.NNEEnergyPrice + Smard.DayaheadRealQH((k-1)*96+1:(k-1)*96+ControlPeriods)/10)/100*1.19;
    ReserveMarketCosts(1:ControlPeriods, 1, n)=((Users{n}.PrivateElectricityPrice + Users{n}.NNEEnergyPrice)/100 - AEOfferPrices)*1.19 - RLOfferPrices/16;
end

%% PV Power and prices

PVCosts=ones(ControlPeriods, 1, NumUsers)*0.097;
PVPower=zeros(ControlPeriods, 1,NumUsers);
for n=1:NumUsers
    Availability(:,1,n)=ismember(Users{n}.LogbookBase((k-1)*96+1:(k-1)*96+ControlPeriods,1), 4:5) & Users{n}.GridConvenientChargingAvailabilityControlPeriod;
    EnergyDemand(1,1,n)=double(Users{n}.BatterySize - (Users{n}.LogbookBase((k-1)*96+ControlPeriods,7) - sum(Users{n}.LogbookBase((k-1)*96+1:(k-1)*96+ControlPeriods,5))));
    if Users{n}.PVPlantExists==true
        PVPower(:,1,n)=double(PVPlants{Users{n}.PVPlant}.ProfileQH((k-1)*96+1:(k-1)*96+ControlPeriods));
    else
        PVCosts(:,1,n)=10000*ones(ControlPeriods,1); % Ensure never use PVPlant if there is non. Also ensured by PowerCons as PVPower is constantly zero
    end
end

%% Aggregate Costs

Costs=[SpotmarketCosts, PVCosts, ReserveMarketCosts];
Costs=Costs(:,CostCats,:);