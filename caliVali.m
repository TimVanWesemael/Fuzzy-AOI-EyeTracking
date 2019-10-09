function [results] = caliVali(data, participant, opt)
%CALIVALI Return the most important parameters for the calibration
    % An unfiltered, complete calivali dataset in structure form is
    % expected as input aswell as an option list. The output will be a
    % table containing the accuracy and average error angle for each
    % calibration cross and the overall mean of those values. The error
    % angle is the visual angel between the gaze point and the calibration
    % cross. The accuracy is the fraction of gaze_points of which the error
    % angle is smaller than a threshold defined in the options. This
    % function can work with raw data or data filtered by the I2MC
    % algorithm. A plot can be made, the data points will then be plotted
    % as well as the visual threshold for the hits.
    
    %% Prepare the data
    data = struct2table(data.all_data);                 % The algorithm is made to work with data in tables, so it needs to be converted first
    [data, slide_indices] = cutRelevantParts(data);     % Cut all the parts where no calibration cross is shown and save the indices where a new cross appears
    slide_indices = [slide_indices height(data)+1];     % Add the last index of the data, here the last calibration cross ends
    angle = deg2rad(opt.angle);                         % The input and output angle are defined in degrees, but the arithmetic happens in radials.
    
    results = zeros(length(opt.m)+1, 3);                % Prepare an array where the results will be saved in
    total_nb_hits = 0;                                  % These variables will be imortant to calculate the overall accuracy, mean error_angle and RMS
    total_nb_msrs = 0;
    total_angle_err = 0;
    total_angle_sqr = 0;
    
    %% Calculate the parameters
    % Loop through every calibration cross to calculate the accuracy mean
    % error angle and RMS error angle.
    for slide = 1:length(opt.m)
        cali_cross = opt.m(slide,:);    % Save the pixel coordinates of the calibration cross
        slide_data = data(slide_indices(slide):slide_indices(slide+1)-1,:); % Select the relevant part of the data for the calibration cross
        if ~opt.raw
            slide_data  = filterI2MC(slide_data, opt);      % Filter the data, if needed
            [nb_hits, nb_msrs, angle_err, angle_square] = validate(slide_data, cali_cross, angle);  % Get the parameters via a helper function
        else
            [nb_hits, nb_msrs, angle_err, angle_square] = validateRaw(slide_data, cali_cross, angle, opt); % If the option to use the raw data is selected, the filter will be skipped.
        end
        results(slide,:) = [nb_hits/nb_msrs, angle_err/nb_msrs, sqrt(angle_square/nb_msrs)]; % Calculate the accuracy, mean average angle and RMS of the error angle and save them in the result table
        
        % Add all the parameters for the overall results
        total_nb_hits = total_nb_hits + nb_hits;
        total_nb_msrs = total_nb_msrs + nb_msrs;
        total_angle_err = total_angle_err + angle_err;
        total_angle_sqr = total_angle_sqr + angle_square;
    end
    
    % Calculate the overall parameters and save them at the end. Convert
    % the matrix to a table with the correct variable names/
    results(length(results),:) = [total_nb_hits/total_nb_msrs, total_angle_err/total_nb_msrs, sqrt(total_angle_sqr/total_nb_msrs)];
    results = array2table(results, 'VariableNames', {'Accuracy', 'Average_angle', 'RMS'});
    
    %% Visualization
    if opt.visualize % Check if a visualisation is wanted
        figure('position', opt.plotpos, 'Name', [participant, ': Calibration validation']); % create the figure
        hold on;  
        
        % Plot the data for every calibration cross
        for slide_index = 1:length(opt.m)
            eye_pos = getEyePos(data, opt); % Get the average eye pos
            [x2,y2] = visualAngleArea(eye_pos, opt.m(slide_index,:), angle, opt.mesh); % Get coordinates for the valid areas
            slide_data = data(slide_indices(slide_index):slide_indices(slide_index+1)-1,:); % Select only the data for the current cross
            if opt.raw
                [x1, y1] = printPath(slide_data, true); % if only raw data is processed, the coordinates of the gaze points are collected
                plot(x1,y1,x2,y2);                      % Plot the ellipses and the gaze path
            else
                fixations = filterI2MC(slide_data, opt); % Filter the data for fixations
                fixations = struct2table(fixations);
                x1 = fixations.xpos;                     % Select the x and y coordinates
                y1 = fixations.ypos;
                plot(x1,y1,'.r');                        % Plot the gaze points
                plot(x2,y2);                             % Plot the ellipses
            end 
        end
        
        % Reshape the plot, to the correct size and correct scale
        axis equal;
        axis([opt.xmin opt.xmax opt.ymin opt.ymax]);
        axis ij;
        hold off
    end
