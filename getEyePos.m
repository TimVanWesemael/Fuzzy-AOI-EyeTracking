function [ eye_pos ] = getEyePos( data, opt, side )
%GETEYEPOS Return the position of the the eye in pxl-coordinates
%   Accepts a single row of table data as input and the left, right or
%   average according to which position needs to be decided. The function
%   returns a list of xyz-coordinates in pixels
    if nargin == 2
        side = 'average';
    end
    
    
    if strcmpi(side, 'average')
        left_eye_pos = getEyePos(data, opt, 'Left');
        right_eye_pos = getEyePos(data, opt, 'Right');
        if isa(left_eye_pos, 'double') && isa(right_eye_pos, 'double')
            eye_pos = mean([left_eye_pos; right_eye_pos]);
        end
    else
        x = data.(matlab.lang.makeValidName(['EyePos',side,'X_ADCSmm_']));
        y = data.(matlab.lang.makeValidName(['EyePos',side,'Y_ADCSmm_']));
        z = data.(matlab.lang.makeValidName(['EyePos',side,'Z_ADCSmm_']));
        if isa(x, 'string') || isa(x, 'char') || isa(x, 'cell'), x = str2double(x)/100; end
        if isa(y, 'string') || isa(y, 'char') || isa(y, 'cell'), y = str2double(y)/100; end
        if isa(z, 'string') || isa(z, 'char') || isa(z, 'cell'), z = str2double(z)/100; end
        if isempty(x) || isempty(y) || isempty(z), return; end
        [x, y, z] = mm2pxl(x,y,z,opt);
        eye_pos = [x, y, z];
        sz = size(eye_pos);
        if sz(1) > 1
            eye_pos = mean(eye_pos, 'omitnan');
        end
    end
end

