%% Description
% This script initialises all variables needed for Algotihm 1 (PreAlgo).
% First some constant factors are set, then user data is processed.
% Finnally, the constraints matrices for the linear optimisation problem are 
% calculated.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
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


%% Control Variables

ControlPeriods=2*24*4;                        % Number of indices that one optimisation period covers. The optimisation period equals the time interval that is considered during the optimisation at 8 am. Usually it equals 48 h, hence 2*24h*4indices/h
CostCats=logical([1, 1, 1]);                  % Active electricity sources. A "1" indicates that this source is active: col1==Spotmarket, col2==PV, col3==reserve energy. This control variable might not work well better keep it as it is
NumCostCats=length(CostCats);%sum(CostCats);
ConstantResPoPowerPeriods=4*Time.StepInd;     % Duration of one time slice (Zeitscheibe) of the reserve power market. In 2021, it was 4h, thus 4h * 4indices/h
ResPoPriceFactor=[0.4]; %0.4                  % Factor for the reserve market price strategy. The offered reserve power is 60% lower than the market average of the last day
ResEnPriceFactor=0.15;                        % Factor for the reserve market price strategy. The offered reserve energy is 15% lower than the the lowest market bid of the last day
PublicChargingThresholdBuffer=1.2; % Best results with 1.2  % Factor that sets a SoC minimum level. It is PublicChargingThresholdBuffer times higher than the PublicChargingThreshold of the user
options = optimoptions('linprog','Algorithm','dual-simplex'); % Use the simplex algorithm to solve the linear optimisation problem
options.Display = 'off';
ResPoBuffer=1

ConstantResPoPowerPeriodsScaling=4*Time.StepInd/ConstantResPoPowerPeriods; % A scaling factor that enables other time slice durations than 16 indices
ResPoOffers=[-10000*ones(6*ConstantResPoPowerPeriodsScaling,1,ceil(length(Time.Sim.Vec)/(Time.StepInd*24))), zeros(6*ConstantResPoPowerPeriodsScaling,1,ceil(length(Time.Sim.Vec)/(Time.StepInd*24)))];  % The variable that covers all reserve power offers of the aggregator. Col1==offered prices [EUR/kW], Col2==offered power [kW]. Row1==0 am, Row2==4 am, Row3=8 am ..., Third dimension equals days
ResEnOffers=-10000*ones(6*ConstantResPoPowerPeriodsScaling,1,ceil(length(Time.Sim.Vec)/(Time.StepInd*24))); % The variable that covers all reserve energy offers of the aggregator [EUR/kWh]. Row1==0 am, Row2==4 am, Row3=8 am ..., Third dimension equals days

