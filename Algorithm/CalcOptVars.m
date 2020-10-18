%% Availability, EnergyDemand and Prices

RLOfferPrices=repelem(ResPoPricesReal4H(floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1:floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1+ControlPeriods/(4*Time.StepInd),3)/1000,4*Time.StepInd); % [€/kW]
RLOfferPrices=RLOfferPrices(1:ControlPeriods);
AEOfferPrices=(ResEnPricesRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods,7)-AEFactor*abs(ResEnPricesRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods,7)))/1000; % [€/kWh]

CostsSpotmarket=zeros(ControlPeriods, 1, NumUsers);
CostsPV=ones(ControlPeriods, 1, NumUsers)*0.097;
CostsReserveMarket=zeros(ControlPeriods, 1, NumUsers);

PVPower=zeros(ControlPeriods, 1,NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    
    Availability(:,1,VarCounter)=(max(0, double(ismember(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,1), 4:5)) - double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,2))/Time.StepMin)) .* Users{k}.GridConvenientChargingAvailabilityControlPeriod;
    
    %EnergyDemandCP(1,1,VarCounter)=Users{k}.BatterySize - double(Users{k}.Logbook(TimeInd+TD.User-1,9)) + sum(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriods,4));
    
    Consumed=Users{k}.Logbook(TimeInd+TD.User+1:TimeInd+TD.User+ControlPeriods-1,4);
    PublicCharged=Users{k}.Logbook(TimeInd+TD.User+1:TimeInd+TD.User+ControlPeriods-1,8);
%     Consumed1=[Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriods-1,4);0]';
%     PublicCharged1=[Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriods-1,8);0]';

    % The maximal energy that is charagble without exceeding the battery
    % limit in every time step
    
    SoC=Users{k}.Logbook(TimeInd+TD.User,9) - sum(Users{k}.Logbook(TimeInd+TD.User,5:7),2) - [0;cumsum(Consumed)] + [0;cumsum(PublicCharged)]; % in Wh
%     SoC1=Users{k}.Logbook(TimeInd+TD.User,9) - sum(Users{k}.Logbook(TimeInd+TD.User,5:7),2) - sum(Consumed1(DemandInds),2) + sum(PublicCharged1(DemandInds),2); % in Wh
%     if any(SoC1~=SoC)
%         error("error")
%     end
    MaxEnergyChargableSoCTS(:,1,VarCounter)=Users{k}.BatterySize - SoC ;
    
    
    % The energy required to charge in every time step to avoid empty
    % batteries
    
    
    % Wie viel Energie kann ich auf MinEnergyRequiredTS maximal drauf
    % addieren, sodass die Energie ladbar ist? Ladbar im Sinne von genügend
    % Möglichkeiten die Energie zu laden und ohne dass das SoC überläuft.
    
    %
    
    MinEnergyRequiredTS(:,1,VarCounter)=round(Users{k}.PublicChargingThreshold_Wh*0.3) - SoC;
%     MinEnergyRequiredTS(:,1,VarCounter)=sum(Consumed(DemandInds),2) - sum(PublicCharged(DemandInds),2) - (Users{k}.Logbook(TimeInd+TD.User,9) - sum(Users{k}.Logbook(TimeInd+TD.User,5:7),2));
    
    
    % The maximal energy that is chargable without exceeding the battery
    % such that the battery is as full as possible at the end of the
    % ControlPeriod
    
    MaxEnergyChargableDeadlockTS=zeros(ControlPeriods,1);
%     MaxEnergyChargableDeadlockTS1=zeros(1,ControlPeriods+1);
    ChargingInds=find(Availability(:,1,VarCounter)>0);
    
    if ~isempty(ChargingInds)
        SoCNew=SoC;
%         SoCNew1=SoC;
        l=0;
        while l<length(ChargingInds) && max(SoCNew(ChargingInds(end-l):end))<Users{k}.BatterySize 
            MaxEnergyChargableDeadlockTS(ChargingInds(end-l),1)=min(Availability(ChargingInds(end-l),1,VarCounter)*MaxPower(1,1,VarCounter)/4, Users{k}.BatterySize-max(SoCNew(ChargingInds(end-l):end)));
            MaxEnergyChargableDeadlockTS1(1,ChargingInds(end-l))=min(Availability(ChargingInds(end-l),1,VarCounter)*MaxPower(1,1,VarCounter)/4, Users{k}.BatterySize-max(SoCNew1(ChargingInds(end-l):end)));
            SoCNew=SoC+[0;cumsum(MaxEnergyChargableDeadlockTS(2:192,1))];
%             SoCNew1=SoC+sum(MaxEnergyChargableDeadlockTS1(DemandInds), 2);
%             if any(SoCNew~=SoCNew1)
%                 error("error")
%             end
            l=l+1;
        end
        
        MaxEnergyChargableDeadlockCP(1,1,VarCounter)=sum(MaxEnergyChargableDeadlockTS);
    else % Availability completly zero
        MaxEnergyChargableDeadlockCP(1,1,VarCounter)=0;
    end
    
   
    
    
    
%     
%     
% 	MinEnergyRequiredToChargeTS(:,1,VarCounter)=-min(0, SoC-double(Users{k}.BatterySize*PublicChargingThreshold/100)); % Prevent empty battery within the next 24h. Gives the required energy to be charged in order to keep the SoC above the PublicChargingThreshold
%     MaxEnergyChargableSoCTS(:,1,VarCounter)=Users{k}.BatterySize - SoC; % Prevent that more energy is charged than the SoC allows. 
    
    
%     MinEnergyChargableDeadlockTS(1,1,VarCounter)=min(Users{k}.BatterySize-SoC(1), Availability(1,1,VarCounter)*MaxPower(1,1,VarCounter)/4);
%     for l=2:ControlPeriods
%         MinEnergyChargableDeadlockTS(l,1,VarCounter)=min(Users{k}.BatterySize-SoC(l)-sum(MinEnergyChargableDeadlockTS(1:l-1,1,VarCounter)), Availability(l,1,VarCounter)*MaxPower(1,1,VarCounter)/4); % !!!muss der letzte Term ein MaxEnergyChargableSoCTS sein?!!!
%     end
%         
%     MinEnergyChargableDeadlockCP(1,1,VarCounter)=sum(MinEnergyChargableDeadlockTS(:,1,VarCounter));
    
    
    CostsSpotmarket(1:ControlPeriods, 1, VarCounter)=(Users{k}.PrivateElectricityPrice + Users{k}.NNEEnergyPrice + Smard.DayaheadRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods)/10)/100*1.19;
    
    if Users{k}.PVPlantExists==true
        PVPower(:,1,VarCounter)=double(PVPlants{Users{k}.PVPlant}.(PVPlants_Profile_Prediction)(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods));
    else
        CostsPV(:,1,VarCounter)=10000*ones(ControlPeriods,1); % Ensure never use PVPlant if there is non. Also ensured by PowerCons as PVPower is constantly zero
    end
    
    CostsReserveMarket(1:ControlPeriods, 1, VarCounter)=((Users{k}.PrivateElectricityPrice + Users{k}.NNEEnergyPrice)/100 - AEOfferPrices)*1.19 - RLOfferPrices/16;
    
end

% if any(MaxEnergyChargableSoCTS(:)<-3)
%     error("Error calculating MaxEnergyChargableSoCTS. Negative values found")
% else
%     MaxEnergyChargableSoCTS=max(0,MaxEnergyChargableSoCTS);
% end


%% Aggregate Costs

Costs=[CostsSpotmarket, CostsPV, CostsReserveMarket];
Costs=Costs(:,CostCats,:);