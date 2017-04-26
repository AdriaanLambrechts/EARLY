function [H,G] = coeffvar(D,figh,P)
% dataset/coeffvar - coefficient of variation of a dataset
%    coeffvar(D) calculates the time dependent coefficient of variation 
%    of inter spike interval distributions for the spike times in
%    dataset D.
%
%    coeffvar(D,figh) uses figure handle figh for plotting
%    (default = [] -> gcf). 
%
%    coeffvar(D,figh,P) uses parameters P for displaying the coeffvar.
%    P is typically a dataviewparam object or a valid 2nd input argument to
%    the dataviewparam constructor method, such as a parameter filename.
%
%    coeffvar is a standard "dataviewer", meaning that it may serve as
%    viewer for online data analysis during data collection. In addition,
%    the plot generated by all dataviewers allow an interactive change of
%    analysis parameter view the Params|Edit pullodwn menu (Ctr-Q).
%    For details on dataviewers, see dataviewparam.
%
%    See also dataviewparam, dataset/enableparamedit.

% Handle the special case of parameter queries. 
% Do this immediately to avoid endless recursion with dataviewparam.
if isvoid(D) && isequal('params', figh),
    [H,G] = local_ParamGUI;
    return;
end

% Should we open a new figure or use an existing one?
if nargin<2 || isempty(figh),
    open_new = isempty(get(0,'CurrentFigure'));
    figh = gcf; 
else
    open_new = isSingleHandle(figh);
end

% Parameters
if nargin<3, P = []; end
if isempty(P), % use default paremeter set for this dataviewer
    P = dataviewparam(mfilename); 
end

% delegate the real work to local fcn
H = local_coeffvar(D, figh, open_new, P);

% enable parameter editing when viewing offline
if isSingleHandle(figh, 'figure'), enableparamedit(D, P, figh); end;



%============================================================
%============================================================
function data_struct = local_coeffvar(D, figh, open_new, P);
% the real work for computing the coefficient of variation
if isSingleHandle(figh, 'figure')
    figure(figh); clf; ah = gca;
    if open_new, placefig(figh, mfilename, D.Stim.GUIname); end % restore previous size 
else
    ah = axes('parent', figh);
end

% Check varied stimulus Params
Pres = D.Stim.Presentation;
P = struct(P); P = P.Param;
isortPlot = P.iCond(P.iCond<=Pres.Ncond); % limit to actual Ncond
if isortPlot==0, isortPlot = 1:Pres.Ncond; end;
Ncond = numel(isortPlot);
AW = P.Anwin;
Chan = 1; % digital input
Rec = D.Rec.RecordInstr(1,Chan);
if ~(P.dt==0)
    dt = P.dt;
else
    Fsam = Rec.Fsam; % sample frequency (in Hz) for acquiring spikes
    dt = 1e3/Fsam; % sample time (in ms)
end
% XXXXXX

% prepare plot
Clab = CondLabel(D);
[axh, Lh, Bh] = plotpanes(Ncond+1, 0, figh);

% get sorted spikes
TC = spiketimes(D, Chan, 'no-unwarp');
BurstDur = max(D.Stim.GenericStimParams.BurstDur(:,1));
if isequal('burstdur', AW),
    aw = [0 BurstDur];
else
    aw = AW;
end
T = aw(1):dt:aw(2);
imw = find((P.Meanwin(1)<=T)&(T<=P.Meanwin(2))); % index of time values in the mean window

% H = zeros(Ncond, P.Nbin);
isortPlot=isortPlot(:).';
for i=1:Ncond
    icond = isortPlot(i);
    % The following exact method is due to Wright et al., 2012
    [u, n] = deal(zeros(Pres.Nrep,length(T)));
    for irep=1:Pres.Nrep
        spt = sort(TC{icond,irep}); % spike times of condition icond and repetition irep in ascending order
        spt = AnWin(spt, aw); % apply analysis window
        DiffSpt = diff(spt); % ISIs
        for ii=1:numel(DiffSpt)
            t = find((spt(ii)<=T)&(T<=spt(ii+1))); % index of time interval to update
            u(irep,t) = u(irep,t) + DiffSpt(ii);
            n(irep,t) = n(irep,t) + 1;
        end
    end
    N = sum(n,1);
    U = sum(u,1)./N; % by defenition, the mean ISI
    Std = sqrt(sum((u-repmat(U,[Pres.Nrep 1])).^2,1)./N); % the corresponding standard deviation
    C = Std./U; % CV 
    meanCV = mean(C(imw));
    CVstr = ['mean CV = ' num2str(meanCV)];
    h = axh(i); % current axes handle
    % axes(h); % slow!!!
