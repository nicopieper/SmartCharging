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

ConsPowerTSb=PowerTS;

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

ConseqMatchLastResPoOffers4HbIt=LastResPoOffersSucessful4H(ResPoBlockedIndices, PreAlgoCounter+1-double(ControlPeriodsIt==ControlPeriods));
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
    
    
else
    ConsPowerTSb((24-hour(TimeOfPreAlgo1))*Time.StepInd+1:(24-hour(TimeOfPreAlgo1))*Time.StepInd+24*Time.StepInd,3,:)=PowerTS((24-hour(TimeOfPreAlgo1))*Time.StepInd+1:(24-hour(TimeOfPreAlgo1))*Time.StepInd+24*Time.StepInd,3,:)*ResPoBuffer; % Limit the available power for reserve power. That is needed to avoid underfulfillment issues, when the planned driving schedules deviate from the real driving schedules.
end

ConsPowerTSb=ConsPowerTSb(:);

SplitDecissionGroups;


%%

% b=[ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt];
% A=[ConsSumPowerTSA; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
% 
% beq=[ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffersSucessful4H];
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
% beq=[ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffersSucessful4H];
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
        
        beq=[ConseqMaxEnergyChargableDeadlockCPbIt(DecissionGroups{k,1})'; ConseqResPoOfferbIt; DecissionGroups{k,4}];
        Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt];
        ub=ConsPowerTSb(SubIndices(DecissionGroups{k,3}, ControlPeriods, ControlPeriodsIt, 3))';
        
        Costf=Costsf(SubIndices(DecissionGroups{k,3}, ControlPeriods, ControlPeriodsIt, 3))';
        
        [x11,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
        
        if isempty(x11) % Resolves the issue that the buffer does not cover the deviation: In this case the underfullfilment must be accepted and as much reserve power as possible will be provided. The deviation from the offer must be satisfied by the other units of the VPP.
            b=[reshape(ConsSumPowerTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(ConsMaxEnergyChargableSoCTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(-ConsMinEnergyRequiredTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); DecissionGroups{k,4}];
            A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt; ConseqMatchLastResPoOffers4HAIt];

            beq=[ConseqMaxEnergyChargableDeadlockCPbIt(DecissionGroups{k,1})'; ConseqResPoOfferbIt]; 
            Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt];

            Costf=Costs;
            Costf(1:length(ResPoBlockedIndices)*Time.StepInd*4,3,:)=-10000;
            Costf=Costf(:);

            [x11,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
        end
        
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

    b=[ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt];
    A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
    
    beq=[ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffers4HbIt];
    Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt];
    
%     b=[ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt];
%     A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
%     
%     beq=[ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffers4HbIt];
%     Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt];

    lb=zeros(ControlPeriodsIt, NumCostCats, NumUsers);
    ub=ConsPowerTSb(:);

    Costf=Costs(:);
    
    tic
    [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
    
    if isempty(x) % Resolves the issue that the buffer does not cover the deviation: In this case the underfulfillment must be accepted and as much reserve power as possible will be provided. The deviation from the offer must be satisfied by the other units of the VPP.
        b=[ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt; ConseqMatchLastResPoOffers4HbIt];
        A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt; ConseqMatchLastResPoOffers4HAIt];

        beq=[ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt;];
        Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt;];
    
        Costf=Costs;
        Costf(1:length(ResPoBlockedIndices)*Time.StepInd*4,3,:)=-10000; % set costs for reserve power virtually so low that it will be used at its maximum possible
        Costf=Costf(:);
    
        [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
    end
    
    x(x<0)=0;   
end
tc1=tc1+toc;


% b=[ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt];
% A=[ConsSumPowerTSA; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
% 
% beq=[ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffersSucessful4H];
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
    ChargingMat{1}(:,:,:,PreAlgoCounter)=OptimalChargingEnergies;
    AvailabilityMat=[AvailabilityMat, Availability(1:96,1,:)];
    
    %SuccessfulResPoOffers(:,PreAlgoCounter+1)=ResPoOffers(:,1,PreAlgoCounter+1)<=ResPoPricesReal4H(floor((TimeInd+TD.Main)/(4*Time.StepInd))+1:floor((TimeInd+TD.Main)/(4*Time.StepInd))+6,3)/1000; %[€/MW]
    SuccessfulResPoOffers(:,PreAlgoCounter+1)=ResPoOffers(:,1,PreAlgoCounter+1)<=ResPoPricesReal4H(floor((TimeInd+TD.Main)/(4*Time.StepInd))+1+(24-hour(TimeOfPreAlgo1))/4:floor((TimeInd+TD.Main)/(4*Time.StepInd))+(24-hour(TimeOfPreAlgo1))/4+6,3)/1000; %[€/MW]
    LastResPoOffers(:,PreAlgoCounter+1)=sum(OptimalChargingEnergies(1:ConstantResPoPowerPeriods:end,3,:), 3);
    LastResPoOffersSucessful4H(:,PreAlgoCounter+1)=LastResPoOffers(:,PreAlgoCounter+1);
    LastResPoOffersSucessful4H(ConsPeriods+1:ConsPeriods+6,PreAlgoCounter+1)=LastResPoOffersSucessful4H(ConsPeriods+1:ConsPeriods+6,PreAlgoCounter+1).*SuccessfulResPoOffers(:,PreAlgoCounter+1);
end
if ismember(TimeInd, TimesOfPreAlgo(2,:))
    ChargingMat{2}(:,:,:,PreAlgoCounter)=OptimalChargingEnergies;
%     PPower(:,PreAlgoCounter)=sum(OptimalChargingEnergies(:,2,:),3);
%     PPPower(:,:,PreAlgoCounter)=squeeze(PVPower);
end

%%
% LastResPoOffersSucessful4H:   The first row corresponds to the
%                               Zeitscheibe at the time of PreAlgo1
%                               (usually 8:00), the second one to the
%                               Zeitscheibe afterwards (12:00) and so on.