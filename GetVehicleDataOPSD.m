% StorageFile="C:\Users\nicop\Desktop\household_data_1min_singleindex_filtered.csv";
% formatSpec='%s';
% File=fopen(StorageFile, 'r');
% VehicleData=fscanf(File,formatSpec);
% b=VehicleData;
% for n=2014:2019
%     b=strrep(b, strcat(num2str(n), "-"), strcat(",", num2str(n), "-"));
% end
% b=strrep(b, "Z,,20", "Z,20");
% c=strsplit(b, ',', 'CollapseDelimiters', false);
% d=reshape(c,5,[])';
% 
% for n=1:2
%     d(d(:,3+n)=='',3+n)='0';
%     EV{n}=str2double(d(2:end,3+n));
% %     EV{n}(isnan(EV{n}))=0;
%     EV{n}=[0; EV{n}(2:end)-EV{n}(1:end-1)];
%     Range=find(EV{n},1):find(EV{n}~=0,1,'last');
%     EV{n}=EV{n}(Range);
%     EV{n}(EV{n}<0.0007)=0;
%     TimeVec{n}=datetime(strrep(erase(erase(d(Range,2), '+0100'), '+0200'), "T", " "), 'InputFormat', 'yyyy-MM-dd HH:mm:ss', 'TimeZone', 'Africa/Tunis');
% end

ChargingTime=NaT(0,2, 'TimeZone', 'Africa/Tunis');
ChargingTime=cell(2);
ChargingPower=cell(2,1);
DatelessChargingTime=cell(2,1);
for n=1:2
    k=1;
    Ind=1;
    Ind1=1;
    TempEV=EV{n};
    Pointer1=0;
    stop=false;
    while ~isempty(Ind1) && ~isempty(Ind) && stop==false
        Ind=find(TempEV,1);
        if ~isempty(Ind)
            Pointer=Pointer1+Ind;
            TempEV=TempEV(Ind:end);
            ChargingTime{n}(end+1,1)=TimeVec{n}(Pointer);
            Ind1=find(TempEV==0,1);
            if isempty(Ind1)
                Ind1=length(TempEV);
                stop=true;
            end
            Pointer1=Pointer+Ind1-2;
            TempEV=TempEV(Ind1:end);
            ChargingTime{n}(end,2)=TimeVec{n}(Pointer1);
            ChargingPower{n}=[ChargingPower{n}; EV{n}(Pointer:Pointer1)];
        end
    end
    DatelessChargingTime{n}=ChargingTime{n}-days(day(ChargingTime{n})-1);
    DatelessChargingTime{n}=DatelessChargingTime{n}-calmonths(month(DatelessChargingTime{n})-1);
    DatelessChargingTime{n}=DatelessChargingTime{n}-calyears(year(DatelessChargingTime{n})-1);
end

for n=0:23
    HistEdges(n*2+1)=datetime(1,1,1,n,0,0, 'TimeZone', 'Africa/Tunis');
    HistEdges(n*2+2)=datetime(1,1,1,n,59,59, 'TimeZone', 'Africa/Tunis');
end

figure(10)
hold off
histogram(DatelessChargingTime{1}, HistEdges, 'Normalization','probability')
hold on
histogram(DatelessChargingTime{2}, HistEdges, 'Normalization','probability')