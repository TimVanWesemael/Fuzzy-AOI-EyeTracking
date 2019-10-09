classdef AOI
    % General code to provide information about area's of interest.
    
    properties
        all_AOIs;
        nb_AOIs;
        allowed_angle;
        trail;
    end
    
    methods
        function aoi_table = AOIGazeData(self, data, opt)
            
            if opt.raw
                aoi_table = zeros(height(data),4);
                current_index = 0;
                for row = 1:height(data)
                    aoi_index = self.checkAOIHit(data(row,:), opt);
                    if row == 1 || aoi_index ~= aoi_table(current_index, 1)
                        current_index = current_index + 1;
                        aoi_table(current_index,:) = [aoi_index 1];
                    else
                        aoi_table(current_index,2) = aoi_table(current_index,2) + 1;
                    end
                end
            else
                aoi_table = zeros(length(data),4);
                current_index = 0;
                for fixation = 1:length(data)
                    aoi_index = self.checkAOIHit(data(fixation), opt);
                    fix_length = (data(fixation).xEnd - data(fixation).start);
                    fix_start = data(fixation).start/opt.freq;
                    fix_end = data(fixation).xEnd/opt.freq;
                    if fixation == 1 || aoi_index ~= aoi_table(current_index, 1)
                        current_index = current_index + 1;
                        aoi_table(current_index,:) = [aoi_index fix_length fix_start fix_end];
                    else
                        aoi_table(current_index, 2) = aoi_table(current_index,2) + fix_length;
                        aoi_table(current_index, 4) = fix_end;
                    end
                end
            end
            aoi_table = array2table(aoi_table(1:current_index,:), 'VariableNames', {'AOI', 'nb_samples', 'start', 'stop'});
        end
        
        function result = first_fixation(self, data, task, opt)
            aoi_data = self.AOIGazeData(data, opt);
            times = opt.aois.(matlab.lang.makeValidName(task)).(matlab.lang.makeValidName(self.trail)).transition_times;
            latency = opt.aois.transition_delay;
            result = struct();
            single = array2table(zeros(0,4), 'VariableNames', {'transition_time', 'AOI', 'start','stop'});
            five = array2table(zeros(0,4), 'VariableNames', {'transition_time', 'AOI', 'start','stop'});
            timed = array2table(zeros(0,4), 'VariableNames', {'transition_time', 'AOI', 'start','stop'});
            time_index = 1;
            data_index = 1;
            while time_index <= length(times)
                if aoi_data{data_index, 3} > times(time_index)
                    single = [single; array2table([times(time_index), aoi_data.AOI(data_index), aoi_data{data_index, 3:4}], 'VariableNames', {'transition_time', 'AOI', 'start','stop'})];
                    for adj = 0:4
                        if data_index + adj <= height(aoi_data)
                            five = [five; array2table([times(time_index), aoi_data.AOI(data_index+adj), aoi_data{data_index+adj, 3:4}], 'VariableNames', {'transition_time', 'AOI', 'start','stop'})];
                        end
                    end
                    last_time = aoi_data.start(data_index);
                    adj = 0;
                    while last_time - times(time_index) <= latency && data_index + adj < height(aoi_data)
                        timed = [timed; array2table([times(time_index), aoi_data.AOI(data_index+adj), aoi_data{data_index+adj, 3:4}], 'VariableNames', {'transition_time', 'AOI', 'start','stop'})];
                        adj = adj + 1;
                        last_time = aoi_data.start(data_index+adj);
                    end
                    time_index = time_index + 1;
                end
                data_index = data_index + 1;
            end
            result.single = single;
            result.five = five;
            result.timed = timed;
        end
        
        function [results, opt] = AOIDistribution(self, data, opt)
            aoi_data = self.AOIGazeData(data, opt);
            all_msrs = 0;
            results = zeros(2, self.nb_AOIs);
            for row = 1:height(aoi_data)
                aoi_index = aoi_data.AOI(row);
                gaze_length = aoi_data.nb_samples(row);
                if aoi_index ~= 0
                    results(:, aoi_index) = results(:, aoi_index) + gaze_length;
                end
                all_msrs = all_msrs + gaze_length;
            end
     
            results(1,:) = results(1,:)/all_msrs;
            results(2,:) = results(2,:)/sum(results(2,:));
        end
        
        function absolute = genTransitionMatrix(self, data, opt)
            nb_entries = self.nb_AOIs + 1;
            absolute = zeros(nb_entries);
            aoi_data = self.AOIGazeData(data, opt);
            
            for row = 2:height(aoi_data)
                from = aoi_data.AOI(row-1)+1;
                to = aoi_data.AOI(row)+1;
                absolute(to,from) = absolute(to, from) +1;
            end

        end
                
        function plotAOI(self, data, participant, opt)
            figure('position', opt.plotpos, 'Name', [participant, ': ', self.trail]);
            hold on;
            filename = ['complete/', self.trail, '.png'];
            face_image = imread(filename);
            image(face_image);
            
            if opt.plot_AOIs
                xs = zeros(1, (opt.xmax-opt.xmin)*(opt.ymax-opt.ymin));
                ys = zeros(1, (opt.xmax-opt.xmin)*(opt.ymax-opt.ymin));
                current_index = 1;

                for x = opt.xmin:opt.xmax
                    for y = opt.ymin:opt.ymax
                        pos = [x,y];
                        if ~self.checkAOIHit(pos, opt)
                            xs(current_index) = x;
                            ys(current_index) = y;
                            current_index = current_index + 1;
                        end
                    end
                end
                xs = xs(1:current_index-1);
                ys = ys(1:current_index-1);
                plot(xs, ys, '.r');
            end
            
            if opt.raw
                [x,y] = printPath(data);
                plot(x,y)
            else
                data = struct2table(data);
                x = data.xpos;
                y = data.ypos;
                plot(x,y, '.y');
            end
            
            if isa(self, 'voronoi_AOI')
                all_aois = self.all_AOIs;
                plot(all_aois(:,1), all_aois(:,2), '.b');
                voronoi(all_aois(:,1), all_aois(:,2), 'r');
            end
            axis ij;
            axis equal;
            axis([opt.xmin opt.xmax opt.ymin opt.ymax]);
            hold off;
        end
        
        function [score, nb_msrs, opt] = getAOIs(self, data_row, opt)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isa(data_row, 'table')
                gaze_point = [str2double(data_row.GazePointX_ADCSpx_),...
                    str2double(data_row.GazePointY_ADCSpx_)];
                eye_pos = getEyePos(data_row, opt);
                fix_length = 1;
            elseif isa(data_row, 'struct')
                gaze_point = [data_row.xpos, data_row.ypos];
                eye_pos = [data_row.eyeX, data_row.eyeY, data_row.eyeZ];
                fix_length = data_row.xEnd - data_row.start;
            end
            
            if max(contains(fieldnames(opt.aois), 'sample_table'))
                score = self.determinedPDFScore(gaze_point, eye_pos, opt);
            else
                [score, sample_table]  = self.normPDFScores(gaze_point, eye_pos, opt);
                opt.aois.sample_table = table2struct(sample_table);
            end
            nb_msrs = fix_length;
            score = score(1:end-1)*fix_length;
        end
        
        function scores = determinedPDFScore(self, gaze_point, eye_pos, opt)
            gaze_point = [gaze_point 0];
            gaze_vector = gaze_point - eye_pos;
            sample_struct = opt.aois.sample_table;
            scores = zeros(1, self.nb_AOIs+1);
            
            for sample_index = 1:length(sample_struct)
                sample = sample_struct(sample_index);
                alpha = sample.halton_a;
                theta = sample.halton_t;
                r    = norm(gaze_vector)*tan(alpha);
                dx   = r*cos(theta);
                dy   = r*sin(theta);
                sample_point = gaze_point + [dx,dy,0];
                
                hitted_AOI = self.checkAOIHit(sample_point, opt);
                
                score = sample.all_scores;
                if hitted_AOI
                    scores(hitted_AOI) = scores(hitted_AOI) + score;
                else
                    scores(end) = scores(end) + score;
                end
            end
            scores = scores/sum(scores);
        end
        
        function [scores, sample_table] = normPDFScores(self, gaze_point, eye_pos, opt)
            gaze_point = [gaze_point, 0];
            gaze_vector = gaze_point - eye_pos;
            scores = zeros(1, self.nb_AOIs+1);
            sigma = opt.calivali.RMS;
            max_a = 5*sigma;
            halton_t = 2*pi*HaltonSequence(opt.aois.max_qmc_samples, opt.aois.qmc_bases(1));
            halton_a = max_a*HaltonSequence(opt.aois.max_qmc_samples, opt.aois.qmc_bases(2));
            all_scores = zeros(opt.aois.max_qmc_samples, 1);
            
            converged = false;
            halton_index = 1;
            evaluated_samples = 0;

            while (~converged || (halton_index < opt.aois.min_qmc_samples)) && (halton_index <= opt.aois.max_qmc_samples)
                alpha = halton_a(halton_index);
                theta = halton_t(halton_index);
                r    = norm(gaze_vector)*tan(alpha);
                dx   = r*cos(theta);
                dy   = r*sin(theta);
                sample_point = gaze_point + [dx,dy,0];
                
                hitted_AOI = self.checkAOIHit(sample_point, opt);
                
                score = normpdf(alpha, 0, sigma);
                all_scores(halton_index) = score;
                
                
                if halton_index > opt.aois.mid_qmc_samples
                    previous_error = current_error;
                    next_error = abs(1 - 2*max_a*(sum(scores)+score)/(evaluated_samples+1));
                    if next_error < previous_error
                        if hitted_AOI
                            scores(hitted_AOI) = scores(hitted_AOI) + score;
                        else
                            scores(end) = scores(end) + score;
                        end
                        evaluated_samples = evaluated_samples + 1;
                        current_error = next_error;
                    else
                        halton_t(halton_index) = nan;
                        halton_a(halton_index) = nan;
                        all_scores(halton_index) = nan;
                        current_error = previous_error;
                    end
                else
                    if hitted_AOI
                        scores(hitted_AOI) = scores(hitted_AOI) + score;
                    else
                        scores(end) = scores(end) + score;
                    end
                    evaluated_samples = evaluated_samples + 1;
                    current_error = abs(1-2*max_a*sum(scores)/evaluated_samples);
                end
                converged = current_error < opt.aois.qmc_error;

                halton_index = halton_index + 1;
            end
            if halton_index == opt.aois.max_qmc_samples
                warning( ['Desired accuracy during ', self.trail, ' could not be reached with number of samples allowed, there is still an error of ', current_error]);
            else
                halton_index = halton_index - 1;
                halton_t = halton_t(1:halton_index);
                halton_t(isnan(halton_t)) = [];
                halton_a = halton_a(1:halton_index);
                halton_a(isnan(halton_a)) = [];
                all_scores = all_scores(1:halton_index);
                all_scores(isnan(all_scores)) = [];
                sample_table = table(halton_t, halton_a, all_scores);
            end
            disp('Number of samples taken:');
            disp(halton_index);
            scores = scores/sum(scores);
        end
        
        function [map, alpha_map] = distributionMap(self, data, opt)
            map = zeros(opt.yres, opt.xres);
            alpha_map = map;
            
            for fixation = 1:height(data)
                gaze_point = [data.xpos(fixation), data.ypos(fixation) 0];
                eye_pos = [data.eyeX(fixation), data.eyeY(fixation), data.eyeZ(fixation)];
                fix_length = data.xEnd(fixation) - data.start(fixation);
                [current_map, current_alpha_map] = PDFMap(self, gaze_point, eye_pos, opt);
                map = map + current_map.*fix_length;
                alpha_map = alpha_map + current_alpha_map;
            end
            alpha_map(alpha_map ~= 0) = 0.5;
        end
        
        function [map, alpha_map] = PDFMap(~, gaze_point, eye_pos, opt)
            gaze_vector = gaze_point - eye_pos;
            r = round(norm(gaze_vector)*tan(5*opt.calivali.RMS));
            map = zeros(opt.yres, opt.xres);
            alpha_map = map;
            pdf = @(angle) (normpdf(angle, 0, opt.calivali.RMS));
            for x = -r:r
                for y = -r:+r
                    if x^2 + y^2 <= r^2
                        sample_point = gaze_point + [x y 0];
                        if sample_point(1) > 0.5 && sample_point(1) < opt.xres && sample_point(2) > 0.5 && sample_point(2) < opt.yres
                            sample_vector = sample_point- eye_pos;
                            param = acos(dot(gaze_vector, sample_vector)/(norm(gaze_vector)*norm(sample_vector)));
                                       
                            sx = round(sample_point(1));
                            sy = round(sample_point(2));
                            map(sy, sx) = pdf(param);
                            alpha_map(sy, sx) = 0.5;
                        end
                    end
                end
            end
        end
    end
end

