%% Description
% This script updates the variables needed to solve the optimisation
% problem for algorithm 1 (PreAlgo). Only variables that change each
% optimisation iteration are calculated in this script. Variables that
% change only once per optimisation period (at 8:00) are updated in
% CalcConsOptVars.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   Simulation              This script is called by Simulation.m
%   PreAlgo                 This script is necessary for PreAlgo.m
%   CalcAvailability        This script calls CalcAvailability.m
%
% General structure of the optimisation variables:
% The variables are three dimensional. First dimension represents the time
% steps, second dimension represents the three electricity sources and the
% third dimension represents the users.



%% Initialisation and calculation of auxilliary variables

% Calculate the times when vehicles are expected to be available for 
% charging and store it in the variable Availability. In case of 
% charging availability, the variable is 1, in case of no availability the
% variable is 0. If the DSO reduces the charging power by 50%, the variable
% is 0.5.
CalcAvailability;

if ~UseParallelAvailability
    CalcLogbooks12;
end
    
Logbooks4=zeros(ControlPeriodsIt,1,NumUsers); % Consumed energy through driving of all users in Wh
SoCInit=zeros(1,1,NumUsers); % State of charge at the beginning of the optimisation period of all users
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    Logbooks4(:,1,VarCounter)=double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,4));
    SoCInit(1,1,VarCounter)=double(Users{k}.Logbook(TimeInd+TD.User,9));
end

SoC=SoCInit - cumsum([zeros(1,1,NumUsers);Logbooks4(1+1:end,1,:)],1); % SoC of all users at each time step if no energy would be charged by driving consumption would be considered


%% Calculation of the optimisation variabless

% The maximal energy that can be charged in sum of all three electricity
% sources. It is determined by the maximal charging power of vehicle and
% charging point and the vehicles's availabilty. The "- 1" does not change
% much but increases stability as it avoids the exceeding of the battery
% capacity due to rounding errors.
SumPower=max(0, MaxPower/4.*Availability - 1);

% The maximal energy that can be charged until the respective time step. It
% equals the difference between the battery capacity and the energy that is
% expected to be in the battery at the respective time step. The algorithm
% is not allowed to exceed this limit because else the battery capacity
% would be exceeded.
MaxEnergyChargableSoCTS=BatterySizes - SoC;

% The maximal amount of energy inside the battery if from
% the beginning of the optimisation period on each possibility is used to
% charge the technical maximal energy at the private charging point.
% Hence it represents the charging strategy: Charge as fast as full as 
% possible. This is a auxillary variabke to calculate MinEnergyRequiredTS
% and MaxEnergyChargableDeadlockCP.
MaxPossibleSoCTS=zeros(ControlPeriodsIt,1,NumUsers);
MaxPossibleSoCTS(1,1,:)=min(BatterySizes, SoC(1,1,:)+SumPower(1,1,:));
for VarCounter=1:NumUsers
    for p=2:ControlPeriodsIt
        MaxPossibleSoCTS(p,1,VarCounter)=min(BatterySizes(1,1,VarCounter), MaxPossibleSoCTS(p-1,1,VarCounter) - Logbooks4(p,1,VarCounter) + SumPower(p,1,VarCounter));
    end
end

% The minimal amount of energy that must have been charged until a time
% step in order to avoid the SoC to fall below the 
% PublicChargingThresholds_Wh. To avoid to demand more energy than can be
% technically charged, the minimum with MaxPossibleSoCTS is calculated. The
% algorithm is not allowed to charge less energy than MinEnergyRequiredTS.
MinEnergyRequiredTS=min([PublicChargingThresholds_Wh(1:ControlPeriodsIt,:,:), MaxPossibleSoCTS], [], 2) - SoC;

% The maximal energy that is chargable without exceeding the battery
% such that the battery is as full as possible at the end of the
% ControlPeriod

% The maximal amount of energy that is technically chargable during one
% optimisation period. The algorithm is not allowed to charge less energy
% during one optimisation period than MaxEnergyChargableDeadlockCP.
MaxEnergyChargableDeadlockCP=MaxPossibleSoCTS(end,1,:) - SoC(end,1,:);
    

% The maximal amount of energy that can be charged due to technical
% constraints like the maximal charging power of the vehicle and the
% chargeing point. No source is allowed to exceed this technical maximum
% (and also their sum is not allowed to do so, c.f. SumPower). This is the
% upper bound of the optimisation variable. Though SumPower limits the 
% charging power too, this variable must be defined because it increases
% the performance and it limits the demand of pv power to the predicted 
% power of the pv plant. Only for the current time step 1, the real pv
% power is known an can be used rather than the prediction.
PowerTS=repelem(MaxPower/4,ControlPeriodsIt,length(CostCats),1);
PowerTS(:,2,:)=min([PowerTS(:,2,:), PVPower(end-ControlPeriodsIt+1:end,:,:)/4], [], 2);
PowerTS(1,2,:)=min(MaxPower/4, PVPowerReal(ControlPeriods-ControlPeriodsIt+1,1,:)/4);

PowerTS=PowerTS.*double(CostCats);

