function [results, opt] = AOIStats(data, participant, opt)
% Return a table with a summary of the AOI statistics for every recorded
% task.
    if isfield(data, 'parameters'), data = rmfield(data, 'parameters'); end
    tasks = fieldnames(data);
    for task_index = 1:length(tasks)
        task = tasks{task_index};
        task_data  = data.(matlab.lang.makeValidName(task));
        aoi_struct = opt.aois.(matlab.lang.makeValidName(task));
        if task_data.is_multi
            [task_results, opt] = multiAOIstats(task_data, participant, task, aoi_struct, opt);
        else
            [task_results, opt] = simpleAOIstats(task_data, participant, task, aoi_struct, opt);
        end
        results.(matlab.lang.makeValidName(task)) = task_results;
    end
end

function [results, opt] = simpleAOIstats(data, participant, task, aoi_struct, opt)
% Interpret given the given data that is no longer divided into subfields.
    data = rmfield(data, 'is_multi');
    experiments = fieldnames(data);
    
    rect_aoi_names = opt.aois.(matlab.lang.makeValidName(task)).names.rect;
    if ~isempty(rect_aoi_names)
        rect_aoi_dist  = zeros(2*length(experiments), length(rect_aoi_names));
        rect_aoi_dist  = array2table(rect_aoi_dist, 'VariableNames', rect_aoi_names);
    end
    
    vor_aoi_names  = opt.aois.(matlab.lang.makeValidName(task)).names.voronoi;
    if ~isempty(vor_aoi_names)
        vor_aoi_dist   = zeros(2*length(experiments), length(vor_aoi_names));
        vor_aoi_dist   = array2table(vor_aoi_dist, 'VariableNames', vor_aoi_names);
    end
    
    experiment_col = array2table(cell(2*length(experiments), 1), 'VariableNames', {'key'});
    
    for experiment_index = 1:length(experiments)
        experiment = experiments{experiment_index};
        
        if opt.raw
            experiment_data = data.(matlab.lang.makeValidName(experiment)).all_data;
            experiment_data = struct2table(experiment_data);
        else
            experiment_data = data.(matlab.lang.makeValidName(experiment)).fixations;
        end
        
        if isfield(data.(matlab.lang.makeValidName(experiment)), 'key')
            key = data.(matlab.lang.makeValidName(experiment)).key;
        else
            key = experiment;
        end
        experiment_col{2*experiment_index-1,1} = {key};
        experiment_col{2*experiment_index,1} = {key};
        
        rect_aois = aoi_struct.(matlab.lang.makeValidName(key)).rect;
        vor_aois  = aoi_struct.(matlab.lang.makeValidName(key)).voronoi;
        max_vor   = aoi_struct.(matlab.lang.makeValidName(key)).max_vor;
        
        if opt.aois.timeframe.enable
            [tfrect, tfvor] = getTimeframeAOIs(experiment_data, participant, key, task, opt.length.(task).(key), rect_aois, vor_aois, max_vor, opt);
        end
        
        if ~isempty(rect_aoi_names)
            [rect_results, tt, opt] = getRectangleAOIs(experiment_data, participant, rect_aois, key, opt, task);
            rect_aoi_dist((experiment_index*2-1):(experiment_index*2),:) = array2table(rect_results);
            if opt.aois.first_fixation
                results.first_fixations.rect.(matlab.lang.makeValidName(experiment)) = tt;
            end
            if opt.aois.timeframe.enable
                tfrect = array2table(tfrect, 'VariableNames', [{'startT', 'endT'}, rect_aoi_names]);
                tfrect = table2struct(tfrect);
                results.timeframe.rect.(matlab.lang.makeValidName(experiment)) = tfrect;
            end
        end
        
        if ~isempty(vor_aoi_names)
            [vor_results, tt, opt] = getVoronoiAOIs(experiment_data, participant, vor_aois, max_vor, key, opt, task);
            vor_aoi_dist((experiment_index*2-1):(experiment_index*2),:) = array2table(vor_results);
            if opt.aois.first_fixation
                results.first_fixation.voronoi.(matlab.lang.makeValidName(experiment)) = tt;
            end
            if opt.aois.timeframe.enable
                tfvor = array2table(tfvor, 'VariableNames', [{'startT', 'endT'}, vor_aoi_names]);
                tfvor = table2struct(tfvor);
                results.timeframe.vor.(matlab.lang.makeValidName(experiment)) = tfvor;
            end
        end   
    end
    
    if ~isempty(rect_aoi_names)
        results.rect = getAverages([rect_aoi_dist experiment_col], task, opt);
    end
    
    if ~isempty(vor_aoi_names)
        results.vor = getAverages([vor_aoi_dist experiment_col], task, opt);
    end
    
