function [data_struct, parameters, raw_data] = importEyetrackingData(filename, opt)
%IMPORTEYETRACKINGDATA Read the contants in a file and save them as a table
%   The expected input is a filename and an option list. The file must be a
%   .tsv file with a comma as decimal operator. It is designed specifically
%   for the output of a Tobii eyetracker, however, other data may work as
%   well. This algorithm will detect if the output file is calibration
%   validation data, or if its experimental data. If its experimental data
%   it will cut the file in to relevant parts and structure it accordingly.
%   This function will also decide the relevancy of each column: if it is
%   empty it will be deleted, if its value is the same on every row, the
%   column will be deleted, but the value will be saved as a parameter.
%   Other columns will be saved. All this data will be returned in a
%   structure.

    %% Import the data
    
    data = readtable(filename, 'DatetimeType', 'text');    % Load the file
    % data = data.textdata;           % Select the field where the actual data is saved
    data_size = size(data);         % Get the number of columns and rows
    height = data_size(1);
    % relevant_data = cell(height-1, width); % Create a table where the results will be saved
    % variable_names = cell(1,width);        % Create a list where the variable name for each column will be saved.
    parameters = containers.Map;           % Columns which contain only one value will be saved in this map
    
    % Loop through every volumn and decide its relevancy; 0 for empty
    % columns that will be deleted, 1 for columns with only one value which
    % will be saved as a parameter, 2 for columns which will be imported
    % completely.
    for column = data.Properties.VariableNames
        column = column{1};
        % variable = matlab.lang.makeValidName(data(1,column_index)); % The first row contains the variable name of the data beneath it
        column_data = data.(matlab.lang.makeValidName(column));     % The first real value will be saved to compare with later values
        first_entry = column_data(1);
        value_type = 0;                                             % The algorithm first assumes the column needs to be deleted, this can be changed later
        
        % Loop through all the rows of the column and compare its values to
        % find its relevancy
        for row_index = 2:height
            if ~strcmp(first_entry, column_data(row_index))         % Check if there is found a different value than that on the first row
                value_type = 2;                                     % If this is the case the whole column will be saved
                break;                                              % Further looping is no longer needed in this case.
            end
        end
        
        if value_type ~= 2 && ~isempty(first_entry(1))              % If the first column contains a value, but the value is the same for the whole row,
            value_type = 1;                                         % it will be saved as a variable
        end                                                        
        
        if value_type == 1                                          % Save the variale in parameters
            parameters(char(column)) = first_entry(1);
            data.(matlab.lang.makeValidName(column)) = [];
        elseif value_type == 0
            data.(matlab.lang.makeValidName(column)) = [];
         end
    end
  % Create a table from all the data
    
    %% Cut the experiments
    
    % First check if the file is a calibration validation, if it is nothing
    % will happen
    if ~contains(parameters('StudioTestName'),'ali')
        participant = parameters('ParticipantName');    % Collect the string wherein the participant is saved
        name = 'unknown';                               % Save a name in case no valid name is found
        for char_index = 1:length(participant)-2        % The string will contain irrelevant characters, so an 'A' or a 'C'
            if (participant(char_index) == 'A' ...      % followed by two numbers will be searched for
               || participant(char_index) == 'C') ...
               && ~isnan(str2double(participant(char_index+1:char_index+2)))
                name = participant(char_index:char_index+2);
            end
        end
        
        parameters('Participant') = name;               % This name will also be saved in the parameters
        participant_order = transpose(data.start);                                    % Save the order for the current participant
        order.indices = find(~strcmpi(participant_order, '')); 
        order.names   = participant_order(~strcmp(participant_order, ''));       % Select the elements which are not empty

        data_struct = genDataStruct(data, parameters, order, opt);         % Generate a structure wherein all data will be saved. 
        raw_data = data;                                                   % Return the uncut data as well
    else
        data_struct = struct();                                            % If the data is from a calibration it needs to be saved in a structure uncut
        data_struct.all_data  = table2struct(data);
        data_struct.parameters = parameters;
    end
end

%% Helper functions


function data_struct = genDataStruct(data_table, parameters, order, opt)
% GENDATASTRUCT Create a  structure with the data per trail.
    % This function will take a data table with starting column and order
    % parameters as input. It will reclassify the data according to their
    % tasks, experiments and faces in the case of an upper/lower task. It
    % will return all this information in the form of a data structure.
    
    data_struct = struct();                         % Create the structure

    % Add the parameters to the structure
    data_struct.parameters = struct();
    for variable = parameters.keys
        data_struct.parameters.(matlab.lang.makeValidName(variable{1})) = parameters(variable{1}); % Create a field for every map key and assign the value to it
    end
    
    all_keys = {};
    key_fields = fieldnames(opt.keys);
    for key_index = 1:length(key_fields)
        key_name = key_fields{key_index};
        all_keys = [all_keys opt.keys.(matlab.lang.makeValidName(key_name))];
    end
    
    % Loop through the start of every experiment and find the end point and
    % save that data in the structure

    for index = 1:length(order.indices)
        current_experiment = order.names{index};
        if ismember(current_experiment, all_keys)
            disp(['Imported ' num2str(index), ' of the ', num2str(length(order.indices)), ' experiments']);
            experiment_start = order.indices(index);             % Save the start of the experiment
            experiment_key = current_experiment;
            experiment_names = fieldnames(opt.keys);
            for experiment_type_index = 1:length(experiment_names)
                experiment_type = experiment_names{experiment_type_index};
                if max(contains(getfield(opt.keys, experiment_type), current_experiment)), break; end 
            end

            while max(contains(fieldnames(data_struct), experiment_type)) && ...
                    max(contains(fieldnames(data_struct.(matlab.lang.makeValidName(experiment_type))), current_experiment))
                current_experiment = [current_experiment, 'I'];
            end

            length_field = opt.length.(matlab.lang.makeValidName(experiment_type)).(matlab.lang.makeValidName(experiment_key));
            if isa(length_field, 'struct')
                sub_start = experiment_start;
                length_field = rmfield(length_field, 'total');
                sub_names = fieldnames(length_field);
                for sub_field_index = 1:length(sub_names)
                    sub_field = sub_names{sub_field_index};
                    sub_end = length_field.(matlab.lang.makeValidName(sub_field)) + sub_start;
                    data_struct.(matlab.lang.makeValidName(experiment_type)).(matlab.lang.makeValidName(current_experiment)).(matlab.lang.makeValidName(sub_field)).all_data = table2struct(data_table(sub_start:sub_end,:));
                    data_struct.(matlab.lang.makeValidName(experiment_type)).(matlab.lang.makeValidName(current_experiment)).(matlab.lang.makeValidName(sub_field)).fixations = filterI2MC(data_table(sub_start:sub_end,:), opt);
                    data_struct.(matlab.lang.makeValidName(experiment_type)).is_multi = true;
                    sub_start = sub_end + 1;
                end
            else
                experiment_end = experiment_start + length_field;

                data_struct.(matlab.lang.makeValidName(experiment_type)).(matlab.lang.makeValidName(current_experiment)).all_data = table2struct(data_table(experiment_start:experiment_end,:));
                data_struct.(matlab.lang.makeValidName(experiment_type)).(matlab.lang.makeValidName(current_experiment)).fixations = filterI2MC(data_table(experiment_start:experiment_end,:),opt);
                data_struct.(matlab.lang.makeValidName(experiment_type)).is_multi = false;
            end
            data_struct.(matlab.lang.makeValidName(experiment_type)).(matlab.lang.makeValidName(current_experiment)).key = experiment_key;
        end
    end
end


