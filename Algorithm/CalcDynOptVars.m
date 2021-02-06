%% Availability, EnergyDemand and Prices

VarCounter=0;
Availability=zeros(ControlPeriodsIt,1,NumUsers);
SumPower=zeros(ControlPeriodsIt,1,NumUsers);
MaxEnergyChargableSoCTS=zeros(ControlPeriodsIt,1,NumUsers);
MaxEnergyChargableDeadlockCP=zeros(1,1,NumUsers);
MinEnergyRequiredTS=zeros(ControlPeriodsIt,1,NumUsers);
MaxPossibleSoCTS=zeros(ControlPeriodsIt,1,NumUsers);

for k=UserNum
    VarCounter=VarCounter+1;
    
    Availability(:,1,VarCounter)=max(0, ismember(double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,1)), 3:5) - double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,2))/Time.StepMin) .* double(Users{k}.GridConvenientChargingAvailabilityControlPeriod(end-ControlPeriodsIt+1:end));
    
    SumPower(:,1,VarCounter)=MaxPower(:,1,VarCounter)/4.*Availability(:,1,VarCounter);
    
    Consumed=double(Users{k}.Logbook(TimeInd+TD.User+1:TimeInd+TD.User+ControlPeriodsIt-1,4));
    
    SoC=double(Users{k}.Logbook(TimeInd+TD.User,9)) - [0;cumsum(Consumed)]; % in Wh
    if ~ismember(TimeInd, TimesOfPreAlgo)
        SoC=SoC + cumsum(sum(double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1,[false(1,4), CostCats])),2)); % in Wh
    end
    
    % The maximal energy that is charagble without exceeding the battery
    % limit in every time step
    
    MaxEnergyChargableSoCTS(:,1,VarCounter)=double(Users{k}.BatterySize) - SoC ;
        
       
    % The maximal energy that is chargable without exceeding the battery
    % such that the battery is as full as possible at the end of the
    % ControlPeriod
    
    MaxEnergyChargableDeadlockTS=zeros(ControlPeriodsIt,1);
    ChargingInds=find(Availability(:,1,VarCounter)>0);
    
    if ~isempty(ChargingInds)
        SoCNew=SoC;
        l=0;
        while l<length(ChargingInds) && max(SoCNew(ChargingInds(end-l):end))<double(Users{k}.BatterySize)
            MaxEnergyChargableDeadlockTS(ChargingInds(end-l),1)=min(Availability(ChargingInds(end-l),1,VarCounter)*MaxPower(1,1,VarCounter)/4, double(Users{k}.BatterySize)-max(SoCNew(ChargingInds(end-l):end)));
            SoCNew=SoC+[0;cumsum(MaxEnergyChargableDeadlockTS(2:end,1))];
            l=l+1;
        end
        
        MaxEnergyChargableDeadlockCP(1,1,VarCounter)=sum(MaxEnergyChargableDeadlockTS);
    else % Availability completly zero
        MaxEnergyChargableDeadlockCP(1,1,VarCounter)=0;
    end
    
    
    % Wie viel Energie kann maximal in der Batterie sein zu jedem
    % Zeitpunkt?
    
    MaxPossibleSoCTS=min(double(Users{k}.BatterySize), SoC(1)+SumPower(1,1,VarCounter));
    for p=2:ControlPeriodsIt
        MaxPossibleSoCTS(p)=min(double(Users{k}.BatterySize), MaxPossibleSoCTS(p-1)-Consumed(p-1)+SumPower(p,1,VarCounter));
    end
    
    
    % Wie viel Energie muss ich mindestens laden, damit mein SoC nicht
    % unter den PublicCharging-Schwellwert fallen wird?
    % Wird nach der Schleife noch verkleinert!
   
    %MinEnergyRequiredTS(:,1,VarCounter)=round(Users{k}.PublicChargingThreshold_Wh*0.3) - SoC;
    MinEnergyRequiredTS(:,1,VarCounter)=min(round(double(Users{k}.PublicChargingThreshold_Wh)*1.8), MaxPossibleSoCTS') - SoC;
    
end



PowerTS=repelem(MaxPower/4,ControlPeriodsIt,NumCostCats,1);
PowerTS(:,2,:)=min([PowerTS(:,2,:), PVPower(end-ControlPeriodsIt+1:end,:,:)/4], [], 2);
PowerTS(1,2,:)=min(MaxPower/4, PVPowerReal(ControlPeriods-ControlPeriodsIt+1,1,:)/4);
ConsPowerTSb=PowerTS;
MinEnergyRequiredTS=min(min([MinEnergyRequiredTS, MaxEnergyChargableSoCTS], [], 2), MaxEnergyChargableDeadlockCP);
