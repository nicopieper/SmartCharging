%% Control Variables

ControlPeriods=96*2;
CostCats=logical([1, 1, 1]);
NumCostCats=sum(CostCats);
ConstantRLPowerPeriods=4*Time.StepInd;
RLFactor=[0.8];
AEFactor=-0.1;
options = optimoptions('linprog','Algorithm','dual-simplex');
options.Display = 'off';
options1 = optimoptions('intlinprog','Display','off');
    

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
a1=0;
a2=0;

DemandInds=tril(ones(ControlPeriods,ControlPeriods)).*(1:ControlPeriods);
DemandInds(:,1)=0;
DemandInds(DemandInds==0)=ControlPeriods+1;

%% Initialise Constraints

ConsSumPowerTSA=sparse(kron(sparse(eye(NumUsers, NumUsers)), repmat(sparse(diag(ones(ControlPeriods,1))),1,NumCostCats))); 
ConsEnergyCPAeq=sparse(kron(sparse(eye(NumUsers, NumUsers)), ones(1,ControlPeriods*NumCostCats)));  % the ones of a single row represent the decission variable of one vehicle. the sum of all powers of one vehicle must no exceed the energy demand

ConsEnergyDemandTSA=sparse(kron(sparse(eye(NumUsers, NumUsers)), sparse(repmat(sparse(tril(ones(ControlPeriods))), 1, NumCostCats))));


RLOfferEqualiyMat1=sparse(zeros(ConstantRLPowerPeriods-1,ConstantRLPowerPeriods));
x=0:ConstantRLPowerPeriods-2;
RLOfferEqualiyMat1(x*ConstantRLPowerPeriods+1)=1;
RLOfferEqualiyMat1(x*ConstantRLPowerPeriods+1+ConstantRLPowerPeriods-1)=-1;
RLOfferEqualiyMat2=sparse(kron(eye(ControlPeriods/ConstantRLPowerPeriods, ControlPeriods/ConstantRLPowerPeriods), RLOfferEqualiyMat1));
ConsRLOfferAeq=sparse(repmat([zeros((ConstantRLPowerPeriods-1)*ControlPeriods/ConstantRLPowerPeriods,ControlPeriods*sum(CostCats(1:2))), RLOfferEqualiyMat2],1,NumUsers)); % one row represents one time step. within one Zeitscheibe the sum of reserve powers offered by all vehicles must be equal. hence it must be the power in timestep=1 must be the same as in timestep=2. this is represented by  a one followed by a -1 per vehicle
ConsRLOfferbeq=zeros((ConstantRLPowerPeriods-1)*ControlPeriods/ConstantRLPowerPeriods,1);

ConsMatchLastReservePowerOffers4HAeq=repmat([zeros(ControlPeriods/(4*Time.StepInd),ControlPeriods*sum(CostCats(1:2))), kron(eye(ControlPeriods/(4*Time.StepInd), ControlPeriods/(4*Time.StepInd)),ones(1,4*Time.StepInd))], 1, NumUsers);
ConsMatchLastReservePowerOffers4HAeq=ConsMatchLastReservePowerOffers4HAeq(1:(24*Time.StepInd-ShiftInds)/(4*Time.StepInd),:);

if TimeOfForecast <= TimeOfReserveMarketOffer
    ConsPeriods=(24*Time.StepInd-ShiftInds)/(4*Time.StepInd);
else
    ConsPeriods=(2*24*Time.StepInd-ShiftInds)/(4*Time.StepInd);
end
ConsMatchLastReservePowerOffers4HAeq=repmat([zeros(ControlPeriods/(4*Time.StepInd),ControlPeriods*sum(CostCats(1:2))), kron(eye(ControlPeriods/(4*Time.StepInd), ControlPeriods/(4*Time.StepInd)),ones(1,4*Time.StepInd))], 1, NumUsers);
ConsMatchLastReservePowerOffers4HAeq=ConsMatchLastReservePowerOffers4HAeq(1:ConsPeriods,:);
ConsMatchLastReservePowerOffers4Hbeq=zeros(ConsPeriods,1);

A=[ConsSumPowerTSA; ConsEnergyDemandTSA; -ConsEnergyDemandTSA];
Aeq=[ConsEnergyCPAeq; ConsRLOfferAeq;ConsMatchLastReservePowerOffers4HAeq];
lb=zeros(ControlPeriods, NumCostCats, NumUsers);
lb=lb(:);