SubIndices = @(Vector, ControlPeriods, ControlPeriodsIt, CostCatsNum) (Vector(:,reshape((1:ControlPeriodsIt)'+(0:CostCatsNum-1)*ControlPeriodsIt,1,[]))-((Vector(:,1)-1)/ControlPeriods*(ControlPeriods-ControlPeriodsIt)));

%% Prepare Users

GridConvenientChargingAvailabilityControlPeriod=zeros(ControlPeriods, 1, NumUsers);
VarCounter=0;
if UseParallelAvailability
    
    for n=UserNum
        VarCounter=VarCounter+1;
        if ApplyGridConvenientCharging
            GridConvenientChargingAvailabilityControlPeriod(:,1,VarCounter)=repmat(Users{n}.GridConvenientChargingAvailability,2,1);
            GridConvenientChargingAvailabilityControlPeriod(:,1,VarCounter)=circshift(GridConvenientChargingAvailabilityControlPeriod(:,1,VarCounter), -ShiftInds);
        else
            GridConvenientChargingAvailabilityControlPeriod(:,1,VarCounter)=ones(ControlPeriods,1);
        end
    end
    
else

    VarCounter=0;
    for n=UserNum
        VarCounter=VarCounter+1;
        if ApplyGridConvenientCharging
            Users{n}.GridConvenientChargingAvailabilityControlPeriod=repmat(Users{n}.GridConvenientChargingAvailability,2,1);
            Users{n}.GridConvenientChargingAvailabilityControlPeriod=circshift(Users{n}.GridConvenientChargingAvailabilityControlPeriod, -ShiftInds);
            Users{n}.GridConvenientChargingAvailabilityControlPeriod=Users{n}.GridConvenientChargingAvailabilityControlPeriod(1:ControlPeriods);
        else
            Users{n}.GridConvenientChargingAvailabilityControlPeriod=ones(ControlPeriods,1);
        end
    end
    
end
    

%% Initialise Optimisation Variables

MaxPower=zeros(1, 1, NumUsers); % Save the maximum charging power at their private charging point of all users
BatterySizes=zeros(1, 1, NumUsers); % Save the battery sizes of all users in one variable
PublicChargingThresholds_Wh=zeros(ControlPeriods, 1, NumUsers); % Save the public charging thresholds of all users in one variable
ChargingEfficiencies=zeros(1, 1, NumUsers); % Save the charging efficiencies of all users in one variable
CostsElectricityBase=zeros(1, 1, NumUsers); % Save the base electricity costs of all users in one variable
CostsPV=ones(ControlPeriodsIt, 1, NumUsers);
VarCounter=0;
if UseIndividualEEGBonus
    for n=UserNum
        VarCounter=VarCounter+1;
        CostsPV(:,1,VarCounter)=CostsPV(:,1,VarCounter)*Users{n}.EEGBonus/100;
    end
else
    CostsPV=CostsPV*(Users{1}.EEGBonus/100);
end
VarCounter=0;
for n=UserNum
    VarCounter=VarCounter+1;
    MaxPower(1,1,VarCounter)=Users{n}.ACChargingPowerHomeCharging;
    BatterySizes(1,1,VarCounter)=double(Users{n}.BatterySize);
    PublicChargingThresholds_Wh(:,1,VarCounter)=ones(ControlPeriods, 1, 1) .* round(double(Users{n}.PublicChargingThreshold_Wh)*PublicChargingThresholdBuffer);
    ChargingEfficiencies(:,1,VarCounter)=double(Users{n}.ChargingEfficiency);
    CostsElectricityBase(1, 1, VarCounter)=double(Users{n}.PrivateElectricityPrice + Users{n}.NNEEnergyPrice);
    if Users{n}.PVPlantExists==true
        CostsPV(:,1,VarCounter)=10000*ones(ControlPeriods,1); % Ensure never use PVPlant if there is non. Also ensured by PowerCons as PVPower is constantly zero
    end
end
CostsPV=CostsPV+((1:ControlPeriodsIt)'-ControlPeriodsIt/2)*0.00001; % Prefer early PV charging over late charging --> The price for charging early is lower than for charging later

    

Users{1}.ChargingMat=cell(size(TimesOfPreAlgo,1)+1,1); % Save the results of each optimisation in this variable (summed load profile)
%Users{1}.ChargingMatDemoUsers=cell(size(TimesOfPreAlgo,1)+1,1);
for k=1:size(Users{1}.ChargingMat,1)-1
    Users{1}.ChargingMat{k,2}=mod(TimesOfPreAlgo(k,1)-1,ControlPeriods) + 96*(TimeOfPreAlgo(k)<TimeOfPreAlgo(1));
    Users{1}.ChargingMat{k,1}=zeros(ControlPeriods-4*Time.StepInd*(k-1), NumCostCats, ceil(length(Time.Sim.Vec)/(Time.StepInd*24)), 'single');
%    Users{1}.ChargingMatDemoUsers{k,2}=mod(TimesOfPreAlgo(k,1)-1,ControlPeriods) + 96*(TimeOfPreAlgo(k)<TimeOfPreAlgo(1));
%    Users{1}.ChargingMatDemoUsers{k,1}=zeros(ControlPeriods-4*Time.StepInd*(k-1), NumCostCats, numel(DemoUsers), ceil(length(Time.Sim.Vec)/(Time.StepInd*24)), 'single');
end

Users{1}.AvailabilityMat=single(zeros(24*Time.StepInd, ceil(length(Time.Sim.Vec)/(Time.StepInd*24)), NumUsers)); % Save when a user parks at its private charging spot
DecissionGroups=cell(NumDecissionGroups,1);
SuccessfulResPoOffers=zeros(6*ConstantResPoPowerPeriodsScaling,1);


%% Initialise Constraints

% Constraint the charging power per user per times step to its technical maximum
% charging power which is determined by the vehicle's and the charging
% point's maximum charging power. The technical maximum charging power is 0
% if the vehicle does not park the charging point or the DSO blocks the
% charging point. The charging power can also be reduced by 50 % in case
% the DSO reduces the charging power rather than blocks the charging
% completly. As this constraint must be applied to each time step
% (therefore TS), it has one constraint for each user and each time step
% (N*T)
% Pattern: P_t,q,n, t:time step, q:electricity source, n:user
%
% Row1:   P_1,1,1  P_2,1,1  ... P_T,1,1  P_1,2,1  P_2,2,1  ... P_T,2,1  ...  P_T,3,N
% Row2:   P_1,1,1  P_2,1,1  ... P_T,1,1  P_1,2,1  P_2,2,1  ... P_T,2,1  ...  P_T,3,N
%                                           |
% RowN*T: P_1,1,1  P_2,1,1  ... P_T,1,1  P_1,2,1  P_2,2,1  ... P_T,2,1  ...  P_T,3,N

% Row1:   1        0        ... 0        1        0        ... 0        ...  0
% Row2:   0        1        ... 0        0        1        ... 0        ...  0
%                                           |
% RowN*T: 0        0        ... 0        0        0        ... 0        ...  1
ConsSumPowerTSA=sparse(kron(sparse(eye(NumUsers/NumDecissionGroups, NumUsers/NumDecissionGroups)), repmat(sparse(diag(ones(ControlPeriods,1))),1,NumCostCats))); 


% Ensure that within one optimisation period the maximum possible energy
% that can be charged will be charged. The maximum possbile enegry can
% be limited by the battery size or the parking time at the private parking
% spot. This constraint is must be applied to each user only once per
% optimisation period (therefore CP) hence it has N rows. Is a constraint
% that makes the charged energy equal to the maximum possible energy and
% minimum required energy, hence the "eq" abbreviation
% Pattern: P_t,q,n, t:time step, q:electricity source, n:user
%
% Row1:   P_1,1,1  P_2,1,1  ... P_T,1,1  P_1,2,1  P_2,2,1  ... P_T,2,1  ...  P_T,3,N
% Row2:   P_1,1,1  P_2,1,1  ... P_T,1,1  P_1,2,1  P_2,2,1  ... P_T,2,1  ...  P_T,3,N
%                                           |
% RowN:   P_1,1,1  P_2,1,1  ... P_T,1,1  P_1,2,1  P_2,2,1  ... P_T,2,1  ...  P_T,3,N
%
% Row1:   1        1        ... 1        1        1        ... 1        ...  0
% Row2:   0        0        ... 0        0        0        ... 0        ...  0
%                                           |
% RowN:   0        0        ... 0        0        0        ... 0        ...  1
ConseqEnergyCPA=sparse(kron(sparse(eye(NumUsers/NumDecissionGroups, NumUsers/NumDecissionGroups)), ones(1,ControlPeriods*NumCostCats)));  % the ones of a single row represent the decission variable of one vehicle. the sum of all powers of one vehicle must no exceed the energy demand


% Used to constraint the charged energy to its techincal maximum such that
% at no point a battery exceeds its capacity. Also used to ensure that at
% no point (if technical possible) the SoC does not come below the users's
% PublicChargingThresholds_Wh. Therefore the charged energy until every
% time step considering all sources of each users must be determined.
% Hence, this is a time step (TS) constraint. It has N*T rows
% Pattern: P_t,q,n, t:time step, q:electricity source, n:user
%
% Row1:   P_1,1,1  P_2,1,1  ... P_T,1,1  P_1,2,1  P_2,2,1  ... P_T,2,1  ...  P_T,3,N
% Row2:   P_1,1,1  P_2,1,1  ... P_T,1,1  P_1,2,1  P_2,2,1  ... P_T,2,1  ...  P_T,3,N
% Row3:   P_1,1,1  P_2,1,1  ... P_T,1,1  P_1,2,1  P_2,2,1  ... P_T,2,1  ...  P_T,3,N
%                                           |
% RowN:   P_1,1,1  P_2,1,1  ... P_T,1,1  P_1,2,1  P_2,2,1  ... P_T,2,1  ...  P_T,3,N
%
% Row1:   1        0        ... 0        1        0        ... 0        ...  0
% Row2:   1        1        ... 0        1        1        ... 0        ...  0
%                                           |
% RowN*T: 0        0        ... 0        0        0        ... 0        ...  1
ConsEnergyDemandTSA=sparse(kron(sparse(eye(NumUsers/NumDecissionGroups, NumUsers/NumDecissionGroups)), sparse(repmat(sparse(tril(ones(ControlPeriods))), 1, NumCostCats))));


ResPoOfferEqualiyMat1=sparse(zeros(ConstantResPoPowerPeriods-1,ConstantResPoPowerPeriods));
x=0:ConstantResPoPowerPeriods-2;
ResPoOfferEqualiyMat1(x*ConstantResPoPowerPeriods+1)=1;
ResPoOfferEqualiyMat1(x*ConstantResPoPowerPeriods+1+ConstantResPoPowerPeriods-1)=-1;
ResPoOfferEqualiyMat2=sparse(kron(eye(ControlPeriods/ConstantResPoPowerPeriods, ControlPeriods/ConstantResPoPowerPeriods), ResPoOfferEqualiyMat1));

% Ensure that in sum over all vehicles the electricity demand from source
% q=3 (reserve energy) is constant over one time slice (Zeitscheibe).
% Threrefore the summed energy demand of all vehicles from q=3 at time t 
% must equal the demand at t+1 if t belongs to the same time silice as t+1.
% Row1:   P_1,1,1  ...  P_1,3,1  P_2,3,1  P_3,3,1  ...  P_15,3,1 P_16,3,1 P_17,3,1  ...  P_T,3,1  ...  P_1,3,2  P_2,3,2  P_3,3,2  ...  P_15,3,2 P_16,3,2 P_17,3,2  ...  P_T,3,N
% Row2:   P_1,1,1  ...  P_1,3,1  P_2,3,1  P_3,3,1  ...  P_15,3,1 P_16,3,1 P_17,3,1  ...  P_T,3,1  ...  P_1,3,2  P_2,3,2  P_3,3,2  ...  P_15,3,2 P_16,3,2 P_17,3,2  ...  P_T,3,N
% Row3:   P_1,1,1  ...  P_1,3,1  P_2,3,1  P_3,3,1  ...  P_15,3,1 P_16,3,1 P_17,3,1  ...  P_T,3,1  ...  P_1,3,2  P_2,3,2  P_3,3,2  ...  P_15,3,2 P_16,3,2 P_17,3,2  ...  P_T,3,N
%                                                   |
% Row15:  P_1,1,1  ...  P_1,3,1  P_2,3,1  P_3,3,1  ...  P_15,3,1 P_16,3,1 P_17,3,1  ...  P_T,3,1  ...  P_1,3,2  P_2,3,2  P_3,3,2  ...  P_15,3,2 P_16,3,2 P_17,3,2  ...  P_T,3,N
% Row16:  P_1,1,1  ...  P_1,3,1  P_2,3,1  P_3,3,1  ...  P_15,3,1 P_16,3,1 P_17,3,1  ...  P_T,3,1  ...  P_1,3,2  P_2,3,2  P_3,3,2  ...  P_15,3,2 P_16,3,2 P_17,3,2  ...  P_T,3,N
%                                                   |
% RowN*T: P_1,1,1  ...  P_1,3,1  P_2,3,1  P_3,3,1  ...  P_15,3,1 P_16,3,1 P_17,3,1  ...  P_T,3,1  ...  P_1,3,2  P_2,3,2  P_3,3,2  ...  P_15,3,2 P_16,3,2 P_17,3,2  ...  P_T,3,N
%
% Row1:    0       ...   1       -1        0       ...   0         0       0        ...   0       ...   1       -1        0       ...   0        0        0        ...   0
% Row2:    0       ...   1       -1        0       ...   0         0       0        ...   0       ...   1       -1        0       ...   0        0        0        ...   0
% Row3:    0       ...   1       -1        0       ...   0         0       0        ...   0       ...   1       -1        0       ...   0        0        0        ...   0
%                                                   |
% Row15:   0       ...   0        0        0       ...   1        -1       0        ...   0       ...   0        0        0       ...   1       -1        0        ...   0
% Row16:   0       ...   0        0        0       ...   0         0       1        ...   0       ...   0        0        0       ...   0        0        1        ...   0
%                                                   |
% RowN*T:  0       ...   0        0        0       ...   0         0       0        ...   0       ...   0        0        0       ...   0        0        0        ...   1
ConseqResPoOfferA=sparse(repmat([zeros((ConstantResPoPowerPeriods-1)*ControlPeriods/ConstantResPoPowerPeriods,ControlPeriods*2), ResPoOfferEqualiyMat2],1,NumUsers/NumDecissionGroups)); % one row represents one time step. within one Zeitscheibe the sum of reserve powers offered by all vehicles must be equal. hence it must be the power in timestep=1 must be the same as in timestep=2. this is represented by  a one followed by a -1 per vehicle



if TimeOfPreAlgo(1) <= TimeOfReserveMarketOffer
    ConsPeriods=(24*Time.StepInd-ShiftInds)/(4*Time.StepInd);
else
    ConsPeriods=(2*24*Time.StepInd-ShiftInds)/(4*Time.StepInd);
end

% Ensure that the summed fleet demand from electricity source q=3 (reserve 
% energy) equals the successfully offered power at the market for all time
% steps the market clearing has already happend. It is sufficient to set
% only the first time step of one time slice to the successfully offered
% reserve power because ConseqResPoOfferA will set all other time steps of
% this time slice to the same value.
% Row1:   P_1,1,1  ...  P_1,3,1  P_2,3,1  ... P_17,3,1 P_18,3,1 ... P_T,3,1  ...  P_1,3,2  P_2,3,2  ... P_17,3,2 P_18,3,2  ...  P_T,3,N
% Row2:   P_1,1,1  ...  P_1,3,1  P_2,3,1  ... P_17,3,1 P_18,3,1 ... P_T,3,1  ...  P_1,3,2  P_2,3,2  ... P_17,3,2 P_18,3,2  ...  P_T,3,N
% Row3:   P_1,1,1  ...  P_1,3,1  P_2,3,1  ... P_17,3,1 P_18,3,1 ... P_T,3,1  ...  P_1,3,2  P_2,3,2  ... P_17,3,2 P_18,3,2  ...  P_T,3,N
%                                          |
% Row12:  P_1,1,1  ...  P_1,3,1  P_2,3,1  ... P_17,3,1 P_18,3,1 ... P_T,3,1  ...  P_1,3,2  P_2,3,2  ... P_17,3,2 P_18,3,2  ...  P_T,3,N
%
% Row1:    0       ...   1        0       ...  0        0       ...  0       ...   1        0       ...  0        0        ...   0
% Row2:    0       ...   0        0       ...  1        0       ...  0       ...   0        0       ...  1        0        ...   0
%                                          |
% Row2:    0       ...   0        0       ...  0        0       ...  0       ...   0        0       ...  0        0        ...   0
ConseqMatchLastResPoOffers4HA=repmat([zeros(ControlPeriods/ConstantResPoPowerPeriods,ControlPeriods*2), kron(eye(ControlPeriods/(4*Time.StepInd)),kron(eye(4*Time.StepInd/ConstantResPoPowerPeriods),[zeros(1,ConstantResPoPowerPeriods-1),ones(1,1)]))], 1, NumUsers/NumDecissionGroups);
ConseqMatchLastResPoOffers4HA=sparse(ConseqMatchLastResPoOffers4HA(1:ceil(ControlPeriods/(ConstantResPoPowerPeriods)),:));

% Saves the offered reserve power during the last auction
LastResPoOffers=zeros(ceil(ControlPeriods/(ConstantResPoPowerPeriods)),1);

% Saves the offered reserve power during the last auction but sets all
% unsuccessful offeres to zero.
LastResPoOffersSuccessful4H=zeros(ceil(ControlPeriods/(ConstantResPoPowerPeriods)),1);


A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
Aeq=[ConseqEnergyCPA; ConseqResPoOfferA; ConseqMatchLastResPoOffers4HA];
lb=zeros(ControlPeriods, NumCostCats, NumUsers);
lb=lb(:);
