%% Calc Optimisation Variables

CalcOptVars;
%ConsMatchLastReservePowerOffers4Hbeq=temp1;

%% Calc Cost function and Constraints

Costf=Costs(:);

ConsSumPowerTSb=repelem(MaxPower(:)/4, ControlPeriods);
ConsPowerTSb=ones(ControlPeriods, 3, NumUsers).*MaxPower/4.*Availability;
ConsPowerTSb(:,2,:)=min([ConsPowerTSb(:,2,:), PVPower/4], [], 2);
ConsPowerTSb=ConsPowerTSb(:,CostCats,:);

ConsMinEnergyToChargeCPbeq=MinEnergyChargableDeadlockCP(:);
SummedMaxEnergyChargeable=[];
for k=1:NumUsers
    Temp=[Availability(:,:,k); 0]';
    SummedMaxEnergyChargeable(:,1,k)=sum(Temp(DemandInds),2);
end

% ConsMinEnergyRequiredToChargeTSb=min([MinEnergyRequiredToChargeTS(:), SummedMaxEnergyChargeable(:)], [], 2); %% !!
ConsMinEnergyRequiredToChargeTSb=min([MinEnergyRequiredToChargeTS(:), MinEnergyChargableDeadlockTS(:)], [], 2);
ConsMaxEnergyChargableTSb=MaxEnergyChargableSoCTS(:);

%%

% A=[ ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
% Aeq=[];
% lb=zeros(ControlPeriods, NumCostCats, NumUsers);
% 
% b=[ ConsMaxEnergyChargableTSb; -ConsMinEnergyRequiredToChargeTSb];
% beq=[];
% ub=ConsPowerTSb(:);



A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq;ConsMatchLastReservePowerOffers4HAeq];
lb=zeros(ControlPeriods, NumCostCats, NumUsers);

b=[ConsSumPowerTSb(:); ConsMaxEnergyChargableTSb; -ConsMinEnergyRequiredToChargeTSb];
beq=[ConsMinEnergyToChargeCPbeq; ConsRLOfferbeq; ConsMatchLastReservePowerOffers4Hbeq];
ub=ConsPowerTSb(:);



% A=[ConsSumPowerA; ConsEnergyDemandA; -ConsEnergyDemandA];
% Aeq=[ConsEnergyAeq; ConsRLOfferAeq;ConsMatchLastReservePowerOffersAeq];
% lb=zeros(ControlPeriods, NumCostCats, NumUsers);
% 
% b=[ConsSumPowerb(:); ConsMaxEnergyChargedb; -ConsMinEnergyRequiredToChargeOneDayb];
% beq=[ConsEnergybeq; ConsRLOfferbeq; ConsMatchLastReservePowerOffers4Hbeq];
% ub=ConsPowerb(:);

%% Calc optimal charging powers

[x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);

%% Evaluate result

OptimalChargingEnergies=reshape(x,ControlPeriods, NumCostCats, NumUsers);
PostPreAlgo;
OptimalChargingEnergies(:,1,:)=OptimalChargingEnergiesSpotmarket;

PreAlgoCounter=PreAlgoCounter+1;
ChargingMat(:,:,:,PreAlgoCounter)=OptimalChargingEnergies;
AvailabilityMat=[AvailabilityMat, Availability(1:96,1,:)];

ConsMatchLastReservePowerOffers4Hbeq=sum(squeeze(OptimalChargingEnergies(24*Time.StepInd+1:4*Time.StepInd:24*Time.StepInd+ConsPeriods*4*Time.StepInd,3,:)), 2);
temp1=ConsMatchLastReservePowerOffers4Hbeq;


if round(sum(x))<round(ConsMinEnergyToChargeCPbeq)
    1
end

if sum(reshape(x,ControlPeriods, NumCostCats, NumUsers)>0 & Availability==0)>1
    error("Availability was not considered")
end