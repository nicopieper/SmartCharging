a1=[];

for n=2:length(Users)
    a1=[a1; [Users{n}.VehicleNum, Users{n}.BatterySize, double(Users{n}.AverageMileageYear_km)]];
end
a2=sort(unique(a1(:,1)),'ascend');
a1=[a2, a1(ismember(a2,a1(:,1)),2:3)];
a2=cell(length(a1), 7);
a2(:,1:3)=num2cell(a1);
a3=cell(length(a1), 7);
a3(:,1:3)=num2cell(a1);


for n=2:length(Users)
    if Users{n}.GridConvenientCharging && Users{n}.PVPlantExists
        Ind=1;
    elseif Users{n}.GridConvenientCharging && ~Users{n}.PVPlantExists
        Ind=2;
    elseif ~Users{n}.GridConvenientCharging && Users{n}.PVPlantExists
        Ind=3;
    elseif ~Users{n}.GridConvenientCharging && ~Users{n}.PVPlantExists
        Ind=4;
    end
    a2{Users{n}.VehicleNum==a1, Ind+3}=[a2{Users{n}.VehicleNum==a1, Ind+3}; [sum(Users{n}.FinListSmart,1), sum(Users{n}.FinListSmart,'all')]];
    a3{Users{n}.VehicleNum==a1, Ind+3}=[a3{Users{n}.VehicleNum==a1, Ind+3}; [sum(Users{n}.FinListSmart,'all')]];
end
for n=1:length(a3)
    for k=4:7
        a3{n,k}=mean(a3{n,k});
    end
end
a4=cell2mat(a3(:,[1:3,4,6]));
%a4=cell2mat(a3(:,[1:3,5,7]));
a4=a4(~isnan(a4(:,4)) & ~isnan(a4(:,5)),:);
a4(:,6)=a4(:,4)>a4(:,5);

a5=zeros(96,2);
for n=2:length(Users)
    Ind=find(Users{n}.VehicleNum==a4(:,1));
    if ~isempty(Ind)
        if a4(Ind,6)==1
            a5(:,1)=a5(:,1)+mean(reshape(Users{n}.LogbookSmart,96,[]), 2);
        else
            a5(:,2)=a5(:,2)+mean(reshape(Users{n}.LogbookSmart,96,[]), 2);
        end
    end
end

for k=1:2
    figure(19+k)
    a5(:,k)=a5(:,k)/mean(a5(:,k));
    plot(1:96,a5(:,k))
    xticks(1:16:96)
    xlim([1 96])
    xticklabels({datestr(Time.Vec(1:16:96),'HH:MM')})
    ylabel("Charging power in kW")
    xlabel("Time")
end

        


% In 73% der Fälle ist beim Vorliegen einer PV-Anlage die
% Anwendung von § 14a nicht ökonomisch. Keine Abhängigkeit von der
% Batteriegröße oder Energieverbrauch erkennbar. Unterschied liegt im
% Schnitt bei 71€!

% Wenn keine PV-Anlage vorliegt, ist § 14a zu 93% ökonomisch, IMSYS-Preise
% außen vor gelassen. Unterschied liegt im Schnitt bei 114€!






%%

a1=cell(4,1);
for n=2:length(Users)
    if Users{n}.GridConvenientCharging && Users{n}.PVPlantExists
        a1{1}=[a1{1}; n];
    elseif Users{n}.GridConvenientCharging && ~Users{n}.PVPlantExists
        a1{2}=[a1{2}; n];
    elseif ~Users{n}.GridConvenientCharging && Users{n}.PVPlantExists
        a1{3}=[a1{3}; n];
    elseif ~Users{n}.GridConvenientCharging && ~Users{n}.PVPlantExists
        a1{4}=[a1{4}; n];
    end
end

a2=cell(4,1);
a3=zeros(4,5);
for k=1:4
    for n=a1{k}'
        a2{k}=[a2{k}; [n, Users{n}.VehicleNum, sum(Users{n}.FinListSmart,1)]];
    end
    a3(k,1:4)=sum(a2{k}(:,3:end),1);
    a3(k,5)=sum(a2{k}(:,3:end),'all');
end