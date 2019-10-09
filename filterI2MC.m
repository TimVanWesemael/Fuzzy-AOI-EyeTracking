function result = filterI2MC(raw_data, opt)
% FILTERI2MC Find the fixations in eyetrackingdata with the I2MC algorithm.
    % The function makes the algoritm written by Hessels et al compatible
    % with the functions used in this project. 
    
    % The I2MC algorithm was designed to accomplish fixation detection in data
    % across a wide range of noise levels and when periods of data loss may
    % occur.

    % Hessels, R.S., Niehorster, D.C., Kemner, C., & Hooge, I.T.C., (2016).
    % Noise-robust fixation detection in eye-movement data - Identification 
    % BY 2-means clustering (I2MC). Submitted.

    % For more information, questions, or to check whether we have updated to a
    % better version, e-mail: royhessels@gmail.com / dcnieho@gmail.com. I2MC is
    % available from www.github.com/royhessels/I2MC

    % Most parts of the I2MC algorithm are licensed under the Creative Commons
    % Attribution 4.0 (CC BY 4.0) license. Some functions are under MIT 
    % license, and some may be under other licenses.
    
    %%  RELEVANT DATA

    % Calculate the average distance of the eye to the screen in cm
    eye_pos_average = getEyePos(raw_data, opt);
    opt.disttoscreen = norm(eye_pos_average - [opt.xres/2, opt.yres/2, 0])/(opt.one_pxl_mm/10);
    
    % Select the columns with gaze point and timestamp data
    data.time    = raw_data.RecordingTimestamp;
    data.left.X  = raw_data.GazePointLeftX_ADCSpx_;
    data.left.Y  = raw_data.GazePointLeftY_ADCSpx_;
    data.right.X = raw_data.GazePointRightX_ADCSpx_;
    data.right.Y = raw_data.GazePointRightY_ADCSpx_;

    %% FIND THE FIXATIONS
    
    fix          = I2MCfunc(data,opt);
    fix_fields   = fieldnames(fix);
    fix_fields(1)= [];
    fix_table = zeros(length(fix.start), length(fix_fields));
    fix_table = array2table(fix_table, 'VariableNames', matlab.lang.makeValidName(fix_fields));

    for field_index = 1:length(fix_fields)
        field_name = fix_fields{field_index};
        field = getfield(fix, field_name);
        sz = size(field);
        if sz(2) ~= 1
            field = transpose(field);
        end
        fix_table{:,field_index} = field;
    end
    
    %% ADD THE EYE POSITIONS
    
    starts  = fix_table.start;
    ends    = fix_table.xEnd;
    eye_pos = zeros(length(starts), 3);
    missing_index = [];
    
    for fixation = 1:length(starts)
        current_eye_pos = getEyePos(raw_data(starts(fixation):ends(fixation),:),opt);
        if isnan(current_eye_pos)
            warning(['Eye position during fixation ', fixation, ' is not found. It will be approximated by interpolation'])
            eye_pos(fixation,:) = eye_pos_average;
            missing_index = [missing_index, fixation];
        else
            eye_pos(fixation,:) = current_eye_pos;
        end
    end
    
    for index = missing_index
        switch index
            case 1
                eye_pos(index,:) = eye_pos(index+1,:);
            case length(starts)
                eye_pos(index,:) = eye_pos(index-1,:);
            otherwise
                eye_pos(index,:) = (eye_pos(index+1,:) + eye_pos(index-1,:))/2;
        end
    end
    
    eye_pos = array2table(eye_pos, 'VariableNames', {'eyeX', 'eyeY', 'eyeZ'});
    fix_table = [fix_table eye_pos];
    
    result = table2struct(fix_table);
    