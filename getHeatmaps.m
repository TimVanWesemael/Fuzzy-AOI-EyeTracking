function heatmaps =  getHeatmaps(data, opt)
    heatmaps     = struct();
    pois_voronoi = opt.aois.UL.M.face1.voronoi + ...
        opt.aois.UL.M.face2.voronoi + ...
        opt.aois.UL.M.face3.voronoi + ...
        opt.aois.UL.M.face4.voronoi + ...
        opt.aois.UL.M.face5.voronoi + ...
        opt.aois.UL.M.face6.voronoi + ...
        opt.aois.UL.F.face1.voronoi + ...
        opt.aois.UL.F.face2.voronoi + ...
        opt.aois.UL.F.face3.voronoi + ...
        opt.aois.UL.F.face4.voronoi + ...
        opt.aois.UL.F.face5.voronoi + ...
        opt.aois.UL.F.face6.voronoi;
    pois_voronoi = pois_voronoi./12;
    map = zeros(opt.yres, opt.xres);
    total_UL_map = map;
    total_UL_amap = map;
    total_HLeft_map = map;
    total_HLeft_amap = map;
    total_FLeft_map = map;
    total_FLeft_amap = map;
    
    if isfield(data, 'UL')
        UL_data = rmfield(data.UL, 'is_multi');
    else
        UL_data = struct();
    end
    if isfield(data, 'HF')
        HF_data = rmfield(data.HF, 'is_multi');
    else
        HF_data = struct();
    end
    vor_AOI = fuzzy_vor_AOI(pois_voronoi, 'total', opt.calivali.allowed_angle, opt);

    for gender = transpose(fieldnames(UL_data))
        disp(gender);
        gender_data = UL_data.(matlab.lang.makeValidName(gender{1}));
        gender_data = rmfield(gender_data, 'key');
        for face = transpose(fieldnames(gender_data))
            disp(face);
            fixations = struct2table(gender_data.(matlab.lang.makeValidName(face{1})).fixations);
            [map, alpha_map] = vor_AOI.distributionMap(fixations, opt);
            total_UL_map = total_UL_map + map;
            total_UL_amap = total_UL_amap + alpha_map;
        end
    end
            
    for HF_task = transpose(fieldnames(HF_data))
        HF_task = HF_task{1};
        disp(HF_task);
        fixations = struct2table(HF_data.(matlab.lang.makeValidName(HF_task)).fixations);
        [map, alpha_map] = vor_AOI.distributionMap(fixations, opt);

        if strcmpi(HF_task(1), 'h')
            total_HLeft_map = total_HLeft_map + map;
            total_HLeft_amap = total_HLeft_amap + alpha_map;
        else
            total_FLeft_map = total_FLeft_map + map;
            total_FLeft_amap = total_FLeft_amap + alpha_map;
        end
    end
    
    heatmaps.UL_map = total_UL_map(opt.ymin:opt.ymax, opt.xmin:opt.xmax);
    heatmaps.UL_amap = total_UL_amap(opt.ymin:opt.ymax, opt.xmin:opt.xmax);
    heatmaps.HLeft_map = total_HLeft_map(opt.ymin:opt.ymax, opt.xmin:opt.xmax);
    heatmaps.HLeft_amap = total_HLeft_amap(opt.ymin:opt.ymax, opt.xmin:opt.xmax);
    heatmaps.FLeft_map = total_FLeft_map(opt.ymin:opt.ymax, opt.xmin:opt.xmax);
    heatmaps.FLeft_amap = total_FLeft_amap(opt.ymin:opt.ymax, opt.xmin:opt.xmax);
end
    
    
    
            