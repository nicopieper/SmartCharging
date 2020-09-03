% MOL={};
% z=0;
% RLCosts=0;
% for n=1:length(DateList)
%     if strcmp(DateList{n}{1,2},'NEG') && DateList{n}{1,3}==240
%         z=z+1;
%         Demand=sum(cell2mat(DateList{n}(:,6)).*(cell2mat(DateList{n}(:,7))-1)*-1);
%         column4 = cell2mat(DateList{n}(:,4));
%         [sortedValues, sortOrder] = sort(column4);
%         MOL{1,z} = DateList{n}(sortOrder, :);  
%         Alloc=0;
%         i=1;
%         while Demand>Alloc
%             temp=Demand-Alloc;
%             Alloc=Alloc+min(MOL{z}{i,6}, Demand-Alloc);
%             i=i+1;
%         end
%         MOL{1,z}{i-1,6}=round(temp);
%         MOL{1,z}(i:end,:)=[];
%         RLCosts=RLCosts+sum(cell2mat(MOL{z}(:,6)).*cell2mat(MOL{z}(:,4)));
%     end
% end
% 
% RLCosts=0;
% for n=1:length(DateList)
%     if strcmp(DateList{n}{1,2},'NEG') && DateList{n}{1,3}==240
%         RLCosts=RLCosts+sum(cell2mat(DateList{n}(:,6)).*cell2mat(DateList{n}(:,4)));
%     end
% end










NegC=0;
PosC=0;
Counter=0;
n=2;
while n<length(RLDemandList)
    NegD=0;
    PosD=0;
    Counter=Counter+1;
    start=1;
    while n<length(RLDemandList) && (mod(RLDemandList{n,2}-15,240)~=0 || start==1)
        NegD=NegD+RLDemandList{n,3};
        PosD=PosD+RLDemandList{n,4};
        n=n+1;
        start=0;
    end
    if NegD==0
        NegC=NegC+1;
    end
    if PosD==0
        PosC=PosC+1;
    end
end    




RLDemandPrice=0;
RLDemand=0;
RLDaily=[];
RLWeekday=zeros(7*6,3);
RLDailyInt=zeros(6,3);
for n=1:length(DateList)
    RLDemand=0;
    RLDemandPrice=0;
    if strcmp(DateList{n}{1,2},'POS')
        RLDemand=RLDemand+sum(cell2mat(DateList{n}(:,6)));
        RLDemandPrice=RLDemandPrice+sum(cell2mat(DateList{n}(:,6)).*cell2mat(DateList{n}(:,4)));
        RLDaily(end+1,1)=RLDemand;
        RLDaily(end,2)=RLDemandPrice;
        RLDaily(end,3)=RLDemandPrice/RLDemand;
        WeekdayNum=mod(weekday(datetime(DateList{n}{1,1},'InputFormat','dd.MM.yyyy', 'Format', 'yyyy-MM-dd'))+5,7);
        TimeNum=DateList{n}{1,3}/240;
        RLWeekday(WeekdayNum*6+TimeNum,1)=RLWeekday(WeekdayNum*6+TimeNum,1)+RLDemand;
        RLWeekday(WeekdayNum*6+TimeNum,2)=RLWeekday(WeekdayNum*6+TimeNum,2)+RLDemandPrice;
    end
    RLDailyInt(DateList{n}{1,3}/240,1)=RLDailyInt(DateList{n}{1,3}/240,1)+RLDemand;
    RLDailyInt(DateList{n}{1,3}/240,2)=RLDailyInt(DateList{n}{1,3}/240,2)+RLDemandPrice;
end
RLDailyInt(:,3)=RLDailyInt(:,2)./RLDailyInt(:,1);
RLWeekday(:,3)=RLWeekday(:,2)./RLWeekday(:,1);

  

PosSRA={};
k=1;
while k<length(ListAcceptedAEOffers)
    Day=ListAcceptedAEOffers{k,1};
    PosSRADayPrice=0;
	PosSRADayDemand=0;
    while k<length(ListAcceptedAEOffers) && strcmp(ListAcceptedAEOffers{k,1},Day)        
        PosSRADayDemand=PosSRADayDemand+ListAcceptedAEOffers{k,3};
        PosSRADayPrice=PosSRADayPrice+ListAcceptedAEOffers{k,4}*ListAcceptedAEOffers{k,3};
        k=k+1;
    end
	PosSRA{end+1,1}=datetime(Day,'InputFormat','dd.MM.yyyy', 'Format', 'yyyy-MM-dd');
    PosSRA{end,2}=PosSRADayDemand;
    PosSRA{end,3}=PosSRADayPrice;
    PosSRA{end,4}=PosSRADayPrice/PosSRADayDemand;
end


