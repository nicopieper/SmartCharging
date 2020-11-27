%% Calc Optimisation Variables

SplitDecissionGroups;
%ConseqMatchLastReservePowerOffers4Hb=temp1;

%% Update Costs

CostsSpotmarket=(CostsElectricityBase/100 + SpotmarktPricesCP/1000)*1.19;
CostsReserveMarket=(CostsElectricityBase/100 - AEOfferPrices)*1.19 - RLOfferPrices/16;

Costs=[CostsSpotmarket, CostsPV, CostsReserveMarket];
Costs=Costs(:,CostCats,:);
Costs=Costs(:);

%% Define Cost function and Constraints

ConsSumPowerTSb=SumPower(:);

ConsMaxEnergyChargableSoCTSb=MaxEnergyChargableSoCTS(:);

ConsMinEnergyRequiredTSb=MinEnergyRequiredTS(:);

ConseqMaxEnergyChargableDeadlockCPb=MaxEnergyChargableDeadlockCP(:);


ConsSumPowerTSAIt=ConsSumPowerTSA;
ConsEnergyDemandTSAIt=ConsEnergyDemandTSA;
ConseqEnergyCPAIt=ConseqEnergyCPA;
ConseqRLOfferAIt=ConseqRLOfferA;

ConseqRLOfferb=zeros((ConstantRLPowerPeriods-1)*ControlPeriodsIt/ConstantRLPowerPeriods,1);

DelCols2=(1:(ControlPeriods-ControlPeriodsIt))'+(0:NumUsers*NumCostCats-1)*ControlPeriods;
DelCols2=DelCols2(:);

ActiveReservePowerIndices=(floor(floor(mod(TimeInd-1, 24*Time.StepInd)/Time.StepInd)/4):5)+1 + (mod(TimeInd-1, (24*Time.StepInd))<=32)*6 - 2;
if hour(Time.Sim.Vec(TimeInd))+minute(Time.Sim.Vec(TimeInd))>hour(TimeOfPreAlgo1)
    ActiveReservePowerIndices=[ActiveReservePowerIndices, 5:10];
end
ActiveReservePowerIndices=((ActiveReservePowerIndices(1):1/(4*Time.StepInd/ConstantRLPowerPeriods):ActiveReservePowerIndices(end)+1-1/(4*Time.StepInd/ConstantRLPowerPeriods))-1)*4*Time.StepInd/ConstantRLPowerPeriods+1;

ConseqMatchLastReservePowerOffers4HbIt=LastReservePowerOffers4Hb(ActiveReservePowerIndices, PreAlgoCounter+1);
ConseqMatchLastReservePowerOffers4HAIt=ConseqMatchLastReservePowerOffers4HA(1:length(ActiveReservePowerIndices),:);
ConseqMatchLastReservePowerOffers4HAIt(:,DelCols2)=[];

if ControlPeriodsIt<ControlPeriods
    DelRows=(ControlPeriodsIt+1:ControlPeriods)'+(0:NumUsers-1)*ControlPeriods;
    DelRows=DelRows(:);
    DelCols=(ControlPeriodsIt+1:ControlPeriods)'+(0:NumUsers*NumCostCats-1)*ControlPeriods;
    DelCols=DelCols(:);
    
    ConsSumPowerTSAIt(DelRows,:)=[];
    ConsSumPowerTSAIt(:,DelCols)=[];
    
    ConsEnergyDemandTSAIt(DelRows,:)=[];
    ConsEnergyDemandTSAIt(:,DelCols)=[];

    ConseqEnergyCPAIt(:,DelCols)=[];
    
    DelRows2=1:(ControlPeriods-ControlPeriodsIt - (floor((ControlPeriods-ControlPeriodsIt)/(4*Time.StepInd))));
    
    ConseqRLOfferAIt(DelRows2,:)=[];
    ConseqRLOfferAIt(:,DelCols2)=[];
    
    Costs(DelCols2)=[];
end


%%

% b=[ConsSumPowerTSb; ConsMaxEnergyChargableSoCTSb; -ConsMinEnergyRequiredTSb];
% A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
% 
% beq=[ConseqMaxEnergyChargableDeadlockCPb; ConseqRLOfferb; ConseqMatchLastReservePowerOffers4Hb];
% Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq; ConsMatchLastReservePowerOffers4HAeq];
% 
% lb=zeros(ControlPeriods, NumCostCats, NumUsers);
% ub=ConsPowerTSb(:);
% % ub=[];
% 
% Costf=Costs;




