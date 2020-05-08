classdef fuzzy_vor_AOI < voronoi_AOI
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function self = fuzzy_vor_AOI(all_pois, trail, allowed_angle, max_vor_distance)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            argin{1} = all_pois;
            argin{2} = trail;
            argin{3} = allowed_angle;
            argin{4} = max_vor_distance;
            self@voronoi_AOI(argin{:});

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
            voronoi(self.all_AOIs(:,1), self.all_AOIs(:,2), 'r');
            self.lrplot();
            
            axis ij;
            axis equal;
            axis([opt.xmin opt.xmax opt.ymin opt.ymax]);
            hold off;
        end
        
        function lrplot(self)
            max_vor = self.voronoi_distance;
            pois = self.all_AOIs;
            x_cor_upper = zeros(1, 2*max_vor);
            x_cor_lower = x_cor_upper;
            y_cor_upper = x_cor_upper;
            y_cor_lower = x_cor_upper;
            cor_index_upper = 1;
            cor_index_lower = 1;
            for i = 1:self.nb_AOIs
                poi = pois(i, :);
                for dx = -max_vor:max_vor
                    dy = sqrt(max_vor^2 - dx^2);
                    x = poi(1) + dx;
                    y1 = poi(2) + dy;
                    y2 = poi(2) - dy;
                    distances1 = zeros(self.nb_AOIs, 1);
                    distances2 = zeros(self.nb_AOIs, 1);
                    for index = 1:length(distances1)
                        poi2 = self.all_AOIs(index,:);
                        distances1(index) = norm([x y1]-poi2);
                        distances2(index) = norm([x y2]-poi2);
                    end
                    [~, nearest1] = min(distances1);
                    [~, nearest2] = min(distances2);
                    if nearest1 == i
                        x_cor_upper(cor_index_upper) = x;
                        y_cor_upper(cor_index_upper) = y1;
                        cor_index_upper = cor_index_upper + 1;
                    end
                    if nearest2 == i
                        x_cor_lower(cor_index_lower) = x;
                        y_cor_lower(cor_index_lower) = y2;
                        cor_index_lower = cor_index_lower + 1;
                    end
                end
                cor_index_lower = cor_index_lower - 1;
                cor_index_upper = cor_index_upper - 1;
                plot(x_cor_lower(1:cor_index_lower), y_cor_lower(1:cor_index_lower), 'r')
                plot(x_cor_upper(1:cor_index_upper), y_cor_upper(1:cor_index_upper), 'r')
                cor_index_upper = 1;
                cor_index_lower = 1;
            end
        end
    end
end


