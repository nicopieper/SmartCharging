%% Define target groups

if ~exist("Users", "var")
    StorageFiles=dir(strcat(Path.Simulation, Dl, "Users_*"));
    [~, StorageInd]=max(datetime({StorageFiles.date}, "InputFormat", "dd-MMM-yyyy HH:mm:ss", 'Locale', 'de_DE'));
    load(strcat(Path.Simulation, Dl, StorageFiles(StorageInd).name))
end

Logbook="LogbookBase";

Targets=["small"; "medium"; "large"; "transporter"];
% Targets=["one user"; "only one user"; "several users"; "undefined"];
% Targets=["company car"; "fleet vehicle"; "undefined"];
% Targets=[0.5; 1; 3; 1000];
% Targets=[hours(10); hours(12); hours(14); hours(24)];

TargetGroups=cell(length(Targets),1);
for n=2:length(Users)
    TargetNum=find(strcmp(Users{n}.VehicleSize,Targets),1);
%     TargetNum=find(strcmp(Users{n}.VehicleUtilisation,Targets),1);
%     TargetNum=find(Users{n}.DistanceCompanyToHome<Targets,1);
%     TargetNum=find(Users{n}.AvgHomeParkingTime<Targets,1);

    TargetGroups{TargetNum}=[TargetGroups{TargetNum} n];
end
ExistingTargets=find(cellfun('length', TargetGroups)>0)';
% ExistingTargets=[1,2, 3,4];
NumExistingTargets=numel(ExistingTargets);
ShowTargets=false;
ShowAll=true;
ShowELaad=true;
ClearWorkspace=true;

DataTable=table(Targets(ExistingTargets));
Location=["Home"; "Other"];

if ShowELaad && ~exist('ELaad', 'var')
    GetELaadData;
end

DayVecHourly=datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis');
DayVecQuaterly=datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):minutes(15):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis')-minutes(15);

%% Charging frequency

ChargeProcesses=cell(length(Targets),2);
ChargeProcessesPerWeek=cell(length(Targets),2);
for k=ExistingTargets
    for n=TargetGroups{k}
        Users{n}.ChargeProcessesHomeBase=sum(ismember(Users{n}.(Logbook)(2:end,1),4:5) & ~ismember(Users{n}.(Logbook)(1:end-1,1), 4:5));
        Users{n}.ChargeProcessesHomeBase1=sum(sum(Users{n}.(Logbook)(2:end,5:7),2)>0 & sum(Users{n}.(Logbook)(1:end-1,5:7),2)==0);
        Users{n}.ChargeProcessesOtherBase=sum(ismember(Users{n}.(Logbook)(2:end,1),6:7) & ~ismember(Users{n}.(Logbook)(1:end-1,1),6:7));
        a=find(ismember(Users{n}.(Logbook)(2:end,1),6:7) & ~ismember(Users{n}.(Logbook)(1:end-1,1),6:7));
        Users{n}.ChargeProcessesOtherBase1=sum(Users{n}.(Logbook)(2:end,8)>0 & Users{n}.(Logbook)(1:end-1,8)==0);
        b=find(Users{n}.(Logbook)(2:end,8)>0 & Users{n}.(Logbook)(1:end-1,8)==0);
        ChargeProcesses{k,1}(n)=Users{n}.ChargeProcessesHomeBase1;
        ChargeProcesses{k,2}(n)=Users{n}.ChargeProcessesOtherBase;
    end
    ChargeProcessesPerWeek{k,1}=sum(ChargeProcesses{k,1})/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1))*7/length(TargetGroups{k});
    ChargeProcessesPerWeek{k,2}=sum(ChargeProcesses{k,2})/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1))*7/length(TargetGroups{k});
end
ChargeProcessesPerWeek=ChargeProcessesPerWeek(ExistingTargets,:);
DataTable.ChargingPorcessesPerWeek=round(cell2mat(ChargeProcessesPerWeek)*100)/100;
disp(strcat("The users charge in average ", num2str(mean(cell2mat(ChargeProcessesPerWeek(:,1)))), " times per week at home and ", num2str(mean(cell2mat(ChargeProcessesPerWeek(:,2))))," times per week at ohter locations"))

