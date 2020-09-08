function [DistanceToHome, HomeSpotFound, AvgHomeParkingTime]=DetermineHomeDistance(LogbookSourceTime, CompanyDistance, MaxHomeSpotDistanceDiff, MinShareHomeParking)
%% Description
% This function determines where the vehicle has its home spot. The home
% spot is defined as the spot, where it is considered that the vehicle has 
% its private charging point. 
% 

ParkingTime=posixtime([LogbookSourceTime(1:end-1,2) LogbookSourceTime(2:end,1)]);
ParkingTime=round((ParkingTime-ParkingTime(1,1))/60);
ScaledDistances=[];
for n=1:length(CompanyDistance)-1
    ScaledDistances=[ScaledDistances; ones((ParkingTime(n,2)-ParkingTime(n,1)),1)*CompanyDistance(n)];
end
[counts,centers]=hist(ScaledDistances,0:0.15:max(CompanyDistance));
[counts, indices]=sort(counts, 'descend');
centers=centers(indices);
% [~, index]=max(counts);
% centers(index);

for n=1:min(3, sum(counts>3))
    
    HomeDistances=[];
    for k=1:length(CompanyDistance)
        if abs(CompanyDistance(k)-centers(n))<0.4
            HomeDistances=[HomeDistances; CompanyDistance(k)];
        end
    end

    DistanceToHome(n)=mean(HomeDistances);

    HomeDistances=[];
    for k=1:length(CompanyDistance)
        if abs(CompanyDistance(k)-DistanceToHome(n))<MaxHomeSpotDistanceDiff
            HomeDistances=[HomeDistances; CompanyDistance(k)];
        end
    end

    DistanceToHome(n)=mean(HomeDistances);
    
    SpotParkingTime(n)=hours(0);
    for k=1:length(ParkingTime)
        if abs(CompanyDistance(k)-DistanceToHome(n))<=MaxHomeSpotDistanceDiff
            SpotParkingTime(n)=SpotParkingTime(n)+ParkingTime(k,2)-ParkingTime(k,1);
        end
    end
end

[~, index]=max(SpotParkingTime);

if SpotParkingTime(index)>=MinShareHomeParking*(ParkingTime(end,2)-ParkingTime(1,1)) % Vehicle must be at least MinShareHomeParking of the time at the home spot
    HomeSpotFound=true;
else
    HomeSpotFound=false;
end

AvgHomeParkingTime=SpotParkingTime(index);
DistanceToHome=DistanceToHome(index);

end