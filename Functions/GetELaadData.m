formatSpec = '%s';

File=fopen(strcat(Path.Vehicle, 'Distribution_of_arrival_times_on_weekdays.csv'),  'r');  % Time, Private, Public, Workplace
ELaad.ArrivalWeekdays=string(fscanf(File,formatSpec));
[~]=fclose(File);
LineBreaks=strfind(ELaad.ArrivalWeekdays, ":");
for n=flip(LineBreaks-2)
    ELaad.ArrivalWeekdays=insertBefore(ELaad.ArrivalWeekdays,n,";");
end
ELaad.ArrivalWeekdays=strsplit(ELaad.ArrivalWeekdays, ";");
ELaad.ArrivalWeekdays=reshape(ELaad.ArrivalWeekdays(5:end)', 4, [])';
ELaad.ArrivalWeekdays=str2double(ELaad.ArrivalWeekdays(1:end, 2:end));

ELaad.ArrivalWeekends=readmatrix(strcat(Path.Vehicle, 'Distribution_of_arrival_times_on_weekends.csv'), 'NumHeaderLines', 1, 'OutputType', 'string');
ELaad.ArrivalWeekends=str2double(strrep(ELaad.ArrivalWeekends(:,2:3), ',', '.')); % Private, Public

ELaad.ArrivalTimes=[(ELaad.ArrivalWeekdays(:,1:2)*5+ELaad.ArrivalWeekends*2)/7, ELaad.ArrivalWeekdays(:,3)];

ELaad.ConnectionTime=readmatrix(strcat(Path.Vehicle, 'Distribution_of_connection_time_per_charging_event.csv'), 'NumHeaderLines', 1, 'OutputType', 'string');
ELaad.ConnectionTime=str2double(strrep(ELaad.ConnectionTime, ',', '.')); % Length in hours, Private, Public, Workplace

ELaad.EnergyDemand=readmatrix(strcat(Path.Vehicle, 'Distribution_of_energy_demand_time_per_charging_event.csv'), 'NumHeaderLines', 1, 'OutputType', 'string');
ELaad.EnergyDemand=str2double(strrep(ELaad.EnergyDemand, ',', '.')); % Length in hours, Private, Public, Workplace


clearvars File formatSpec LineBreaks n