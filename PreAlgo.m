%% Calc Optimisation Variables

CalcOptVars;

%% Calc Cost function and Constraints

Costf=Costs(:);

ConsSumPowerb=repelem(MaxPower(:)/4, ControlPeriods);
ConsPowerb=[reshape(repelem(MaxPower(:)/4, ControlPeriods), ControlPeriods, 1, []), PVPower/4, reshape(repelem(MaxPower(:)/4, ControlPeriods), ControlPeriods, 1, [])] .*Availability;
ConsPowerb=ConsPowerb(:,CostCats,:);
ConsPowerb=ConsPowerb(:);
ConsEnergybeq=squeeze(min(EnergyDemandControlPeriod, sum(Availability, 1).*MaxPower/4));
ConsEnergyDemandEssentialOneDayb=EnergyDemandEssentialOneDay(:);
ConsMaxEnergyChargedb=MaxEnergyCharged(:);

A=[ConsSumPowerA; ConsEnergyDemandA; -ConsEnergyDemandA];% ConsPowerA];
b=[ConsSumPowerb(:); ConsMaxEnergyChargedb; -ConsEnergyDemandEssentialOneDayb];% ConsPowerb];

Aeq=[ConsEnergyAeq; ConsRLOfferAeq;ConsMatchLastReservePowerOffersAeq];
beq=[ConsEnergybeq; ConsRLOfferbeq;ConsMatchLastReservePowerOffersbeq];

lb=zeros(ControlPeriods, NumCostCats, NumUsers);
ub=ConsPowerb;

%% Calc optimal charging powers

[x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);

%% Evaluate result

OptimalChargingEnergies=reshape(x,ControlPeriods, NumCostCats, NumUsers);
ChargingMat(:,:,:,end+1)=OptimalChargingEnergies;
ChargingVehicle=[ChargingVehicle; sum(ChargingMat(1:96,:,:,end),2)];
ChargingType=[ChargingType; sum(ChargingMat(1:96,:,:,end),3)];
AvailabilityMat=[AvailabilityMat, Availability(1:96,1,:)];
% ConsMatchLastReservePowerOffersbeq=sum(squeeze(OptimalChargingEnergies(1:4*Time.StepInd:24*Time.StepInd-ShiftInds,3,:)), 2);
ConsMatchLastReservePowerOffersbeq=sum(squeeze(OptimalChargingEnergies(24*Time.StepInd:4*Time.StepInd:24*Time.StepInd+ConsPeriods*4*Time.StepInd-1,3,:)), 2);

if sum(x)<ConsEnergybeq
    1
end

if sum(reshape(x,ControlPeriods, NumCostCats, NumUsers)>0 & Availability==0)>1
    error("Availability was not considered")
end