end

function [results, opt] = multiAOIstats(data, participant, task, aoi_struct, opt)
    data = rmfield(data, 'is_multi');
    experiments = fieldnames(data);
    
    rect_aoi_names = opt.aois.(matlab.lang.makeValidName(task)).names.rect;
    if ~isempty(rect_aoi_names)
        rect_aoi_dist  = zeros(2*length(experiments), length(rect_aoi_names));
        rect_aoi_dist  = array2table(rect_aoi_dist, 'VariableNames', rect_aoi_names);
    end
    
    vor_aoi_names  = opt.aois.(matlab.lang.makeValidName(task)).names.voronoi;
    if ~isempty(vor_aoi_names)
        vor_aoi_dist   = zeros(2*length(experiments), length(vor_aoi_names));
        vor_aoi_dist   = array2table(vor_aoi_dist, 'VariableNames', vor_aoi_names);
    end
    
    experiment_col = array2table(cell(2*length(experiments), 1), 'VariableNames', {'key'});
    
    for experiment_index = 1:length(experiments)
        experiment = experiments{experiment_index};
        
        if isfield(data.(matlab.lang.makeValidName(experiment)), 'key')
            key = data.(matlab.lang.makeValidName(experiment)).key;
        else
            key = experiment;
        end
        experiment_col{2*experiment_index-1,1} = {key};
        experiment_col{2*experiment_index,1} = {key};
        
        data.(matlab.lang.makeValidName(experiment)) = rmfield(data.(matlab.lang.makeValidName(experiment)), 'key');
        part_exps = fieldnames(data.(matlab.lang.makeValidName(experiment)));
        total_part_length = 0;
        time_offset = 0;
        first_fixation_rect.single = array2table(zeros(0,4), 'VariableNames', {'transition_time', 'AOI', 'start','stop'});
        first_fixation_rect.five = array2table(zeros(0,4), 'VariableNames', {'transition_time', 'AOI', 'start','stop'});
        first_fixation_rect.timed = array2table(zeros(0,4), 'VariableNames', {'transition_time', 'AOI', 'start','stop'});    
        first_fixation_vor.single = array2table(zeros(0,4), 'VariableNames', {'transition_time', 'AOI', 'start','stop'});
        first_fixation_vor.five = array2table(zeros(0,4), 'VariableNames', {'transition_time', 'AOI', 'start','stop'});
        first_fixation_vor.timed = array2table(zeros(0,4), 'VariableNames', {'transition_time', 'AOI', 'start','stop'});
        tvor = [];
        trect = [];
        
        for part_exp_index = 1:length(part_exps)
            part_exp = part_exps{part_exp_index};
            
            rect_aois = aoi_struct.(matlab.lang.makeValidName(key)).(matlab.lang.makeValidName(part_exp)).rect;
            vor_aois  = aoi_struct.(matlab.lang.makeValidName(key)).(matlab.lang.makeValidName(part_exp)).voronoi;
            max_vor   = aoi_struct.(matlab.lang.makeValidName(key)).(matlab.lang.makeValidName(part_exp)).max_vor;
            part_length = opt.length.(matlab.lang.makeValidName(task)).(matlab.lang.makeValidName(key)).(matlab.lang.makeValidName(part_exp));
            total_part_length = total_part_length + part_length;
            
            if opt.raw
                experiment_data = data.(matlab.lang.makeValidName(experiment)).(matlab.lang.makeValidName(part_exp)).all_data;
                experiment_data = struct2table(experiment_data);
            else
                experiment_data = data.(matlab.lang.makeValidName(experiment)).(matlab.lang.makeValidName(part_exp)).fixations;
            end
            
            if opt.aois.timeframe.enable
                if strcmp('F', experiment)
                        experiment;
                end
                [tfrect, tfvor] = getTimeframeAOIs(experiment_data, participant, key, task, opt.length.(task).(key).(part_exp), rect_aois, vor_aois, max_vor, opt);
            end
            
            if ~isempty(rect_aoi_names)
                [rect_results, tt, opt] = getRectangleAOIs(experiment_data, participant, rect_aois, key, opt, task);
                rect_aoi_dist{(experiment_index*2-1):(experiment_index*2),:} = ...
                rect_aoi_dist{(experiment_index*2-1):(experiment_index*2),:} + ...
                rect_results*part_length;
                if opt.aois.first_fixation
                    for i = [1 3 4]
                        tt.single{:,i} = tt.single{:,i} + time_offset;
                        tt.five{:,i} = tt.five{:,i} + time_offset;
                        if height(tt.timed) > 0, tt.timed{:,i} = tt.timed{:,i} + time_offset; end
                    end
                    first_fixation_rect.single = [first_fixation_rect.single; tt.single];
                    first_fixation_rect.five = [first_fixation_rect.five; tt.five];
                    first_fixation_rect.timed = [first_fixation_rect.timed; tt.timed];
                end
                
                if opt.aois.timeframe.enable
                    tfrect(:,1:2) = tfrect(:,1:2) + time_offset*1000;
                    trect = [trect; tfrect];
                end
            end
        
            if ~isempty(vor_aoi_names)
                [vor_results, tt, opt] = getVoronoiAOIs(experiment_data, participant, vor_aois, max_vor, key, opt, task);
                vor_aoi_dist{(experiment_index*2-1):(experiment_index*2),:} = ...
                vor_aoi_dist{(experiment_index*2-1):(experiment_index*2),:} + ...
                vor_results*part_length;
                if opt.aois.first_fixation
                    for i = [1 3 4]
                        tt.single{:,i} = tt.single{:,i} + time_offset;
                        tt.five{:,i} = tt.five{:,i} + time_offset;
                        if height(tt.timed) > 0, tt.timed{:,i} = tt.timed{:,i} + time_offset; end
                    end
                    first_fixation_vor.single = [first_fixation_vor.single; tt.single];
                    first_fixation_vor.five = [first_fixation_vor.five; tt.five];
                    first_fixation_vor.timed = [first_fixation_vor.timed; tt.timed];
                end
                
                if opt.aois.timeframe.enable
                    tfvor(:,1:2) = tfvor(:,1:2) + time_offset*1000;
                    tvor = [tvor; tfvor];
                end
            end
            
            time_offset = time_offset + opt.length.(matlab.lang.makeValidName(task)).(matlab.lang.makeValidName(key)).(matlab.lang.makeValidName(part_exp))/opt.freq;
        end
        
        if ~isempty(rect_aoi_names)
            rect_aoi_dist{(experiment_index*2-1):(experiment_index*2),:} = ...
            rect_aoi_dist{(experiment_index*2-1):(experiment_index*2),:} / total_part_length;
            if opt.aois.first_fixation
                results.first_fixations.rect.(matlab.lang.makeValidName(experiment)) = first_fixation_rect;
            end
            
            if opt.aois.timeframe.enable
                trect = array2table(trect, 'VariableNames', [{'startT', 'endT'}, rect_aoi_names]);
                trect = table2struct(trect);
                results.timeframe.rect.(matlab.lang.makeValidName(experiment)) = trect;
            end
        end
        
        if ~isempty(vor_aoi_names)
            vor_aoi_dist{(experiment_index*2-1):(experiment_index*2),:} = ...
            vor_aoi_dist{(experiment_index*2-1):(experiment_index*2),:} / total_part_length;
            if opt.aois.first_fixation
                results.first_fixations.vor.(matlab.lang.makeValidName(experiment)) = first_fixation_vor;
            end
            
            if opt.aois.timeframe.enable
                tvor = array2table(tvor, 'VariableNames', [{'startT', 'endT'}, vor_aoi_names]);
                tvor = table2struct(tvor);
                results.timeframe.vor.(matlab.lang.makeValidName(experiment)) = tvor;
            end
        end
    end
    
    if ~isempty(rect_aoi_names)
        results.rect = getAverages([rect_aoi_dist experiment_col], task, opt);
    end
    
    if ~isempty(vor_aoi_names)
        results.vor = getAverages([vor_aoi_dist experiment_col], task, opt);
    end
