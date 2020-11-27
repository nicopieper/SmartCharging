%% Control Variables

ControlPeriods=96*2;
CostCats=logical([1, 1, 1]);
NumCostCats=sum(CostCats);
ConstantRLPowerPeriods=4*Time.StepInd;
RLFactor=[0.8];
AEFactor=-0.1;
options = optimoptions('linprog','Algorithm','dual-simplex');
options.Display = 'off';
    

%% Prepare Users

for n=UserNum
    Users{n}.GridConvenientChargingAvailabilityControlPeriod=repmat(Users{n}.GridConvenientChargingAvailability,2,1);
	Users{n}.GridConvenientChargingAvailabilityControlPeriod=circshift(Users{n}.GridConvenientChargingAvailabilityControlPeriod, -ShiftInds);
    Users{n}.GridConvenientChargingAvailabilityControlPeriod=Users{n}.GridConvenientChargingAvailabilityControlPeriod(1:ControlPeriods);
end

%% Initialise Optimisation Variables

MaxPower=[];
VarCounter=1;
for n=UserNum
    MaxPower(1,1,VarCounter)=double(Users{n}.ACChargingPowerHomeCharging);
    VarCounter=VarCounter+1;
end

PreAlgoCounter=0;
Availability=[];
EnergyDemand=[];
ChargingMat=[];
ChargingVehicle=[];
ChargingType=[];
AvailabilityMat=[];
MaxEnergyChargableSoCTS=[];
MinEnergyRequiredTS=[];
MaxEnergyChargableDeadlockCP=[];
DecissionGroups=cell(NumDecissionGroups,1);

DemandInds=tril(ones(ControlPeriods,ControlPeriods)).*(1:ControlPeriods);
DemandInds(:,1)=0;
DemandInds(DemandInds==0)=ControlPeriods+1;

CostsElectricityBase=zeros(ControlPeriods, 1, NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    CostsElectricityBase(1:ControlPeriods, 1, VarCounter)=Users{k}.PrivateElectricityPrice + Users{k}.NNEEnergyPrice;
end

%% Initialise Constraints

ConsSumPowerTSA=sparse(kron(sparse(eye(NumUsers/NumDecissionGroups, NumUsers/NumDecissionGroups)), repmat(sparse(diag(ones(ControlPeriods,1))),1,NumCostCats))); 
ConseqEnergyCPA=sparse(kron(sparse(eye(NumUsers/NumDecissionGroups, NumUsers/NumDecissionGroups)), ones(1,ControlPeriods*NumCostCats)));  % the ones of a single row represent the decission variable of one vehicle. the sum of all powers of one vehicle must no exceed the energy demand
ConsEnergyDemandTSA=sparse(kron(sparse(eye(NumUsers/NumDecissionGroups, NumUsers/NumDecissionGroups)), sparse(repmat(sparse(tril(ones(ControlPeriods))), 1, NumCostCats))));


RLOfferEqualiyMat1=sparse(zeros(ConstantRLPowerPeriods-1,ConstantRLPowerPeriods));
x=0:ConstantRLPowerPeriods-2;
RLOfferEqualiyMat1(x*ConstantRLPowerPeriods+1)=1;
RLOfferEqualiyMat1(x*ConstantRLPowerPeriods+1+ConstantRLPowerPeriods-1)=-1;
RLOfferEqualiyMat2=sparse(kron(eye(ControlPeriods/ConstantRLPowerPeriods, ControlPeriods/ConstantRLPowerPeriods), RLOfferEqualiyMat1));
ConseqRLOfferA=sparse(repmat([zeros((ConstantRLPowerPeriods-1)*ControlPeriods/ConstantRLPowerPeriods,ControlPeriods*sum(CostCats(1:2))), RLOfferEqualiyMat2],1,NumUsers/NumDecissionGroups)); % one row represents one time step. within one Zeitscheibe the sum of reserve powers offered by all vehicles must be equal. hence it must be the power in timestep=1 must be the same as in timestep=2. this is represented by  a one followed by a -1 per vehicle


if TimeOfPreAlgo1 <= TimeOfReserveMarketOffer
    ConsPeriods=(24*Time.StepInd-ShiftInds)/(4*Time.StepInd);
else
    ConsPeriods=(2*24*Time.StepInd-ShiftInds)/(4*Time.StepInd);
end

%ConseqMatchLastReservePowerOffers4HA=repmat([zeros(ControlPeriods/(4*Time.StepInd),ControlPeriods*sum(CostCats(1:2))), kron(eye(ControlPeriods/(4*Time.StepInd), ControlPeriods/(4*Time.StepInd)),ones(1,4*Time.StepInd))], 1, NumUsers/NumDecissionGroups);
ConseqMatchLastReservePowerOffers4HA=repmat([zeros(ControlPeriods/ConstantRLPowerPeriods,ControlPeriods*sum(CostCats(1:2))), kron(eye(ControlPeriods/(4*Time.StepInd)),kron(eye(4*Time.StepInd/ConstantRLPowerPeriods),[zeros(1,ConstantRLPowerPeriods-1),ones(1,1)]))], 1, NumUsers/NumDecissionGroups);


%ConseqMatchLastReservePowerOffers4HA=sparse(ConseqMatchLastReservePowerOffers4HA(1:ConsPeriods,:));
ConseqMatchLastReservePowerOffers4HA=sparse(ConseqMatchLastReservePowerOffers4HA(1:ceil(ControlPeriods/(ConstantRLPowerPeriods)),:));
%ConseqMatchLastReservePowerOffers4Hb=zeros(ConsPeriods,1);
LastReservePowerOffers4Hb=zeros(ceil(ControlPeriods/(ConstantRLPowerPeriods)),1);

A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
Aeq=[ConseqEnergyCPA; ConseqRLOfferA;ConseqMatchLastReservePowerOffers4HA];
lb=zeros(ControlPeriods, NumCostCats, NumUsers);
lb=lb(:);
