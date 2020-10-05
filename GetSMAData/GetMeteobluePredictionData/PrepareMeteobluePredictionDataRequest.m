formatSpec = '%s';
Files=dir(PathSMAData);
Files=Files(strlength(cellstr({Files(:).name}))>5);
Files=Files(~strcmp(cellstr({Files(:).name}),'ListOfUnsuitablePlants.csv'));
options=weboptions;
options.Timeout=10;

OpendatasoftURL="https://public.opendatasoft.com/api/records/1.0/search/?dataset=postleitzahlen-deutschland&q=";

close all hidden
clearvars ID City PeakPower Azimuth Slope Lat Long MaxPowerTime PVPlantsNum Yield ZIP
h=waitbar(0, 'Prepare prediction request data');    
counter=0;
for n=1:size(Files,1)

    waitbar(n/size(Files,1));
    PlantPath=strcat(PathSMAData, Files(n).name);
    
    k=1;
    while k<=length(PVPlants) && ~strcmp(PVPlants{k}.ID, Files(n).name)
        k=k+1;
    end
    if k>length(PVPlants)
        continue
    end
    
    if isfile(strcat(PlantPath, Dl, 'AzimutSlope.csv'))
    
        File=fopen(strcat(PlantPath, Dl, 'AzimutSlope.csv'), 'r');
        AzimuthSlope = fscanf(File,formatSpec);
        fclose(File);
        if length(AzimuthSlope)<5
            disp(['AzimuthSlope of plant ' Files(n).name ' is empty'])
        end
        Colon=strfind(AzimuthSlope, ":");
        Degree=strfind(AzimuthSlope, "°");
        
    else
        continue
    end
    
    File=fopen(strcat(PlantPath, Dl, 'PlantProperties.csv'), 'r');
    Properties = fscanf(File,formatSpec);
    fclose(File);
    if length(Properties)<20
        disp(['Properties of plant ' Files(n).name ' are empty'])
    end
    Delimiter=strfind(Properties, '"');
    Properties=strsplit(strrep(Properties, '"', ";"), ';');
    CityTemp=erase(string(Properties{2}), '"');
    ZIPTemp=erase(string(Properties{9}), '"');
    if length(char(ZIPTemp))>5
        continue
    end

    
    counter=counter+1;
    ZIP(counter,1)=ZIPTemp;
    
    CoordsRaw=webread(strcat(OpendatasoftURL, ZIPTemp, "&facet=note&facet=plz"), options);
    Coords=CoordsRaw.records(1).fields.geo_point_2d;
    Lat(counter,1)=Coords(1);
    Long(counter,1)=Coords(2);
    
    PeakPower(counter,1)=str2double(strrep(erase(string(Properties{4}), "kWp"), ",", "."));
    ID(counter,1)=string(Properties{5});
    City(counter,1)=erase(CityTemp, ",Deutschland");
    Slope(counter,1)=str2double(AzimuthSlope(Colon(1)+1:Degree(1)-1));
    Azimuth(counter,1)=str2double(AzimuthSlope(Colon(2)+1:Degree(2)-1));
    
    
    DailyProfile=mean(reshape(PVPlants{k}.Profile, 96, []),2);
    [~, temp]=max(DailyProfile);
    MaxPowerTime(counter,1)=hours(temp/4);
    Yield(counter,1)=sum(double(PVPlants{k}.Profile))/4/ceil(days(Time.End-Time.Start))/1000*365.25;
    
    PVPlantsNum(counter,1)=k;
    
end
close(h);

PlantTab=table(PVPlantsNum, ID, City, PeakPower, Yield, Yield./PeakPower, Azimuth, Slope, MaxPowerTime, Lat, Long, ZIP)
% ID,, Long, ZIP)

DeleteList=["0857d19f-8338-4227-9dc1-6ecb82d5a84b", "1256d348-4e6d-46f0-8caf-8d4e5f390a82", "125d8258-934e-41f8-b790-ba8828d485a8",...
    "4a46e65a-1bfb-47f3-bc3f-04779803e7e7", "531cfeb4-6cdd-47f0-bdad-23fccb7ca555", "53545e47-302f-4793-b629-57c9a61702d1", ...
    "582c9aa7-4673-437c-963e-ffc68684eb20", "6af7de5c-adc5-4a55-b079-cc60e5e4fe10", "7cd8481b-5956-4f73-9acf-761e11fb3254", ...
    "8d84e5be-8b95-4ffa-b608-7b2efe522819", "9f046f84-b2d8-4112-ac1b-198f349f161b", "a3a90ed2-9252-4e73-8a34-b1234ad3349e", ...
    "a51d19f7-704b-423e-876e-f6ae390853d0", "af3c5280-6d51-4938-b713-5dc8a30f47fd", "b80b94b5-2795-4d43-b891-81a2cae00ed9", ...
    "be866834-9e69-49b0-8dc3-bafedc0ad7e4", "c0b4580c-9a68-42f0-b2f6-559b4e6f492e", "e88bc356-9469-46bc-b2b5-51dcfbcfd3d2", ...
    "f092357c-83d9-4ded-8610-a2dc599bb2c3", "43f6649d-cf36-4dcf-beee-07b358a5142d", "242d4e6e-7cff-40e0-8c70-f521d9ce2bc5", ...
    "b768e200-21ee-4328-a985-eb567c5607fe", "7bd53432-9908-4d0c-b953-344c32505379", "2929c3b5-e44a-40b7-be2d-947f12ddf304", ...
    "1fda8c85-11d7-47a6-a291-21c4d2b01115", "6c8869fc-dc18-443d-9380-f740979f5628", "defde1e1-030f-4c01-a782-c33cd704fffc", ...
    "8405cae5-f8d9-4d07-bd7d-7d7c0c52f2af", "9dc44cd6-d6cb-46fb-b225-723d999bb464", "6c8869fc-dc18-443d-9380-f740979f5628", ...   
    "26b6ecdc-a431-40e2-afe2-ce57520e6a41", "fc49e5d1-9367-4a3e-bef2-fe0875bd8b33", "69600703-8fbf-404e-ab41-031f7c2b724b", ...
    "3520c141-8b83-4251-9a25-5a703b3e9d44", "94e422fb-2345-4290-ba89-c93f7762e8af", "37db6797-960c-4213-bdbc-22b3578c01e3", ...
    "47578a10-c2a6-4de2-b761-ae76b18a425a", "575bf92a-a588-46aa-aa70-3dd05898bdfd", "fb4dc600-2792-4d06-8fdc-07f3a85179f4", ...
    "ebc28225-e5a9-40c7-b811-bec059966cde", "c4437621-f9eb-47f6-81bd-7a81619ed4d4", "67c94c1b-525f-4817-a0a8-e04da92b7f8e", ...
    "3460d7a9-71e4-4808-9a48-1ae9f688d469", "e95b00f5-ed25-469a-992f-9972977ac908"
    ];

%%
Indices=[];
for n=1:length(DeleteList)
    PlantTab(find(ismember(PlantTab.ID, DeleteList(n))), :)=[];
end
 
%%
counter