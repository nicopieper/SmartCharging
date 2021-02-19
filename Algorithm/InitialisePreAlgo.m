%% Control Variables

ControlPeriods=96*2;
CostCats=logical([1, 1, 1]);
NumCostCats=sum(CostCats);
ConstantResPoPowerPeriods=4*Time.StepInd;
ResPoPriceFactor=[0.4]; %0.4
ResEnPriceFactor=0.15;
options = optimoptions('linprog','Algorithm','dual-simplex');
options.Display = 'off';
ResPoBuffer=1;

ConstantResPoPowerPeriodsScaling=4*Time.StepInd/ConstantResPoPowerPeriods;
ResPoOffers=[-10000*ones(6*ConstantResPoPowerPeriodsScaling,1,ceil(length(Time.Sim.Vec)/(Time.StepInd*24))), zeros(6*ConstantResPoPowerPeriodsScaling,1,ceil(length(Time.Sim.Vec)/(Time.StepInd*24)))];
ResEnOffers=-10000*ones(6*ConstantResPoPowerPeriodsScaling,1,ceil(length(Time.Sim.Vec)/(Time.StepInd*24)));

SubIndices = @(Vector, ControlPeriods, ControlPeriodsIt, CostCatsNum) (Vector(:,reshape((1:ControlPeriodsIt)'+(0:CostCatsNum-1)*ControlPeriodsIt,1,[]))-((Vector(:,1)-1)/ControlPeriods*(ControlPeriods-ControlPeriodsIt)));

%% Prepare Users

for n=UserNum
    if ApplyGridConvenientCharging
        Users{n}.GridConvenientChargingAvailabilityControlPeriod=repmat(Users{n}.GridConvenientChargingAvailability,2,1);
        Users{n}.GridConvenientChargingAvailabilityControlPeriod=circshift(Users{n}.GridConvenientChargingAvailabilityControlPeriod, -ShiftInds);
        Users{n}.GridConvenientChargingAvailabilityControlPeriod=Users{n}.GridConvenientChargingAvailabilityControlPeriod(1:ControlPeriods);
    else
        Users{n}.GridConvenientChargingAvailabilityControlPeriod=ones(ControlPeriods,1);
    end
end

%% Initialise Optimisation Variables

MaxPower=[];
VarCounter=1;
for n=UserNum
    MaxPower(1,1,VarCounter)=Users{n}.ACChargingPowerHomeCharging;
    VarCounter=VarCounter+1;
end

Users{1}.ChargingMat=cell(size(TimesOfPreAlgo,1)+1,1);
%Users{1}.ChargingMatDemoUsers=cell(size(TimesOfPreAlgo,1)+1,1);
for k=1:size(Users{1}.ChargingMat,1)-1
    Users{1}.ChargingMat{k,2}=mod(TimesOfPreAlgo(k,1)-1,ControlPeriods) + 96*(TimeOfPreAlgo(k)<TimeOfPreAlgo(1));
    Users{1}.ChargingMat{k,1}=zeros(ControlPeriods-4*Time.StepInd*(k-1), NumCostCats, ceil(length(Time.Sim.Vec)/(Time.StepInd*24)), 'single');
    Users{1}.ChargingMatDemoUsers{k,2}=mod(TimesOfPreAlgo(k,1)-1,ControlPeriods) + 96*(TimeOfPreAlgo(k)<TimeOfPreAlgo(1));
    Users{1}.ChargingMatDemoUsers{k,1}=zeros(ControlPeriods-4*Time.StepInd*(k-1), NumCostCats, numel(DemoUsers), ceil(length(Time.Sim.Vec)/(Time.StepInd*24)), 'single');
end

Users{1}.AvailabilityMat=single(zeros(24*Time.StepInd, ceil(length(Time.Sim.Vec)/(Time.StepInd*24)), NumUsers));
DecissionGroups=cell(NumDecissionGroups,1);
SuccessfulResPoOffers=zeros(6*ConstantResPoPowerPeriodsScaling,1);

% DemandInds=tril(ones(ControlPeriods,ControlPeriods)).*(1:ControlPeriods);
% DemandInds(:,1)=0;
% DemandInds(DemandInds==0)=ControlPeriods+1;

CostsElectricityBase=zeros(1, 1, NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    CostsElectricityBase(1, 1, VarCounter)=double(Users{k}.PrivateElectricityPrice + Users{k}.NNEEnergyPrice);
end

%% Initialise Constraints

ConsSumPowerTSA=sparse(kron(sparse(eye(NumUsers/NumDecissionGroups, NumUsers/NumDecissionGroups)), repmat(sparse(diag(ones(ControlPeriods,1))),1,NumCostCats))); 
ConseqEnergyCPA=sparse(kron(sparse(eye(NumUsers/NumDecissionGroups, NumUsers/NumDecissionGroups)), ones(1,ControlPeriods*NumCostCats)));  % the ones of a single row represent the decission variable of one vehicle. the sum of all powers of one vehicle must no exceed the energy demand
ConsEnergyDemandTSA=sparse(kron(sparse(eye(NumUsers/NumDecissionGroups, NumUsers/NumDecissionGroups)), sparse(repmat(sparse(tril(ones(ControlPeriods))), 1, NumCostCats))));


ResPoOfferEqualiyMat1=sparse(zeros(ConstantResPoPowerPeriods-1,ConstantResPoPowerPeriods));
x=0:ConstantResPoPowerPeriods-2;
ResPoOfferEqualiyMat1(x*ConstantResPoPowerPeriods+1)=1;
ResPoOfferEqualiyMat1(x*ConstantResPoPowerPeriods+1+ConstantResPoPowerPeriods-1)=-1;
ResPoOfferEqualiyMat2=sparse(kron(eye(ControlPeriods/ConstantResPoPowerPeriods, ControlPeriods/ConstantResPoPowerPeriods), ResPoOfferEqualiyMat1));


ConseqResPoOfferA=sparse(repmat([zeros((ConstantResPoPowerPeriods-1)*ControlPeriods/ConstantResPoPowerPeriods,ControlPeriods*sum(CostCats(1:2))), ResPoOfferEqualiyMat2],1,NumUsers/NumDecissionGroups)); % one row represents one time step. within one Zeitscheibe the sum of reserve powers offered by all vehicles must be equal. hence it must be the power in timestep=1 must be the same as in timestep=2. this is represented by  a one followed by a -1 per vehicle



if TimeOfPreAlgo(1) <= TimeOfReserveMarketOffer
    ConsPeriods=(24*Time.StepInd-ShiftInds)/(4*Time.StepInd);
else
    ConsPeriods=(2*24*Time.StepInd-ShiftInds)/(4*Time.StepInd);
end

ConseqMatchLastResPoOffers4HA=repmat([zeros(ControlPeriods/ConstantResPoPowerPeriods,ControlPeriods*sum(CostCats(1:2))), kron(eye(ControlPeriods/(4*Time.StepInd)),kron(eye(4*Time.StepInd/ConstantResPoPowerPeriods),[zeros(1,ConstantResPoPowerPeriods-1),ones(1,1)]))], 1, NumUsers/NumDecissionGroups);
ConseqMatchLastResPoOffers4HA=sparse(ConseqMatchLastResPoOffers4HA(1:ceil(ControlPeriods/(ConstantResPoPowerPeriods)),:));

if ~Debugging
    LastResPoOffers=zeros(ceil(ControlPeriods/(ConstantResPoPowerPeriods)),1);
    LastResPoOffersSucessful4H=zeros(ceil(ControlPeriods/(ConstantResPoPowerPeriods)),1);
end

A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
Aeq=[ConseqEnergyCPA; ConseqResPoOfferA; ConseqMatchLastResPoOffers4HA];
lb=zeros(ControlPeriods, NumCostCats, NumUsers);
lb=lb(:);



% One row represents one constraint. The columns represent the decission
% variables. They are ordered in the following way: The first 192 decission
% variables represent the charging powers for the first 192 quaterly hours
% that could be used for charging using CostCat1 by User1. Then 192
% variables for CostCat2 two and 192 for CostCat3 for User1. Then the
% decission variables for all other users are concatenated in the same
% manner