%     plot(h, T, U, 'k'); hold on
%     plot(h, T, [U-Std, U+Std], 'Color', 0.7*[1 1 1], 'Linestyle', ':');
%     plot(h, T, C, 'Color', 'r', 'LineWidth', 1);
    [h, hU, hC] = plotyy(h,T,[U; U-Std; U+Std],T,C,'plot','plot');
    set(hU,'Color','b');
    set(hC,'Color','r'); set(hC,'LineWidth',2);
    set(h,{'ycolor'},{'b';'r'});
    title(h(2), Clab{icond});
    set(gcf,'CurrentAxes',h(1));
    text(0.1, 0.1, CVstr, 'units', 'normalized', 'color', 'r', 'fontsize', 12 , 'interpreter', 'latex');

    data_struct.spt{icond} = spt;
    data_struct.DiffSpt{icond} = DiffSpt;
    data_struct.aw = aw;
    data_struct.U{icond} = U;
    data_struct.N{icond} = N;
    data_struct.Std{icond} = Std;
    data_struct.meanCV(icond) = meanCV;
    data_struct.CVstr{icond} = CVstr;
    data_struct.title{icond} = Clab{icond};
    data_struct.xlabel = 'time (ms)';
    data_struct.ylabal = 'mean (ms) / CV';
    
    
    
end
Xlabels(Bh,'time (ms)','fontsize',10);
Ylabels(Lh,'mean (ms) / CV','fontsize',10);
% axes(axh(end));
set(gcf,'CurrentAxes',axh(end));
text(0.1, 0.5, IDstring(D, 'full'), 'fontsize', 12, 'fontweight', 'bold','interpreter','none');
if nargout<1, clear H ; end % suppress unwanted echoing
        
function [T,G] = local_ParamGUI
% Returns the GUI for specifying the analysis parameters.
P = GUIpanel('coeffvar','');
iCond = ParamQuery('iCond', 'iCond:', '0', '', 'integer',...
    'Condition indices for which to calculate the CV. 0 means: all conditions.', 20);
Anwin = ParamQuery('Anwin', 'analysis window:', 'burstdur', '', 'anwin',...
    'Analysis window (in ms) [t0 t1] re the stimulus onset. The string "burstdur" means [0 t], in which t is the burst duration of the stimulus.');
Meanwin = ParamQuery('Meanwin', 'mean window:', '[12 20]', '', 'anwin',...
    'Window (in ms) [t0 t1] considered when computing the mean CV.');
dt = ParamQuery('dt', 'dt:', '0', '', 'rreal/nonnegative',...
    'Analysis interval (in ms) between points of time on which the CV is computed. 0 means: use sample frequency resolution.', 1);
% ParamOrder = ParamQuery('ParamOrder', 'param order:', '', {'[1 2]','[2 1]'}, 'posint',...
%     'Order of independent parameters when sorting [1 2] = "Fastest varied" = "Fastest varied". [2 1] = conversely.', 10);
% SortOrder = ParamQuery('SortOrder', 'sorting order:', '0 0', '', 'integer',...
%     'Sorting order of corresponding independent parameters. (-1,0,1)=(descending, as visited, ascending)',10);
P = add(P, iCond);
P = add(P, Anwin, below(iCond));
P = add(P, Meanwin, below(Anwin));
P = add(P, dt, below(Meanwin));
% P = add(P, ParamOrder, below(Anwin));
% P = add(P, SortOrder, below(ParamOrder));
P = marginalize(P,[4 4]);
G = GUIpiece([mfilename '_parameters'],[],[0 0],[10 10]);
G = add(G,P);
G = marginalize(G,[10 10]);
% list all parameters in a struct
T = VoidStruct('iCond/Anwin/Meanwin/dt');
