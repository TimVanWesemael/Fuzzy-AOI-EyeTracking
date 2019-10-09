function  averageGroup(results, name, opt)
    all_participants = fieldnames(results);
    experiments = opt.experiments;
    
    for experiment = experiments
        experiment = experiment{1};
        aoi_names = opt.aois.(matlab.lang.makeValidName(experiment)).names;
        nb_aois = length(aoi_names.voronoi) + length(aoi_names.rect);
        results_A_mean = zeros(2, nb_aois);
        results_C_mean = zeros(2, nb_aois);
        results_A = [];
        results_C = [];
        nb_A = 0;
        nb_C = 0;
        
        for participant_index = 1:length(all_participants)
            participant = all_participants{participant_index};
            if isfield(results.(matlab.lang.makeValidName(participant)).results, experiment)
                part_results = results.(matlab.lang.makeValidName(participant)).results.(matlab.lang.makeValidName(experiment));
                curr = [];
                if isfield(part_results, 'vor')
                    curr = [curr part_results.vor]; %#ok<*AGROW>
                    curr.key =[];
                end
                if isfield(part_results, 'rect')
                    curr = [curr part_results.rect]; %#ok<*AGROW>
                    curr.key =[];
                end
                curr = curr{end-1:end, :};
            else
                curr = nan*ones(2, nb_aois);
            end
            participant_col = ones(2,1)*str2double(participant(2:3));
            curr = [participant_col curr];
            if contains(participant, 'A')
                if ~max(isnan(curr))
                    results_A_mean = results_A_mean + curr(:,2:end);
                    nb_A = nb_A + 1;
                end
                results_A = [results_A; curr];
            else
                if ~max(isnan(curr))
                    results_C_mean = results_C_mean + curr(:,2:end);
                    nb_C = nb_C + 1;
                end
                results_C = [results_C; curr];
            end
        end
        results_A_mean = results_A_mean./nb_A;
        results_C_mean = results_C_mean./nb_C;

        results_A_mean = [zeros(2,1) results_A_mean];
        results_C_mean = [zeros(2,1) results_C_mean];

        results_A = [results_A; results_A_mean];
        results_C = [results_C; results_C_mean];

        results_A = [results_A(1:2:end, :) results_A(2:2:end, 2:end)];
        results_C = [results_C(1:2:end, :) results_C(2:2:end, 2:end)];

        var_names = [{'Participant'} aoi_names.voronoi aoi_names.rect];
        for name_index = 2:length(var_names)
            name = var_names{name_index};
            var_names = [var_names [name '_rel']]; 
        end
        results_A = array2table(results_A, 'VariableNames', var_names);
        results_C = array2table(results_C, 'VariableNames', var_names);

        mkdir results;

        writetable(results_A, ['results/', experiment, '_results_A_', name,'.csv']);
        writetable(results_C, ['results/', experiment, '_results_C_', name,'.csv']);
    end
end

