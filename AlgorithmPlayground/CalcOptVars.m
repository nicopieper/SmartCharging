SpotmarketCosts=zeros(ControlPeriods, 1, NumUsers);
for n=1:NumUsers
    SpotmarketCosts=UsersT(

SpotmarketCosts=repmat((ElectricityBasePrice+DayaheadReal1QH((k-1)*96+1:(k-1)*96+ControlPeriods)/1000)*1.19, 1, 1, NumUsers);



PVCosts=ones(ControlPeriods, 1, NumUsers)*0.097;
PVPower=zeros(ControlPeriods, 1,NumUsers);
for n=1:NumUsers
    Availability(:,1,n)=ismember(UsersT{n}.LogbookBase((k-1)*96+1:(k-1)*96+ControlPeriods,1), 4:5);
    EnergyDemand(1,1,n)=double(UsersT{n}.BatterySize - (UsersT{n}.LogbookBase((k-1)*96+ControlPeriods,7) - sum(UsersT{n}.LogbookBase((k-1)*96+1:(k-1)*96+ControlPeriods,5))));
    if UsersT{n}.PVPlantExists==true
        PVPower(:,1,n)=double(PVPlants{UsersT{n}.PVPointer}.Profile((k-1)*96+1:(k-1)*96+ControlPeriods));
    else
        PVCosts(:,2,n)=10000*ones(ControlPeriods,1); % Ensure never use PVPlant if there is non. Also ensured by PowerCons as PVPower is constantly zero
    end
end


RLOfferPrices=repelem(ResPoPricesReal4H((k-1)*6+1:(k-1)*6+ControlPeriods/4/4,3)/1000,16); % [€/kW]
RLOfferPrices=RLOfferPrices(1:ControlPeriods);
AEOfferPrices=(ResEnPricesRealQH((k-1)*96+1:(k-1)*96+ControlPeriods,7)-AEFactor*abs(ResEnPricesRealQH((k-1)*96+1:(k-1)*96+ControlPeriods,7)))/1000; % [€/kWh]

ReserveMarketCosts=(ElectricityBasePrice-repmat(AEOfferPrices,1,1,NumUsers))*1.19 - RLOfferPrices/16;



