%% Calc Optimisation Variables

CalcOptVars;

%% Calc Cost function and Constraints

Costf=Costs(:);

ConsSumPowerb=repelem(MaxPower(:)/4, ControlPeriods);
ConsPowerb=[reshape(repelem(MaxPower(:)/4, ControlPeriods), ControlPeriods, 1, []), PVPower/4, reshape(repelem(MaxPower(:)/4, ControlPeriods), ControlPeriods, 1, [])];
ConsPowerb=ConsPowerb(:,CostCats,:);
ConsPowerb=ConsPowerb(:);
ConsEnergybeq=squeeze(min(EnergyDemand, sum(Availability, 1).*MaxPower/4));

A=[ConsSumPowerA];% ConsPowerA];
b=[ConsSumPowerb(:)];% ConsPowerb];
Aeq=[ConsEnergyAeq;ConsRLOfferAeq];
beq=[ConsEnergybeq;ConsRLOfferbeq];
lb=zeros(ControlPeriods, NumCostCats, NumUsers);
ub=ConsPowerb;

%% Calc optimal charging powers

[x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);

%% Evaluate result

ChargingMat(:,:,:,end+1)=reshape(x,ControlPeriods, NumCostCats, NumUsers);
ChargingVehicle=[ChargingVehicle; sum(ChargingMat(1:96,:,:,end),2)];
ChargingType=[ChargingType; sum(ChargingMat(1:96,:,:,end),3)];
AvailabilityMat=[AvailabilityMat, Availability(1:96,1,:)];

if sum(x)<ConsEnergybeq
    1
end

if sum(reshape(x,ControlPeriods, NumCostCats, NumUsers)>0 & Availability==0)>1
    error("Availability was not considered")
end