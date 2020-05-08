% EYE TRACKING DATA INTERPRETATION
%% ________________________________

% This script collects information about gaze data and area's of interest 
% for specific tasks recorded with a Tobii eyetracker device. An
% I2MC-filter is used to find the fixations is noisy data.

%% OPTIONS
%% Screen options

opt.xres       = 1920;      % maximum value of horizontal resolution in pixels
opt.yres       = 1200;      % maximum value of vertical resolution in pixels
opt.one_pxl_mm = 0.26972;   % The diameter of one pixel in millimeter
opt.scrSz      = [opt.xres opt.yres]*opt.one_pxl_mm/10; % screen size in cm


%% Data options

opt.freq                = 120;                                             % The number of samples taken every second
opt.raw                 = false;                                           % If this setting is set to true, the fixation filter will be ignored and the raw data will be used
opt.expected_eye_pos    = [opt.xres/2 opt.yres/2 -600/opt.one_pxl_mm];     % The position where the eye is expected to be in a pixel coordinate system.
opt.experiments         = {'UL'};                                    % The different experiments that are recorded in the data ('HF', 'UL')
opt.keys.UL             = {'iddisc'};                                      % Keywords that correspond to the start of an upper-lower experiment


%% Task options

opt.aois.UL.names.voronoi = {'right_eye', 'left_eye', 'mouth', 'nose'};
opt.aois.UL.names.rect    = {};
opt.length.UL.iddisc  = 40*opt.freq;                 % The total number of samples in an upper-lower trail
opt.aois.UL.iddisc.voronoi  = [901 546; 1018 545; 963 682; 963 622];
opt.aois.UL.iddisc.max_vor  = 125;


opt.aois.type            = 3;        % Select the type of AOI which will be used: 1) Standard 2) Broad borders 3) Normal distribution
opt.aois.min_qmc_samples = 100;
opt.aois.mid_qmc_samples = 1000;     
opt.aois.max_qmc_samples = 10000;
opt.aois.qmc_bases   = [2,3];        % The base for the x and y halton sequence
opt.aois.qmc_error   = 10^-4;        % The maximum error which will be interpreted as converged


opt.angle         = 1;    % The maximum angle which will count as valid 
opt.acc_threshold = 0.5;  % The minimum value for the accuracy, for the data processing to continue
opt.m_sld         = [730.5 243.5; 527.5 359.5; 528.5 493.5; 557.5 414.5; 579.5 327.5; 631.5 439.5; 719.5 400.5; 691.5 329.5; 768.5 360.5]; % The positions of the calibration crosses on the slide
opt.m             = opt.m_sld + [320 240]; % Adjust the positions of the calibration crosses to be relative to the screen


%% Plot options

opt.overall_plot    = false;
opt.visualize       = true;                       % Choose if plots are created
opt.xmin            = 560;                        % The area which is plotted, when making a plot
opt.xmax            = 1360;
opt.ymin            = 300;
opt.ymax            = 900;
opt.plotpos         = [100, 100, 700, 650];       % The position of the plot on the screen
opt.mesh            = 100;                        % Number of coordinates of the ellipse that are plotted for the calibration validation
opt.plot            = {'iddiscr'};  % The index of the trail that will be plotted (facesL, housesL, M, F)
opt.plot_AOIs       = true;


%% Filter options

opt.missingx    = -opt.xres; % missing value for horizontal position in eye-tracking data (example data uses -xres). used throughout functions as signal for data loss
opt.missingy    = -opt.yres; % missing value for vertical position in eye-tracking data (example data uses -yres). used throughout functions as signal for data loss
opt.downsamples = [];        % Collection of the divisors for downsampling the data. If too much downsampled, there is a risk there are too little samples for the algorithm to run


%% DATA PROCESSING
%% find the input

calibration_file = {};
experiment_file = {};
started = false;
participants = struct();

while ~started
    % Find the data files that need to be used
    while isempty(calibration_file) || isempty(experiment_file)
        % Ask for the participant whos data need to be processed
        participant = input('Which participant''s data would you like to process? If you would like to start, type ''start'': ','s');
        if strcmp(participant, 'start'), started = true; break; end
        
        % Loop through all filenames
        all_files = dir;    
        for file = 1:length(all_files)
            filename = all_files(file).name;
            if max(strfind(filename, participant)) % Check if the file belongs to the participant
                if max(strfind(filename, 'ali'))   % Check if it is a calibration or task data file
                    calibration_file = [calibration_file filename];
                else
                    experiment_file = [experiment_file filename];
                end
            end
        end
    end
    
    if started, break; end
    % If more than one calibration file is found, ask which one needs to be
    % used
    if length(calibration_file) > 1
        fprintf('The following calibration files are found: \n ')
        disp(calibration_file);
        index = input('Please enter the index of the file you want to keep: ');
        calibration_file = calibration_file{index};
    else
        calibration_file = calibration_file{1};
    end

    % If more than one task data file is found, ask which one needs to be used
    if length(experiment_file) > 1
        fprintf('The following trail data files are found: \n ')
        disp(experiment_file);
        index = input('Please enter the index of the file you want to keep: ');
        experiment_file = experiment_file{index};
    else
        experiment_file = experiment_file{1};
    end
    disp(['the following files will be processed: ', calibration_file, ' and ', experiment_file]);
    participants.(matlab.lang.makeValidName(participant)).calibration_file = calibration_file;
    participants.(matlab.lang.makeValidName(participant)).experiment_file  = experiment_file;
    calibration_file = {};
    experiment_file = {};
end

all_participants = fieldnames(participants);
for participant_field_index = 1:length(all_participants)
    participant_field = all_participants{participant_field_index};
    disp('Current participant:');
    disp(participant_field);
    participant = participants.(matlab.lang.makeValidName(participant_field));
    %% Calibration validation
    
    % Validate the calibration
    calibration_data       = importEyetrackingData(participant.calibration_file, opt);  % Import the calibration file;
    disp('Starting calibration validation.');
    calibration_validation = caliVali(calibration_data, participant_field, opt);                % Interpret the calibration validation results
    opt.calivali.RMS                    = calibration_validation{end,3};
    opt.calivali.allowed_angle          = calibration_validation{end,2};
    opt.calivali.accuracy               = calibration_validation{end,1};
    participant.calibration_validation  = calibration_validation;
    if opt.calivali.accuracy < opt.acc_threshold
        error('The accuracy is lower then the threshold. If you want to continue, please adjust the calivali parameters.');
    end
    
    %% Data processing

    % Process the AOI data
    experiment_data                    = importEyetrackingData(participant.experiment_file, opt);
    if opt.overall_plot, participant.heatmaps = getHeatmaps(experiment_data, opt); end
    [participant.results, opt] = AOIStats(experiment_data, participant_field, opt);
    participant = rmfield(participant, 'experiment_file');
    participant = rmfield(participant, 'calibration_file');
    results.(matlab.lang.makeValidName(participant_field)) = participant;
    if opt.aois.type == 3, opt.aois = rmfield(opt.aois, 'sample_table'); end
end

switch opt.aois.type
    case 1
        name = 'raw';
    case 2
        name = 'broad_borders';
    case 3
        name = 'normal_dist';
end

ET_average_group(results, name);
if opt.overall_plot, results = overall_plots(results, opt); end

clear name calibration_data all_files calibration_file file filename index trail_data trail_file ans opt calibration_validation experiment_data experiment_file HF_results participant particpant_field participants started UL_results participant_field all_participants participant_field_index
