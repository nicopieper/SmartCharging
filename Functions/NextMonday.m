function Monday=NextMonday(Date)
    Monday=Date+days(mod(7-mod(weekday(Date)+5,7),7));
end