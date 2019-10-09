function  averageTimeframe(results, name, opt)
    all_participants = fieldnames(results);
    experiments = opt.experiments;
    
    for experiment = experiments
        experiment = experiment{1};
        aoi_names = opt.aois.(matlab.lang.makeValidName(experiment)).names;
        nb_aois = length(aoi_names.voronoi) + length(aoi_names.rect);
        A = [];
        C = [];
        nb_A = 0;
        nb_C = 0;
        
        for participant_index = 1:length(all_participants)
            participant = all_participants{participant_index};
            if isfield(results.(matlab.lang.makeValidName(participant)).results, experiment)
                part_timeframe = results.(matlab.lang.makeValidName(participant)).results.(matlab.lang.makeValidName(experiment)).timeframe;
                curr= [];
                if isfield(part_timeframe, 'vor')
                    trails = fieldnames(part_timeframe.vor);
                    for tr = 1:length(trails)
                        trail = trails{tr};
                        trdata = struct2table(part_timeframe.vor.(trail));
                        if isempty(curr)
                            curr = trdata;
                        else
                            curr{:,:} = curr{:,:} + trdata{:,:};
                        end
                    end
                    curr{:,:} = curr{:,:}./length(trails);
                end
                if isfield(part_timeframe, 'rect')
                    cur = [];
                    trails = fieldnames(part_timeframe.rect);
                    for tr = 1:length(trails)
                        trail = trails{tr};
                        trdata = struct2table(part_timeframe.rect.(trail));
                        if isempty(cur)
                            cur = trdata;
                        else
                            cur{:,:} = cur{:,:} + trdata{:,:};
                        end
                    end
                    cur{:,:} = cur{:,:}./length(trails);
                    if isempty(curr)
                        curr = cur;
                    else
                        curr = [curr cur(:,3:end)];
                    end
                end
            end
            if contains(participant, 'A')
                if isempty(A)
                    A = curr;
                else
                    A{:,:} = A{:,:} + curr{:,:};
                end
                nb_A = nb_A + 1;
            end
            if contains(participant, 'C')
                if isempty(C)
                    C = curr;
                else
                    C{:,:} = C{:,:} + curr{:,:};
                end
                nb_C = nb_C + 1;
            end
        end
        mkdir results;
        if nb_A > 0
            A{:,:} = A{:,:}./nb_A;
            plot_timeframe(table2struct(A), [experiment, '_A_timeframe_', name]);
            writetable(A, ['results/', experiment, '_A_timeframe_', name, '.csv']);
        end
        if nb_C > 0
            C{:,:} = C{:,:}./nb_C;
            plot_timeframe(table2struct(C), [experiment, '_C_timeframe_', name]);
            writetable(A, ['results/', experiment, '_C_timeframe_', name, '.csv']);
        end
    end
end

