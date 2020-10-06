%% Control Variables

ControlPeriods=96*1.5;
CostCats=logical([1, 1, 1]);
NumCostCats=sum(CostCats);
ConstantRLPowerPeriods=16;
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

%% Initialise Constraints

ConsSumPowerA=sparse(kron(sparse(eye(NumUsers, NumUsers)), repmat(sparse(diag(ones(ControlPeriods,1))),1,NumCostCats)));
ConsEnergyAeq=sparse(kron(sparse(eye(NumUsers, NumUsers)),ones(1,ControlPeriods*NumCostCats)));

RLOfferEqualiyMat1=sparse(zeros(ConstantRLPowerPeriods-1,ConstantRLPowerPeriods));
x=0:ConstantRLPowerPeriods-2;
RLOfferEqualiyMat1(x*ConstantRLPowerPeriods+1)=1;
RLOfferEqualiyMat1(x*ConstantRLPowerPeriods+1+ConstantRLPowerPeriods-1)=-1;
RLOfferEqualiyMat2=sparse(kron(eye(ControlPeriods/ConstantRLPowerPeriods, ControlPeriods/ConstantRLPowerPeriods), RLOfferEqualiyMat1));
ConsRLOfferAeq=sparse(repmat([zeros((ConstantRLPowerPeriods-1)*ControlPeriods/ConstantRLPowerPeriods,ControlPeriods*2), RLOfferEqualiyMat2],1,NumUsers));
ConsRLOfferbeq=zeros((ConstantRLPowerPeriods-1)*ControlPeriods/ConstantRLPowerPeriods,1);