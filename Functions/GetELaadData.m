formatSpec = '%s';

File=fopen(strcat(PathVehicleData, 'Distribution_of_arrival_times_on_weekdays.csv'),  'r');  % Time, Private, Public, Workplace
ArrivalWeekdaysELaad=fscanf(File,formatSpec);
fclose(File);
ArrivalWeekdaysELaad=strrep(ArrivalWeekdaysELaad, '";', ';');
ArrivalWeekdaysELaad=strrep(ArrivalWeekdaysELaad, '"', ';');
ArrivalWeekdaysELaad=strsplit(ArrivalWeekdaysELaad, ";");
ArrivalWeekdaysELaad=reshape(ArrivalWeekdaysELaad(6:end)', 4, [])';
ArrivalWeekdaysELaad=str2double(strrep(ArrivalWeekdaysELaad(1:end, 2:end), ",", "."));

ArrivalWeekendsELaad=readmatrix(strcat(PathVehicleData, 'Distribution_of_arrival_times_on_weekends.csv'), 'NumHeaderLines', 1, 'OutputType', 'string');
ArrivalWeekendsELaad=str2double(strrep(ArrivalWeekendsELaad(:,2:3), ',', '.')); % Private, Public

ArrivalTimesELaad=[(ArrivalWeekdaysELaad(:,1:2)*5+ArrivalWeekendsELaad*2)/7, ArrivalWeekdaysELaad(:,3)];

ConnectionTimeELaad=readmatrix(strcat(PathVehicleData, 'Distribution_of_connection_time_per_charging_event.csv'), 'NumHeaderLines', 1, 'OutputType', 'string');
ConnectionTimeELaad=str2double(strrep(ConnectionTimeELaad, ',', '.')); % Length in hours, Private, Public, Workplace

EnergyDemandELaad=readmatrix(strcat(PathVehicleData, 'Distribution_of_energy_demand_time_per_charging_event.csv'), 'NumHeaderLines', 1, 'OutputType', 'string');
EnergyDemandELaad=str2double(strrep(EnergyDemandELaad, ',', '.')); % Length in hours, Private, Public, Workplace


clearvars File formatSpec