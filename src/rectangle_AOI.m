classdef rectangle_AOI < AOI
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function self = rectangle_AOI(aois, trail, allowed_angle)
            self.all_AOIs = aois;
            self.allowed_angle = allowed_angle;
            self.trail = trail;
            sz = size(self.all_AOIs);
            self.nb_AOIs = sz(1);
        end
           
        function AOI = checkAOIHit(self, data_row, opt)
            if isa(data_row, 'table')
                gaze_point = [str2double(data_row.GazePointX_ADCSpx_),...
                    str2double(data_row.GazePointY_ADCSpx_)];
                eye_pos = getEyePos(data_row, opt);
            elseif isa(data_row, 'struct')
                gaze_point = [data_row.xpos, data_row.ypos];
                eye_pos = [data_row.eyeX, data_row.eyeY, data_row.eyeZ];
            elseif isa(data_row, 'double')
                gaze_point = data_row(1:2);
                eye_pos = opt.expected_eye_pos;
            end
            AOI = [];
            for AOI_area_index = 1:self.nb_AOIs
                AOI_area = self.all_AOIs(AOI_area_index,:);
                if gaze_point(1) > AOI_area(1) && ...
                   gaze_point(1) < AOI_area(2) && ...
                   gaze_point(2) > AOI_area(3) && ...
                   gaze_point(2) < AOI_area(4) && ...
                   (self.validate([gaze_point 0], AOI_area, eye_pos) || ...
                   opt.aois.type ~= 2)
                    AOI = [AOI, AOI_area_index];
                end
            end
            if isempty(AOI), AOI = 0; end
        end
        
        function valid = validate(self, gaze_point, AOI_area, eye_pos)
            distance_vector = [gaze_point(1) - AOI_area(1), ...
                               gaze_point(1) - AOI_area(2), ...
                               gaze_point(2) - AOI_area(3), ...
                               gaze_point(2) - AOI_area(4)];
            [~, min_index] = min(abs(distance_vector));
            proj_point = gaze_point;
            proj_point(ceil(min_index/2)) = proj_point(ceil(min_index/2)) - distance_vector(min_index);
            theta = abs(acos(dot(proj_point-eye_pos, gaze_point-eye_pos)/(norm(proj_point-eye_pos)*norm(gaze_point-eye_pos)))); 
            valid = theta >= self.allowed_angle;
        end
                    
    end
    
end