PosSRAWeeks={};
n=1;
while n<length(PosSRA)
    weeknum=week(PosSRA{n,1});
    PosSRAWeeks{weeknum,2}=0;
    PosSRAWeeks{weeknum,3}=0;    
    PosSRAWeeks{weeknum,1}=weeknum;
    while n<length(PosSRA) && week(PosSRA{n,1})==weeknum
        PosSRAWeeks{weeknum,2}=PosSRAWeeks{weeknum,2}+PosSRA{n,2};
        PosSRAWeeks{weeknum,3}=PosSRAWeeks{weeknum,3}+PosSRA{n,3};
        n=n+1;
    end    
    PosSRAWeeks{weeknum,4}=PosSRAWeeks{weeknum,3}/PosSRAWeeks{weeknum,2};
end
    
PosSRAMonthly={};
n=1;
while n<length(PosSRA)
    monthnum=month(PosSRA{n,1});
    PosSRAMonthly{monthnum,2}=0;
    PosSRAMonthly{monthnum,3}=0;    
    PosSRAMonthly{monthnum,1}=monthnum;
    while n<length(PosSRA) && month(PosSRA{n,1})==monthnum
        PosSRAMonthly{monthnum,2}=PosSRAMonthly{monthnum,2}+PosSRA{n,2};
        PosSRAMonthly{monthnum,3}=PosSRAMonthly{monthnum,3}+PosSRA{n,3};
        n=n+1;
    end    
    PosSRAMonthly{monthnum,4}=PosSRAMonthly{monthnum,3}/PosSRAMonthly{monthnum,2};
end
    
NegSRAQH=num2cell([(1:1440/15)' zeros(4*24,2)]);
PosSRAQH=num2cell([(1:1440/15)' zeros(4*24,2)]);
for n=2:length(RLDemandList)
    NegSRAQH{RLDemandList{n,2}/15,2}=NegSRAQH{RLDemandList{n,2}/15,2}+RLDemandList{n,3};
    NegSRAQH{RLDemandList{n,2}/15,3}=NegSRAQH{RLDemandList{n,2}/15,3}+RLDemandList{n,5};
    PosSRAQH{RLDemandList{n,2}/15,2}=PosSRAQH{RLDemandList{n,2}/15,2}+RLDemandList{n,4};    
    PosSRAQH{RLDemandList{n,2}/15,3}=PosSRAQH{RLDemandList{n,2}/15,3}+RLDemandList{n,6};
    NegSRAQH{RLDemandList{n,2}/15,4}=NegSRAQH{RLDemandList{n,2}/15,3}/NegSRAQH{RLDemandList{n,2}/15,2};
    PosSRAQH{RLDemandList{n,2}/15,4}=PosSRAQH{RLDemandList{n,2}/15,3}/PosSRAQH{RLDemandList{n,2}/15,2};
end

NegSRAQHInt=zeros(6,3);
PosSRAQHInt=zeros(6,3);

for n =1:length(NegSRAQH)
    NegSRAQHInt(floor((n-1)/16)+1,1)=NegSRAQHInt(floor((n-1)/16)+1,1)+NegSRAQH{n,2};
    NegSRAQHInt(floor((n-1)/16)+1,2)=NegSRAQHInt(floor((n-1)/16)+1,2)+NegSRAQH{n,3};
    PosSRAQHInt(floor((n-1)/16)+1,1)=PosSRAQHInt(floor((n-1)/16)+1,1)+PosSRAQH{n,2};
    PosSRAQHInt(floor((n-1)/16)+1,2)=PosSRAQHInt(floor((n-1)/16)+1,2)+PosSRAQH{n,3};
end
NegSRAQHInt(:,3)=NegSRAQHInt(:,2)./NegSRAQHInt(:,1);
PosSRAQHInt(:,3)=PosSRAQHInt(:,2)./PosSRAQHInt(:,1);


NegSRAWeeklyQH=zeros(4*24*7,3);
PosSRAWeeklyQH=zeros(4*24*7,3);
for n=2:length(RLDemandList)
    WeekdayNum=mod(weekday(datetime(RLDemandList{n,1},'InputFormat','dd.MM.yyyy', 'Format', 'yyyy-MM-dd'))+5,7);
    TimeNum=RLDemandList{n,2}/15; TimeNum=RLDemandList{n,2}/15;
    NegSRAWeeklyQH(WeekdayNum*96+TimeNum,1)=NegSRAWeeklyQH(WeekdayNum*96+TimeNum,1)+RLDemandList{n,3};
    NegSRAWeeklyQH(WeekdayNum*96+TimeNum,2)=NegSRAWeeklyQH(WeekdayNum*96+TimeNum,2)+RLDemandList{n,5};
    PosSRAWeeklyQH(WeekdayNum*96+TimeNum,1)=PosSRAWeeklyQH(WeekdayNum*96+TimeNum,1)+RLDemandList{n,4};
    PosSRAWeeklyQH(WeekdayNum*96+TimeNum,2)=PosSRAWeeklyQH(WeekdayNum*96+TimeNum,2)+RLDemandList{n,6};      
end
NegSRAWeeklyQH(:,3)=NegSRAWeeklyQH(:,2)./NegSRAWeeklyQH(:,1)*4;
PosSRAWeeklyQH(:,3)=PosSRAWeeklyQH(:,2)./PosSRAWeeklyQH(:,1)*4;