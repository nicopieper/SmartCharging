%%

Periods=2;
Vehicles=2;
Costs=[30; 40];
MaxPower=[3,6];
EnergyDemand=[4,8];

A=eye(Vehicles*Periods);
Aeq=zeros(Vehicles, Periods*Vehicles);
for n=1:Vehicles
    Aeq(n,(n-1)*Periods+1:(n)*Periods)=ones(1,Periods);
end

b=repelem(MaxPower,2);
beq=EnergyDemand;

f=repmat(Costs, 2,1)';

x=linprog(f,A,b,Aeq,beq);

% working

%% 
tic
Periods=2;
Vehicles=10000;
Costs=[30; 40];
MaxPower=TruncatedGaussian(2, [3,11]-7,1,Vehicles)+7;
EnergyDemand=MaxPower.*(TruncatedGaussian(0.1, [1.2 1.9]-1.5,1,Vehicles)+1.5);
Availability=ones(Periods, Vehicles);
for n=1:Vehicles
    Availability(randi([1,Periods],randi([1,6],1,1),1), n)=0;
end

%% 
tic

A=[eye(Vehicles*Periods); -eye(Vehicles*Periods)]; % first matrix represents MaxChargingPower. Each diagonal cell corresponds to one time step of one vehicle. The first cell represents vehicle one at time step one. The following diagonal cells represents the sesequent time steps of vehicle until all time steps are coverd. then follows vehicle two. the next matrix is comparable but for charging>=0 criterion
Aeq=zeros(Vehicles, Periods*Vehicles); % one row represents one vehicle. the first column represents timestep one of vehicle one. the second column is time step two of vehicle one and so on until all time step are covered for vehicle one. then the next column represents time step one of vehicle two and so on.
for n=1:Vehicles % the summed charged energy in all time steps must equal the energy demand for each vehicle
    Aeq(n,(n-1)*Periods+1:(n)*Periods)=ones(1,Periods);
end

b=[repelem(MaxPower,Periods) zeros(1, Vehicles*Periods)]; % first matrix: in no time step the maxpower can be exceeded. second matrix: in no timestep the charging power can be smaller zero
b(Availability(:) == 0)=0; % in unavailable timestep charging power must be zero
beq=EnergyDemand; % within all time step of one vehicle the energy demand must be satisfied

f=repmat(Costs, Vehicles,1)'; % repeat the costs for each vehicle. first cell represents costs for vehicle one at time step one, then time step increases until all timesteps are covered. then start costs for vehicle two.

x=linprog(f,A,b,Aeq,beq);
x=reshape(x,[],Vehicles);
toc