%% Define target groups

if ~exist("Users", "var")
    PathSimulationData=strcat(Path, "Simulation");
    StorageFiles=dir(strcat(PathSimulationData, Dl, "Users_*"));
    [~, StorageInd]=max(datetime({StorageFiles.date}, "InputFormat", "dd-MMM-yyyy HH:mm:ss"));
    load(strcat(PathSimulationData, Dl, StorageFiles(StorageInd).name))
end

% Targets=["small"; "medium"; "large"; "transporter"];
% Targets=["one user"; "only one user"; "several users"; "undefined"];
% Targets=["company car"; "fleet vehicle"; "undefined"];
% Targets=[0.5; 1; 3; 1000];
Targets=[hours(10); hours(12); hours(14); hours(24)];

TargetGroups=cell(length(Targets),1);
for n=2:length(Users)
%     TargetNum=strcmp(Users{n}.VehicleSize,Targets);
%     TargetNum=strcmp(Users{n}.VehicleUtilisation,Targets);
%     TargetNum=find(Users{n}.DistanceCompanyToHome<Targets,1);
    TargetNum=find(Users{n}.AvgHomeParkingTime<Targets,1);
    TargetGroups{TargetNum}=[TargetGroups{TargetNum} n];
end
ExistingTargets=find(cellfun('length', TargetGroups)>0)';
% ExistingTargets=[1,2, 3,4];
NumExistingTargets=numel(ExistingTargets);
ShowTargets=true;
ShowAll=true;
ShowELaad=true;
ClearWorkspace=true;

DataTable=table(Targets(ExistingTargets));
Location=["Home"; "Other"];

if ShowELaad
    GetELaadData;
end

%% Energy charged per week

ChargeProcesses=cell(length(Targets),2);
ChargeProcessesPerWeek=cell(length(Targets),2);
for k=ExistingTargets
    for n=TargetGroups{k}
        Users{n}.ChargeProcessesHomeBase=sum(Users{n}.LogbookBase(2:end,5)>0 & Users{n}.LogbookBase(1:end-1,5)==0);
        Users{n}.ChargeProcessesOtherBase=sum(Users{n}.LogbookBase(2:end,6)>0 & Users{n}.LogbookBase(1:end-1,6)==0);
        ChargeProcesses{k,1}(n)=Users{n}.ChargeProcessesHomeBase;
        ChargeProcesses{k,2}(n)=Users{n}.ChargeProcessesOtherBase;
    end
    ChargeProcessesPerWeek{k,1}=sum(ChargeProcesses{k,1})/days(DateEnd-DateStart)*7/length(TargetGroups{k});
    ChargeProcessesPerWeek{k,2}=sum(ChargeProcesses{k,2})/days(DateEnd-DateStart)*7/length(TargetGroups{k});
end
ChargeProcessesPerWeek=ChargeProcessesPerWeek(ExistingTargets,:);
DataTable.ChargingPorcessesPerWeek=round(cell2mat(ChargeProcessesPerWeek)*100)/100;
disp(strcat("The users charge in average ", num2str(mean(cell2mat(ChargeProcessesPerWeek(:,1)))), " times per week at home and ", num2str(mean(cell2mat(ChargeProcessesPerWeek(:,2))))," times per week at ohter locations"))

%% Energy charged per charging process

EnergyPerChargingProcess=cell(length(Targets),2);
for k=ExistingTargets
    EnergyPerChargingProcess{k,1}=-ones(length(Users)-1*1000,1);
    EnergyPerChargingProcess{k,2}=-ones(length(Users)-1*1000,1);
    for col=5:6
        counter=1;
        for n=TargetGroups{k}
            ChargingBlocks=[find(Users{n}.LogbookBase(1:end,col)>0 & [0; Users{n}.LogbookBase(1:end-1,col)]==0)+1, find(Users{n}.LogbookBase(1:end,col)>0 & [Users{n}.LogbookBase(2:end,col);0]==0)];
            for h=1:size(ChargingBlocks,1)
                EnergyPerChargingProcess{k,col-4}(counter,1)=sum(Users{n}.LogbookBase(ChargingBlocks(h,1):ChargingBlocks(h,2),col));
                counter=counter+1;
            end
        end
        EnergyPerChargingProcess{k,col-4}=EnergyPerChargingProcess{k,col-4}(EnergyPerChargingProcess{k,col-4}~=-1);
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
        legappend(l, "All");
    end
    if ShowTargets
        for k=1:NumExistingTargets
            [counts, centers]=hist(EnergyPerChargingProcess{k, col}/1000, 0:4:100);
            plot(centers, counts./sum(counts))
            legappend(l, Targets(ExistingTargets(k)));
        end
    end
    if ShowELaad
        [counts, centers]=hist(EnergyDemandELaad(:,col+1), 0:4:100);
        plot(centers, counts./sum(counts))
        legappend(l, "ELaad");
    end
    title(strcat("Energy per charging event in kWh ", Location(col)))
    xlabel("Energy in kWh")
    ylabel("Probability")
end

disp(strcat("In average per charging event, ", num2str(mean(cell2mat(EnergyPerChargingProcess(:,1))/1000)), " kWh were charged at home and ", num2str(mean(cell2mat(EnergyPerChargingProcess(:,2))/1000)), " at other places"))

DataTable.EnergyPerChargingProcess=round(cellfun(@mean,EnergyPerChargingProcess)/1000*100)/100;

%% Energy charged per User

