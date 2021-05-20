%% Description
% This script caluclates the appropiate limits for the y axes of the plots.
% Depending on DemoPlots{n}.YMin{k} / DemoPlots{n}.YMax{k}, the axes are 
% set dynamically basing on the highest and lowest values during the next 
% days or they are set constantly as defined by DemoPlots{n}.YMin{k} / 
% DemoPlots{n}.YMax{k}.
%
% Depended scripts / folders
%   Initialisation.m        Needed for the execution of this script
%   Demonstration.m         This script is called by Demonstration.m


%% Update Y axis min limit

if ~strcmp(DemoPlots{n}.YMin{k}, 'dynamic')
    DemoPlots{n}.ymin{k}=DemoPlots{n}.YMin{k};
else    
    ymin=min(DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}-24*2*Time.StepInd:min(length(DemoPlots{n}.Data{k}),TimeInd+DemoPlots{n}.Time.TD{k}+24*2*Time.StepInd)));
    ymin=ymin-abs(ymin)*0.1;
    if ymin~=0
        DemoPlots{n}.ymin{k}=round(ymin-abs(ymin)*0.1, ceil(log10(abs(ymin))));
    else
        DemoPlots{n}.ymin{k}=0;
    end
end


%% Update Y axis max limit

if ~strcmp(DemoPlots{n}.YMax{k}, 'dynamic')
    DemoPlots{n}.ymax{k}=DemoPlots{n}.YMax{k};
else    
    ymax=max(DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}-24*2*Time.StepInd:min(length(DemoPlots{n}.Data{k}),TimeInd+DemoPlots{n}.Time.TD{k}+24*2*Time.StepInd)));
    ymax=ymax+abs(ymax)*0.1;
    if ymax~=0
    	DemoPlots{n}.ymax{k}=round(ymax+abs(ymax)*0.1, ceil(log10(abs(ymax))));
    elseif ymin<0
        DemoPlots{n}.ymax{k}=0;
    else
        DemoPlots{n}.ymax{k}=round(ymax);
    end
end