end

%% Helper functions

function [relevant_data, start_indices] = cutRelevantParts(data)
% CUTRELEVANTPARTS Delete the parts of the data where no cross is shown.
    % This algorithm will find the parts of a complete data set where
    % calibration crosses are shown and will delete all other data points.
    % It will return the cutted data set and the list of row indices where
    % the gaze data for each gaze point will start and end.
    
    
    event_column = data.StudioEvent;        % Select the column where information about the appearing and disappearing of calibaration crosses 
    start_row = [];                         % In this list the indices of the data rows where the calibration crosses appear will be saved
    end_row = [];                           % In this list the indices of the data rows where the calibration crosses disappear will be saved
    
    % Loop through all data points to find the appearing and disappearing
    % of calibration crosses.
    for row = 1:length(event_column)
        % If this row contains a start or end event, add the index to the
        % corresponding list.
        event = event_column(row); 
        if strcmp(event, 'ImageStart')
            start_row = [start_row row];
        elseif strcmp(event, 'ImageEnd')
            end_row = [end_row row];
        end
    end
    
    start_indices = zeros(1,length(start_row)); % This list will contain the indices of the row where a new calibration croos appears in the cutted data
    start_indices(1) = 1;                       % The first cross will appear at the begining of the data
    
    % For every calibartion cross the start index in the cutted dataset is
    % calculated
    for index = 1:length(start_row)-1
        start_indices(index+1) = 1 + start_indices(index) - start_row(index) + end_row(index);
    end
    
    % The absolute end index plus one is added to the start row and the
    % absolute start minus one is added in front of the end row, to 
    % keep an 'index exceeds matrix dimensions' from happening next
    % for-loop.
    start_row = [start_row length(event_column)+1];
    end_row = [0 end_row];
   
    % The relevant parts are cut out of the data in reverse order. This is
    % because the abolishment of early data points will change the indices
    % of later rows and incorrect data will be deleted in that case.
    for index = length(start_row):-1:1
        data(end_row(index)+1:start_row(index)-1,:) = [];
    end
    relevant_data = data;
end

function [nb_hits, nb_msrs, angle_err, angle_square] = validate(data, center, angle)
% VALIDATE Return the most important parameters to validate the calibration
    % The function expects as input: a list of fixations in the form of a
    % structure, coordinates for a calibration cross, the visual angle
    % threshold for a hit and a option list. It will return the number of
    % number of measurments smaller than the threshold, the total number of
    % measurements, the cumulative sum of the angle errors and that of the
    % square of the angle errors. The function will discard all data before
    % the first hit of an calibration cross.
    
    % Initialize the counters
    nb_hits = 0;                % The number of measurements within the threshold
    angle_err = 0;              % The sum of the angle errors
    nb_msrs = 0;                % The total number of measurements
    angle_square = 0;           % The sum of the squre of the angle errors
    center = [center 0];        % Add the z-coordinate      
    already_hitted = false;     % This is important to decide when to start recording data
    
    % Loop through every fixation to calculate the parameters
    for fix = 1:length(data)
        gaze_pos = [data(fix).xpos, data(fix).ypos, 0];                 % The gaze point of the fixation is extracted from the data 
        eye_pos  = [data(fix).eyeX data(fix).eyeY data(fix).eyeZ];      % The average eye position during the fixation is extracted from the data
        error_angle = abs(acos(dot((gaze_pos-eye_pos),(center-eye_pos))/(norm(gaze_pos-eye_pos)*norm(center-eye_pos)))); % The error angle is calculated using vector arithmetic
        fix_length = data(fix).xEnd - data(fix).start - 1;              % The number of samples the fixation lasted is calculated
        % Decide wheter the fixation is a hit or not
        if error_angle < angle
            hit = true;
        else
            hit = false;
        end
        
        if ~already_hitted
            if hit
                % If it is the first hit add all measurments
                already_hitted = true;
                nb_hits = nb_hits + fix_length;
                nb_msrs = nb_msrs + fix_length;
                angle_err = angle_err + error_angle*fix_length;
                angle_square = angle_square + (error_angle^2)*fix_length;
            end
        else
            % Add all the measurements for every fixation after the first
            % hit
            nb_msrs = nb_msrs + fix_length; 
            angle_err = angle_err + error_angle*fix_length;
            angle_square = angle_square + (error_angle^2)*fix_length;
            if hit
                nb_hits = nb_hits + fix_length; % If a hit is recorded, add the samples to the fixation as well
            end
        end
    end
