function [ x_px, y_px, z_px ] = mm2pxl( x_mm,y_mm, z_mm, opt )
%MM2PXL Change to mm coordinates to pixel coordinates
    x_px = x_mm/opt.one_pxl_mm;
    y_px = opt.yres - y_mm/opt.one_pxl_mm;
    if nargin == 4
        z_px = -z_mm/opt.one_pxl_mm;
    end
end

