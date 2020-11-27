for n=UserNum
        
    ChargedEnergy=min([Users{n}.BatterySize - (Users{n}.Logbook(TimeInd+TD.User-1, 9) - Users{n}.Logbook(TimeInd+TD.User, 4)), sum(Users{n}.Logbook(TimeInd+TD.User, 5:8))]);
    Users{n}.Logbook(TimeInd+TD.User, 9)=Users{n}.Logbook(TimeInd+TD.User-1, 9)-Users{n}.Logbook(TimeInd+TD.User, 4) + ChargedEnergy;
    if ChargedEnergy==0 && Users{n}.Logbook(TimeInd+TD.User, 1)==5
        Users{n}.Logbook(TimeInd+TD.User, 1)=4;
    end
    if ChargedEnergy < sum(Users{n}.Logbook(TimeInd+TD.User, 5:8)) - 0.01
        Users{n}.Logbook(TimeInd+TD.User, 5:8)=Users{n}.Logbook(TimeInd+TD.User, 5:8).*(ChargedEnergy/sum(Users{n}.Logbook(TimeInd+TD.User, 5:8)));
    end

    if ~(Users{n}.Logbook(TimeInd+TD.User,9)<(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))+3 && Users{n}.Logbook(TimeInd+TD.User,9)>(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))-3)
        error("Wrong addition")
    end
    
    if Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1, 9)>Users{n}.BatterySize
        2
    end

end


    
%     Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1, 9)=min([ones(ControlPeriodsIt,1)*Users{n}.BatterySize, Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1, 9)], [],2);
%     if ~(Users{n}.Logbook(TimeInd+TD.User,9)<(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))+3 && Users{n}.Logbook(TimeInd+TD.User,9)>(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))-3)
%         error("Wrong addition")
%     end
    