%% Energy charged per charging process

EnergyPerChargingProcess=cell(length(Targets),2);
for k=ExistingTargets
    EnergyPerChargingProcess{k,1}=-ones(length(Users)-1*1000,1);
    EnergyPerChargingProcess{k,2}=-ones(length(Users)-1*1000,1);
    cols=[(5:7)', [8;0;0]];
    for col=cols
        col=col(col~=0);
        counter=1;
        for n=TargetGroups{k}
            ChargingBlocks=[find(sum(Users{n}.(Logbook)(1:end,col),2)>0 & [0; sum(Users{n}.(Logbook)(1:end-1,col),2)]==0), find(sum(Users{n}.(Logbook)(1:end,col),2)>0 & [sum(Users{n}.(Logbook)(2:end,col),2);0]==0)];
            for h=1:size(ChargingBlocks,1)
                % Target 2, other last two rows have way too high energy
                % charged. needs to be fixed!
                EnergyPerChargingProcess{k,find(sum(col==cols,1))}(counter,1)=sum(Users{n}.(Logbook)(ChargingBlocks(h,1):ChargingBlocks(h,2),col), 'all');
                counter=counter+1;
            end
        end
        EnergyPerChargingProcess{k,find(sum(col==cols,1))}=EnergyPerChargingProcess{k,find(sum(col==cols,1))}(EnergyPerChargingProcess{k,find(sum(col==cols,1))}~=-1);
    end
end

EnergyPerChargingProcess=EnergyPerChargingProcess(ExistingTargets,:);
figure(10)
clf
for col=1:2
    subplot(2,1,col)
    hold on
    l=legend;
    if ShowAll
        [counts, centers]=hist(cat(1, EnergyPerChargingProcess{:,col})/1000, 0:4:100);
        plot(centers, counts./sum(counts))
        legappend(l, "Simulation");
    end
    if ShowTargets
        for k=1:NumExistingTargets
            [counts, centers]=hist(EnergyPerChargingProcess{k, col}/1000, 0:4:100);
            plot(centers, counts./sum(counts))
            legappend(l, Targets(ExistingTargets(k)));
        end
    end
    if ShowELaad
        [counts, centers]=hist(ELaad.EnergyDemand(:,col+1), 0:4:100);
        plot(centers, counts./sum(counts))
        legappend(l, "ELaad");
    end
    title(strcat("Energy per charging event in kWh ", Location(col)))
    xlabel("Energy in kWh")
    ylabel("Probability")
end

disp(strcat("In average per charging event, ", num2str(mean(cell2mat(EnergyPerChargingProcess(:,1))/1000)), " kWh were charged at home and ", num2str(mean(cell2mat(EnergyPerChargingProcess(:,2))/1000)), " kWh at other places"))

DataTable.EnergyPerChargingProcess=round(cellfun(@mean,EnergyPerChargingProcess)/1000*100)/100;

%% Energy charged per User

EnergyCharged=cell(length(Targets),2);
for k=ExistingTargets
    for n=TargetGroups{k}
        EnergyCharged{k,1}(end+1)=sum(Users{n}.(Logbook)(1:end,5:7),'all');
        EnergyCharged{k,2}(end+1)=sum(Users{n}.(Logbook)(1:end,8));
    end
end
EnergyCharged=EnergyCharged(ExistingTargets,:);
EnergyChargedPerDayPerVehicle=cellfun(@sum,EnergyCharged)/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1))/1000./cellfun(@length, TargetGroups(ExistingTargets));
HomeChargingQuote=sum(EnergyChargedPerDayPerVehicle(:,1))/sum(EnergyChargedPerDayPerVehicle,'all');
disp(strcat("The users charged in average ", num2str(sum(cellfun(@sum, EnergyCharged), 'all')/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1))/1000/length(Users)-1), " kWh per day"))
disp(strcat(num2str(HomeChargingQuote*100), " % of all charging events took place at home"))
% DataTable.EnergyChargedPerDay=

%% Arrival and Connection time at charging point

