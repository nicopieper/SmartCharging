%% Availability, EnergyDemand and Prices

RLOfferPrices=repelem(ResPoPricesReal4H(floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1:floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1+ControlPeriods/(4*Time.StepInd),3)/1000,4*Time.StepInd); % [€/kW]
RLOfferPrices=RLOfferPrices(1:ControlPeriods);
AEOfferPrices=(ResEnPricesRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods,7)-AEFactor*abs(ResEnPricesRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods,7)))/1000; % [€/kWh]

CostsSpotmarket=zeros(ControlPeriods, 1, NumUsers);
CostsPV=ones(ControlPeriods, 1, NumUsers)*0.097;
CostsReserveMarket=zeros(ControlPeriods, 1, NumUsers);

PVPower=zeros(ControlPeriods, 1,NumUsers);
VarCounter=1;
for k=UserNum
    Availability(:,1,VarCounter)=(max(0, double(ismember(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,1), 4:5)) - double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,2))/Time.StepMin)) .* Users{k}.GridConvenientChargingAvailabilityControlPeriod;
    
    EnergyDemandCP(1,1,VarCounter)=double(Users{k}.BatterySize) - double(Users{k}.Logbook(TimeInd+TD.User-1,9)) + sum(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,4));
    
    Temp=[Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriods-1,4);0]';
    Temp1=[Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriods-1,8);0]';
    SoC=(double(Users{k}.Logbook(TimeInd+TD.User,9)) - sum(Temp(DemandInds),2) + sum(Temp1(DemandInds),2)); % in Wh
	MinEnergyRequiredToChargeTS(:,1,VarCounter)=-min(0, SoC-double(Users{k}.BatterySize*PublicChargingThreshold/100)); % Prevent empty battery within the next 24h. Gives the required energy to be charged in order to keep the SoC above the PublicChargingThreshold
    MaxEnergyChargableSoCTS(:,1,VarCounter)=double(Users{k}.BatterySize) - SoC; % Prevent that more energy is charged than the SoC allows. 

    MinEnergyChargableDeadlockTS(1,1,VarCounter)=min(double(Users{k}.BatterySize)-SoC(1), Availability(1,1,VarCounter)*MaxPower(1,1,VarCounter)/4);
    for l=2:ControlPeriods
        MinEnergyChargableDeadlockTS(l,1,VarCounter)=min(double(Users{k}.BatterySize)-SoC(l)-sum(MinEnergyChargableDeadlockTS(1:l-1,1,VarCounter)), Availability(l,1,VarCounter)*MaxPower(1,1,VarCounter)/4); % !!!muss der letzte Term ein MaxEnergyChargableSoCTS sein?!!!
    end
        
    MinEnergyChargableDeadlockCP(1,1,VarCounter)=sum(MinEnergyChargableDeadlockTS(:,1,VarCounter));
    
    
    
    
    
    
    
    
    
    
    
    
    CostsSpotmarket(1:ControlPeriods, 1, VarCounter)=(Users{k}.PrivateElectricityPrice + Users{k}.NNEEnergyPrice + Smard.DayaheadRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods)/10)/100*1.19;
    
    if Users{k}.PVPlantExists==true
        PVPower(:,1,VarCounter)=double(PVPlants{Users{k}.PVPlant}.(PVPlants_Profile_Prediction)(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods));
    else
        CostsPV(:,1,VarCounter)=10000*ones(ControlPeriods,1); % Ensure never use PVPlant if there is non. Also ensured by PowerCons as PVPower is constantly zero
    end
    
    CostsReserveMarket(1:ControlPeriods, 1, VarCounter)=((Users{k}.PrivateElectricityPrice + Users{k}.NNEEnergyPrice)/100 - AEOfferPrices)*1.19 - RLOfferPrices/16;
    
    VarCounter=VarCounter+1;
end


%% Aggregate Costs

Costs=[CostsSpotmarket, CostsPV, CostsReserveMarket];
Costs=Costs(:,CostCats,:);