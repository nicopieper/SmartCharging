%% Calc Optimisation Variables

CalcOptVars;
OptPeriods=ControlPeriods-mod(TimeInd-TimesOfPreAlgo(1)-1, ControlPeriods);


if hour(TimeOfPreAlgo1)==hour(Time.Sim.Vec(TimeInd))
    CostsSpotmarket=(CostsSpotmarketBase + SpotmarketPricesPred1(TimeInd+TD.SpotmarketPricesPred1:TimeInd+TD.SpotmarketPricesPred1-1+ControlPeriods)/10)/100*1.19;
    SplitDecissionGroups;
elseif hour(TimeOfPreAlgo2)==hour(Time-Sim.Vec(TimeInd))
    CostsSpotmarket=(CostsSpotmarketBase + SpotmarketPricesPred1(TimeInd+TD.SpotmarketPricesPred1:TimeInd+TD.SpotmarketPricesPred2-1+ControlPeriods)/10)/100*1.19;
end


% else
%     SuccessfulRLOffers=RLOfferdPrices(1:4*Time.StepInd:end)<=ResPoPricesReal4H(floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1:floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1+ControlPeriods/(4*Time.StepInd),3)/1000;
%     ConsMatchLastReservePowerOffers4Hbeq=sum(squeeze(OptimalChargingEnergies((hour(TimeOfPreAlgo2)-hour(TimeOfPreAlgo1))*Time.StepInd+1:4*Time.StepInd:24*Time.StepInd+ConsPeriods*4*Time.StepInd,3,:)), 2);
%     
%     % Complete ConsMatchLastReservePowerOffers4Hbeq. dazugehöriges Aeq muss
%     % für Algo2 entsprechend verlängert werden --> Neudefinition
% end    
    
    
    
    
    
%ConsMatchLastReservePowerOffers4Hbeq=temp1;


%% Calc Cost function and Constraints

Costs=[CostsSpotmarket, CostsPV, CostsReserveMarket];
Costs=Costs(:);

SumPower=MaxPower/4.*Availability;
ConsbSumPowerTS=reshape(SumPower(end-OptPeriods+1:end), [], 1);

PowerTS=repelem(MaxPower/4,ControlPeriods,NumCostCats,1);
PowerTS(:,2,:)=min([PowerTS(:,2,:), PVPower/4], [], 2);
ConsbPowerTS=reshape(PowerTS(end-OptPeriods+1:end), [], 1);

ConsbMaxEnergyChargableSoCTS=reshape(MaxEnergyChargableSoCTS(end-OptPeriods+1:end), [], 1);

ConsbMinEnergyRequiredTS=reshape(MinEnergyRequiredTS(end-OptPeriods+1:end), [], 1);

ConsbeqMaxEnergyChargableDeadlockCP=reshape(MaxEnergyChargableDeadlockCP(end-OptPeriods+1:end), [], 1);


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
    beq=[ConsbeqMaxEnergyChargableDeadlockCP; ConsRLOfferbeq; ConsMatchLastReservePowerOffers4Hbeq];

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