%% Update Costs

CostsSpotmarket=(CostsElectricityBase/100 + SpotmarktPricesCP/1000)*Users{1}.MwSt; % [EUR/kWh]
CostsReserveMarket=(CostsElectricityBase/100 - ResEnOfferPrices - ResPoOfferPrices/(4*Time.StepInd))*Users{1}.MwSt; % [EUR/kWh]

Costs=[CostsSpotmarket, CostsPV(end-ControlPeriodsIt+1:end,1,:), CostsReserveMarket(end-ControlPeriodsIt+1:end,1,:)]; % [EUR/kWh]
%Costs=Costs(:,CostCats,:);


%% Define Constraints and DecissionGroups

ConsPowerTSb=PowerTS;

ConsSumPowerTSbIt=SumPower(:);

ConsMaxEnergyChargableSoCTSbIt=MaxEnergyChargableSoCTS(:);

ConsMinEnergyRequiredTSbIt=MinEnergyRequiredTS(:);

ConseqMaxEnergyChargableDeadlockCPbIt=MaxEnergyChargableDeadlockCP(:);


ConsSumPowerTSAIt=ConsSumPowerTSA;
ConsEnergyDemandTSAIt=ConsEnergyDemandTSA;
ConseqEnergyCPAIt=ConseqEnergyCPA;
ConseqResPoOfferAIt=ConseqResPoOfferA;

ConseqResPoOfferbIt=zeros((ConstantResPoPowerPeriods-1)*ControlPeriodsIt/ConstantResPoPowerPeriods,1 );

DelCols2=(1:(ControlPeriods-ControlPeriodsIt))'+(0:NumUsers/NumDecissionGroups*NumCostCats-1)*ControlPeriods;
DelCols2=DelCols2(:);

ResPoBlockedIndices=(floor(floor(mod(TimeInd-1, 24*Time.StepInd)/Time.StepInd)/4):5)+1 + (mod(TimeInd-1, (24*Time.StepInd))<=8*Time.StepInd)*6 - 2;
if hour(Time.Sim.Vec(TimeInd))+minute(Time.Sim.Vec(TimeInd))>hour(TimeOfPreAlgo(1))
    ResPoBlockedIndices=[ResPoBlockedIndices, 5:10];
end
ResPoBlockedIndices=((ResPoBlockedIndices(1):1/(4*Time.StepInd/ConstantResPoPowerPeriods):ResPoBlockedIndices(end)+1-1/(4*Time.StepInd/ConstantResPoPowerPeriods))-1)*4*Time.StepInd/ConstantResPoPowerPeriods+1;

