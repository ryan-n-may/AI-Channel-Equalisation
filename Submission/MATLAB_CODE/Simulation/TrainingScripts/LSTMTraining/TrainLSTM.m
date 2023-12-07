%% INITIAL LSTM TRAINING
CreateLSTM;
CreateTrainingData;
CreateValidationData;

load("LSTMTRAININGDATA.mat", "LSTM_INPUT", "CHANNEL_H");
load("TrainedEstimator.mat", "lstm");
lstm = lstm.Mute();
[lstm, LSTMnet] = lstm.TrainLSTM(LSTM_INPUT, CHANNEL_H, false, NaN);
save("TrainedEstimator.mat", "LSTMnet", "lstm");

%% ITTERATIVE TRAINING
ROUNDS = 1000;
for i = 1:ROUNDS
    CreateTrainingData;
    fileName = getLatestFile("CheckpointPath/");
    load("CheckpointPath/" + fileName, "net")  
    load("LSTMTRAININGDATA.mat", "LSTM_INPUT", "CHANNEL_H");
    load("TrainedEstimator.mat", "lstm");
    [lstm, LSTMnet] = lstm.TrainLSTM(LSTM_INPUT, CHANNEL_H, true, net);
    save("TrainedEstimator.mat", "LSTMnet", "lstm");
end

CreateTrainingData;
fileName = getLatestFile("CheckpointPath/");
load("CheckpointPath/" + fileName, "net")  
load("LSTMTRAININGDATA.mat", "LSTM_INPUT", "CHANNEL_H");
load("TrainedEstimator.mat", "lstm");
lstm = lstm.UnMute();
[lstm, LSTMnet] = lstm.TrainLSTM(LSTM_INPUT, CHANNEL_H, true, net);
save("TrainedEstimator.mat", "LSTMnet", "lstm");

function [file] = getLatestFile(filedir)
    directory = dir(filedir);
    directory = directory(find(~cellfun(@isfolder,{directory(:).name})));
    [~, I] = max([directory(:).datenum]);
    if ~isempty(I)
        file = directory(I).name;
        disp(file);
    end
end