end

function [nb_hits, nb_msrs, angle_err, angle_square] = validateRaw(data, center, angle, opt)
% VALIDATE Return the most important parameters to validate the calibration
    % The function expects as input: a list of raw data in table form, 
    % coordinates for a calibration cross, the visual angle
    % threshold for a hit and a option list. It will return the number of
    % number of measurments smaller than the threshold, the total number of
    % measurements, the cumulative sum of the angle errors and that of the
    % square of the angle errors. The function will discard all data before
    % the first hit of an calibration cross.
    
    % Initialize the counters
    nb_hits = 0;                % The number of measurements within the threshold
    angle_err = 0;              % The sum of the angle errors
    nb_msrs = 0;                % The total number of measurements
    angle_square = 0;           % The sum of the squre of the angle errors
    center = [center 0];        % Add the z-coordinate
    
    % Calculate everything for both eyes
    for side_str = {'Left', 'Right'}
        side = char(side_str);
        % Select the right data columns and save them in the right order.
        gaze_x_col = data.(matlab.lang.makeValidName(['GazePoint', side, 'X_ADCSpx_'])); % The x position of the gaze point
        gaze_y_col = data.(matlab.lang.makeValidName(['GazePoint', side, 'Y_ADCSpx_'])); % The y position of the gaze_point
        x_eye_col = data.(matlab.lang.makeValidName(['EyePos',side,'X_ADCSmm_']));   % The x position of the eye
        y_eye_col = data.(matlab.lang.makeValidName(['EyePos',side,'Y_ADCSmm_']));   % The y position of the eye
        z_eye_col = data.(matlab.lang.makeValidName(['EyePos',side,'Z_ADCSmm_']));   % the z position of the eye
        [x_eye_col, y_eye_col, z_eye_col] = mm2pxl(x_eye_col,y_eye_col,z_eye_col, opt); % Change the eye coordinates from mm to pixel
        eye_col = [x_eye_col, y_eye_col, z_eye_col]; % Save the complete position of the eye
        gaze_col = [gaze_x_col gaze_y_col];          % Save the complete position of the gaze point
        already_hitted = false;                      % This is important to decide when to start recording data
        
        % Loop through every data point the calculate the parameters
        for row = 1:min([length(eye_col),length(gaze_col)])
            eye_pos = eye_col(row,:);           % Select the correct eye position
            gaze_pos = [gaze_col(row,:) 0];     % Select the corresponding gaze point
            error_angle = abs(acos(dot((gaze_pos-eye_pos),(center-eye_pos))/(norm(gaze_pos-eye_pos)*norm(center-eye_pos)))); % Use vector arithmetic to calculate the visual angle between the calibration cross and gaze point
            if ~isnan(error_angle)      % Make sure there is a valid result
                if error_angle < angle  % Check if the visual angle is beneath the threshold
                    hit = true;
                else
                    hit = false;
                end
                
                if ~already_hitted
                    % If it is the first hit, start counting
                    if hit
                        already_hitted = true;
                        nb_hits = nb_hits + 1;
                        nb_msrs = nb_msrs + 1;
                        angle_err = angle_err + error_angle;
                        angle_square = angle_square + error_angle^2;
                    end
                else
                    % When already hitted, this needs to be counted with
                    % every measurement
                    nb_msrs = nb_msrs + 1; 
                    angle_err = angle_err + error_angle;
                    angle_square = angle_square + error_angle^2;
                    if hit
                        % If a hit occurs, count that as well
                        nb_hits = nb_hits + 1;
                    end
                end
            end
        end
    end
end
        