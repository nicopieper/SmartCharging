%% Description
% This Script loads Vehicle driving profiles from two xlsx files provided 
% by Fraunhofer ISI. The data bases on the REM2030 project. In this
% project, vehicles used by companies were tracked using a GPS sender.
% Several types of companies participated. Some of the vehicles were used
% as fleet cars and some as company cars. The fleet cars are used only for
% business rides, whereas the company cars can also be used privately. The
% driving profile file records the rides of the participating vehicles.
% Data about the beginning and end of their trips, the driven distances and
% the distances between the location of company and the destination of the 
% rides are given by the file.
%
% This script processes the data of both files. At first the general 
% vehicle properties are extracted. For each vehicle its properties are
% stored in one cell of "Vehicles". Then for each vehicle, the driving
% profiles are extracted from the large driving profile matrix and also
% stored in the corresponding cell of "Vehicles".
%
% Later, this script uses Posixtim rather that Datetime in order to improve
% the performance of the script.
%
% Depended scripts
%   Initialisation          Needed for the execution of this script
%   InitialiseUsers         This script is called by InitialiseUsers and 
%                           uses the vehicle profiles within the user
%                           profiles
%
% Description of important variables
%
%
%   NumVehicles:        Maximum number of vehicles profiles that shall be 
%                       extracted from the files. (1,1)
%   LogbookTime:        The later time vector of all finished vehicle
%                       profiles. Given by the variables defined during the
%                       initialisation. Datetime (N,1)
%   LogbookTimePosix:   Same vector as LogbookTime but using Posixtime.
%                       Double (N,1)
%   VehiclePropertiesMat:   The matrix loaded from an excel file containing
%                       all properties of each vehicle.
%   Vehicles:           An cell array containing the information of all
%                       vehicles. Each vehicle represents one cell. The 
%                       first cell contains processing information. Inside
%                       the following cells, the vehicle data is stored, 
%                       each as a struct. Cell (NumVehicles+1, 1)
%   DrivingProfileMat:  The matrix loaded from an excel file containing
%                       all recorded rides. Departure and arrival time,
%                       trip distance and distance to company of the
%                       destination are given. Double (M,13)
%   MaxHomeSpotDistanceDiff:    The distance in km of the arrival
%                       location to the determined home spot that is 
%                       allowed to consider a parking spot as the home
%                       spot. dobule (1,1) in km
%   MinShareHomeParking:Minimum share of time that the vehicle is parking
%                       at the determined home spot. If minimum share is 
%                       not fulfilled, the vehicle is not further
%                       considered
%   MaxPlausibleVelocity:Maximum average velocity of a 15 minute driving
%                       interval that is considered to be plausible.
%   ActivateWaitbar     Indicates whether the waitbar is active or not
%   ProcessNewVehicles  When true, the Data is vehicle data is processed
%                       newly. Else, if a file exists with the vehicle data
%                       and equal MinShareHomeParking, NumVehicles, 
%                       MaxHomeSpotDistanceDiff, the data is loaded from a
%                       file. logical (1,1)

%

%% Initialisation

tic

AddNoise=true;
ActivateWaitbar=true;
ProcessNewVehicles=true;
Evaluation=false;

MinShareHomeParking=10/24;
NumVehicles=800;
MaxHomeSpotDistanceDiff=0.1; % [km]
MaxPlausibleVelocity=60; % [m/s]
TimeNoiseStdFac=0.05; % Std=TimeNoiseStdFac*TripTime
PathVehicleData=[Path 'Predictions' Dl 'VehicleData' Dl];
StorageFile=strcat(PathVehicleData, "VehicleData_", num2str(NumVehicles), "_", num2str(MaxHomeSpotDistanceDiff), "_", num2str(MinShareHomeParking), "_", num2str(AddNoise));
StorageFiles=dir(strcat(StorageFile, "*"));

NumTripsDays=0;
close all hidden

if ProcessNewVehicles==false && ~isempty(StorageFiles)
    [~, StorageInd]=max(datetime({StorageFiles.date}, "InputFormat", "dd-MMM-yyyy HH:mm:ss"));
    load(strcat(PathVehicleData, StorageFiles(StorageInd).name))
