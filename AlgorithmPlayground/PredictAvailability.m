%% Availability Period Forecast

ACFs=[];
ACFsCorr=[];
ACFsNoCorr=[];
for n=2:length(Users)
    Availability=ismember(Users{n}.LogbookBase(:,1), 4:5);
    Availability1=[0;double(Availability(2:end)==1 & Availability(1:end-1)==0)];
    Availability2=Availability1 + [Availability1(2:end); 0] + [0; Availability1(1:end-1)];

    ACFs(:,n-1)=autocorr(Availability,96*3);
    if any(ACFs(96:end,n-1)>0.25)
        ACFsCorr=[ACFsCorr, ACFs(:,n-1)];
    else
        ACFsNoCorr=[ACFsNoCorr, ACFs(:,n-1)];
    end
end
[~,temp]=sort(max(ACFsCorr(96:end,:), [], 1), 'descend');
ACFsCorr=ACFsCorr(:,temp');
[~,temp]=sort(max(ACFsNoCorr(96:end,:), [], 1), 'descend');
ACFsNoCorr=ACFsNoCorr(:,temp);

%% Chose 10 best ACF coefficients

for n=2:2%length(Users)
    Availability=ismember(Users{n}.LogbookBase(:,1), 4:5);
    Availability1=[0;double(Availability(2:end)==1 & Availability(1:end-1)==0)];
    Availability2=Availability1 + [Availability1(2:end); 0] + [0; Availability1(1:end-1)];

    ACFs(:,n-1)=autocorr(Availability,96*3);
    
    [TopACFCs, order]=sort(ACFs(:,n-1), 'descend');
    
    DelayInds=order(1:10);
    
    GeneratePrediction;
    a=Prediction;
    figure
    plot(Time.Vec, a)
    hold on
    plot(Time.Vec, Availability)
    ylim([-0.1 1.1])

end


%% Availability Beginning Forecast
User=40;
Availability=ismember(Users{User}.LogbookBase(:,1), 4:5);
Availability1=[0;double(Availability(2:end)==1 & Availability(1:end-1)==0)];
Availability2=Availability1 + [Availability1(2:end); 0] + [0; Availability1(1:end-1)];

figure
autocorr(Availability,96*3)

SoC=double(Users{User}.LogbookBase(:,9))/double(Users{User}.BatterySize);
SoC1=repelem(SoC(1:24:end), 24);

Weekday=mod(weekday(Time.Vec)+5, 7)+1<=5;

%%

GeneratePrediction;
a=Prediction;
figure
plot(Time.Vec, a)
hold on
plot(Time.Vec, Availability1)
ylim([-0.1 1.1])

%%
a=Prediction;
Roll=1;
for n=1:length(a)-Roll
    [Max, Ind]=max(a(n:+n+Roll-1));
    a(n:n+Roll-1)=0;
    a(Ind+n-1)=Max;
end
T=0.12;
a(a<=T)=0;
a(a>T)=1;
a2=a + [a(2:end); 0] + [0; a(1:end-1)];
TP=sum(a==1 & Availability2==1);
FP=sum(a==1 & Availability2==0);
FN=sum(a2==0 & Availability1==1);

accuracy=sqrt(TP/(TP+FP)*TP/(TP+FN))

%%

figure
plot(Time.Vec, a)
hold on
plot(Time.Vec, Availability2)
plot(Time.Vec, Weekday/7)
ylim([-0.1 1.1])
