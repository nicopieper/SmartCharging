%% Update Costs

CostsSpotmarket=(CostsElectricityBase(end-ControlPeriodsIt+1:end,1,:)/100 + SpotmarktPricesCP/1000)*MwSt;
CostsReserveMarket=(CostsElectricityBase/100 - ResEnOfferPrices - ResPoOfferPrices/16)*MwSt;

if ismember(TimeInd, TimesOfPreAlgo(1,:))
%     C1(:,:,PreAlgoCounter)=CostsReserveMarket;
%     C2(:,PreAlgoCounter)=-ResEnOfferPrices;
%     C3(:,PreAlgoCounter)=-ResPoOfferPrices/16;
end

Costs=[CostsSpotmarket, CostsPV(end-ControlPeriodsIt+1:end,1,:), CostsReserveMarket(end-ControlPeriodsIt+1:end,1,:)];
Costs=Costs(:,CostCats,:);


%% Define Cost function, Constraints and DecissionGroups

ConsSumPowerTSbIt=SumPower(:);

ConsMaxEnergyChargableSoCTSbIt=MaxEnergyChargableSoCTS(:);

ConsMinEnergyRequiredTSbIt=MinEnergyRequiredTS(:);

ConseqMaxEnergyChargableDeadlockCPbIt=MaxEnergyChargableDeadlockCP(:);


ConsSumPowerTSAIt=ConsSumPowerTSA;
ConsEnergyDemandTSAIt=ConsEnergyDemandTSA;
ConseqEnergyCPAIt=ConseqEnergyCPA;
ConseqResPoOfferAIt=ConseqResPoOfferA;

ConseqResPoOfferbIt=zeros((ConstantResPoPowerPeriods-1)*ControlPeriodsIt/ConstantResPoPowerPeriods,1);

DelCols2=(1:(ControlPeriods-ControlPeriodsIt))'+(0:NumUsers/NumDecissionGroups*NumCostCats-1)*ControlPeriods;
DelCols2=DelCols2(:);

ResPoBlockedIndices=(floor(floor(mod(TimeInd-1, 24*Time.StepInd)/Time.StepInd)/4):5)+1 + (mod(TimeInd-1, (24*Time.StepInd))<=32)*6 - 2;
if hour(Time.Sim.Vec(TimeInd))+minute(Time.Sim.Vec(TimeInd))>hour(TimeOfPreAlgo1)
    ResPoBlockedIndices=[ResPoBlockedIndices, 5:10];
end
ResPoBlockedIndices=((ResPoBlockedIndices(1):1/(4*Time.StepInd/ConstantResPoPowerPeriods):ResPoBlockedIndices(end)+1-1/(4*Time.StepInd/ConstantResPoPowerPeriods))-1)*4*Time.StepInd/ConstantResPoPowerPeriods+1;

