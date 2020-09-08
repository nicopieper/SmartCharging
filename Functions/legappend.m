function [Legend]=legappend(Legend, Label)
if ~isstring(Label)
    Label=string(Label);
end
if isempty(Legend)
    Legend=legend(Label);
else
    Legend.String{end}=Label;
end
end