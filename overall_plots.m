function results = overall_plots(results, opt)
    all_participants = fieldnames(results);
    map = zeros(opt.ymax-opt.ymin+1, opt.xmax-opt.xmin+1);
    total_A_UL_map = map;
    total_A_UL_amap = map;
    total_A_HLeft_map = map;
    total_A_HLeft_amap = map;
    total_A_FLeft_map = map;
    total_A_FLeft_amap = map;
    total_C_UL_map = map;
    total_C_UL_amap = map;
    total_C_HLeft_map = map;
    total_C_HLeft_amap = map;
    total_C_FLeft_map = map;
    total_C_FLeft_amap = map;
    
    for participant = transpose(all_participants)
        participant = participant{1};
        disp(participant);
        heatmaps = results.(matlab.lang.makeValidName(participant)).heatmaps;
        %results = rmfield(results.(matlab.lang.makeValidName(participant)), 'heatmaps');
        if isfield(heatmaps, 'UL_map')
            UL_map = heatmaps.UL_map;
            UL_amap = heatmaps.UL_amap;
        else
            UL_map = map;
            UL_amap = map;
        end
        if isfield(heatmaps, 'HLeft_map')
            HLeft_map = heatmaps.HLeft_map;
            HLeft_amap = heatmaps.HLeft_amap;
            FLeft_map = heatmaps.FLeft_map;
            FLeft_amap = heatmaps.FLeft_amap;
        else
            HLeft_map = map;
            HLeft_amap = map;
            FLeft_map = map;
            FLeft_amap = map;
        end
        
        if contains(participant, 'A')
            total_A_UL_map = total_A_UL_map + UL_map;
            total_A_UL_amap = total_A_UL_amap + UL_amap;
            total_A_HLeft_map = total_A_HLeft_map + HLeft_map;
            total_A_HLeft_amap = total_A_HLeft_amap + HLeft_amap;
            total_A_FLeft_map = total_A_FLeft_map + FLeft_map;
            total_A_FLeft_amap = total_A_FLeft_amap + FLeft_amap;
        else
            total_C_UL_map = total_C_UL_map + UL_map;
            total_C_UL_amap = total_C_UL_amap + UL_amap;
            total_C_HLeft_map = total_C_HLeft_map + HLeft_map;
            total_C_HLeft_amap = total_C_HLeft_amap + HLeft_amap;
            total_C_FLeft_map = total_C_FLeft_map + FLeft_map;
            total_C_FLeft_amap = total_C_FLeft_amap + FLeft_amap;
        end
    end
    
    total_A_UL_amap(total_A_UL_amap~=0) = 0.5;
    total_A_HLeft_amap(total_A_HLeft_amap~=0) = 0.5;
    total_A_FLeft_amap(total_A_FLeft_amap~=0) = 0.5;
    total_C_UL_amap(total_C_UL_amap~=0) = 0.5;
    total_C_HLeft_amap(total_C_HLeft_amap~=0) = 0.5;
    total_C_FLeft_amap(total_C_FLeft_amap~=0) = 0.5;
    
    total_A_UL_map = reconcatenate(total_A_UL_map, opt);
    total_A_UL_amap = reconcatenate(total_A_UL_amap, opt);
    total_A_HLeft_map = reconcatenate(total_A_HLeft_map, opt);
    total_A_HLeft_amap = reconcatenate(total_A_HLeft_amap, opt);
    total_A_FLeft_map = reconcatenate(total_A_FLeft_map, opt);
    total_A_FLeft_amap = reconcatenate(total_A_FLeft_amap, opt);
    total_C_UL_map = reconcatenate(total_C_UL_map, opt);
    total_C_UL_amap = reconcatenate(total_C_UL_amap, opt);
    total_C_HLeft_map = reconcatenate(total_C_HLeft_map, opt);
    total_C_HLeft_amap = reconcatenate(total_C_HLeft_amap, opt);
    total_C_FLeft_map = reconcatenate(total_C_FLeft_map, opt);
    total_C_FLeft_amap = reconcatenate(total_C_FLeft_amap, opt);
    
    UL_min = min(min(min([total_A_UL_map, total_C_UL_map])));
    UL_max = max(max(max([total_A_UL_map, total_C_UL_map])));
    HF_min = min(min(min([total_A_HLeft_map, total_C_HLeft_map total_A_FLeft_map total_C_FLeft_map])));
    HF_max = max(max(max([total_A_HLeft_map, total_C_HLeft_map total_A_FLeft_map total_C_FLeft_map])));
    
    f = figure('position', opt.plotpos, 'Name', 'total_UL_A');
    hold on;
    filename = 'complete/M1.png';
    face_image = imread(filename);
    image(face_image);
    img = imagesc(total_A_UL_map, [UL_min UL_max]);
    alpha(img, total_A_UL_amap);
    axis ij;
    axis equal;
    axis([opt.xmin opt.xmax opt.ymin opt.ymax]);
    colorbar;
    hold off;
    saveas(f, 'total_UL_A.jpg', 'jpg');
    
    f = figure('position', opt.plotpos, 'Name', 'total_Hleft_A');
    hold on;
    filename = 'complete/housesL.png';
    face_image = imread(filename);
    image(face_image);
    img = imagesc(total_A_HLeft_map, [HF_min HF_max]);
    alpha(img, total_A_HLeft_amap);
    axis ij;
    axis equal;
    axis([opt.xmin opt.xmax opt.ymin opt.ymax]);
    colorbar;
    hold off;
    saveas(f, 'total_HLeft_A.jpg', 'jpg');
    
    f = figure('position', opt.plotpos, 'Name', 'total_Fleft_A');
    hold on;
    filename = 'complete/facesL.png';
    face_image = imread(filename);
    image(face_image);
    img = imagesc(total_A_FLeft_map, [HF_min HF_max]);
    alpha(img, total_A_FLeft_amap);
    axis ij;
    axis equal;
    axis([opt.xmin opt.xmax opt.ymin opt.ymax]);
    colorbar;
    hold off;
    saveas(f, 'total_FLeft_A.jpg', 'jpg');
    
    f = figure('position', opt.plotpos, 'Name', 'total_UL_C');
    hold on;
    filename = 'complete/M1.png';
    face_image = imread(filename);
    image(face_image);
    img = imagesc(total_C_UL_map, [UL_min UL_max]);
    alpha(img, total_C_UL_amap);
    axis ij;
    axis equal;
    axis([opt.xmin opt.xmax opt.ymin opt.ymax]);
    colorbar;
    hold off;
    saveas(f, 'total_UL_C.jpg', 'jpg');
    
    f = figure('position', opt.plotpos, 'Name', 'total_Hleft_C');
    hold on;
    filename = 'complete/housesL.png';
    face_image = imread(filename);
    image(face_image);
    img = imagesc(total_C_HLeft_map, [HF_min HF_max]);
    alpha(img, total_C_HLeft_amap);
    axis ij;
    axis equal;
    axis([opt.xmin opt.xmax opt.ymin opt.ymax]);
    colorbar;
    hold off;
    saveas(f, 'total_HLeft_C.jpg', 'jpg');
    
    f = figure('position', opt.plotpos, 'Name', 'total_Fleft_C');
    hold on;
    filename = 'complete/facesL.png';
    face_image = imread(filename);
    image(face_image);
    img = imagesc(total_C_FLeft_map, [HF_min HF_max]);
    alpha(img, total_C_FLeft_amap);
    axis ij;
    axis equal;
    axis([opt.xmin opt.xmax opt.ymin opt.ymax]);
    colorbar;
    hold off;
    saveas(f, 'total_FLeft_C.jpg', 'jpg');
end

function map = reconcatenate(map, opt)
    map = [zeros(opt.ymin-1, opt.xres); ...
           zeros(opt.ymax - opt.ymin + 1, opt.xmin-1), map, zeros(opt.ymax-opt.ymin+1, opt.xres-opt.xmax); ...
           zeros(opt.yres-opt.ymax-1, opt.xres);];
end