else
    
    Trips=[];
    DayTrips=[];

    LogbookTime=(DateStart:TimeStep:DateEnd)'; % the time vector with is relevant for all vehicle logbooks
    LogbookTimePosix=posixtime(LogbookTime); % ... converted to posixtime, used later for performance reasons

    VehiclePropertiesMat=readmatrix(strcat(PathVehicleData, 'REM2030_v2015_car_info.csv'), 'OutputType', 'string'); % id, vehicle_size, economic_sector, nace_section, economic_segment, nace_division, description_of_the_economic_sector_according_to_company, city_size, company_size, comment, vehicle_utilization, number_of_users, parking_spot, federal_state, company_id

    DrivingProfileMat=readmatrix(strcat(PathVehicleData, 'REM2030_v2015.csv')); % id, deptyear, deptmonth, deptday, depthour, deptminute, arryear, arrmonth, arrday, arrhour, arrminute, , _to_company
    DrivingProfileMat(:,12)=DrivingProfileMat(:,12)*1000; % Use meters rather than km for the distance such that integers can be used

    DateMatStr=string(DrivingProfileMat(:,2:11)); % Convert the columns for departure and arrival time to two datetime columns
    DateMatStr(:,1:2)=[strcat(DateMatStr(:,3), ".", DateMatStr(:,2), ".", DateMatStr(:,1), " ", DateMatStr(:,4), ":", DateMatStr(:,5)), strcat(DateMatStr(:,8), ".", DateMatStr(:,7), ".", DateMatStr(:,6), " ", DateMatStr(:,9), ":", DateMatStr(:,10))];
    DateMat=[datetime(DateMatStr(:,1), 'InputFormat', "d.M.yyyy H:m", 'TimeZone','Africa/Tunis'), datetime(DateMatStr(:,2), 'InputFormat', "d.M.yyyy H:m", 'TimeZone','Africa/Tunis')]; % the arrival and departure times of all trips of all vehicles
    
    Vehicles=cell(min([NumVehicles size(VehiclePropertiesMat,1)])+1,1); % The vehicle profiles are stored in a cell array, each vehicle has one cell
    Vehicles{1}.TimeVec=TimeVec; % store properties of data processing in first cell
    Vehicles{1}.TimeStep=TimeStep;
    Vehicles{1}.MinShareHomeParking=MinShareHomeParking;
    Vehicles{1}.MaxHomeSpotDistanceDiff=MaxHomeSpotDistanceDiff;
    Vehicles{1}.MaxPlausibleVelocity=MaxPlausibleVelocity;
    Vehicles{1}.TimeNoiseStdFac=TimeNoiseStdFac;

    %% Properties Matrix

    for n=2:size(Vehicles,1)
        Vehicles{n}.ID=uint32(str2num(VehiclePropertiesMat(n-1,1)));  % Inside the cell, the information is stored in a struct
        Vehicles{n}.VehicleSize=VehiclePropertiesMat(n-1,2);
        Vehicles{n}.VehicleSizeMerged=Vehicles{n}.VehicleSize;
        if strcmp(Vehicles{n}.VehicleSizeMerged, "transporter")
            Vehicles{n}.VehicleSizeMerged="large";
        end
        Vehicles{n}.EconomicSegement=VehiclePropertiesMat(n-1,5);
        Vehicles{n}.CitySize=VehiclePropertiesMat(n-1,8);
        Vehicles{n}.CompanySize=VehiclePropertiesMat(n-1,9);
        Vehicles{n}.VehicleUtilisation=VehiclePropertiesMat(n-1,11);
        Vehicles{n}.NumberUsers=VehiclePropertiesMat(n-1,12);
        Vehicles{n}.ParkingSpot=VehiclePropertiesMat(n-1,13);
    end

    %% Profiles

    if ActivateWaitbar
        h=waitbar(0, 'Initialise Vehicles from Fraunhofer ISI Database');
    end
    for k=418:length(Vehicles) % for each vehicle extract the its driving profile from DrivingProfileMat

        VehicleMatIndices=DrivingProfileMat(:,1)==Vehicles{k}.ID; % Get all rows that represent trips of the vehicle
        DrivingProfile=DrivingProfileMat(VehicleMatIndices,12:13); % Get all trip distances and distances to company from vehicle number n
        DrivingProfileTime=DateMat(VehicleMatIndices,:); % Get all the departure and arrival times of all trips of vehicle number n
        DrivingProfileTimePosix=posixtime(DrivingProfileTime); % ... converted to posixtime. later used for performance reasons
        
        if days(DrivingProfileTime(end,2)-DrivingProfileTime(1,1))<days(14) % do not consider this vehicle if less than 14 days were recorded
    %         Vehicles{k}.ID
            Vehicles{k}=[];
            continue
        end
        
        Velocities=DrivingProfile(:,1)./(DrivingProfileTimePosix(:,2)-DrivingProfileTimePosix(:,1)); % Check whether velocity of each trip is plausible, in m/s. Division of trip distance [m] by trip duration [s]
        if max(Velocities)>MaxPlausibleVelocity % is there a velocity unplausible?
            Indices=find(DrivingProfileTimePosix(:,2)==DrivingProfileTimePosix(:,1)); % Some trips are shorter than 1 minute, hence departure and arrival time are equal wich leads to mathematically infinet velocity. Find those cases
            if ~isempty(Indices) 
                for n=length(Indices):-1:1 
                    if Indices(n)+1<=length(DrivingProfile) && DrivingProfileTime(Indices(n),2)+minutes(1)<DrivingProfileTime(Indices(n)+1,1) && DrivingProfile(Indices(n),1)<MaxPlausibleVelocity*2*60
                        DrivingProfileTime(Indices(n), 2)=DrivingProfileTime(Indices(n), 2)+minutes(1); % if the next trip does not start immediatly after the case of equal departure and arrival time, then shift the arrival time for one minute
                    else
                        DrivingProfile(Indices(n),:)=[]; % else delete the trip
                        DrivingProfileTime(Indices(n),:)=[];
                    end
                end
                DrivingProfileTimePosix=posixtime(DrivingProfileTime); % recalculate the DrivingProfileTimePosix
                Velocities=DrivingProfile(:,1)./(DrivingProfileTimePosix(:,2)-DrivingProfileTimePosix(:,1)); % and Velocities as they might have changed
            end
            DrivingProfile(Velocities>MaxPlausibleVelocity,1)=uint32(mean(Velocities(Velocities<=MaxPlausibleVelocity))*(DrivingProfileTimePosix(Velocities>MaxPlausibleVelocity,2)-DrivingProfileTimePosix(Velocities>MaxPlausibleVelocity,1))); % Exchange all remaining unplausible velocities with the average velocity of the car by shortening the trip distance  m/s * s = m
        end

        DateRange=between(dateshift(DrivingProfileTime(1,1), 'start', 'day'), dateshift(DrivingProfileTime(end,2), 'start', 'day'), 'days')+caldays(1); % The number of calendar days from the first trip to the last one (01.01.2020 23:59 --> 20.01.2020 00:00 would equal to 20 days as well as 01.01.2020 0:00 --> 20.01.2020 23:59)
        Ranges(k)=DateRange; % save of DateRanges for evaluation reasons

        [DistanceCompanyToHome, HomeSpotFound, AvgHomeParkingTime]=DetermineHomeDistance(DrivingProfileTime, DrivingProfile(:,2), MaxHomeSpotDistanceDiff, MinShareHomeParking); % Investigate where most likely is the home spot of the vehicle. Find the spots where the vehicle is parked most often. Calculate the parking time per spot. The spot with the highest parking time is the home spot which is considered to have a charging point

        if DistanceCompanyToHome>0.012 || DistanceCompanyToHome<0.01
            continue
        else
            k
        end
        
        if ~HomeSpotFound % do not consider this vehicle if no valid home spot could be found
