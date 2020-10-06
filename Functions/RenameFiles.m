%% Rename VehicleData

StorageFile=strcat(Path.Vehicle, "VehicleData_*");
StorageFiles=dir(strcat(StorageFile));

for n=StorageFiles'
    load(strcat(n.folder, '\', n.name))
    FileName=n.name;
    if isfield(Vehicles{1}, 'TimeStamp')
        Vehicles{1}.Time.Stamp=Vehicles{1}.TimeStamp;
        Vehicles{1}=rmfield(Vehicles{1}, 'TimeStamp');
    end
    Del=strfind(n.name, '_');
    TimeInterval=strcat(datestr(Vehicles{1}.Time.Vec(1), 'yyyymmdd'), "-", datestr(Vehicles{1}.Time.Vec(end), 'yyyymmdd'));
    FileNameTemp=strcat("VehicleData", FileName(end-17:end-4), "_", TimeInterval, FileName(12:end-18), ".mat");
    Vehicles{1}.FileName=FileNameTemp;
    save(strcat(n.folder, '\', FileNameTemp), 'Vehicles', '-v7.3');
end