ConseqMatchLastResPoOffers4HbIt=LastResPoOffersSucessful4Hb(ResPoBlockedIndices, end);
ConseqMatchLastResPoOffers4HAIt=ConseqMatchLastResPoOffers4HA(1:length(ResPoBlockedIndices),:);
ConseqMatchLastResPoOffers4HAIt(:,repelem(ControlPeriods:ControlPeriods*2:ControlPeriods*NumUsers/NumDecissionGroups*NumCostCats*2,ControlPeriods-ControlPeriodsIt)'-DelCols2)=[];

% Sicherstellen, dass beide Variablen korrekt zugeschnitten werden, für beide oder
% alle Fälle.
% Nach Ursacher für Fehlermeldung suchen

if ControlPeriodsIt<ControlPeriods
    DelRows=(ControlPeriodsIt+1:ControlPeriods)'+(0:NumUsers/NumDecissionGroups-1)*ControlPeriods;
    DelRows=DelRows(:);
    DelCols=(ControlPeriodsIt+1:ControlPeriods)'+(0:NumUsers/NumDecissionGroups*NumCostCats-1)*ControlPeriods;
    DelCols=DelCols(:);
    
    ConsSumPowerTSAIt(DelRows,:)=[];
    ConsSumPowerTSAIt(:,DelCols)=[];
    
    ConsEnergyDemandTSAIt(DelRows,:)=[];
    ConsEnergyDemandTSAIt(:,DelCols)=[];

    ConseqEnergyCPAIt(:,DelCols)=[];
    
    DelRows2=1:(ControlPeriods-ControlPeriodsIt - (floor((ControlPeriods-ControlPeriodsIt)/(4*Time.StepInd))));
    
    ConseqResPoOfferAIt(DelRows2,:)=[];
    ConseqResPoOfferAIt(:,DelCols2)=[];
    
%     Costs(DelCols2)=[];
end

SplitDecissionGroups;


%%

% b=[ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt];
% A=[ConsSumPowerTSA; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
% 
% beq=[ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffersSucessful4Hb];
% Aeq=[ConsEnergyCPAeq; ConseqResPoOfferAIt; ConsMatchLastResPoOffers4HAeq];
% 
% lb=zeros(ControlPeriods, NumCostCats, NumUsers);
% ub=ConsPowerTSb(:);
% % ub=[];
% 
% Costf=Costs;




% A=[ConsSumPowerTSA; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
% b=[ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt];
% 
% beq=[ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffersSucessful4Hb];
% Aeq=[ConsEnergyCPAeq; ConseqResPoOfferAIt; ConsMatchLastResPoOffers4HAeq];



%% Calc optimal charging powers

tic
if UseParallel
    
    ConsSumPowerTSbIt=ConsSumPowerTSbIt';
    ConsMaxEnergyChargableSoCTSbIt=ConsMaxEnergyChargableSoCTSbIt';
    ConsMinEnergyRequiredTSbIt=ConsMinEnergyRequiredTSbIt';
    ConseqMaxEnergyChargableDeadlockCPbIt=ConseqMaxEnergyChargableDeadlockCPbIt';
    ConsPowerTSb=ConsPowerTSb';
    Costsf=Costs(:)';

    x1=cell(NumDecissionGroups,1);
    lb=zeros(ControlPeriodsIt, NumCostCats, NumUsers/NumDecissionGroups);

    parfor k=1:NumDecissionGroups
        b=[reshape(ConsSumPowerTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(ConsMaxEnergyChargableSoCTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(-ConsMinEnergyRequiredTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1)];
        A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
        
        beq=[ConseqMaxEnergyChargableDeadlockCPbIt(DecissionGroups{k,1})'; ConseqResPoOfferbIt; DecissionGroups{k,4}]; %% this is wrong as ConseqMatchLastResPoOffersSucessful4Hb must be constant in sum
        Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt];
        ub=ConsPowerTSb(SubIndices(DecissionGroups{k,3}, ControlPeriods, ControlPeriodsIt, 3))';
        
        Costf=Costsf(SubIndices(DecissionGroups{k,3}, ControlPeriods, ControlPeriodsIt, 3))';
        
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
    x=reshape(x,ControlPeriodsIt,NumCostCats,NumUsers);
    x=x(:,:,BackwardsOrder);
    x=x(:);
else

%     b=[ConsSumPowerTSbIt; ];
%     A=[ConsSumPowerTSAIt; ];
% 
%     beq=[ConseqResPoOfferbIt; ConseqMatchLastResPoOffers4HbIt];
%     Aeq=[ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt];
    
    b=[ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt];
    A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
    
    beq=[ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffers4HbIt];
    Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt];

    lb=zeros(ControlPeriodsIt, NumCostCats, NumUsers);
    ub=ConsPowerTSb(:);

    Costf=Costs(:);
    
    [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
    x(x<0)=0;   
end
tc1=tc1+toc;


% b=[ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt];
% A=[ConsSumPowerTSA; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
% 
% beq=[ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffersSucessful4Hb];
% Aeq=[ConsEnergyCPAeq; ConseqResPoOfferAIt; ConsMatchLastResPoOffers4HAeq];
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
    ChargingMat(:,:,:,PreAlgoCounter)=OptimalChargingEnergies;
    AvailabilityMat=[AvailabilityMat, Availability(1:96,1,:)];
    
    SuccessfulResPoOffers=ResPoOffers(:,1,PreAlgoCounter+1)<=ResPoPricesReal4H(floor((TimeInd+TD.Main)/(4*Time.StepInd))+1:floor((TimeInd+TD.Main)/(4*Time.StepInd))+6,3)/1000; %[€/MW]
    LastResPoOffers(:,PreAlgoCounter+1)=sum(OptimalChargingEnergies(1:ConstantResPoPowerPeriods:end,3,:), 3);
    LastResPoOffersSucessful4Hb(:,PreAlgoCounter+1)=LastResPoOffers(:,PreAlgoCounter+1);
    LastResPoOffersSucessful4Hb(ConsPeriods+1:ConsPeriods+6,PreAlgoCounter+1)=LastResPoOffersSucessful4Hb(ConsPeriods+1:ConsPeriods+6,PreAlgoCounter+1).*SuccessfulResPoOffers;
end

%ConseqMatchLastResPoOffersSucessful4Hb=sum(squeeze(OptimalChargingEnergies(24*Time.StepInd+1:4*Time.StepInd:24*Time.StepInd+ConsPeriods*4*Time.StepInd,3,:)), 2);
%temp1=ConseqMatchLastResPoOffersSucessful4Hb;


% if round(sum(x))<round(ConsMinEnergyToChargeCPbeq)
%     1
% end

% if sum(reshape(x,ControlPeriods, NumCostCats, NumUsers)>0 & Availability==0)>1
%     error("Availability was not considered")
% end