%             Vehicles{k}.ID
            Vehicles{k}=[];
            continue
        end
        
        Trips=[Trips; DrivingProfile(:,1)]; % record the trips of all vehicles for evaluation reasons
        NumTripsDays=NumTripsDays+caldays(DateRange); % record the total trip distance of every day of all vehicles for evaluation reasons

        DrivingProfileTime(:,2)=DrivingProfileTime(:,2)-seconds(1); % Ensures that one ride never ends when a transition of TimeVar happens. The -1 represents one second
        DrivingProfileTime=DrivingProfileTime+between(DrivingProfileTime(1,1),DateStart, 'days')-days(mod(7+(weekday(DateStart)-weekday(DrivingProfileTime(1,1))),7))+days(1); % Shift the dates such that the first ride starts at the first day before (or exactly at) DateStart that is the same weekday as the weekday of the first ride. 

        RemainingDates=mod(caldays(DateRange), 7); % One driving profile should cover a integer number of full weeks. Mostly this is not the case. 7-RemainingDates equals the number of missing days to complete the last week
        if RemainingDates~=0
            if RemainingDates<=2 % if there are two or one days more than one week (e. g. 15 or 16 days instead of 14)
                DeleteIndices=false(size(DrivingProfileTime, 1),1); % ... delete the trips of the surplus days
                for n=0:RemainingDates-1
                    DeleteIndices=DeleteIndices | dateshift(DrivingProfileTime(:,2), 'start', 'day')==dateshift(DrivingProfileTime(end,2), 'start', 'day')-caldays(n);
                end
                DrivingProfileTime(DeleteIndices, :)=[];
                DrivingProfile(DeleteIndices, :)=[];
            else % ... else add the trips of past days in order to complete this week. Therefore, the trips of the needed weekdays are copied and time shifted such that they complete the week
                TargetDate=dateshift(DrivingProfileTime(end,2), 'start', 'day')-caldays(caldays(DateRange)-mod(caldays(DateRange),7)-1); % The first recorded day that has the same weekday as the first one that is needed in order to complete the week
                while isempty(find(TargetDate==dateshift(DrivingProfileTime(:,1), 'start', 'day'),1)) % ... if on this date there are no trips recorded, search for the next day with recorded trips
                    TargetDate=TargetDate+caldays(1);
                end
                while dateshift(DrivingProfileTime(1,1), 'start', 'day')+caldays(7) > TargetDate % Copy all trips of the past days, shift them in time in order to complete the week
                    Indices=TargetDate==dateshift(DrivingProfileTime(:,1), 'start', 'day'); % find all trips that belog to TargetDay
                    DrivingProfileTime=[DrivingProfileTime; DrivingProfileTime(Indices,:)+DateRange-caldays(RemainingDates)]; % add them to the driving profile time and shift them in time
                    DrivingProfile=[DrivingProfile; DrivingProfile(Indices, :)]; % add them to the driving profile
                    TargetDate=TargetDate+caldays(1); % increment TargetDate until week is completed
                end
            end
        end

        DateRange=caldays(between(dateshift(DrivingProfileTime(1,1), 'start', 'day'), dateshift(DrivingProfileTime(end,2), 'start', 'day'), 'days')+caldays(1)); % Recalculate DateRange as it might have changed due to the fill up of the week

        if ~AddNoise
            DrivingProfileTimeExt=repmat(DrivingProfileTime, ceil(days(DateEnd-DateStart)/DateRange)+1,1); % The driving profile of this few weeks (2-5) is used a multiple times in order to fill the duration defined by DateStart and DateEnd. Therefore, this few weeks driving profile is repeated several times until the duration is reached
            DrivingProfileExt=repmat(DrivingProfile, ceil(days(DateEnd-DateStart)/DateRange)+1,1); % same as above with the trip distances and compan distances

            for n=1:ceil(days(DateEnd-DateStart)/DateRange)+1-1 % shift all departure and arrival times of the repeated profiles such that they match the interval specified by DateStart and DateEnd. So the first trip starts at or shortly after DateStart and the last trip ends shortly before or at DateEnd
                DrivingProfileTimeExt(n*size(DrivingProfile,1)+1:(n+1)*size(DrivingProfile,1),:)=DrivingProfileTimeExt(n*size(DrivingProfile,1)+1:(n+1)*size(DrivingProfile,1),:)+days(n*DateRange);
            end
            
            DrivingProfileTimeExtPosix=posix(DrivingProfileTimeExt);
        else
            
            WeekdayTable=cell(7,1);
            DayShiftedTimeProfiles=dateshift(DrivingProfileTime, 'start', 'day');
            DayOneShiftedTimeProfiles=DayShiftedTimeProfiles(1,1)+hours(hour(DrivingProfileTime))+minutes(minute(DrivingProfileTime))+seconds(second(DrivingProfileTime));
            DayOneShiftedTimeProfiles(DayOneShiftedTimeProfiles(:,1)>DayOneShiftedTimeProfiles(:,2),2)=DayOneShiftedTimeProfiles(DayOneShiftedTimeProfiles(:,1)>DayOneShiftedTimeProfiles(:,2),2)+day(1);
            DayProfileVec=(DayShiftedTimeProfiles(1,1):caldays(1):DayShiftedTimeProfiles(1,1)+caldays(DateRange-1))';
            for n=1:length(DayProfileVec)
                WeekdayTable{weekday(DayProfileVec(n)), ceil((n)/7)}=find(DayShiftedTimeProfiles(:,1)==DayProfileVec(n)); % first cell captures all driving profile times of all Sundays (weekday==1), seconds of all Mondays (weekday==2) and so on
            end
            
            RandDays=[(mod((0:ceil(days(DateEnd-DrivingProfileTime(end,2))-2))+weekday(DayShiftedTimeProfiles(1,1)+caldays(DateRange))-1,7)+1)', randi([1 ceil(DateRange/7)],ceil(days(DateEnd-DrivingProfileTime(end,2))-1),1)];
            DaysVec=(0:ceil(days(DateEnd-DrivingProfileTime(end,2))-2))'+DateRange;
            DrivingProfileTimeExt=[DrivingProfileTime; DayOneShiftedTimeProfiles(cell2mat(WeekdayTable((RandDays(:,2)-1)*7+RandDays(:,1))),:) + repmat(caldays(repelem(DaysVec,cellfun('length',WeekdayTable((RandDays(:,2)-1)*7+RandDays(:,1))))),1,2)];
            DrivingProfileExt=[DrivingProfile; DrivingProfile(cell2mat(WeekdayTable((RandDays(:,2)-1)*7+RandDays(:,1))),:)];
            
            DrivingProfileTimeExtPosix=posixtime(DrivingProfileTimeExt);            
            ParkingTime=[0;(DrivingProfileTimeExtPosix(2:end,1)-DrivingProfileTimeExtPosix(1:end-1,2))/60;0]; %[min]
            
            OverlappingTrips=find(ParkingTime<0)';            
            if ~isempty(OverlappingTrips)
                for n=flip(OverlappingTrips)
                    if n==length(DrivingProfileTimeExtPosix) || DrivingProfileTimeExtPosix(n,2)+max(-ParkingTime(n)*60*1.2, 60*60)<DrivingProfileTimeExtPosix(n+1,1)
                        DrivingProfileTimeExtPosix(n,:)=DrivingProfileTimeExtPosix(n,:)+max(-ParkingTime(n)*60*1.2, 60*60);
                    else
                        DrivingProfileTimeExtPosix(n-1,:)=[];
                        DrivingProfileExt(n-1,:)=[];
                    end
                end
                ParkingTime=[0;(DrivingProfileTimeExtPosix(2:end,1)-DrivingProfileTimeExtPosix(1:end-1,2))/60;0]; %[min]
            end
            
            OverlappingTrips=find(ParkingTime<0)';
            if ~isempty(OverlappingTrips)
                disp("Error")
                k
            end
            
            TripTime=(DrivingProfileTimeExtPosix(:,2)-DrivingProfileTimeExtPosix(:,1))/60; % [min]
            DrivingTimeHalf=TripTime/2; % [min]
            ShiftStart=zeros(length(TripTime),1);
            ShiftEnd=zeros(length(TripTime),1);
            for n=1:length(TripTime)
                ShiftStart(n,1)=TruncatedGaussian(TripTime(n)*TimeNoiseStdFac,[-ParkingTime(n) DrivingTimeHalf(n)],1); % [min]
                ShiftEnd(n,1)=TruncatedGaussian(TripTime(n)*TimeNoiseStdFac,[-DrivingTimeHalf(n) ParkingTime(n+1)],1); % [min]
            end

            DrivingProfileTimeExtPosix=DrivingProfileTimeExtPosix + fix([ShiftStart, ShiftStart+ShiftEnd])*60; %[s]
%             DrivingProfileTimeExt1=datetime(DrivingProfileTimeExtPosix1, 'ConvertFrom', 'posix', 'TimeZone', 'Africa/Tunis');
            DrivingProfileExt=[round(DrivingProfileExt(:,1) .* (1+(diff(DrivingProfileTimeExtPosix,1,2)-diff(DrivingProfileTimeExtPosix,1,2))./diff(DrivingProfileTimeExtPosix,1,2)).*(1+TruncatedGaussian(TimeNoiseStdFac,[0.9 1.1]-1,length(DrivingProfileTimeExtPosix),1))), DrivingProfileExt(:,2)];
            
        end
        
        DrivingProfileExt(DrivingProfileTimeExtPosix(:,1)<posixtime(DateStart) | DrivingProfileTimeExtPosix(:,1)>posixtime(DateEnd),:)=[]; % Delete all trips which are not between DateStart and DateEnd
        DrivingProfileTimeExtPosix(DrivingProfileTimeExtPosix(:,1)<posixtime(DateStart) | DrivingProfileTimeExtPosix(:,1)>posixtime(DateEnd),:)=[];
        

        LargestValue=max(DrivingProfile); % Check whether uint32 can be used

        % The Logbook covers all time intervals of LogbookTime. It stores
        % the current vehicle state (driving / parking, see encoding
        % below), the trip distance, the consumed energy through driving,
        % the charged energy at the home spot charger, the charged energy
        % at public chargers, the SoC
        % State: 1==Driving, 2==Parking anywhere, 3==Parking at home charging point, 4==connected to home charging point, 5==charging at home charging point, 6==charging at public charger
        
        if LargestValue<2^32 % State, DrivingTime [min], Distance [m], Consumption [Wh], Charged energy at home spot [Wh], Charged energy at public chagrer [Wh] SoC [Wh]
            Vehicles{k}.Logbook=uint32(zeros(size(LogbookTime,1),7)); 
        else 
            Vehicles{k}.Logbook=uint64(zeros(size(LogbookTime,1),7));
            disp(strcat("The largest value of Logbook ", num2str(n), " is larger than 2^32!"))
        end

        LogbookPointer=1; % Pointer that iterates through the logbook entries. Points to the current trip in Vehicles{k}.Logbook
        DrivingProfilePointer=1; % Pointer that iterates trough the time from DateStart to DateEnd in TimeStep intervals. Pointer points to index in LogbookTime and LogbookTimePosix

        for TimeVar=LogbookTimePosix(2:end)' % The time of TimeVar represents the the current real time. If TimeVar==15:15 then it is 15:15 right now, so the Logbook must give the status and SoC at 15:15. Hence, insided the loop, for each element of LogbookTime the past 15 minutes (15:00:00 - 15:14:59) are evaluated

            LogbookPointer=LogbookPointer+1;
            Distance=0; % Distance traveld during current TimeStep time interval [m]
            TripTime=0; % The duration of the current trip within during the TimeStep time interval [s]
            TimeStepDrivingTime=0; % Time driven during current TimeStep time interval [s]
            Vehicles{k}.Logbook(LogbookPointer,1)=0; % first state is undefined

            while DrivingProfilePointer<=size(DrivingProfileTimeExtPosix,1) && TimeVar>=DrivingProfileTimeExtPosix(DrivingProfilePointer,1) % if DrivingProfilePointer does not exceed DateEnd and the current time is larger than the departure time of the Logbook entry DrivingProfilePointer is pointing to, then the car is driving within this interval. Iterate through all logbook entries whichs trips are (partly) within the time interval pointed to by DrivingProfilePointer

                TripTime=min([TimeStepMin*60, DrivingProfileTimeExtPosix(DrivingProfilePointer,2)+1-DrivingProfileTimeExtPosix(DrivingProfilePointer,1), DrivingProfileTimeExtPosix(DrivingProfilePointer,2)+1-(TimeVar-TimeStepMin*60), TimeVar-DrivingProfileTimeExtPosix(DrivingProfilePointer,1)]); % [s] The driving time of this time interval is maximal TimeStepMin in seconds (therefore *60) long. This is the case, if depature time is before the beginning of the interval and the arrival time after it. If one of them was during the last TimeStepMin minutes, the part of the trip time that is within the interval is calculated
                TimeStepDrivingTime=TimeStepDrivingTime+TripTime;
    %             DrivingTime=DrivingTime+min([minutes(15), DrivingProfileTimeExt(DrivingProfilePointer,2)+seconds(1)-DrivingProfileTimeExt(DrivingProfilePointer,1), DrivingProfileTimeExt(DrivingProfilePointer,2)+seconds(1)-(TimeVar-minutes(15)), TimeVar-DrivingProfileTimeExt(DrivingProfilePointer,1)]);
                Distance=Distance+DrivingProfileExt(DrivingProfilePointer,1)*TripTime/(DrivingProfileTimeExtPosix(DrivingProfilePointer,2)-DrivingProfileTimeExtPosix(DrivingProfilePointer,1)); % Calculate within TimeStepinterval as timely share of (multiple) DrivingProfile entries
                
                if Distance/TimeStepDrivingTime>60
                    1
                end
                    
                if TimeVar >= DrivingProfileTimeExtPosix(DrivingProfilePointer,1) && TimeVar < DrivingProfileTimeExtPosix(DrivingProfilePointer,2) % if at the end of the time interval the car is still driving, than the state is driving (==1)
                    Vehicles{k}.Logbook(LogbookPointer,1)=1;
                end
                if TimeVar>DrivingProfileTimeExtPosix(DrivingProfilePointer,2) && DrivingProfilePointer<=size(DrivingProfileTimeExtPosix,1) % if at the end of the time interval the last trip has ended, point to the next trip
                    DrivingProfilePointer=DrivingProfilePointer+1;
                else
                    break
                end
            end

            Vehicles{k}.Logbook(LogbookPointer,2)=round(TimeStepDrivingTime/60); % driven time in minutes
            Vehicles{k}.Logbook(LogbookPointer,3)=Distance; % distance in meters

            if Vehicles{k}.Logbook(LogbookPointer,1)==0 % if the car is not driving at the end of the time interval (else before it was set to 1)
                if abs(DrivingProfileExt(max(DrivingProfilePointer-1,1), 2)-DistanceCompanyToHome)<MaxHomeSpotDistanceDiff % if the distance to the company to the home spot at the end of the last trip is smaller than MaxHomeSpotDistanceDiff
                    Vehicles{k}.Logbook(LogbookPointer,1)=3; % ... then the charger is parked at home and might be defined as charging within the simulation script
                else
                    Vehicles{k}.Logbook(LogbookPointer,1)=2; % ... else it is parked anywhere else
                end
            end

            if DrivingProfilePointer>size(DrivingProfileTimeExtPosix,1) % if all trips of the driving profiles are processed
                Vehicles{k}.Logbook(LogbookPointer:end,1)=Vehicles{k}.Logbook(LogbookPointer,1); % extend the current state until the end of the logbook
                break % and end this loop for this vehicle
            end
        end
        Vehicles{k}.Logbook(1,1)=Vehicles{k}.Logbook(2,1); % copy the state of the second logbook entry to the first one, as it was undefined
        Vehicles{k}.AverageMileageDay_m=uint32(sum(Vehicles{k}.Logbook(:,3))/days(DateEnd-DateStart)); %[m] 
        Vehicles{k}.AverageMileageYear_km=uint32(sum(Vehicles{k}.Logbook(:,3))/days(DateEnd-DateStart)*365.25/1000); %[km]
        Vehicles{k}.DistanceCompanyToHome=DistanceCompanyToHome;
        Vehicles{k}.AvgHomeParkingTime=AvgHomeParkingTime;
        
        DayTrips=[DayTrips; sum(reshape(Vehicles{k}.Logbook(1:DateRange*96,3), 96, []), 1)'];
        
        if ActivateWaitbar
            waitbar(k/length(Vehicles))
        end

    end
    if ActivateWaitbar
        close(h);
    end

    Vehicles=Vehicles(~cellfun('isempty', Vehicles)); % delete all cells of those vehicles that weren't furhter considered
    CheckField = @(Vehicle, Field) (isfield(Vehicle, 'Logbook') || isfield(Vehicle, 'TimeVec'));
    Vehicles=Vehicles(cellfun(CheckField, Vehicles));

    Vehicles{1}.TimeStamp=datetime('now');
    Vehicles{1}.FileName=strcat(StorageFile, "_", datestr(Vehicles{1}.TimeStamp, "yyyy-mm-dd_HH-MM"), ".mat");
    save(Vehicles{1}.FileName, "Vehicles", "-v7.3") % save the data in a file

    clearvars TimeVar DrivingProfilePointer DrivingProfileMatrix PathVehicleData VehicleID DateMat DrivingProfileTime DrivingProfileTimeExt Distance DrivingTime LogbookPointer DistanceCompanyToHome    
    clearvars DateMat DateMatStr DateRange DeleteIndices DrivingProfile Distances DrivingProfileMat DrivingProfileTimePosix h HomeSpotFound 
    clearvars Indices k LargestValue LogbookTime LogbookTimePosix CheckField StorageFiles StorageFile StorageInd AvgHomeParkingTime
    clearvars n Ranges RemainingDates SpotParkingTime TargetDate VehicleInfoMat VehicleMatIndices VehiclePropertiesMat VehicleDataRep
    clearvars DayOneShiftedTimeProfiles DayProfileVec DayShiftedTimeProfiles DaysVec DayTrips DrivingProfilesExt DrivingProfileTimeExtPosix DrivingTimeHalf
    clearvars MaxPlausibleVelocity MinShareHomeParking NumTripsDays OverlappingTrips ParkingTime RandDays TimeNoiseStdFac Trips TripTime VehicleMatIndices
    clearvars Velocities WeekdayTable ShiftStart ShiftEnd
end

clearvars ActivateWaitbar AddNoise NumVehicles MaxHomeSpotDistanceDiff StorageFile PathVehicleData

disp(['Vehcile Data successfully imported ' num2str(toc) 's'])

if Evaluation
    %% Evaluation

    DistanceYearPerVehicle=0;
    a=[];
    EvalMat=cell(length(Vehicles)+1,1);
    EvalMat(1,1:3)=[{"Size"}, {"NumUsers"}, {"YearMileage"}];

    for k=1:length(Vehicles)
        EvalMat{k+1,1}=Vehicles{k}.VehicleSize;
        EvalMat{k+1,2}=Vehicles{k}.NumberUsers;
        EvalMat{k+1,3}=sum(Vehicles{k}.Logbook(:,3))/years(DateEnd-DateStart)/1000; % [km]

        DistanceYearPerVehicle=DistanceYearPerVehicle+sum(Vehicles{k}.Logbook(:,3))/1000;
        a(k,1)=sum(Vehicles{k}.Logbook(:,3))/1000;
        if max(Vehicles{k}.Logbook(:,3))>1000*1000
            k
            [~, ind]=max(Vehicles{k}.Logbook(:,3))
        end
    end
    DistanceYearPerVehicle=DistanceYearPerVehicle/length(Vehicles)/years(DateEnd-DateStart)
    
    if exist('Trips', 'var')
        histogram(Trips/1000, 0:5:max(Trips)/1000)
        figure
        DayTripsExZeros=DayTrips(DayTrips>0);
        histogram(DayTripsExZeros/1000, 0:5:max(DayTripsExZeros)/1000)
        disp(strcat("Trips per Day: ", num2str(numel(Trips)/NumTripsDays)))
    end

    figure
    histogram(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="small"],3)), 0:5000:max(cell2mat(EvalMat(2:end,3))), 'Normalization','probability')
    hold on    
    histogram(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="medium"],3)), 0:5000:max(cell2mat(EvalMat(2:end,3))), 'Normalization','probability')
    histogram(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="large"],3)), 0:5000:max(cell2mat(EvalMat(2:end,3))), 'Normalization','probability')
    histogram(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="transporter"],3)), 0:5000:max(cell2mat(EvalMat(2:end,3))), 'Normalization','probability')
    legend(["small", "medium", "large", "transporter"])

    MileageMap=[{"catgegory"}, {"small"}, {"medium"}, {"large"}, {"transporter"}];
    MileageMap(2,:)=[{"Num Vehicles"}, num2cell([numel(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="small"],3))), numel(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="medium"],3))), numel(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="large"],3))), numel(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="transporter"],3)))])];
    MileageMap(3,:)=[{"yearly mileage [km]"}, num2cell([mean(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="small"],3))), mean(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="medium"],3))), mean(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="large"],3))), mean(cell2mat(EvalMat([false;string(EvalMat(2:end,1))=="transporter"],3)))])];
end

clearvars Evaluation 