%% Calc Optimisation Variables

CalcOptVars;
SplitDecissionGroups;
%ConsMatchLastReservePowerOffers4Hbeq=temp1;

%% Calc Cost function and Constraints

Costs=Costs(:);

SumPower=MaxPower/4.*Availability;
ConsbSumPowerTS=SumPower(:);

PowerTS=repelem(MaxPower/4,ControlPeriods,NumCostCats,1);
PowerTS(:,2,:)=min([PowerTS(:,2,:), PVPower/4], [], 2);
ConsbPowerTS=PowerTS(:);

ConsbMaxEnergyChargableSoCTS=MaxEnergyChargableSoCTS(:);

ConsbMinEnergyRequiredTS=MinEnergyRequiredTS(:);

ConsbeqMaxEnergyChargableDeadlockCP=MaxEnergyChargableDeadlockCP(:);


%%

% b=[ConsbSumPowerTS; ConsbMaxEnergyChargableSoCTS; -ConsbMinEnergyRequiredTS];
% A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
% 
% beq=[ConsbeqMaxEnergyChargableDeadlockCP; ConsRLOfferbeq; ConsMatchLastReservePowerOffers4Hbeq];
% Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq; ConsMatchLastReservePowerOffers4HAeq];
% 
% lb=zeros(ControlPeriods, NumCostCats, NumUsers);
% ub=ConsbPowerTS(:);
% % ub=[];
% 
% Costf=Costs;




% A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
% b=[ConsbSumPowerTS; ConsbMaxEnergyChargableSoCTS; -ConsbMinEnergyRequiredTS];
% 
% beq=[ConsbeqMaxEnergyChargableDeadlockCP; ConsRLOfferbeq; ConsMatchLastReservePowerOffers4Hbeq];
% Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq; ConsMatchLastReservePowerOffers4HAeq];



%% Calc optimal charging powers

tic
if UseParallel
    
    ConsbSumPowerTS=ConsbSumPowerTS';
    ConsbMaxEnergyChargableSoCTS=ConsbMaxEnergyChargableSoCTS';
    ConsbMinEnergyRequiredTS=ConsbMinEnergyRequiredTS';
    ConsbeqMaxEnergyChargableDeadlockCP=ConsbeqMaxEnergyChargableDeadlockCP';
    ConsbPowerTS=ConsbPowerTS';
    Costs=Costs';

    x1=cell(NumDecissionGroups,1);
    lb=zeros(ControlPeriods, NumCostCats, NumUsers/NumDecissionGroups);

    parfor k=1:NumDecissionGroups
        b=[ConsbSumPowerTS(DecissionGroups{k,2}); ConsbMaxEnergyChargableSoCTS(DecissionGroups{k,2}); -ConsbMinEnergyRequiredTS(DecissionGroups{k,2})]';
        beq=[ConsbeqMaxEnergyChargableDeadlockCP(DecissionGroups{k,1})'; ConsRLOfferbeq; DecissionGroups{k,4}]'; %% this is wrong as ConsMatchLastReservePowerOffers4Hbeq must be constant in sum
        ub=ConsbPowerTS(DecissionGroups{k,3})';
        Costf=Costs(DecissionGroups{k,3})';
        [x11,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
        x11(x11<0)=0;
        x1{k}=x11;
    end
    
    x=[];
    BackwardsOrder=[];
    for k=1:NumDecissionGroups
        x=[x; x1{k}];
        BackwardsOrder=[BackwardsOrder; DecissionGroups{k,1}];
    end
    [~, BackwardsOrder]=sort(BackwardsOrder, 'ascend');
    x=reshape(x,ControlPeriods,NumCostCats,NumUsers);
    x=x(:,:,BackwardsOrder);
    x=x(:);
else
	b=[ConsbSumPowerTS; ConsbMaxEnergyChargableSoCTS; -ConsbMinEnergyRequiredTS];
    A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];

    beq=[ConsbeqMaxEnergyChargableDeadlockCP; ConsRLOfferbeq; ConsMatchLastReservePowerOffers4Hbeq];
    Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq; ConsMatchLastReservePowerOffers4HAeq];

    lb=zeros(ControlPeriods, NumCostCats, NumUsers);
    ub=ConsbPowerTS(:);

    Costf=Costs;
    
    [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
    x(x<0)=0;   
end
tc1=tc1+toc;


% b=[ConsbSumPowerTS; ConsbMaxEnergyChargableSoCTS; -ConsbMinEnergyRequiredTS];
% A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
% 
% beq=[ConsbeqMaxEnergyChargableDeadlockCP; ConsRLOfferbeq; ConsMatchLastReservePowerOffers4Hbeq];
% Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq; ConsMatchLastReservePowerOffers4HAeq];
% 
% lb=zeros(ControlPeriods, NumCostCats, NumUsers);
% ub=ConsbPowerTS(:);
% ub=[];

% tic
% for n=1:4
%     [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
%     x(x<0)=0; % Due to the accuracy of the algorithm, sometimes values lower than zero appear. But they are so close to zero (e. g. 1e-12) that it does not influence the result
% end
% tc=tc+toc;


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