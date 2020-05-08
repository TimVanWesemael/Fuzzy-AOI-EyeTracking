function [x,y] = visualAngleArea(eye_pos, centre, angle, number)
% VISUALANGLEAREA Return a ellips which displays the area with a valid
% visual angle.
    % The function takes an eye position, a focus of the ellips, a maximum
    % angle and the number of coordinates that need to be returned as
    % input. It will return one list of x coordinates and one list of y
    % coordiates which will form the ellips wherein all gaze points with a
    % visual angle lower than the maximum are situated.
    
    % Calculate parameters that determine the size, shape and position of
    % the ellipse
    [alpha, beta] = getPosAngles(eye_pos, [centre 0]);      % Get two necessary angles 
    original_length = norm(centre(1:2)-eye_pos(1:2));   % Calculate the distance between the projection of the eye on the screen and the focus
    z = abs(eye_pos(3));                                % This is the distance between the eye and its projection on the screen
    p1 = abs(original_length - z*tan(alpha-angle));     % The distance from the focus to the point on the ellipse closest to the projection of the eye
    p2 = abs(z*tan(alpha+angle) - original_length);     % The distance from the focus to the point on the ellipse furthest from the projection of the eye
    a = (p1 + p2)/2;                                    % Length of the semi major axis         
    c = abs(a - p1);                                    % Half the distance between the two foci
    b = sqrt(a^2 - c^2);                                % Length of the semi minor axis

    % Calculate points that will form the edge of the ellipse
    theta = linspace(0,2*pi,number);    % The collection of polar angles
    r = zeros(1,number);                % The collection of polar distances
    for index = 1:number                % Find for every polar angle the corresponding distance, using the definition of an ellipse
        p = b^2/a;
        e = c/a;
        r(index) = p/(1-e*cos(theta(index)-beta));  
    end
    [x,y] = pol2cart(theta,r);          % Convert the polar to cartesian coordinates
    x = x + centre(1);                  % Translate the ellipse in a way that the foci is in the same pixel as the gaze point.
    y = y + centre(2);
end
   
function [ alpha, beta ] = getPosAngles( eye_pos, gaze_pos )
%GETPOSANGLES Return the angels between 2 positions
%   When given a position of the eye and a gaze point, this algorithm will
%   calculate:
%       - alpha: the visual angle between the gaze point and the projection
%                of the eye on the screen
%       - beta:  the angle between the line that connects the projection
%                of the eye with the gaze point and a horizontal line.
           
    % Calculate the position vectors in the horizontal and vertical plane
    eye_prj = eye_pos;
    eye_prj(3) = 0;                 % Because the screen is placed orthogonal, the only coordinate that changes is z to 0
    v_prj = eye_prj-eye_pos;        % The projection vector is pointed from the eye to its projection
    v_gaze =  gaze_pos-eye_pos;     % The gaze vector is pointed from the eye to the gaze point
    dx = gaze_pos(1) - eye_prj(1);  % The horizontal and vertical distances between the projection of the eye and the gaze point are calculated
    dy = gaze_pos(2) - eye_prj(2);

    % Calculate alpha and beta projected on the screen
    alpha = abs(acos(dot(v_prj, v_gaze)/(norm(v_prj)*norm(v_gaze))));   % Alpha is calculated with vector arithmetic
    beta = cart2pol(dx,dy);                                             % Beta is calculated by converting the distances to polar coordinates
end
