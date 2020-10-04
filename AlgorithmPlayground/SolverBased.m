%% 
clearvars -except DayaheadReal1QH ResEnPricesRealQH ResPoDemRealQH ResPoPricesReal4H TimeVec Users PVPlants NumUsersTemp
NumUsers=400;
Periods=length(TimeVec);
ControlPeriods=96*1.5;
ElectricityBasePrice=0.222;
CostCats=3;
ConstantRLPowerPeriods=16;


if ~exist("Users", "var")
    load('C:\Users\nicop\MATLAB\SmartCharging\Simulation\Users_1.2_800_2020-09-17_17-06.mat');
end
UsersT=Users(2:NumUsers+1);
for n=1:NumUsers
    if mod(n,2)==1
        UsersT{n}.PVPlantExists=true;
        UsersT{n}.PVPointer=mod(n-1, 482)+1;
    else
        UsersT{n}.PVPlantExists=false;
    end
end

NumUsersTemp=NumUsers;

MaxPower=[];
for n=1:NumUsers
    MaxPower(1,1,n)=double(UsersT{n}.ACChargingPowerHomeCharging);
end

%% 
options = optimoptions('linprog','Algorithm','dual-simplex');
options.Display = 'off';

tic
Availability=[];
EnergyDemand=[];
ChargingMat=[];
ChargingVehicle=[];
ChargingType=[];
AvailabilityMat=[];
ConsSumPowerA=sparse(kron(sparse(eye(NumUsers, NumUsers)), repmat(sparse(diag(ones(ControlPeriods,1))),1,CostCats)));
ConsEnergyAeq=sparse(kron(sparse(eye(NumUsers, NumUsers)),ones(1,ControlPeriods*CostCats)));

RLOfferEqualiyMat1=sparse(zeros(ConstantRLPowerPeriods-1,ConstantRLPowerPeriods));
x=0:ConstantRLPowerPeriods-2;
RLOfferEqualiyMat1(x*ConstantRLPowerPeriods+1)=1;
RLOfferEqualiyMat1(x*ConstantRLPowerPeriods+1+ConstantRLPowerPeriods-1)=-1;

RLOfferEqualiyMat2=sparse(kron(eye(ControlPeriods/ConstantRLPowerPeriods, ControlPeriods/ConstantRLPowerPeriods), RLOfferEqualiyMat1));
ConsRLOfferAeq=sparse(repmat([zeros((ConstantRLPowerPeriods-1)*ControlPeriods/ConstantRLPowerPeriods,ControlPeriods*2), RLOfferEqualiyMat2],1,NumUsers));
ConsRLOfferbeq=zeros((ConstantRLPowerPeriods-1)*ControlPeriods/ConstantRLPowerPeriods,1);

for k=1:Periods/96-1
    CalcOptVars;
    
    ConsSumPowerb=repelem(MaxPower(:)/4, ControlPeriods);
    ConsPowerb=[reshape(repelem(MaxPower(:)/4, ControlPeriods), ControlPeriods, 1, []), PVPower/4, reshape(repelem(MaxPower(:)/4, ControlPeriods), ControlPeriods, 1, [])];
    ConsPowerb=ConsPowerb(:);
    ConsEnergybeq=squeeze(min(EnergyDemand, sum(Availability, 1).*MaxPower/4));
    
    A=[ConsSumPowerA];% ConsPowerA];
    b=[ConsSumPowerb(:)];% ConsPowerb];
    Aeq=[ConsEnergyAeq;ConsRLOfferAeq];
    beq=[ConsEnergybeq;ConsRLOfferbeq];
    lb=zeros(ControlPeriods, CostCats, NumUsers);
    ub=ConsPowerb;
    
    Costf=Costs(:);   
    [x,fval]=linprog(Costf,A,b,Aeq,beq,lb,ub, options);
    
%     CostFunction=@(y) sum(Costs(:).*y);
%     x0=zeros(ControlPeriods*CostCats*NumUsers,1);
%     [x1,fval1]=fmincon(CostFunction,x0,A,b,Aeq,beq,lb,ub);
    
    ChargingMat(:,:,:,k)=reshape(x,ControlPeriods, CostCats, NumUsers);
    ChargingVehicle=[ChargingVehicle; sum(ChargingMat(1:96,:,:,k),2)];
    ChargingType=[ChargingType; sum(ChargingMat(1:96,:,:,k),3)];
    AvailabilityMat=[AvailabilityMat, Availability(1:96,1,:)];
    
    if sum(x)<ConsEnergybeq
        1
    end
    
    if sum(reshape(x,ControlPeriods, CostCats, NumUsers)>0 & Availability==0)>1
        error("Availability was not considered")
    end

