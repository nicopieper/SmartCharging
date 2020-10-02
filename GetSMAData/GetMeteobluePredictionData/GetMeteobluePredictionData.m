MeteoblueURL="http://my.meteoblue.com/packages/historypv-1h?apikey=";
MeteoblueKey="6eb6f7089799";

StartDateURL=["2018-01-01"; "2019-01-01"; "2020-01-01"];
EndDateURL=["2018-12-31"; "2019-12-31"; "2020-08-31"];
Years=["2018"; "2019"; "2020"];

options=weboptions;
options.Timeout=100;

h=waitbar(0, "Load data from meteoblue API");

for n=1:20%size(PlantTab,1) % Vollständig 1-3
    PlantPath=strcat(PathSMAData, PlantTab.ID(n), Dl, "PredictionData");
    
    for k=1:3 %3
        YearPath=strcat(PlantPath, Dl, Years(k));

        if ~isfolder(YearPath)
            mkdir(YearPath)
        end

        URL=strcat(MeteoblueURL, MeteoblueKey, "&lat=", num2str(PlantTab.Lat(n)), "&lon=", num2str(PlantTab.Long(n)), "&tz=Africa%2FTunis&city=", PlantTab.City(n), "&startdate=", StartDateURL(k), "&enddate=", EndDateURL(k), "&kwp=", num2str(PlantTab.PeakPower(n)), "&slope=", num2str(PlantTab.Slope(n)), "&facing=", num2str(180+PlantTab.Azimuth(n)));

