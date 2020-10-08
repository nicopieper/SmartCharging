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

for n=2:NumUsers+1
    Users{n}.GridConvenientChargingAvailabilityControlPeriod=repmat(Users{n}.GridConvenientChargingAvailability,2,1);
	Users{n}.GridConvenientChargingAvailabilityControlPeriod=circshift(Users{n}.GridConvenientChargingAvailabilityControlPeriod, -ShiftInds);
    Users{n}.GridConvenientChargingAvailabilityControlPeriod=Users{n}.GridConvenientChargingAvailabilityControlPeriod(1:ControlPeriods);
end

%% Initialise Optimisation Variables

MaxPower=[];
for n=2:NumUsers+1
    MaxPower(1,1,n-1)=double(Users{n}.ACChargingPowerHomeCharging);
end

Availability=[];
EnergyDemand=[];
ChargingMat=[];
ChargingVehicle=[];
ChargingType=[];
AvailabilityMat=[];
DemandInds=tril(ones(ControlPeriods,ControlPeriods)).*(1:ControlPeriods);
DemandInds(DemandInds==0)=ControlPeriods+1;

%% Initialise Constraints

ConsSumPowerA=sparse(kron(sparse(eye(NumUsers, NumUsers)), repmat(sparse(diag(ones(ControlPeriods,1))),1,NumCostCats))); 
ConsEnergyAeq=sparse(kron(sparse(eye(NumUsers, NumUsers)),ones(1,ControlPeriods*NumCostCats)));  % the ones of a single row represent the decission variable of one vehicle. the sum of all powers of one vehicle must no exceed the energy demand

ConsEnergyDemandA=sparse(kron(sparse(eye(NumUsers, NumUsers)), sparse(repmat(sparse(tril(ones(ControlPeriods))), 1, NumCostCats))));


RLOfferEqualiyMat1=sparse(zeros(ConstantRLPowerPeriods-1,ConstantRLPowerPeriods));
x=0:ConstantRLPowerPeriods-2;
RLOfferEqualiyMat1(x*ConstantRLPowerPeriods+1)=1;
RLOfferEqualiyMat1(x*ConstantRLPowerPeriods+1+ConstantRLPowerPeriods-1)=-1;
RLOfferEqualiyMat2=sparse(kron(eye(ControlPeriods/ConstantRLPowerPeriods, ControlPeriods/ConstantRLPowerPeriods), RLOfferEqualiyMat1));
ConsRLOfferAeq=sparse(repmat([zeros((ConstantRLPowerPeriods-1)*ControlPeriods/ConstantRLPowerPeriods,ControlPeriods*sum(CostCats(1:2))), RLOfferEqualiyMat2],1,NumUsers)); % one row represents one time step. within one Zeitscheibe the sum of reserve powers offered by all vehicles must be equal. hence it must be the power in timestep=1 must be the same as in timestep=2. this is represented by  a one followed by a -1 per vehicle
ConsRLOfferbeq=zeros((ConstantRLPowerPeriods-1)*ControlPeriods/ConstantRLPowerPeriods,1);

ConsMatchLastReservePowerOffersAeq=repmat([zeros(ControlPeriods/(4*Time.StepInd),ControlPeriods*sum(CostCats(1:2))), kron(eye(ControlPeriods/(4*Time.StepInd), ControlPeriods/(4*Time.StepInd)),ones(1,4*Time.StepInd))], 1, NumUsers);
ConsMatchLastReservePowerOffersAeq=ConsMatchLastReservePowerOffersAeq(1:(24*Time.StepInd-ShiftInds)/(4*Time.StepInd),:);

if TimeOfForecast <= TimeOfReserveMarketOffer
    ConsPeriods=(24*Time.StepInd-ShiftInds)/(4*Time.StepInd);
else
    ConsPeriods=(2*24*Time.StepInd-ShiftInds)/(4*Time.StepInd);
end
ConsMatchLastReservePowerOffersAeq=repmat([zeros(ControlPeriods/(4*Time.StepInd),ControlPeriods*sum(CostCats(1:2))), kron(eye(ControlPeriods/(4*Time.StepInd), ControlPeriods/(4*Time.StepInd)),ones(1,4*Time.StepInd))], 1, NumUsers);
ConsMatchLastReservePowerOffersAeq=ConsMatchLastReservePowerOffersAeq(1:ConsPeriods,:);
ConsMatchLastReservePowerOffersbeq=zeros(ConsPeriods,1);

A=[ConsSumPowerA; ConsEnergyDemandA; -ConsEnergyDemandA];
Aeq=[ConsEnergyAeq; ConsRLOfferAeq;ConsMatchLastReservePowerOffersAeq];
lb=zeros(ControlPeriods, NumCostCats, NumUsers);
