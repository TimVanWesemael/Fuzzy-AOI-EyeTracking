function [UL_results_A, HF_results_A, UL_results_C, HF_results_C] = ET_average_group(results, name)
    all_participants = fieldnames(results);
    UL_results_A_mean = zeros(2,6);
    HF_results_A_mean = zeros(2,2);
    UL_results_C_mean = zeros(2,6);
    HF_results_C_mean = zeros(2,2);
    HF_results_A = [];
    UL_results_A = [];
    HF_results_C = [];
    UL_results_C = [];
    nb_A_UL = 0;
    nb_A_HF = 0;
    nb_C_UL = 0;
    nb_C_HF = 0;

    for participant_index = 1:length(all_participants)
        participant = all_participants{participant_index};
        if isfield(results.(matlab.lang.makeValidName(participant)).results, 'UL')
            curr_UL = results.(matlab.lang.makeValidName(participant)).results.UL.rect;
            curr_UL.key = [];
            curr_UL = [curr_UL results.(matlab.lang.makeValidName(participant)).results.UL.vor]; %#ok<*AGROW>
            curr_UL = curr_UL{end-1:end, 1:end-1};
        else
            curr_UL = nan*ones(2, 6);
        end
        if isfield(results.(matlab.lang.makeValidName(participant)).results, 'HF')
            curr_HF = results.(matlab.lang.makeValidName(participant)).results.HF.rect;
            curr_HF = curr_HF{end-1:end, 1:end-1};
        else
            curr_HF = nan*ones(2, 2);
        end
        participant_col = ones(2,1)*str2double(participant(2:3));
        if contains(participant, 'A')
            if ~max(isnan(curr_UL))
                UL_results_A_mean = UL_results_A_mean + curr_UL;
                nb_A_UL = nb_A_UL + 1;
            end
            if ~max(isnan(curr_HF))
                HF_results_A_mean = HF_results_A_mean + curr_HF;
                nb_A_HF = nb_A_HF + 1;
            end
            curr_HF = [participant_col curr_HF];
            curr_UL = [participant_col curr_UL];
            UL_results_A = [UL_results_A; curr_UL];
            HF_results_A = [HF_results_A; curr_HF];
        else
            if ~max(isnan(curr_UL))
                UL_results_C_mean = UL_results_C_mean + curr_UL;
                nb_C_UL = nb_C_UL + 1;
            end
            if ~max(isnan(curr_HF))
                HF_results_C_mean = HF_results_C_mean + curr_HF;
                nb_C_HF = nb_C_HF + 1;
            end
            curr_HF = [participant_col curr_HF];
            curr_UL = [participant_col curr_UL];
            UL_results_C = [UL_results_C; curr_UL];
            HF_results_C = [HF_results_C; curr_HF];
        end
    end
    UL_results_A_mean = UL_results_A_mean./nb_A_UL;
    HF_results_A_mean = HF_results_A_mean./nb_A_HF;
    UL_results_C_mean = UL_results_C_mean./nb_C_UL;
    HF_results_C_mean = HF_results_C_mean./nb_C_HF;

    UL_results_A_mean = [zeros(2,1) UL_results_A_mean];
    HF_results_A_mean = [zeros(2,1) HF_results_A_mean];
    UL_results_C_mean = [zeros(2,1) UL_results_C_mean];
    HF_results_C_mean = [zeros(2,1) HF_results_C_mean];

    UL_results_A = [UL_results_A; UL_results_A_mean];
    HF_results_A = [HF_results_A; HF_results_A_mean];
    UL_results_C = [UL_results_C; UL_results_C_mean];
    HF_results_C = [HF_results_C; HF_results_C_mean];

    UL_results_A = [UL_results_A(1:2:end,:) UL_results_A(2:2:end,:)];
    HF_results_A = [HF_results_A(1:2:end,:) HF_results_A(2:2:end,:)];
    UL_results_C = [UL_results_C(1:2:end,:) UL_results_C(2:2:end,:)];
    HF_results_C = [HF_results_C(1:2:end,:) HF_results_C(2:2:end,:)];

    UL_results_A(:,8) = [];
    HF_results_A(:,4) = [];
    UL_results_C(:,8) = [];
    HF_results_C(:,4) = [];

    UL_results_A = array2table(UL_results_A, 'VariableNames', {'Participant', 'Upper', 'Lower', 'Right_eye', 'Left_eye', 'Mouth', 'Nose', 'Upper_rel', 'Lower_rel', 'Right_eye_rel', 'Left_eye_rel', 'Mouth_rel', 'Nose_rel'});
    HF_results_A = array2table(HF_results_A, 'VariableNames', {'Participant', 'Faces', 'Houses', 'Faces_rel', 'Houses_rel'});
    UL_results_C = array2table(UL_results_C, 'VariableNames', {'Participant', 'Upper', 'Lower', 'Right_eye', 'Left_eye', 'Mouth', 'Nose', 'Upper_rel', 'Lower_rel', 'Right_eye_rel', 'Left_eye_rel', 'Mouth_rel', 'Nose_rel'});
    HF_results_C = array2table(HF_results_C, 'VariableNames', {'Participant', 'Faces', 'Houses', 'Faces_rel', 'Houses_rel'});

    mkdir results
    writetable(UL_results_A, ['results/UL_results_A_', name,'.csv']);
    writetable(HF_results_A, ['results/HF_results_A_', name,'.csv']);
    writetable(UL_results_C, ['results/UL_results_C_', name,'.csv']);
    writetable(HF_results_C, ['results/HF_results_C_', name,'.csv']);
end
