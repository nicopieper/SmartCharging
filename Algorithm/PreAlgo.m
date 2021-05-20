%% Description
% This script calculates the optimal charging schedules and represents
% algorithm 1. Therefore linear optimisations is applied. The objective is
% to minimise the charging costs during the optimisation period by
% calculating the optimal charging powers P_t,q,n for 
% each time step t (1...T), each electricity source q (1...3) and 
% each user (1...N). The optimisation problem is divided into 
% NumDecissionGroups problems in order to reduce computational time and RAM
% resources. The optimisation problems os solved for each group seperately.
% If UseParallel==true then parallel computing is used to calculate the
% optimisation problems in parallel.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   InitialisePreAlgo       Needed for the execution of this script (called
%                           by Simulation.m)
%   CalcDynOptVars          Needed for the execution of this script (called
%                           by Simulation.m)
%   CalcConsOptVars         Needed for the execution of this script (called
%                           by Simulation.m)
%   SplitDecissionGroups    This script calls SplitDecissionGroups.m
%   PostPreAlgo             This script calls PostPreAlgo.m
%   Simulation              This script is called by Simulation.m
%
% General structure of the constraint variables:
% One row represents one constraint. The columns represent the decission
% variables. They are ordered in the following way: The first 192 decission
% variables represent the charging powers for the first 192 quaterly hours
% that could be used for charging using CostCat1 by User1. Then 192
% variables for CostCat2 two and 192 for CostCat3 for User1. Then the
% decission variables for all other users are concatenated in the same
% manner



%% Update Costs

% For each user, each electricity source and each time step costs for the
% consumption of charging energy is defined. 

% The costs for the demand of electricity from the spotmarket equal the 
% base costs (constant external electricity price components like taxes, 
% EEG-Umlage etc.) and the current day-ahead spot market prices, hence this
% price component is dynamic and varies in time.
CostsSpotmarket=(CostsElectricityBase/100 + SpotmarktPricesCP/1000)*Users{1}.MwSt; % [EUR/kWh]

% The costs for the usage of pv power equals the EEG remuneration, that, in
% case of not using the pv power, would have been paid to the user. Hence
% this costs are constant at all times as the EEG remuneration do not
% change (hence they are defined in CalcConsOptVars). But, because early
% charging is preferred rather than charging at a later time, in this
% optimisation problem the price for charging pv power rises slightly
% during the optimisation period, hence charging early is more 
% advantageous.

% The costs for the demand of negative reserve energy equal base costs 
% (constant external electricity price components like taxes, EEG-Umlage 
% etc.) minus the remuneration of the reserve energy (wich can be also 
% negative) minus the remuneartion for the reserve power.
CostsReserveMarket=(CostsElectricityBase/100 - ResEnOfferPrices - ResPoOfferPrices/(4*Time.StepInd))*Users{1}.MwSt; % [EUR/kWh]

% In case of short Zeitscheiben do not apply the same proce to each time 
% step to avoid high concentration and hence cannibalisation
if ConstantResPoPowerPeriods<4*Time.StepInd
    CostsReserveMarket=CostsReserveMarket+(rand(ControlPeriods, NumUsers)-0.5)/10000;
end

Costs=[CostsSpotmarket, CostsPV(end-ControlPeriodsIt+1:end,1,:), CostsReserveMarket(end-ControlPeriodsIt+1:end,1,:)]; % [EUR/kWh]


%% Define Constraints and DecissionGroups

% Right side of the constraints

ConsPowerTSb=PowerTS;
ConsSumPowerTSbIt=SumPower(:);
ConsMaxEnergyChargableSoCTSbIt=MaxEnergyChargableSoCTS(:);
ConsMinEnergyRequiredTSbIt=MinEnergyRequiredTS(:);
ConseqMaxEnergyChargableDeadlockCPbIt=MaxEnergyChargableDeadlockCP(:);
ConseqResPoOfferbIt=zeros((ConstantResPoPowerPeriods-1)*ControlPeriodsIt/ConstantResPoPowerPeriods,1 );