ConnectionTime=cell(length(Targets),2);
ArrivalTimes=cell(length(Targets),2);
for k=ExistingTargets
    ConnectionTime{k,1}=[];
    ConnectionTime{k,2}=[];
    ArrivalTimes{k,1}=NaT(0,0, 'TimeZone', 'Africa/Tunis');
    ArrivalTimes{k,2}=NaT(0,0, 'TimeZone', 'Africa/Tunis');
    for n=TargetGroups{k}
        ConnectionBlocksHome=[find(ismember(Users{n}.(Logbook)(1:end,1),4:5) & ~ismember([0;Users{n}.(Logbook)(1:end-1,1)],4:5)), find(ismember(Users{n}.(Logbook)(1:end,1),4:5) & ~ismember([Users{n}.(Logbook)(2:end,1);0],4:5))];
        ConnectionBlocksOther=[find(ismember(Users{n}.(Logbook)(1:end,1),6:7) & ~ismember([0;Users{n}.(Logbook)(1:end-1,1)],6:7)), find(ismember(Users{n}.(Logbook)(1:end,1),6:7) & ~ismember([Users{n}.(Logbook)(2:end,1);0],6:7))];
        ConnectionTime{k,1}=[ConnectionTime{k,1}; (ConnectionBlocksHome(:,2)-ConnectionBlocksHome(:,1)+1)*Time.StepMin];
        ConnectionTime{k,2}=[ConnectionTime{k,2}; (ConnectionBlocksOther(:,2)-ConnectionBlocksOther(:,1)+1)*Time.StepMin];
        ArrivalTimes{k,1}=[ArrivalTimes{k,1}; datetime(ones(length(ConnectionBlocksHome),1),ones(length(ConnectionBlocksHome),1),ones(length(ConnectionBlocksHome),1), hour(Users{1}.Time.Vec(ConnectionBlocksHome(:,1))), minute((Users{1}.Time.Vec(ConnectionBlocksHome(:,1)))),zeros(length(ConnectionBlocksHome),1), 'TimeZone', 'Africa/Tunis')];
        ArrivalTimes{k,2}=[ArrivalTimes{k,2}; datetime(ones(length(ConnectionBlocksOther),1),ones(length(ConnectionBlocksOther),1),ones(length(ConnectionBlocksOther),1), hour(Users{1}.Time.Vec(ConnectionBlocksOther(:,1))), minute((Users{1}.Time.Vec(ConnectionBlocksOther(:,1)))),zeros(length(ConnectionBlocksOther),1), 'TimeZone', 'Africa/Tunis')];
    end
end
ConnectionTime=ConnectionTime(ExistingTargets,:);
ArrivalTimes=ArrivalTimes(ExistingTargets,:);

figure(11)
clf
for col=1:2
    subplot(2,1,col)
    hold on
    l=legend;
    if ShowAll
        [counts, centers]=hist(cat(1, ConnectionTime{:,col}), (0:2:48)*60);
        plot(centers/60, counts./sum(counts))
        legappend(l, "Simulation");
    end
    if ShowTargets
        for k=1:NumExistingTargets
            [counts, centers]=hist(ConnectionTime{k,col}, (0:2:48)*60);
            plot(centers/60, counts./sum(counts))
            legappend(l, Targets(ExistingTargets(k)));
        end
    end
    if ShowELaad
        [counts, centers]=hist(ELaad.ConnectionTime(:,col+1), (0:2:48));
        plot(centers, counts./sum(counts))
        legappend(l, "ELaad");
    end
    title(strcat("Connection to charging point duration at ", Location(col)))
    xlabel("Duration in hours")
    ylabel("Probability")
end