ConseqMatchLastResPoOffers4HbIt=LastResPoOffersSucessful4H(ResPoBlockedIndices, PreAlgoCounter+1-double(ControlPeriodsIt==ControlPeriods));
ConseqMatchLastResPoOffers4HAIt=ConseqMatchLastResPoOffers4HA(1:length(ResPoBlockedIndices),:);
ConseqMatchLastResPoOffers4HAIt(:,repelem(ControlPeriods:ControlPeriods*2:ControlPeriods*NumUsers/NumDecissionGroups*NumCostCats*2,ControlPeriods-ControlPeriodsIt)'-DelCols2)=[];


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
    DelRows3=1:size(ConseqResPoOfferA,1)/12 * (floor((ControlPeriods-ControlPeriodsIt)/(4*Time.StepInd)));
    
%     if DelRows3~=DelRows2
%         error("Damn")
%     end
    
    ConseqResPoOfferAIt(DelRows3,:)=[];
    ConseqResPoOfferAIt(:,DelCols2)=[];
    
    
elseif CostCats(3)
    ConsPowerTSb((24-hour(TimeOfPreAlgo(1)))*Time.StepInd+1:(24-hour(TimeOfPreAlgo(1)))*Time.StepInd+24*Time.StepInd,sum(CostCats(1:3)),:)=PowerTS((24-hour(TimeOfPreAlgo(1)))*Time.StepInd+1:(24-hour(TimeOfPreAlgo(1)))*Time.StepInd+24*Time.StepInd,sum(CostCats(1:3)),:)*ResPoBuffer; % Limit the available power for reserve power. That is needed to avoid underfulfillment issues, when the planned driving schedules deviate from the real driving schedules.
end

ConsPowerTSb=ConsPowerTSb(:);

SplitDecissionGroups;


%% Calc optimal charging powers

if UseParallel
    
    ConsSumPowerTSbIt=ConsSumPowerTSbIt';
    ConsMaxEnergyChargableSoCTSbIt=ConsMaxEnergyChargableSoCTSbIt';
    ConsMinEnergyRequiredTSbIt=ConsMinEnergyRequiredTSbIt';
    ConseqMaxEnergyChargableDeadlockCPbIt=ConseqMaxEnergyChargableDeadlockCPbIt';
    ConsPowerTSb=ConsPowerTSb';
    Costsf=Costs(:)';

    x1=cell(NumDecissionGroups,1);
    lb=zeros(ControlPeriodsIt, NumCostCats, NumUsers/NumDecissionGroups);
    
    b=cell(NumDecissionGroups,1);
    beq=cell(NumDecissionGroups,1);
    ub=cell(NumDecissionGroups,1);
    Costf=cell(NumDecissionGroups,1);
    
    A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
    Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt];
    %Aeq=[ConseqEnergyCPAIt];
   
    
    for k=1:NumDecissionGroups
        b{k,1}=double([reshape(ConsSumPowerTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(ConsMaxEnergyChargableSoCTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(-ConsMinEnergyRequiredTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1)]);
        beq{k,1}=double([ConseqMaxEnergyChargableDeadlockCPbIt(DecissionGroups{k,1})'; ConseqResPoOfferbIt; DecissionGroups{k,4}]);        
        %beq{k,1}=double([ConseqMaxEnergyChargableDeadlockCPbIt(DecissionGroups{k,1})']);
        ub{k,1}=double(ConsPowerTSb(SubIndices(DecissionGroups{k,3}, ControlPeriods, ControlPeriodsIt, 3))');
        Costf{k,1}=double(Costsf(SubIndices(DecissionGroups{k,3}, ControlPeriods, ControlPeriodsIt, 3))');
    end
    
    %ticBytes(gcp)
    parfor k=1:NumDecissionGroups
        [x11,fval]=linprog(Costf{k,1},A,b{k,1},Aeq,beq{k,1},lb,ub{k,1}, options);
        x11(x11<0.01)=0;
        x1{k}=x11; 
    end
    %tocBytes(gcp)

    Costf1=double(Costs);
    Costf1(1:length(ResPoBlockedIndices)*Time.StepInd*4,3,:)=-10000;
    Costf1=Costf1(:);
    
    
    A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt; ConseqMatchLastResPoOffers4HAIt];
    Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt];
    %A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
    %Aeq=[ConseqEnergyCPAIt];
    
    for k=find(cellfun(@isempty,x1)') % Resolves the issue that the buffer does not cover the deviation: In this case the underfullfilment must be accepted and as much reserve power as possible will be provided. The deviation from the offer must be satisfied by the other units of the VPP.
        b{k,1}=double([reshape(ConsSumPowerTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(ConsMaxEnergyChargableSoCTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(-ConsMinEnergyRequiredTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); DecissionGroups{k,4}]);
        %b{k,1}=double([reshape(ConsSumPowerTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(ConsMaxEnergyChargableSoCTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(-ConsMinEnergyRequiredTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1)]);
        beq{k,1}=double([ConseqMaxEnergyChargableDeadlockCPbIt(DecissionGroups{k,1})'; ConseqResPoOfferbIt]);
        %beq{k,1}=double([ConseqMaxEnergyChargableDeadlockCPbIt(DecissionGroups{k,1})']);
        Costf{k,1}=Costf1(SubIndices(DecissionGroups{k,3}, ControlPeriods, ControlPeriodsIt, 3))';
    end
    
    UnsolvedProblems=find(cellfun(@isempty,x1)');
	parfor k=1:NumDecissionGroups
        if ismember(k,UnsolvedProblems)
            [x11,fval]=linprog(Costf{k,1},A,b{k,1},Aeq,beq{k,1},lb,ub{k,1}, options);
            x11(x11<0.01)=0;
            x1{k}=x11; 
        end
    end
    
    BackwardsOrder=reshape([DecissionGroups{:,1}], [], 1);
    x=reshape([x1{:,1}], [], 1);
    
    [~, BackwardsOrder]=sort(BackwardsOrder, 'ascend');
    x=reshape(x,ControlPeriodsIt,NumCostCats,NumUsers);
    x=x(:,:,BackwardsOrder);
    x=x(:);
 
    
else

    b=double([ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt]);
    A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
    
    beq=double([ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffers4HbIt]);
    Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt];
    
%     b=double([ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt]);
%     A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt];
%     
%     beq=double([ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffers4HbIt]);
%     Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt];

    lb=zeros(ControlPeriodsIt, NumCostCats, NumUsers);
    ub=double(ConsPowerTSb(:));

    Costf=double(Costs(:));
    
    [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
      
    if isempty(x) % Resolves the issue that the buffer does not cover the deviation: In this case the underfulfillment must be accepted and as much reserve power as possible will be provided. The deviation from the offer must be satisfied by the other units of the VPP.
        b=double([ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt; ConseqMatchLastResPoOffers4HbIt]);
        A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt; ConseqMatchLastResPoOffers4HAIt];

        beq=double([ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt;]);
        Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt;];
    
        Costf=double(Costs);
        Costf(1:length(ResPoBlockedIndices)*Time.StepInd*4/ConstantResPoPowerPeriodsScaling,3,:)=-10000; % set costs for reserve power virtually so low that it will be used at its maximum possible
        Costf=Costf(:);
    
        [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
    end
    
    x(x<0.01)=0;   
end


%% Evaluate result

OptimalChargingEnergies=reshape(x,ControlPeriodsIt, NumCostCats, NumUsers);
if any(OptimalChargingEnergies(:,3,:)>0.1)
    1
end

if CostCats(1)
    PostPreAlgo;
    OptimalChargingEnergies(:,1,:)=OptimalChargingEnergiesSpotmarket;
end

[Row, ~]=find(TimeInd==TimesOfPreAlgo);
Users{1}.ChargingMat{Row,1}(:,:,PreAlgoCounter)=single(sum(OptimalChargingEnergies,3));
%Users{1}.ChargingMatDemoUsers{Row,1}(:,:,1:numel(DemoUsers),PreAlgoCounter)=single(OptimalChargingEnergies(:,:,DemoUsers-1));

if ismember(TimeInd, TimesOfPreAlgo(1,:))
    Users{1}.AvailabilityMat(:,PreAlgoCounter,:)=single(Availability(1:24*Time.StepInd,1,:));
    
    SuccessfulResPoOffers(:,PreAlgoCounter+1)=ResPoOffers(:,1,PreAlgoCounter+1)<=repelem(ResPoPricesReal4H(floor((TimeInd+TD.Main)/(4*Time.StepInd))+1+(24-hour(TimeOfPreAlgo(1)))/4:floor((TimeInd+TD.Main)/(4*Time.StepInd))+(24-hour(TimeOfPreAlgo(1)))/4+6,5)/1000, ConstantResPoPowerPeriodsScaling); %[EUR/kW]
    LastResPoOffers(:,PreAlgoCounter+1)=sum(OptimalChargingEnergies(1:ConstantResPoPowerPeriods:end,3,:), 3); % [Wh]
    LastResPoOffersSucessful4H(:,PreAlgoCounter+1)=LastResPoOffers(:,PreAlgoCounter+1); % [Wh]
    LastResPoOffersSucessful4H(ConsPeriods*ConstantResPoPowerPeriodsScaling+1:(ConsPeriods+6)*ConstantResPoPowerPeriodsScaling,PreAlgoCounter+1)=LastResPoOffersSucessful4H(ConsPeriods*ConstantResPoPowerPeriodsScaling+1:(ConsPeriods+6)*ConstantResPoPowerPeriodsScaling,PreAlgoCounter+1).*SuccessfulResPoOffers(:,PreAlgoCounter+1);
    
    ResPoOffers(:,2,PreAlgoCounter+1)=sum(OptimalChargingEnergies((24-hour(TimeOfPreAlgo(1)))*Time.StepInd+1:ConstantResPoPowerPeriods:(24-hour(TimeOfPreAlgo(1))+24)*Time.StepInd,3,:)./ChargingEfficiencies, 3)/1000*4.*SuccessfulResPoOffers(:,PreAlgoCounter+1);

end

%%
% LastResPoOffersSucessful4H:   The first row corresponds to the
%                               Zeitscheibe at the time of PreAlgo(1)
%                               (usually 8:00), the second one to the
%                               Zeitscheibe afterwards (12:00) and so on.