EnergyCharged=cell(length(Targets),2);
for k=ExistingTargets
    for n=TargetGroups{k}
        EnergyCharged{k,1}(end+1)=sum(Users{n}.LogbookBase(1:end,5),1);
        EnergyCharged{k,2}(end+1)=sum(Users{n}.LogbookBase(1:end,6),1);
    end
end
EnergyCharged=EnergyCharged(ExistingTargets,:);
EnergyChargedPerDayPerVehicle=cellfun(@sum,EnergyCharged)/days(DateEnd-DateStart)/1000./cellfun(@length, TargetGroups(ExistingTargets));
HomeChargingQuote=sum(EnergyChargedPerDayPerVehicle(:,1))/sum(EnergyChargedPerDayPerVehicle,'all');
disp(strcat("The users charged in average ", num2str(sum(cellfun(@sum, EnergyCharged), 'all')/days(DateEnd-DateStart)/1000/length(Users)-1), " kWh per day"))
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
        ConnectionBlocksHome=[find(ismember(Users{n}.LogbookBase(1:end,1),4:5) & ~ismember([0;Users{n}.LogbookBase(1:end-1,1)],4:5)), find(ismember(Users{n}.LogbookBase(1:end,1),4:5) & ~ismember([Users{n}.LogbookBase(2:end,1);0],4:5))];
        ConnectionBlocksOther=[find(ismember(Users{n}.LogbookBase(1:end,1),6) & ~ismember([0;Users{n}.LogbookBase(1:end-1,1)],6)), find(ismember(Users{n}.LogbookBase(1:end,1),6) & ~ismember([Users{n}.LogbookBase(2:end,1);0],6))];
        ConnectionTime{k,1}=[ConnectionTime{k,1}; (ConnectionBlocksHome(:,2)-ConnectionBlocksHome(:,1)+1)*TimeStepMin];
        ConnectionTime{k,2}=[ConnectionTime{k,2}; (ConnectionBlocksOther(:,2)-ConnectionBlocksOther(:,1)+1)*TimeStepMin];
        ArrivalTimes{k,1}=[ArrivalTimes{k,1}; datetime(ones(length(ConnectionBlocksHome),1),ones(length(ConnectionBlocksHome),1),ones(length(ConnectionBlocksHome),1), hour(TimeVec(ConnectionBlocksHome(:,1))), minute((TimeVec(ConnectionBlocksHome(:,1)))),zeros(length(ConnectionBlocksHome),1), 'TimeZone', 'Africa/Tunis')];
        ArrivalTimes{k,2}=[ArrivalTimes{k,2}; datetime(ones(length(ConnectionBlocksOther),1),ones(length(ConnectionBlocksOther),1),ones(length(ConnectionBlocksOther),1), hour(TimeVec(ConnectionBlocksOther(:,1))), minute((TimeVec(ConnectionBlocksOther(:,1)))),zeros(length(ConnectionBlocksOther),1), 'TimeZone', 'Africa/Tunis')];
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
        legappend(l, "All");
    end
    if ShowTargets
        for k=1:NumExistingTargets
            [counts, centers]=hist(ConnectionTime{k,col}, (0:2:48)*60);
            plot(centers/60, counts./sum(counts))
            legappend(l, Targets(ExistingTargets(k)));
        end
    end
    if ShowELaad
        [counts, centers]=hist(ConnectionTimeELaad(:,col+1), (0:2:48));
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
        [counts, edges]=histcounts(cat(1, ArrivalTimes{:,col}), datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'));
        centers=edges(1:end-1)+(edges(2)-edges(1))/2;
        plot(centers, counts./sum(counts))
        legappend(l, "All");
    end
    if ShowTargets
        [nrows,~] = cellfun(@size, ArrivalTimes(:,col));
        for k=find(nrows>0)'
            [counts, edges]=histcounts(ArrivalTimes{k,col}, datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'));
            centers=edges(1:end-1)+(edges(2)-edges(1))/2;
            plot(centers, counts./sum(counts))
            legappend(l, Targets(ExistingTargets(k)));
        end
    end
    if ShowELaad
        plot(datetime(1,1,1,0,30,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(1,1,1,23,30,0, 'TimeZone', 'Africa/Tunis'), sum(reshape(ArrivalTimesELaad(:,col), 4, []))/100)
        legappend(l, "ELaad");
    end
    xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
    xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
    xlabel("Time of date")
    ylabel("Probability")
    title(strcat("Arrival time at charging point at ", Location(col)))
end


%% Mileage and Consumption

MileageYearKm=0;
AvgConsumption=[];
for n=2:length(Users)
    MileageYearKm=MileageYearKm+Users{n}.AverageMileageYear_km;
    AvgConsumption=[AvgConsumption; Users{n}.LogbookBase(Users{n}.LogbookBase(:,4)>0, 4), Users{n}.LogbookBase(Users{n}.LogbookBase(:,4)>0, 3)];
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

figure(13)
clf
histogram(VehicleNums, 1:1:max(VehicleNums))
disp(strcat(num2str(length(unique(VehicleNums))), " unique Vehicles are covered by this targets"))

%% Empty Batteries

EmptyBattery=0;
for n=2:length(Users)
    EmptyBattery(n)=sum(Users{n}.LogbookBase(2:end,7)<=0 & Users{n}.LogbookBase(1:end-1,7)>0);
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
    clearvars ArrivalTimesELaad ArrivalWeekdaysELaad ArrivalWeekendsELaad ConnectionTimeELaad
end