figure(12)
clf
for col=1:2
    subplot(2,1,col)
    hold on
    l=legend;
    if ShowAll
        [counts, edges]=histcounts(cat(1, ArrivalTimes{:,col}), DayVecHourly);
        centers=edges(1:end-1)+(edges(2)-edges(1))/2;
        plot(centers, counts./sum(counts))
        legappend(l, "Simulation");
    end
    if ShowTargets
        [nrows,~] = cellfun(@size, ArrivalTimes(:,col));
        for k=find(nrows>0)'
            [counts, edges]=histcounts(ArrivalTimes{k,col}, DayVecHourly);
            centers=edges(1:end-1)+(edges(2)-edges(1))/2;
            plot(centers, counts./sum(counts))
            legappend(l, Targets(ExistingTargets(k)));
        end
    end
    if ShowELaad
        plot(datetime(1,1,1,0,30,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(1,1,1,23,30,0, 'TimeZone', 'Africa/Tunis'), sum(reshape(ELaad.ArrivalTimes(:,col), 4, []))/100)
        legappend(l, "ELaad");
    end
    xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
    xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
    xlabel("Time of date")
    ylabel("Probability")
    title(strcat("Arrival time at charging point at ", Location(col)))
end

%% Load Profile

Load=cell(length(Targets),2);
for k=ExistingTargets
    Load{k,1}=zeros(96,1);
    Load{k,2}=zeros(96,1);
    for n=TargetGroups{k}
        Load{k,1}=Load{k,1}+sum(reshape(sum(Users{n}.(Logbook)(:,5:7), 2), 96, []),2)*4/1e3/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1));
        Load{k,2}=Load{k,2}+sum(reshape(Users{n}.(Logbook)(:,8), 96, []),2)*4/1e3/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1));
    end
    Load{k,1}=Load{k,1};
    Load{k,2}=Load{k,2};
end
Load=Load(ExistingTargets,:);

figure(13)
clf
for col=1:2
    subplot(2,1,col)
    hold on
    l=legend;
    if ShowAll
        plot(DayVecQuaterly, sum(cat(2, Load{:,col}),2)/numel(cat(2,TargetGroups{:})))
        legappend(l, "Simulation");
    end
    if ShowTargets
        for k=1:NumExistingTargets
            plot(DayVecQuaterly, Load{k,col}/numel(TargetGroups{ExistingTargets(k)}))
            legappend(l, Targets(ExistingTargets(k)));
        end
    end
    title(strcat("Load profile of fleet at ", Location(col)))
    xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
    xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
    xlabel("Time of date")
    ylabel("Load per user in kW")
end

%% Mileage and Consumption

MileageYearKm=0;
AvgConsumption=[];
for n=2:length(Users)
    MileageYearKm=MileageYearKm+Users{n}.AverageMileageYear_km;
    AvgConsumption=[AvgConsumption; Users{n}.(Logbook)(Users{n}.(Logbook)(:,4)>0, 4), Users{n}.(Logbook)(Users{n}.(Logbook)(:,4)>0, 3)];
end
MileageYearKm=MileageYearKm/length(Users)-1;
disp(strcat("The users drove in average ", num2str(MileageYearKm), " km per year"))
disp(strcat("The average consumption was ", num2str(sum(AvgConsumption(:,1))/sum(AvgConsumption(:,2))*100), " kWh/100km"))

%% Coverage of VehicleNumbers

VehicleNums=[];
for k=ExistingTargets
    for n=TargetGroups{k}
        VehicleNums=[VehicleNums; Users{n}.VehicleNum];
    end
end

figure(14)
clf
histogram(VehicleNums, 1:1:max(VehicleNums))
disp(strcat(num2str(length(unique(VehicleNums))), " unique Vehicles are covered by this targets"))

%% Empty Batteries

EmptyBattery=0;
for n=2:length(Users)
    EmptyBattery(n)=sum(Users{n}.(Logbook)(2:end,9)<=0 & Users{n}.(Logbook)(1:end-1,9)>0);
end
disp(strcat(num2str(sum(EmptyBattery>0)), " users experienced empty batteries"))
if sum(EmptyBattery>0)==0
    clearvars EmptyBattery
end

%% Clear Workspace

if ClearWorkspace
    clearvars ArrivalTimes centers ChargeProcesses ChargeProcessesPerWeek ChargingBlocks ChargingEfficiency col ConnectionBlocksHome ConnectionBlocksOther 
    clearvars ConnectionTime counter counts edges EnergyCharged EnergyChargedPerDayPerVehicle EnergyPerChargingProcess ExistingTargets HomeChargingQuote k l 
    clearvars Location MileageYearKm n nrows NumExistingTargets ShowAll ShowELaad ShowTargets TargetGroups TargetNum Targets
    clearvars VehicleNums StorageInd StorageFiles Load h DayVecQuaterly DayVecHourly
    clearvars AvgConsumption ClearWorkspace
end