% A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
% b=[ConsSumPowerTSb; ConsMaxEnergyChargableSoCTSb; -ConsMinEnergyRequiredTSb];
% 
% beq=[ConseqMaxEnergyChargableDeadlockCPb; ConseqRLOfferb; ConseqMatchLastReservePowerOffers4Hb];
% Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq; ConsMatchLastReservePowerOffers4HAeq];



%% Calc optimal charging powers

tic
if UseParallel
    
    ConsSumPowerTSb=ConsSumPowerTSb';
    ConsMaxEnergyChargableSoCTSb=ConsMaxEnergyChargableSoCTSb';
    ConsMinEnergyRequiredTSb=ConsMinEnergyRequiredTSb';
    ConseqMaxEnergyChargableDeadlockCPb=ConseqMaxEnergyChargableDeadlockCPb';
    ConsPowerTSb=ConsPowerTSb';
    Costs=Costs';

    x1=cell(NumDecissionGroups,1);
    lb=zeros(ControlPeriods, NumCostCats, NumUsers/NumDecissionGroups);

    parfor k=1:NumDecissionGroups
        b=[ConsSumPowerTSb(DecissionGroups{k,2}); ConsMaxEnergyChargableSoCTSb(DecissionGroups{k,2}); -ConsMinEnergyRequiredTSb(DecissionGroups{k,2})]';
        beq=[ConseqMaxEnergyChargableDeadlockCPb(DecissionGroups{k,1})'; ConseqRLOfferb; DecissionGroups{k,4}]'; %% this is wrong as ConseqMatchLastReservePowerOffers4Hb must be constant in sum
        ub=ConsPowerTSb(DecissionGroups{k,3})';
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

    b=[ConsSumPowerTSb; ConsMaxEnergyChargableSoCTSb; -ConsMinEnergyRequiredTSb];
    A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];

    beq=[ConseqMaxEnergyChargableDeadlockCPb; ConseqRLOfferb; ConseqMatchLastReservePowerOffers4HbIt];
    Aeq=[ConseqEnergyCPAIt; ConseqRLOfferAIt; ConseqMatchLastReservePowerOffers4HAIt];

    lb=zeros(ControlPeriodsIt, NumCostCats, NumUsers);
    ub=ConsPowerTSb(:);

    Costf=Costs;
    
    [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
    x(x<0)=0;   
end
tc1=tc1+toc;


% b=[ConsSumPowerTSb; ConsMaxEnergyChargableSoCTSb; -ConsMinEnergyRequiredTSb];
% A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
% 
% beq=[ConseqMaxEnergyChargableDeadlockCPb; ConseqRLOfferb; ConseqMatchLastReservePowerOffers4Hb];
% Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq; ConsMatchLastReservePowerOffers4HAeq];
% 
% lb=zeros(ControlPeriods, NumCostCats, NumUsers);
% ub=ConsPowerTSb(:);
% ub=[];

% tic
% for n=1:4
%     [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
%     x(x<0)=0; % Due to the accuracy of the algorithm, sometimes values lower than zero appear. But they are so close to zero (e. g. 1e-12) that it does not influence the result
% end
% tc=tc+toc;


%% Evaluate result
OptimalChargingEnergies=reshape(x,ControlPeriodsIt, NumCostCats, NumUsers);
PostPreAlgo;
OptimalChargingEnergies(:,1,:)=OptimalChargingEnergiesSpotmarket;

if ismember(TimeInd, TimesOfPreAlgo(1,:))
    PreAlgoCounter=PreAlgoCounter+1;
    ChargingMat(:,:,:,PreAlgoCounter)=OptimalChargingEnergies;
    AvailabilityMat=[AvailabilityMat, Availability(1:96,1,:)];
    LastReservePowerOffers4Hb(:,PreAlgoCounter+1)=sum(OptimalChargingEnergies(1:ConstantRLPowerPeriods:end,3,:), 3);
end

%ConseqMatchLastReservePowerOffers4Hb=sum(squeeze(OptimalChargingEnergies(24*Time.StepInd+1:4*Time.StepInd:24*Time.StepInd+ConsPeriods*4*Time.StepInd,3,:)), 2);
%temp1=ConseqMatchLastReservePowerOffers4Hb;


% if round(sum(x))<round(ConsMinEnergyToChargeCPbeq)
%     1
% end

% if sum(reshape(x,ControlPeriods, NumCostCats, NumUsers)>0 & Availability==0)>1
%     error("Availability was not considered")
% end