% Determine for which Zeitscheiben the demand from electricity source q=3
% is fixed because the reserve market auctions already have taken place
ResPoBlockedIndices=(floor(floor(mod(TimeInd-1, 24*Time.StepInd)/Time.StepInd)/4):5)+1 + (mod(TimeInd-1, (24*Time.StepInd))<=8*Time.StepInd)*6 - 2;
if hour(Time.Sim.Vec(TimeInd))+minute(Time.Sim.Vec(TimeInd))>hour(TimeOfPreAlgo(1))
    ResPoBlockedIndices=[ResPoBlockedIndices, 5:10];
end
ResPoBlockedIndices=((ResPoBlockedIndices(1):1/(4*Time.StepInd/ConstantResPoPowerPeriods):ResPoBlockedIndices(end)+1-1/(4*Time.StepInd/ConstantResPoPowerPeriods))-1)*4*Time.StepInd/ConstantResPoPowerPeriods+1;

ConseqMatchLastResPoOffers4HbIt=LastResPoOffersSuccessful4H(ResPoBlockedIndices, PreAlgoCounter+1-double(ControlPeriodsIt==ControlPeriods));

% Left side of the constraints

ConsSumPowerTSAIt=ConsSumPowerTSA;
ConsEnergyDemandTSAIt=ConsEnergyDemandTSA;
ConseqEnergyCPAIt=ConseqEnergyCPA;
ConseqResPoOfferAIt=ConseqResPoOfferA;
ConseqMatchLastResPoOffers4HAIt=ConseqMatchLastResPoOffers4HA(1:length(ResPoBlockedIndices),:);
ConseqMatchLastResPoOffers4HAIt(:,repelem(ControlPeriods:ControlPeriods*2:ControlPeriods*NumUsers/NumDecissionGroups*NumCostCats*2,ControlPeriods-ControlPeriodsIt)'-DelCols2)=[];

% The left side matrices of the constraints must be cut to the number of
% time steps considered during the current optimisation period. The
% optimisation at 8:00 considers 192 time steps, the one at 12:00 176, the
% one at 16:00 152 and so on.

DelCols2=(1:(ControlPeriods-ControlPeriodsIt))'+(0:NumUsers/NumDecissionGroups*NumCostCats-1)*ControlPeriods;
DelCols2=DelCols2(:);

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
        
    ConseqResPoOfferAIt(DelRows3,:)=[];
    ConseqResPoOfferAIt(:,DelCols2)=[];
    
elseif CostCats(3)
    ConsPowerTSb((24-hour(TimeOfPreAlgo(1)))*Time.StepInd+1:(24-hour(TimeOfPreAlgo(1)))*Time.StepInd+24*Time.StepInd,sum(CostCats(1:3)),:)=PowerTS((24-hour(TimeOfPreAlgo(1)))*Time.StepInd+1:(24-hour(TimeOfPreAlgo(1)))*Time.StepInd+24*Time.StepInd,sum(CostCats(1:3)),:)*ResPoBuffer; % Limit the available power for reserve power. That is needed to avoid underfulfillment issues, when the planned driving schedules deviate from the real driving schedules.
end

ConsPowerTSb=ConsPowerTSb(:);


SplitDecissionGroups; % splits the users into NumDecissionGroups groups


%% Calc optimal charging powers

if UseParallel % in this case parallel computing is used to solve the optimisation problems in parallel
    
    ConsSumPowerTSbIt=ConsSumPowerTSbIt';
    ConsMaxEnergyChargableSoCTSbIt=ConsMaxEnergyChargableSoCTSbIt';
    ConsMinEnergyRequiredTSbIt=ConsMinEnergyRequiredTSbIt';
    ConseqMaxEnergyChargableDeadlockCPbIt=ConseqMaxEnergyChargableDeadlockCPbIt';
    ConsPowerTSb=ConsPowerTSb';
    Costsf=Costs(:)';

    x1=cell(NumDecissionGroups,1);
    lb=zeros(ControlPeriodsIt, NumCostCats, NumUsers/NumDecissionGroups); % lower bound for the optimisation variable, constant over all DecissionGroups
    
    % store the constraints of each DecissionGroup in one cell hence parfor
    % can iterate through them and split them to different workers.
    
    b=cell(NumDecissionGroups,1); % right side lower than constraints
    beq=cell(NumDecissionGroups,1); % right side equality constraints
    ub=cell(NumDecissionGroups,1); % upper bound for the optimisation variables
    Costf=cell(NumDecissionGroups,1);
    
    A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt]; % left side lower than constraints
    Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt]; % left side equality constraints
  
    
    for k=1:NumDecissionGroups
        b{k,1}=double([reshape(ConsSumPowerTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(ConsMaxEnergyChargableSoCTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(-ConsMinEnergyRequiredTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1)]);
        beq{k,1}=double([ConseqMaxEnergyChargableDeadlockCPbIt(DecissionGroups{k,1})'; ConseqResPoOfferbIt; DecissionGroups{k,4}]);        
        ub{k,1}=double(ConsPowerTSb(SubIndices(DecissionGroups{k,3}, ControlPeriods, ControlPeriodsIt, 3))');
        Costf{k,1}=double(Costsf(SubIndices(DecissionGroups{k,3}, ControlPeriods, ControlPeriodsIt, 3))');
    end
    
    % Solve the optimisation problem for each DecissionGroup in parallel
    % and save the result in x1. Set values below 0.01 to zero
    
    parfor k=1:NumDecissionGroups
        [x11,fval]=linprog(Costf{k,1},A,b{k,1},Aeq,beq{k,1},lb,ub{k,1}, options);
        x11(x11<0.01)=0;
        x1{k}=x11; 
    end
    
    
    % In case that optimisation problem k can not be solved, x1{k} is
    % empty. This occurs usually because the algorithm can not fullfil the 
    % ConseqResPoOfferAIt constraint as due to public charging events
    % therer is not enough charging power to satisfy the offered reserve
    % power. Hence the algorithm is repeated and shall allocat as much
    % power as possible to electricity source q=3 for all Zeitscheiben the
    % reserve auctions already have taken place. Therefore, costs for this
    % source and these time steps are set to -10000 and the constraints
    % becomes a lower than constraint. Then the new optimisation problem is
    % solved.

    Costf1=double(Costs);
    Costf1(1:length(ResPoBlockedIndices)*Time.StepInd*4,3,:)=-10000;
    Costf1=Costf1(:);
    
    A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt; ConseqMatchLastResPoOffers4HAIt];
    Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt];
    
    for k=find(cellfun(@isempty,x1)') % Resolves the issue that the buffer does not cover the deviation: In this case the underfullfilment must be accepted and as much reserve power as possible will be provided. The deviation from the offer must be satisfied by the other units of the VPP.
        b{k,1}=double([reshape(ConsSumPowerTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(ConsMaxEnergyChargableSoCTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(-ConsMinEnergyRequiredTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); DecissionGroups{k,4}]);
        %b{k,1}=double([reshape(ConsSumPowerTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(ConsMaxEnergyChargableSoCTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1); reshape(-ConsMinEnergyRequiredTSbIt(SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1)'),[],1)]);
        beq{k,1}=double([ConseqMaxEnergyChargableDeadlockCPbIt(DecissionGroups{k,1})'; ConseqResPoOfferbIt]);
        %beq{k,1}=double([ConseqMaxEnergyChargableDeadlockCPbIt(DecissionGroups{k,1})']);
        Costf{k,1}=Costf1(SubIndices(DecissionGroups{k,3}, ControlPeriods, ControlPeriodsIt, 3))';
    end
    
    UnsolvedProblems=find(cellfun(@isempty,x1)'); % all optimisation problems no solution could be found for
	parfor k=1:NumDecissionGroups
        if ismember(k,UnsolvedProblems)
            [x11,fval]=linprog(Costf{k,1},A,b{k,1},Aeq,beq{k,1},lb,ub{k,1}, options);
            x11(x11<0.01)=0;
            x1{k}=x11; 
        end
    end
    
    
    % Save the optimal charging powers of all DecissionGroups in one
    % variable.
    
    BackwardsOrder=reshape([DecissionGroups{:,1}], [], 1);
    x=reshape([x1{:,1}], [], 1);
    
    [~, BackwardsOrder]=sort(BackwardsOrder, 'ascend');
    x=reshape(x,ControlPeriodsIt,NumCostCats,NumUsers);
    x=x(:,:,BackwardsOrder);
    x=x(:);
   
else % do not use parallel computing

    b=double([ConsSumPowerTSbIt; ConsMaxEnergyChargableSoCTSbIt; -ConsMinEnergyRequiredTSbIt]); % right side of the lower than constraints
    A=[ConsSumPowerTSAIt; ConsEnergyDemandTSAIt; -ConsEnergyDemandTSAIt]; % left side of the lower than constraints
    
    beq=double([ConseqMaxEnergyChargableDeadlockCPbIt; ConseqResPoOfferbIt; ConseqMatchLastResPoOffers4HbIt]); % right side of the equality constraints
    Aeq=[ConseqEnergyCPAIt; ConseqResPoOfferAIt; ConseqMatchLastResPoOffers4HAIt]; % left side of the equality constraints

    lb=zeros(ControlPeriodsIt, NumCostCats, NumUsers); % lower bound of the optimisation variables
    ub=double(ConsPowerTSb(:)); % upper bound of the optimisation variables

    Costf=double(Costs(:)); % cost function
    
    [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options); % solve the optimisation problem
      
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

OptimalChargingEnergies=reshape(x,ControlPeriodsIt, NumCostCats, NumUsers); % reshape the optimisation variable into the common form. 1:time steps, 2 electricity source, 3:users
if any(OptimalChargingEnergies(:,3,:)>0.1)
    1
end

if CostCats(1) % if electricity from the spotmarket can be used
    PostPreAlgo; % reallocates the spotmarket demand in order to smoothen the demand during one hour.
    OptimalChargingEnergies(:,1,:)=OptimalChargingEnergiesSpotmarket;
end

[Row, ~]=find(TimeInd==TimesOfPreAlgo);
Users{1}.ChargingMat{Row,1}(:,:,PreAlgoCounter)=single(sum(OptimalChargingEnergies,3)); % save the fleets charging power in this variable
%Users{1}.ChargingMatDemoUsers{Row,1}(:,:,1:numel(DemoUsers),PreAlgoCounter)=single(OptimalChargingEnergies(:,:,DemoUsers-1));

if ismember(TimeInd, TimesOfPreAlgo(1,:)) % if this is the 8:00 optimisation
    Users{1}.AvailabilityMat(:,PreAlgoCounter,:)=single(Availability(1:24*Time.StepInd,1,:)); % save the fleets charging availability in this variable
    
    % save the reserve market offers
    SuccessfulResPoOffers(:,PreAlgoCounter+1)=ResPoOffers(:,1,PreAlgoCounter+1)<=repelem(ResPoPricesReal4H(floor((TimeInd+TD.Main)/(4*Time.StepInd))+1+(24-hour(TimeOfPreAlgo(1)))/4:floor((TimeInd+TD.Main)/(4*Time.StepInd))+(24-hour(TimeOfPreAlgo(1)))/4+6,5)/1000, ConstantResPoPowerPeriodsScaling); %[EUR/kW]
    LastResPoOffers(:,PreAlgoCounter+1)=sum(OptimalChargingEnergies(1:ConstantResPoPowerPeriods:end,3,:), 3); % [Wh]
    LastResPoOffersSuccessful4H(:,PreAlgoCounter+1)=LastResPoOffers(:,PreAlgoCounter+1); % [Wh]
    LastResPoOffersSuccessful4H(ConsPeriods*ConstantResPoPowerPeriodsScaling+1:(ConsPeriods+6)*ConstantResPoPowerPeriodsScaling,PreAlgoCounter+1)=LastResPoOffersSuccessful4H(ConsPeriods*ConstantResPoPowerPeriodsScaling+1:(ConsPeriods+6)*ConstantResPoPowerPeriodsScaling,PreAlgoCounter+1).*SuccessfulResPoOffers(:,PreAlgoCounter+1);
    
    ResPoOffers(:,2,PreAlgoCounter+1)=sum(OptimalChargingEnergies((24-hour(TimeOfPreAlgo(1)))*Time.StepInd+1:ConstantResPoPowerPeriods:(24-hour(TimeOfPreAlgo(1))+24)*Time.StepInd,3,:)./ChargingEfficiencies, 3)/1000*Time.StepInd.*SuccessfulResPoOffers(:,PreAlgoCounter+1); % [kW]

end

%%
% LastResPoOffersSuccessful4H:   The first row corresponds to the
%                               Zeitscheibe at the time of PreAlgo(1)
%                               (usually 8:00), the second one to the
%                               Zeitscheibe afterwards (12:00) and so on.