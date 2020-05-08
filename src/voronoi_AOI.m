classdef voronoi_AOI < AOI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        voronoi_distance;
    end
    
    methods
        function self = voronoi_AOI(all_pois, trail, allowed_angle, max_vor_distance)
            self.allowed_angle = allowed_angle;
            self.all_AOIs = all_pois;
            self.voronoi_distance = max_vor_distance;
            self.trail = trail;
            sz = size(self.all_AOIs);
            self.nb_AOIs = sz(1);
        end
        
        function AOI = checkAOIHit(self, data_row, opt)
            % Get the the distance between the gaze point and the POIs
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
            distances = zeros(self.nb_AOIs, 1);

            for index = 1:length(distances)
                poi = self.all_AOIs(index,:);
                distances(index) = norm(gaze_point-poi);
            end
            [nearest, min_index] = min(distances);
            distances(min_index) = inf;
            [~,sec_index] = min(distances);
            AOI1 = self.all_AOIs(min_index,:);
            AOI2 = self.all_AOIs(sec_index,:);
            if opt.aois.type == 2
                max_d = self.voronoi_distance - tan(self.allowed_angle)*norm(eye_pos-[gaze_point 0]);
            else
                max_d = self.voronoi_distance;
            end
            if nearest < max_d && ...
                    (self.validateAOI(AOI1, AOI2, gaze_point, eye_pos) ...
                    || opt.aois.type ~= 2)
                AOI = min_index;
            else
                AOI = 0;
            end
        end
        
        function valid = validateAOI(self, AOI1, AOI2, gaze_point, eye_pos)
            gaze_point = [gaze_point 0];
            x0 = gaze_point(1);
            y0 = gaze_point(2);
            x1 = AOI1(1);
            y1 = AOI1(2);
            x2 = AOI2(1);
            y2 = AOI2(2);
            a = 2*(x1-x2);
            b = 2*(y1-y2);
            c = x2^2 - x1^2 + y2^2 -y1^2;
            proj = [(b*(b*x0-a*y0)-a*c) ...
                (a*(-b*x0+a*y0)-b*c) 0]/(a^2 + b^2);
            angle = acos(dot(proj-eye_pos, gaze_point-eye_pos)/(norm(proj-eye_pos)*norm(gaze_point-eye_pos)));
            valid = angle > self.allowed_angle;
        end 
    end    
end

