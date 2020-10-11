if ~strcmp(DemoPlots{n}.YMin{k}, 'dynamic')
    DemoPlots{n}.ymin{k}=DemoPlots{n}.YMin{k};
else    
    ymin=min(DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}-24*2*Time.Demo.StepInd:min(length(DemoPlots{n}.Data{k}),TimeInd+DemoPlots{n}.Time.TD{k}+24*2*Time.Demo.StepInd)));
    DemoPlots{n}.ymin{k}=round(ymin-abs(ymin)*0.1);
end

if ~strcmp(DemoPlots{n}.YMax{k}, 'dynamic')
    DemoPlots{n}.ymax{k}=DemoPlots{n}.YMax{k};
else    
    ymax=max(DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}-24*2*Time.Demo.StepInd:min(length(DemoPlots{n}.Data{k}),TimeInd+DemoPlots{n}.Time.TD{k}+24*2*Time.Demo.StepInd)));
    DemoPlots{n}.ymax{k}=round(ymax+abs(ymax)*0.1);
end