%         RawData1=webread("http://my.meteoblue.com/packages/historypv-day?lat=47.56&lon=7.57&startdate=2020-01-01&enddate=2020-01-31&apikey=DEMOKEY&sig=29c407c9c80d4663f66e24c9ac9bebd8", options);
        RawData=webread(URL, options);
        save(strcat(YearPath, Dl, "RawPredictionData", "_", Years(k), ".mat"), "RawData", "-v7.3");
        PlantData=RawData.history_1h.pvpower_backwards;
        PlantDataTime=RawData.history_1h.time;
        
        writematrix(PlantData,strcat(YearPath, Dl, "PlantData_", Years(k), ".csv"),'Delimiter','comma');
        writecell(PlantDataTime,strcat(YearPath, Dl, "PlantDataTime_", Years(k), ".csv"),'Delimiter','comma');
        
        if strcmp(Years(k), "2018")
            PlantData1=[PlantData(1:24*(31+28+24)+2); 0; PlantData(24*(31+28+24)+3:24*(31+28+31+30+31+30+31+31+30+28)+3); PlantData(24*(31+28+31+30+31+30+31+31+30+28)+5:end)];
            Profile=double(PVPlants{PlantTab.PVPlantsNum(n)}.Profile(1:96*365));
        elseif strcmp(Years(k), "2019")
            PlantData1=[PlantData(1:24*(31+28+30)+2); 0; PlantData(24*(31+28+30)+3:24*(31+28+31+30+31+30+31+31+30+26)+3); PlantData(24*(31+28+31+30+31+30+31+31+30+26)+5:end)];
            Profile=double(PVPlants{PlantTab.PVPlantsNum(n)}.Profile(1+96*365:2*96*365));
        elseif strcmp(Years(k), "2020")
            PlantData1=[PlantData(1:24*(31+28+28)+2); 0; PlantData(24*(31+28+28)+3:end-1)];
            Profile=double(PVPlants{PlantTab.PVPlantsNum(n)}.Profile(1+2*96*365:2*96*365+96*(31+29+31+30+31+30+31+31)));
        end

        %%
        RMSE=[];
        MAE=[];
        Corr=[];
        for m=1:4
            a=PlantData1;
            ProfileH=mean(reshape([zeros(m,1); Profile(1:end-m)], 4,[],1));
            RMSE(m)=sqrt(mean((ProfileH'/PlantTab.PeakPower(n)/1000-a/mean(a)*mean(ProfileH)/PlantTab.PeakPower(n)/1000).^2));
            MAE(m)=mean(abs(ProfileH'/PlantTab.PeakPower(n)/1000-a/mean(a)*mean(ProfileH)/PlantTab.PeakPower(n)/1000));
            temp=corrcoef(ProfileH', a);
            Corrs(m)=temp(2,1);
        end
        Years(k)
        [min(RMSE), min(MAE), max(Corrs)]
        %%
    end
    
    waitbar(n/size(PlantTab,1));
end

close(h)


%% Load to mat files

Files=dir(PathSMAData);
Files=Files(strlength(cellstr({Files(:).name}))>5);
Files=Files(~strcmp(cellstr({Files(:).name}),'ListOfUnsuitablePlants.csv'));
close all hidden

Plants=[];
h=waitbar(0, 'Lade PV-Profile von lokalem Pfad');    
for n=1:size(Files,1)

    PlantPath=strcat(PathSMAData, Files(n).name);
    
    if ~isfolder(strcat(PlantPath, Dl, "PredictionData"))
        continue
    end
    
    if isfile(strcat(PlantPath, Dl, "PredictionData", Dl, "PlantDataComplete_2018-01-01_2020-08-31", ".mat"))
        delete(strcat(PlantPath, Dl, "PredictionData", Dl, "PlantDataComplete_2018-01-01_2020-08-31", ".mat"))
    end
    if isfile(strcat(PlantPath, Dl, "PredictionData", Dl, "PlantDataTimeComplete_2018-01-01_2020-08-31", ".mat"))
        delete(strcat(PlantPath, Dl, "PredictionData", Dl, "PlantDataTimeComplete_2018-01-01_2020-08-31", ".mat"))
    end
    
    Folders=dir(strcat(PlantPath, Dl, "PredictionData"));
    Folders=Folders(strlength(cellstr({Folders(:).name}))==4);
       
    PlantDataComplete=[];
    PlantDataTimeComplete=[];
    for k=1:size(Folders,1)
        PlantData=readmatrix(strcat(PlantPath, Dl, "PredictionData", Dl, Folders(k).name, Dl, "PlantData_", Folders(k).name, ".csv"));
        
        if length(PlantData)>2000        
             Plants=[Plants; string(Files(n).name)];
        
            if strcmp(Folders(k).name, "2018")
                PlantData=[PlantData(1:24*(31+28+24)+2); 0; PlantData(24*(31+28+24)+3:24*(31+28+31+30+31+30+31+31+30+28)+3); PlantData(24*(31+28+31+30+31+30+31+31+30+28)+5:end)];
            elseif strcmp(Folders(k).name, "2019")
                PlantData=[PlantData(1:24*(31+28+30)+2); 0; PlantData(24*(31+28+30)+3:24*(31+28+31+30+31+30+31+31+30+26)+3); PlantData(24*(31+28+31+30+31+30+31+31+30+26)+5:end)];
            elseif strcmp(Folders(k).name, "2020")
                PlantData=[PlantData(1:24*(31+28+28)+2); 0; PlantData(24*(31+28+28)+3:end-1)];
            end
        end
        PlantDataComplete=[PlantDataComplete; PlantData];
        PlantDataTimeComplete=[PlantDataTimeComplete; readmatrix(strcat(PlantPath, Dl, "PredictionData", Dl, Folders(k).name, Dl, "PlantDataTime_", Folders(k).name, ".csv"))];

    end
    save(strcat(PlantPath, Dl, "PredictionData", Dl, "PlantDataComplete_2018-01-01_2020-08-31", ".mat"), "PlantDataComplete","-v7.3");
    save(strcat(PlantPath, Dl, "PredictionData", Dl, "PlantDataTimeComplete_2018-01-01_2020-08-31", ".mat"), "PlantDataTimeComplete","-v7.3");
    waitbar(n/size(Files,1))
end
Plants2=unique(Plants);
close(h);