end

function [results, tt, opt] = getRectangleAOIs(data, participant, aois, key, opt, task)
% Interpret the given data on the rectangle AOIs.
    angle = opt.calivali.allowed_angle;
    
    if opt.aois.type == 3
        task_aoi = fuzzy_rect_AOI(aois, key, angle);
    else
        task_aoi = rectangle_AOI(aois, key, angle);
    end
    
    [results, opt] = task_aoi.AOIDistribution(data, opt);
    
    if opt.aois.first_fixation
        tt = task_aoi.first_fixation(data, task, opt);
    else
        tt = null(1);
    end
    
    % Visualize if wanted
    if opt.visualize && any(strcmpi(opt.plot, key)), task_aoi.plotAOI(data, participant, opt); end
end

function [rect, vor] = getTimeframeAOIs(data, participant, key, task, len, rect_aois, vor_aois, max_vor, opt)
    end_reached = false;
    start_found = false;
    end_found = false;
    nb_aois = size(rect_aois);
    nb_aois = nb_aois(1);
    rect = zeros(len/(opt.freq*opt.aois.timeframe.shift), 2+nb_aois);
    nb_aois = size(vor_aois);
    nb_aois = nb_aois(1);
    vor = zeros(len/(opt.freq*opt.aois.timeframe.shift), 2+nb_aois);
    frame_start = data(1).startT - (data(1).start-1)*1000/opt.freq;
    frame_end = frame_start + opt.aois.timeframe.length*1000;
    task_start = frame_start;
    start_index = 1;
    end_index = 1;
    data_index = 1;
    
    while ~end_reached
        while ~(start_found && end_found)
            if data(start_index).endT >= frame_start
                start_found = true;
            else
                if ~start_found
                    start_index = start_index + 1;
                end
            end
            if data(end_index).endT >= frame_end
                end_found = true;
            else
                if ~end_found
                    end_index = end_index + 1;
                end
                if end_index > length(data)
                    end_index = length(data);
                end
                if (end_index == length(data))
                    end_found = true;

                end
            end
        end
        if data(end_index).startT > frame_end
            end_index = end_index -1;
        end
        dataframe = data(start_index:end_index);
        
        if dataframe(1).startT < frame_start
            delta = frame_start - dataframe(1).startT;
            delta = delta/1000*opt.freq;
            dataframe(1).startT = frame_start;
            dataframe(1).start = dataframe(1).start + delta;
        end
        
        if dataframe(end).endT > frame_end
            delta = frame_end - dataframe(end).endT;
            delta = delta/1000*opt.freq;
            dataframe(end).endT = frame_end;
            dataframe(end).xEnd  = dataframe(end).xEnd + delta;
        end
        
        if ~isempty(rect_aois)
            b = getRectangleAOIs(dataframe, participant, rect_aois, key, opt, task);
            rect(data_index, 3:end) = b(1,:);
            rect(data_index, 1:2) = [frame_start, frame_end]-task_start;
        end
        
        if ~isempty(vor_aois)
            b = getVoronoiAOIs(dataframe, participant, vor_aois, max_vor, key, opt, task);
            vor(data_index, 3:end) = b(1,:);
            vor(data_index, 1:2) = [frame_start, frame_end]-task_start;
        end
        
        data_index = data_index + 1;
        
        frame_start = frame_start + opt.aois.timeframe.shift*1000;
        frame_end = frame_start + opt.aois.timeframe.length*1000;
        end_found = false;
        start_found = false;
        
        if (frame_end > 1000*len/opt.freq + task_start)
            end_reached = true;
        end
    
    end
    rect = rect(1:data_index-1, :);
    vor = vor(1:data_index-1, :);
