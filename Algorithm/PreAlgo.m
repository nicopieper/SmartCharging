%% Calc Optimisation Variables

CalcOptVars;

%% Calc Cost function and Constraints

Costf=Costs(:);

ConsSumPowerb=repelem(MaxPower(:)/4, ControlPeriods);
ConsPowerb=[reshape(repelem(MaxPower(:)/4, ControlPeriods), ControlPeriods, 1, []), PVPower/4, reshape(repelem(MaxPower(:)/4, ControlPeriods), ControlPeriods, 1, [])] .*Availability;
ConsPowerb=ConsPowerb(:,CostCats,:);

ConsEnergybeq=squeeze(min(EnergyDemandControlPeriod, sum(Availability, 1).*MaxPower/4));
ConsEnergyDemandEssentialOneDayb=EnergyDemandEssentialOneDay(:);
ConsMaxEnergyChargedb=MaxEnergyCharged(:);

b=[ConsSumPowerb(:); ConsMaxEnergyChargedb; -ConsEnergyDemandEssentialOneDayb];
beq=[ConsEnergybeq; ConsRLOfferbeq;ConsMatchLastReservePowerOffersbeq];
ub=ConsPowerb(:);

%% Calc optimal charging powers

[x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);

%% Evaluate result

OptimalChargingEnergies=reshape(x,ControlPeriods, NumCostCats, NumUsers);
PostPreAlgo;
OptimalChargingEnergies(:,1,:)=OptimalChargingEnergiesSpotmarket;

PreAlgoCounter=PreAlgoCounter+1;
ChargingMat(:,:,:,PreAlgoCounter)=OptimalChargingEnergies;
AvailabilityMat=[AvailabilityMat, Availability(1:96,1,:)];

ConsMatchLastReservePowerOffersbeq=sum(squeeze(OptimalChargingEnergies(24*Time.StepInd:4*Time.StepInd:24*Time.StepInd+ConsPeriods*4*Time.StepInd-1,3,:)), 2);

if sum(x)<ConsEnergybeq
    1
end

if sum(reshape(x,ControlPeriods, NumCostCats, NumUsers)>0 & Availability==0)>1
    error("Availability was not considered")
end