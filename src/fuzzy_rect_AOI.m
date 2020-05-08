classdef fuzzy_rect_AOI < rectangle_AOI

     methods
        function self = fuzzy_rect_AOI(all_aois, trail, allowed_angle)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            argin{1} = all_aois;
            argin{2} = trail;
            argin{3} = allowed_angle;
            self@rectangle_AOI(argin{:});

        end
        
        function [results, opt] = AOIDistribution(self, data, opt)
            results = zeros(1, self.nb_AOIs);
            total_nb_msrs = 0;
            
            if opt.raw
                for row = 1:height(data)
                    [current_result, nb_msrs, opt] = self.getAOIs(data(row,:), opt);
                    results = results + current_result;
                    total_nb_msrs = total_nb_msrs + nb_msrs;
                end
            else
                for fixation = 1:length(data)
                    [current_result, nb_msrs, opt] = self.getAOIs(data(fixation), opt);
                    results = results + current_result;
                    total_nb_msrs = total_nb_msrs + nb_msrs;
                end
            end
            results = [results/total_nb_msrs; results/sum(results)];
        end
        
        function plotAOI(self, data, participant, opt)
            figure('position', opt.plotpos, 'Name', [participant, ': ', self.trail]);
            hold on;
            filename = ['complete/', self.trail, '.png'];
            face_image = imread(filename);
            image(face_image);
            
            if opt.raw
                [x,y] = printPath(data);
                plot(x,y)
            else
                data = struct2table(data);
                [map, alpha_map] = self.distributionMap(data, opt);
                img = imagesc(map);
                alpha(img, alpha_map);
                x = data.xpos;
                y = data.ypos;
                plot(x,y, '.y');
            end
            
            for index = 1:self.nb_AOIs
                current_aoi = self.all_AOIs(index,:);
                plot([current_aoi(1) current_aoi(1) current_aoi(2) current_aoi(2) current_aoi(1)], ...
                     [current_aoi(3) current_aoi(4) current_aoi(4) current_aoi(3) current_aoi(3)], 'r');
            end
            
            axis ij;
            axis equal;
            axis([opt.xmin opt.xmax opt.ymin opt.ymax]);
            hold off;
        end
        
     end
end