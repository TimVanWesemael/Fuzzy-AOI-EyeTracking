function plot_timeframe(data, name)
%PLOT_TIMEFRAME Summary of this function goes here
%   Detailed explanation goes here
    figure('Name', name);
    hold on;
    ylim([0, 1]);
    ylabel 'absolute score of aoi'
    xlabel 'time of frame in seconds'
    leg = {};
    colors = {'m', 'c', 'g', 'b', 'r', 'k'};
    for i = 1:length(data)
        aois = fieldnames(data);
        aois(strcmp(aois, 'startT'))=[];
        aois(strcmp(aois, 'endT'))=[];
        for a = 1:length(aois)
            aoi = aois{a};
            plot([data(i).startT data(i).endT]/1000, [data(i).(aoi) data(i).(aoi)], colors{a});
        end
    end
    legend(aois);
    hold off
end

