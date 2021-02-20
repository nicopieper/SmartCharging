%% Availability, EnergyDemand and Prices

CalcAvailability;

MaxEnergyChargableSoCTS=zeros(ControlPeriodsIt,1,NumUsers);
MaxEnergyChargableDeadlockCP=zeros(1,1,NumUsers);
MinEnergyRequiredTS=zeros(ControlPeriodsIt,1,NumUsers);
SumPower=MaxPower/4.*Availability;

if ~UseParallelAvailability
    CalcLogbooks12;
end
    
Logbooks4=zeros(ControlPeriodsIt,1,NumUsers);
SoCInit=zeros(1,1,NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    Logbooks4(:,1,VarCounter)=double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,4));
    SoCInit(1,1,VarCounter)=double(Users{k}.Logbook(TimeInd+TD.User,9));
end

SoC=SoCInit - cumsum([zeros(1,1,NumUsers);Logbooks4(1+1:end,1,:)],1);

% The maximal energy that is charagble without exceeding the battery
% limit in every time step

MaxEnergyChargableSoCTS=BatterySizes - SoC;

% Wie viel Energie kann maximal in der Batterie sein zu jedem
% Zeitpunkt?

MaxPossibleSoCTS=zeros(ControlPeriodsIt,1,NumUsers);
MaxPossibleSoCTS(1,1,:)=min(BatterySizes, SoC(1,1,:)+SumPower(1,1,:));
tic
for VarCounter=1:NumUsers
    for p=2:ControlPeriodsIt
        MaxPossibleSoCTS(p,1,VarCounter)=min(BatterySizes(1,1,VarCounter), MaxPossibleSoCTS(p-1,1,VarCounter) - Logbooks4(p,1,VarCounter) + SumPower(p,1,VarCounter));
    end
end


% Wie viel Energie muss ich mindestens laden, damit mein SoC nicht
% unter den PublicCharging-Schwellwert fallen wird?
% Wird nach der Schleife noch verkleinert!

MinEnergyRequiredTS=min([PublicChargingThresholds_Wh(1:ControlPeriodsIt,:,:), MaxPossibleSoCTS], [], 2) - SoC;

% The maximal energy that is chargable without exceeding the battery
% such that the battery is as full as possible at the end of the
% ControlPeriod

MaxEnergyChargableDeadlockCP=MaxPossibleSoCTS(end,1,:) - SoC(end,1,:);
    

PowerTS=repelem(MaxPower/4,ControlPeriodsIt,NumCostCats,1);
PowerTS(:,2,:)=min([PowerTS(:,2,:), PVPower(end-ControlPeriodsIt+1:end,:,:)/4], [], 2);
PowerTS(1,2,:)=min(MaxPower/4, PVPowerReal(ControlPeriods-ControlPeriodsIt+1,1,:)/4);
ConsPowerTSb=PowerTS;
MinEnergyRequiredTS=min(MinEnergyRequiredTS,MaxEnergyChargableDeadlockCP);