end
ChargingSum=sum(ChargingVehicle, 3);
[sum(ChargingType(:,1,:),'all'), sum(ChargingType(:,2,:),'all'), sum(ChargingType(:,3,:),'all')]/sum(ChargingType(:,:,:),'all')
toc

figure
Load=mean(reshape(ChargingType',3,96,[]),3)';
x = 1:96;
y = mean(reshape(ChargingSum, 96, []), 2)';
z = zeros(size(x));
col = (Load./repmat(max(Load, [], 2),1,3))';
surface([x;x],[y;y],[z;z],[permute(repmat(col,1,1,2),[3,2,1])], 'facecol','no', 'edgecol','interp', 'linew',2);
xticks(1:16:96)
xticklabels({datestr(TimeVec(1:16:96),'HH:MM')})

hold on
plot(squeeze(mean(reshape(ChargingType(:,1),96,[],1),2)), "LineWidth", 1.2, "Color", [1, 0, 0])
plot(squeeze(mean(reshape(ChargingType(:,2),96,[],1),2)), "LineWidth", 1.2, "Color", [0, 1, 0])
plot(squeeze(mean(reshape(ChargingType(:,3),96,[],1),2)), "LineWidth", 1.2, "Color", [0, 0, 1])
xticks(1:16:96)
xticklabels({datestr(TimeVec(1:16:96),'HH:MM')})
legend(["All", "Spotmarket", "PV", "Secondary Reserve Energy"])

figure
plot(mean(sum(AvailabilityMat,3),2))




    

    





%%

% Periods=2;
% NumUsers=2;
% Costs=[30; 40];
% MaxPower=[3,6];
% EnergyDemand=[4,8];
% 
% A=eye(NumUsers*Periods);
% Aeq=zeros(NumUsers, Periods*NumUsers);
% for n=1:NumUsers
%     Aeq(n,(n-1)*Periods+1:(n)*Periods)=ones(1,Periods);
% end
% 
% b=repelem(MaxPower,2);
% beq=EnergyDemand;
% 
% f=repmat(Costs, 2,1)';
% 
% tic
% [x,fval]=linprog(f,A,b,Aeq,beq)
% toc
% 
% fun=@(x) sum(repmat(Costs, NumUsers,1).*x);
% x0=zeros(Periods*NumUsers,1);
% tic
% [x1,fval]=fmincon(fun,x0,A,b,Aeq,beq)
% toc

% working







% A=[eye(NumUsers*Periods); -eye(NumUsers*Periods)]; % first matrix represents MaxChargingPower. Each diagonal cell corresponds to one time step of one vehicle. The first cell represents vehicle one at time step one. The following diagonal cells represents the sesequent time steps of vehicle until all time steps are coverd. then follows vehicle two. the next matrix is comparable but for charging>=0 criterion
% Aeq=zeros(NumUsers, Periods*NumUsers); % one row represents one vehicle. the first column represents timestep one of vehicle one. the second column is time step two of vehicle one and so on until all time step are covered for vehicle one. then the next column represents time step one of vehicle two and so on.
% for n=1:NumUsers % the summed charged energy in all time steps must equal the energy demand for each vehicle
%     Aeq(n,(n-1)*Periods+1:(n)*Periods)=ones(1,Periods);
% end
% 
% b=[repelem(MaxPower,Periods) zeros(1, NumUsers*Periods)]; % first matrix: in no time step the maxpower can be exceeded. second matrix: in no timestep the charging power can be smaller zero
% b(Availability(:) == 0)=0; % in unavailable timestep charging power must be zero
% beq=EnergyDemand; % within all time step of one vehicle the energy demand must be satisfied
% 
% f=repmat(Costs, NumUsers,1)'; % repeat the costs for each vehicle. first cell represents costs for vehicle one at time step one, then time step increases until all timesteps are covered. then start costs for vehicle two.
% 
% x=linprog(f,A,b,Aeq,beq);
% x=reshape(x,[],NumUsers);
% toc

