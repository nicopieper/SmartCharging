function x=FillMissingValues(x, TimeStep) % Replace NaN values in matrices. Depending on where the NaN occurs, either past (24h and 24*7h) or future values (24h or 24*7h) are used.
indices=find(isnan(x));
Warning=0;

if ~isempty(indices)
    if numel(indices)<0.2*numel(x)
        n=1;
        while n<=length(indices)
            if indices(n)>7*24*TimeStep
               try
                while n<=length(indices)
                    x(indices(n))=mean([x(indices(n)-24*TimeStep),x(indices(n)-24*7*TimeStep)]);
                    n=n+1;
                end
               catch ME
                   x(indices(n))
                   mean(x(indices(n)-24*TimeStep),x(indices(n)-24*7*TimeStep))
               end
            elseif indices(n) >=24*TimeStep
                x(indices(n))=mean([x(indices(n)-24*TimeStep),x(indices(n)-1)]);
                n=n+1;
            else
                if ~isnan(x(indices(n)+24*TimeStep))
                    x(indices(n))=x(indices(n)+24*TimeStep);
                    n=n+1;
                elseif ~isnan(x(indices(n)+24*7*TimeStep))
                    x(indices(n))=x(indices(n)+24*7*TimeStep);
                    n=n+1;
                else
                    if Warning==0
                        disp(strcat('Too many undefined values. Filling the time series failed, starting at n=', num2str(n), '.'))
                        Warning=1;
                    end                
                end
            end
        end
    else
        disp('Too many undefined values.')
    end
end  

end