end

function [results, tt, opt] = getVoronoiAOIs(data, participant, pois, max_vor, key, opt, task)
% Interpret the given data on the Voronoi AOIs.
    angle = opt.calivali.allowed_angle;

    if opt.aois.type == 3
        task_aoi = fuzzy_vor_AOI(pois, key, angle, max_vor);
    else
        task_aoi = voronoi_AOI(pois, key, angle, max_vor);
    end
    
    [results, opt] = task_aoi.AOIDistribution(data, opt);
    
    if opt.aois.first_fixation
        tt = task_aoi.first_fixation(data, task, opt);
    else
        tt = null(1);
    end
    
    % Visualize if wanted
    if opt.visualize && any(strcmp(opt.plot, key)), task_aoi.plotAOI(data, participant, opt); end
end

function results = getAverages(data_table, task, opt)
    abs_sum = zeros(1, width(data_table)-1);
    total_length = 0;
    var_names = data_table.Properties.VariableNames;
    for row = 1:2:height(data_table)
        key = data_table{row, end};
        length_field = opt.length.(matlab.lang.makeValidName(task)).(matlab.lang.makeValidName(key{1}));
        if isstruct(length_field)           
            task_length = length_field.total;
        else
            task_length = length_field;
        end
        abs_sum = abs_sum + data_table{row, 1:end-1}*task_length;
        total_length = total_length + task_length;
    end
    
    abs_average = abs_sum./total_length;
    rel_average = abs_sum./sum(abs_sum);
    average_col = cell2table({'average'; 'average'}, 'VariableNames', {'key'});
    average_table = array2table([abs_average; rel_average], 'VariableNames', var_names(1:end-1));
    average_table = [average_table average_col];
    results = [data_table; average_table];
end
    