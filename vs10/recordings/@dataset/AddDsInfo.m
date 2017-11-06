function [ DS ] = AddDsInfo( DS,ds_info )
%AddDsInfo Add Info on Pen Depth, Electrode & SubStimType to the dataset
%   ds_info is a struct with at least these fields:
%   pen_depth: penetration depth in micron
%   electrode: number of the electrode used
%   SubStimType: Sub Stimulus Type(Comes behimd the StimType of the dataset)

if DS.ID.PenDepth ~= ds_info.pen_depth
    DS.ID.PenDepth = ds_info.pen_depth;
    DS.ID.Experiment = status(DS.ID.Experiment,'iCell',ds_info.iCell,'iRecOfCell',ds_info.iRecOfCell-1, 'PenDepth', ds_info.pen_depth);
%     LogStr = {['-----------Unit ' num2str(ds_info.iCell) ' (' num2str(ds_info.pen_depth) ' um)---------']};
    LogStr = ['-----------Unit ' num2str(ds_info.iCell) ' (' num2str(ds_info.pen_depth) ' um)---------']; %EVE 09/08/2017: Function is not defined for 'cell' inputs. 
    
    addtolog(DS.ID.Experiment, LogStr);
end
DS.ID.SubStimType = ds_info.SubStimType;

iPen = ds_info.electrode;
if isempty(iPen) || isequal(0, iPen) || numel(iPen)>1, 
    warndlg('Invalid electrode number.','error'); 
else,
    DS.ID.iPen;
    DS.ID.Experiment = status(DS.ID.Experiment, 'iPen', iPen, 'PenDepth', ds_info.pen_depth);
    addtolog(DS.ID.Experiment, ['==========Electrode # ' num2str(iPen) '==========']);
end



end

