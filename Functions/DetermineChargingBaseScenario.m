function [Users]=DetermineChargingBaseScenario(Users, TimeInd, Time.Step)
    PThreshold=1.5;

    if Users.ChargingStrategy==1 % Always connect car to charging point if Duration of parking is higher than MinimumPluginTime
        ParkingDuration=(find(Users.LogbookBase(TimeInd:end,1)<3,1)-1)*Time.Step;
        if ParkingDuration>Users.MinimumPluginTime
            Users.LogbookBase(TimeInd,1)=4; % Plugged-in
        else
            Users.LogbookBase(TimeInd,1)=3; % Not plugged-in
        end
    
    elseif Users.ChargingStrategy==2 % The probability of connection is a function of Plug-in time, SoC and the consumption within the next 24h
        Consumption24h=uint32(sum(Users.LogbookBase(TimeInd:TimeInd+hours(24)/Time.Step-1, 3))*Users.Consumption/1000); % [Wh]
        if Consumption24h>Users.LogbookBase(TimeInd-1,6)
            Users.LogbookBase(TimeInd,1)=4; % Plugged-in
        else
            PlugInTime=(find(Users.LogbookBase(TimeInd+1:end,1)<3,1)-1)*Time.Step;
            P=min(1,PlugInTime/hours(2)) + min(1, (single(Users.BatterySize-Users.LogbookBase(TimeInd-1,6)))/single(Users.BatterySize)) + min(1, single(Consumption24h)/single(Users.LogbookBase(TimeInd-1,6)));
            if P>PThreshold
                Users.LogbookBase(TimeInd,1)=4; % Plugged-in
            else
                Users.LogbookBase(TimeInd,1)=3; % Not plugged-in
            end
        end
    end
end