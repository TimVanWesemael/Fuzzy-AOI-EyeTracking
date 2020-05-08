function [x,y] = printPath( data, holding )
%PRINTPATH Print the the path of gaze points and return the coordinates
%   When given a gaze data table this function will filter out the gaze
%   positions and print them. If holding is set to true it will only return
%   the coordinates.

    % Give a default value to holding
    if nargin == 1
        holding = false;
    end
    
    % Prepare the coordinate data
    len = height(data);
    x = zeros(len);
    y = zeros(len);
    cor_index = 1;
    x_column = data.GazePointX_ADCSpx_; % Find the x column
    y_column = data.GazePointY_ADCSpx_; % Find the y column
    
    % Loop through all data to find lost data
    for index = 1:len
        x_cor = x_column(index);    % Convert the coordinates to numbers
        y_cor = y_column(index);
        if ~isnan(x_cor) && ~isempty(x_cor) && ~isnan(y_cor) && ~isempty(y_cor) % Check if they are valid
            x(cor_index) = x_cor;
            y(cor_index) = y_cor;
            cor_index = cor_index + 1;
        end
    end
    x = x(1:cor_index-1);   % Cut the lists to the right size
    y = y(1:cor_index-1);
    
    % Plot the path if wanted
    if ~holding
        hold on
        plot(x,y);
        axis equal;
        axis ij;
        hold off
    end
end

