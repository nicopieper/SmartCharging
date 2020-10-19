%% Calc Optimisation Variables

CalcOptVars;
%ConsMatchLastReservePowerOffers4Hbeq=temp1;

%% Calc Cost function and Constraints

Costf=Costs(:);


SumPower=MaxPower/4.*Availability;
ConsbSumPowerTS=SumPower(:);

PowerTS=repelem(MaxPower/4,ControlPeriods,NumCostCats,1);
PowerTS(:,2,:)=min([PowerTS(:,2,:), PVPower/4], [], 2);
ConsbPowerTS=PowerTS(:);

ConsbMaxEnergyChargableSoCTS=MaxEnergyChargableSoCTS(:);

ConsbMinEnergyRequiredTS=MinEnergyRequiredTS(:);

ConsbeqMaxEnergyChargableDeadlockCP=MaxEnergyChargableDeadlockCP(:);


%%

b=[ConsbSumPowerTS; ConsbMaxEnergyChargableSoCTS; -ConsbMinEnergyRequiredTS];
% A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];

beq=[ConsbeqMaxEnergyChargableDeadlockCP; ConsRLOfferbeq; ConsMatchLastReservePowerOffers4Hbeq];
% Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq; ConsMatchLastReservePowerOffers4HAeq];

lb=zeros(ControlPeriods, NumCostCats, NumUsers);
ub=ConsbPowerTS(:);
% ub=[];


% A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
% b=[ConsbSumPowerTS; ConsbMaxEnergyChargableSoCTS; -ConsbMinEnergyRequiredTS];
% 
% beq=[ConsbeqMaxEnergyChargableDeadlockCP; ConsRLOfferbeq; ConsMatchLastReservePowerOffers4Hbeq];
% Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq; ConsMatchLastReservePowerOffers4HAeq];



%% Calc optimal charging powers

tic
for k=1:4
    [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
    x(x<0)=0; % Due to the accuracy of the algorithm, sometimes values lower than zero appear. But they are so close to zero (e. g. 1e-12) that it does not influence the result
end
tc=tc+toc;
tic
parfor k=1:4
    [x1,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
    x1(x1<0)=0; % Due to the accuracy of the algorithm, sometimes values lower than zero appear. But they are so close to zero (e. g. 1e-12) that it does not influence the result
end
tc1=tc1+toc;

%% Evaluate result

OptimalChargingEnergies=reshape(x,ControlPeriods, NumCostCats, NumUsers);
PostPreAlgo;
OptimalChargingEnergies(:,1,:)=OptimalChargingEnergiesSpotmarket;

PreAlgoCounter=PreAlgoCounter+1;
ChargingMat(:,:,:,PreAlgoCounter)=OptimalChargingEnergies;
AvailabilityMat=[AvailabilityMat, Availability(1:96,1,:)];

ConsMatchLastReservePowerOffers4Hbeq=sum(squeeze(OptimalChargingEnergies(24*Time.StepInd+1:4*Time.StepInd:24*Time.StepInd+ConsPeriods*4*Time.StepInd,3,:)), 2);
temp1=ConsMatchLastReservePowerOffers4Hbeq;


% if round(sum(x))<round(ConsMinEnergyToChargeCPbeq)
%     1
% end

% if sum(reshape(x,ControlPeriods, NumCostCats, NumUsers)>0 & Availability==0)>1
%     error("Availability was not considered")
% end