%% Availability, EnergyDemand and Prices

VarCounter=0;
Availability=zeros(ControlPeriodsIt,1,NumUsers);
MaxEnergyChargableSoCTS=zeros(ControlPeriodsIt,1,NumUsers);
MaxEnergyChargableDeadlockCP=zeros(1,1,NumUsers);
MinEnergyRequiredTS=zeros(ControlPeriodsIt,1,NumUsers);

for k=UserNum
    VarCounter=VarCounter+1;
    
    Availability(:,1,VarCounter)=(max(0, double(ismember(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,1), 3:5)) - double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,2))/Time.StepMin)) .* Users{k}.GridConvenientChargingAvailabilityControlPeriod(end-ControlPeriodsIt+1:end);
    
    Consumed=Users{k}.Logbook(TimeInd+TD.User+1:TimeInd+TD.User+ControlPeriodsIt-1,4);
    SoC=Users{k}.Logbook(TimeInd+TD.User,9) - [0;cumsum(Consumed)]; % in Wh
    
    % The maximal energy that is charagble without exceeding the battery
    % limit in every time step
    
    MaxEnergyChargableSoCTS(:,1,VarCounter)=Users{k}.BatterySize - SoC ;
        
       
    % The maximal energy that is chargable without exceeding the battery
    % such that the battery is as full as possible at the end of the
    % ControlPeriod
    
    MaxEnergyChargableDeadlockTS=zeros(ControlPeriodsIt,1);
    ChargingInds=find(Availability(:,1,VarCounter)>0);
    
    if ~isempty(ChargingInds)
        SoCNew=SoC;
        l=0;
        while l<length(ChargingInds) && max(SoCNew(ChargingInds(end-l):end))<Users{k}.BatterySize 
            MaxEnergyChargableDeadlockTS(ChargingInds(end-l),1)=min(Availability(ChargingInds(end-l),1,VarCounter)*MaxPower(1,1,VarCounter)/4, Users{k}.BatterySize-max(SoCNew(ChargingInds(end-l):end)));
            SoCNew=SoC+[0;cumsum(MaxEnergyChargableDeadlockTS(2:end,1))];
            l=l+1;
        end
        
        MaxEnergyChargableDeadlockCP(1,1,VarCounter)=sum(MaxEnergyChargableDeadlockTS);
    else % Availability completly zero
        MaxEnergyChargableDeadlockCP(1,1,VarCounter)=0;
    end
    
    % Wie viel Energie muss ich mindestens laden, damit mein SoC nicht
    % unter den PublicCharging-Schwellwert fallen wird?
    % Wird nach der Schleife noch verkleinert!
   
    MinEnergyRequiredTS(:,1,VarCounter)=round(Users{k}.PublicChargingThreshold_Wh*0.3) - SoC;
    
end

SumPower=MaxPower/4.*Availability;

PowerTS=repelem(MaxPower/4,ControlPeriodsIt,NumCostCats,1);
PowerTS(:,2,:)=min([PowerTS(:,2,:), PVPower(end-ControlPeriodsIt+1:end,:,:)/4], [], 2);
ConsPowerTSb=PowerTS;

MinEnergyRequiredTS=min(min([MinEnergyRequiredTS, MaxEnergyChargableSoCTS, SumPower], [], 2), MaxEnergyChargableDeadlockCP);

