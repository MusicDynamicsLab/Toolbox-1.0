%% outputDisplay
%  General function for displaying network and/or connection outputs after running a simulation, given a model variable
% 
%  The first input must be the model structure
%  Each subsequent group of inputs specifies a particular display or group of displays
% 
%  For network display(s):
%   First input 'net', 
% 	then the unique network id assigned in the model structure to the desired network,
% 	then one or more display types, each specified as a string.
% 		'mean'   - Plot of mean field time-domain waveform of the network
% 		'amp'    - Plot of averaged amplitudes of each oscillator in the network 
% 		'fft'    - Plot of mean-field log spectrum of the network 
% 		'ampx'   - Image of amplitudes (in color) of all oscillators (Y-axis) over time (X-axis)
% 		'spec'   - Spectrogram of mean-field of network 
% 		'auto'   - Autocorrelogram of mean-field of network 
% 		'oscfft' - Log spectrum (in color) of each oscillator (X-axis), with frequency on Y-axis
% 
%  For connection display(s):
% 	First input 'con',
% 	then the unique network id assigned in the model structure to the desired network,
% 	then the unique connection id assigned in the network structure for the desired input connectivity,
% 	then one or more display types of the final connectivity, each specified as a string.
% 		'ampall'   - Image of the amplitudes of the connectivity matrix
% 		'phaseall' - Image of the phases of the connectivity matrix
% 		'realall'  - Image of the real portion of the connectivity matrix
% 		'imagall'  - Image of the imaginary portion of the connectivity matrix
% 		'amp'      - Plot of the amplitudes of the middle row of the connectivity matrix
% 		'phase'    - Plot of the phases of the middle row of the connectivity matrix
% 		'real'     - Plot of the real portion of the middle row of the connectivity matrix
% 		'imag'     - Plot of the imaginary portion of the middle row of the connectivity matrix
% 
%  A figure is automatically generated for each individual plot specified. If a specific axes handle should
%  be used instead of a novel figure, that handle can be an input directly before the display type string.
% 
%  Example calls:
% 
%   outputDisplay(M,'net',3,'oscfft','fft')
%   outputDisplay(M,'net',2,'ampx','net',1,'amp','net',3,'spec','auto')
%   outputDisplay(M,'net',2,'con',2,1,'con',3,1,'phaseall')
% 
%  And if hand1 and hand2 are axes handles,
%  outputDisplay(M,'net',2,'con',2,1,'net',3,hand1,'fft',hand2,'ampx','con',3,1,'phaseall')
% 
%  The following code generates a 2-by-2 subplot, assuming there were at least 2 networks in the simulation:
% 
%   figure
%   set(gcf,'position',[50 50 800 600])
%   subplot(2,2,1)
%   hand1=gca;
%   subplot(2,2,2)
%   hand2=gca;
%   subplot(2,2,3)
%   hand3=gca;
%   subplot(2,2,4)
%   hand4=gca;
%   outputDisplay(M,'net',1,hand1,'fft',hand3,'spec','net',2,hand2,'fft',hand4,'spec')

%%
function outputDisplay(M,varargin)
%% Parse input
for i=1:length(varargin)
    if ischar(varargin{i}) && strcmpi(varargin{i},'net') && length(varargin) > i
        id = varargin{i+1};
        displays = {};
        handles = {};
        if length(varargin) > i + 1 && (ischar(varargin{i+2}) || ishghandle(varargin{i+2})) && ~strcmpi(varargin{i+2},'net') && ~strcmpi(varargin{i+2},'con')
            temp = varargin{i+2};
            count = i + 2;
            plotNum = 1;
            while ~isempty(temp) && ~strcmpi(temp,'net') && ~strcmpi(temp,'con')
                if ishghandle(temp)
                    handles{plotNum} = temp;
                    if length(varargin) > count
                        temp = varargin{count+1};
                    else
                        temp = [];
                    end
                else
                    displays{plotNum} = temp;
                    if length(handles) < length(displays)
                        handles{plotNum} = [];
                    end
                    if length(varargin) > count
                        temp = varargin{count+1};
                        plotNum = plotNum + 1;
                    else
                        temp = [];
                    end
                end
                count = count + 1;
            end
        else
            handles={[]};
            displays = {'amp'};
        end
        if length(handles) == 1 && isempty(displays)
            displays = {'amp'};
        end
        
        
        for j = 1:length(displays)
            if strcmpi(displays{j},'mean')
                meanTime(M,id,handles{j});
            elseif strcmpi(displays{j},'amp')
                averagedAmps(M,id,handles{j});
            elseif strcmpi(displays{j},'fft')
                simpleSpec(M,id,handles{j});
            elseif strcmpi(displays{j},'ampx')
                allAmps(M,id,handles{j});
            elseif strcmpi(displays{j},'spec')
                spectrogramMeanField(M,id,handles{j});
            elseif strcmpi(displays{j},'auto')
                autocorrelogramMeanField(M,id,handles{j});
            elseif strcmpi(displays{j},'oscfft')
                allFFT(M,id,handles{j});
            else
                message = ['Not a valid network display: ' displays{j}];
                error(message);
            end
        end
    end
    
    
    if ischar(varargin{i}) && strcmpi(varargin{i},'con') && length(varargin) > i + 1
        netid = varargin{i+1};
        conid = varargin{i+2};
        displays = {};
        handles = {};
        if length(varargin) > i + 2 && (ischar(varargin{i+3}) || ishghandle(varargin{i+3})) && ~strcmpi(varargin{i+3},'net') && ~strcmpi(varargin{i+3},'con')
            temp = varargin{i+3};
            count = i + 3;
            plotNum = 1;
            while ~isempty(temp) && ~strcmpi(temp,'net') && ~strcmpi(temp,'con')
                if ishghandle(temp)
                    handles{plotNum} = temp;
                    if length(varargin) > count
                        temp = varargin{count+1};
                    else
                        temp = [];
                    end
                else
                    displays{plotNum} = temp;
                    if length(handles) < length(displays)
                        handles{plotNum} = [];
                    end
                    if length(varargin) > count
                        temp = varargin{count+1};
                        plotNum = plotNum + 1;
                    else
                        temp = [];
                    end
                end
                count = count + 1;
            end
        else
            handles={[]};
            displays = {'ampall'};
        end
        if length(handles) == 1 && isempty(displays)
            displays = {'ampall'};
        end
        for j = 1:length(displays)
            if strcmpi(displays{j},'ampall')
                connectionAmpsAll(M,netid,conid,handles{j});
            elseif strcmpi(displays{j},'phaseall')
                connectionPhasesAll(M,netid,conid,handles{j});
            elseif strcmpi(displays{j},'realall')
                connectionRealAll(M,netid,conid,handles{j});
            elseif strcmpi(displays{j},'imagall')
                connectionImagAll(M,netid,conid,handles{j});
            elseif strcmpi(displays{j},'amp')
                connectionAmps(M,netid,conid,handles{j});
            elseif strcmpi(displays{j},'phase')
                connectionPhases(M,netid,conid,handles{j});
            elseif strcmpi(displays{j},'real')
                connectionReal(M,netid,conid,handles{j});
            elseif strcmpi(displays{j},'imag')
                connectionImag(M,netid,conid,handles{j});
            else
                message = ['Not a valid connection display: ' displays{j}];
                error(message);
            end
        end
    end
end

%% Network mean field time domain plot
function meanTime(M,id,handle)
n = M.n{id};
t = n.t;
Z = real(mean(n.Z));
% ticks = tickMake(f,8);
if isempty(handle)
    figure;
else
    axes(handle);
end
plot(t,Z);axis tight;grid on;zoom xon;
title(sprintf('Mean field time-domain waveform of network %d',id));
xlabel('Time (sec)');
ylabel('Amplitude');
drawnow;

%% Network averaged amplitudes plot
function averagedAmps(M,id,handle)
n = M.n{id};
f = n.f;
amps = mean(abs(n.Z),2);
% ticks = tickMake(f,8);
if isempty(handle)
    figure;
else
    axes(handle);
end
switch n.fspac
    case 'log'
        semilogx(f,amps,'.-');axis tight;grid on;zoom xon;
    case 'lin'
        plot(f,amps,'.-');axis tight;grid on;zoom xon;
end
if ~isempty(n.tick)
    set(gca,'xtick',n.tick);
end
title(sprintf('Averaged amplitudes of oscillators in network %d',id));
xlabel('Oscillator natural frequency (Hz)');
ylabel('Average amplitude');
drawnow;

%% Network mean-field FFT plot
function simpleSpec(M,id,handle)
freqLim = max(M.n{id}.f)*2;
Z = real(mean(M.n{id}.Z));
fs = M.fs/M.n{id}.sStep;
NFFT = 16384;
freqs = fs/2*linspace(0,1,NFFT/2+1);
ind = floor(length(freqs)*freqLim/(fs/2));
% ind = length(freqs)-1';
Zfreq = magSpec(Z,NFFT);
if isempty(handle)
    figure;
else
    axes(handle);
end
plot(freqs(1:ind),Zfreq(1:ind));axis tight;grid on;zoom xon;
title(sprintf('Fourier transform of mean field of network %d',id));
xlabel('Frequency (Hz)');
ylabel('Amplitude (dB)');
drawnow;

%% Image of oscillator amplitudes over time
function allAmps(M,id,handle)
n = M.n{id};
t = n.t;
Z = abs(n.Z);
f = getLim(n);
% ticks = tickMake(f,8);
if isempty(handle)
    figure;
else
    axes(handle);
end
imagesc(t,f,Z);
cbar = colorbar;set(get(cbar,'ylabel'),'string','Amplitude');
switch n.fspac
    case 'log'
        if ~isempty(n.tick)
            set(gca,'ydir','normal','yscale','log','ytick',n.tick);
        else
            set(gca,'ydir','normal','yscale','log');
        end
    case 'lin'
        if ~isempty(n.tick)
            set(gca,'ydir','normal','ytick',n.tick);
        else
            set(gca,'ydir','normal');
        end
end
title(sprintf('Amplitudes of oscillators over time in network %d',id));
xlabel('Time (sec)');
ylabel('Oscillator natural frequency (Hz)');
drawnow;

%% Network mean-field spectrogram
function spectrogramMeanField(M,id,handle)
Z = real(mean(M.n{id}.Z));
fs = M.fs/M.n{id}.sStep;
NFFT = 16384;
freqLim = max(M.n{id}.f)*2;
percentages = [0 100*freqLim/(fs/2)];
if isempty(handle)
    figure;
else
    axes(handle);
end
myFreqs(Z,NFFT,fs,percentages);
title(sprintf('Spectrogram for mean field of network %d',id));

%% Network mean-field autocorrelogram
function autocorrelogramMeanField(M,id,handle)
Z = real(mean(M.n{id}.Z));
fs = M.fs/M.n{id}.sStep;
NFFT = 16384;
freqLim = max(M.n{id}.f)*2;
percentages = [0 100*freqLim/(fs/2)];
if isempty(handle)
    figure;
else
    axes(handle);
end
myAutocorr(Z,NFFT,fs,percentages);
title(sprintf('Autocorrelogram for mean field of network %d',id));

%% Network FFT of all oscillators
function allFFT(M,id,handle)
n = M.n{id};
Z = real(n.Z)';
NFFT = 16384;
freqLim = max(n.f)*2;
fs = M.fs/n.sStep;
freqs = fs/2*linspace(0,1,NFFT/2+1);
ind = floor(length(freqs)*freqLim/(fs/2));
% ticks = tickMake(f,8);
Zfreq = magSpec(Z,NFFT);
if isempty(handle)
    figure;
else
    axes(handle);
end
f = getLim(n);
imagesc(f,freqs(1:ind),Zfreq(1:ind,:));
cbar = colorbar;set(get(cbar,'ylabel'),'string','Amplitude (dB)');
switch n.fspac
    case 'log'
        if ~isempty(n.tick)
            set(gca,'ydir','normal','xscale','log','xtick',n.tick);
        else
            set(gca,'ydir','normal','xscale','log');
        end
    case 'lin'
        if ~isempty(n.tick)
            set(gca,'ydir','normal','xtick',n.tick);
        else
            set(gca,'ydir','normal');
        end
end
title(sprintf('Fourier transform of every oscillator in network %d',id));
xlabel('Oscillator natural frequency (Hz)');
ylabel('Frequency (Hz)');
drawnow;

%% Image of amplitudes of connectivity matrix
function connectionAmpsAll(M,netTo,conid,handle)
nTo = M.n{netTo};
nFrom = M.n{M.n{netTo}.con{conid}.source};
fTo = getLim(nTo);
fFrom = getLim(nFrom);
C = abs(nTo.con{conid}.C);
% ticks = tickMake(f,8);
if isempty(handle)
    figure;
else
    axes(handle);
end
imagesc(fFrom,fTo,C);
cbar = colorbar;set(get(cbar,'ylabel'),'string','Amplitude');
switch nFrom.fspac
    case 'log'
        if ~isempty(nFrom.tick)
            set(gca,'xscale','log','xtick',nFrom.tick);            
        else
            set(gca,'xscale','log');
        end
    case 'lin'
        if ~isempty(nFrom.tick)
            set(gca,'xtick',nFrom.tick)
        end
end
switch nTo.fspac
    case 'log'
        if ~isempty(nTo.tick)
            set(gca,'yscale','log','ytick',nTo.tick);            
        else
            set(gca,'yscale','log');
        end
    case 'lin'
        if ~isempty(nTo.tick)
            set(gca,'ytick',nTo.tick)
        end
end
title(sprintf('Amplitudes of connection matrix %d to network %d',conid,netTo));
xlabel(sprintf('Oscillator natural frequency (Hz): Network %d',nFrom.id));
ylabel(sprintf('Oscillator natural frequency (Hz): Network %d',netTo));
drawnow;

%% Image of phases of connectivity matrix
function connectionPhasesAll(M,netTo,conid,handle)
nTo = M.n{netTo};
nFrom = M.n{M.n{netTo}.con{conid}.source};
fTo = getLim(nTo);
fFrom = getLim(nFrom);
C = angle(nTo.con{conid}.C);
% ticks = tickMake(f,8);
if isempty(handle)
    figure;
else
    axes(handle);
end
imagesc(fFrom,fTo,C);
load('MyColormaps', 'IF_colormap');
circular = IF_colormap;
cbar = colorbar;set(get(cbar,'ylabel'),'string','Phase');
colormap(cbar,circular);
% set(gcf,'colormap',circular)
switch nFrom.fspac
    case 'log'
        if ~isempty(nFrom.tick)
            set(gca,'xscale','log','xtick',nFrom.tick);            
        else
            set(gca,'xscale','log');
        end
    case 'lin'
        if ~isempty(nFrom.tick)
            set(gca,'xtick',nFrom.tick)
        end
end
switch nTo.fspac
    case 'log'
        if ~isempty(nTo.tick)
            set(gca,'yscale','log','ytick',nTo.tick);            
        else
            set(gca,'yscale','log');
        end
    case 'lin'
        if ~isempty(nTo.tick)
            set(gca,'ytick',nTo.tick)
        end
end
title(sprintf('Phases of connection matrix %d to network %d',conid,netTo));
xlabel(sprintf('Oscillator natural frequency (Hz): Network %d',nFrom.id));
ylabel(sprintf('Oscillator natural frequency (Hz): Network %d',netTo));
drawnow;

%% Image of real portion of connectivity matrix
function connectionRealAll(M,netTo,conid,handle)
nTo = M.n{netTo};
nFrom = M.n{M.n{netTo}.con{conid}.source};
fTo = getLim(nTo);
fFrom = getLim(nFrom);
C = real(nTo.con{conid}.C);
% ticks = tickMake(f,8);
if isempty(handle)
    figure;
else
    axes(handle);
end
imagesc(fFrom,fTo,C);
cbar = colorbar;set(get(cbar,'ylabel'),'string','Real part');
switch nFrom.fspac
    case 'log'
        if ~isempty(nFrom.tick)
            set(gca,'xscale','log','xtick',nFrom.tick);            
        else
            set(gca,'xscale','log');
        end
    case 'lin'
        if ~isempty(nFrom.tick)
            set(gca,'xtick',nFrom.tick)
        end
end
switch nTo.fspac
    case 'log'
        if ~isempty(nTo.tick)
            set(gca,'yscale','log','ytick',nTo.tick);            
        else
            set(gca,'yscale','log');
        end
    case 'lin'
        if ~isempty(nTo.tick)
            set(gca,'ytick',nTo.tick)
        end
end
title(sprintf('Real part of connection matrix %d to network %d',conid,netTo));
xlabel(sprintf('Oscillator natural frequency (Hz): Network %d',nFrom.id));
ylabel(sprintf('Oscillator natural frequency (Hz): Network %d',netTo));
drawnow;

%% Image of imaginary portion of connectivity matrix
function connectionImagAll(M,netTo,conid,handle)
nTo = M.n{netTo};
nFrom = M.n{M.n{netTo}.con{conid}.source};
fTo = getLim(nTo);
fFrom = getLim(nFrom);
C = imag(nTo.con{conid}.C);
% ticks = tickMake(f,8);
if isempty(handle)
    figure;
else
    axes(handle);
end
imagesc(fFrom,fTo,C);
cbar = colorbar;set(get(cbar,'ylabel'),'string','Imaginary part');
switch nFrom.fspac
    case 'log'
        if ~isempty(nFrom.tick)
            set(gca,'xscale','log','xtick',nFrom.tick);            
        else
            set(gca,'xscale','log');
        end
    case 'lin'
        if ~isempty(nFrom.tick)
            set(gca,'xtick',nFrom.tick)
        end
end
switch nTo.fspac
    case 'log'
        if ~isempty(nTo.tick)
            set(gca,'yscale','log','ytick',nTo.tick);            
        else
            set(gca,'yscale','log');
        end
    case 'lin'
        if ~isempty(nTo.tick)
            set(gca,'ytick',nTo.tick)
        end
end
title(sprintf('Imaginary part of connection matrix %d to network %d',conid,netTo));
xlabel(sprintf('Oscillator natural frequency (Hz): Network %d',nFrom.id));
ylabel(sprintf('Oscillator natural frequency (Hz): Network %d',netTo));
drawnow;

%% Connection amplitudes of middle row of connectivity matrix
function connectionAmps(M,netTo,conid,handle)
n = M.n{netTo};
f = n.f;
ind = ceil(length(f)/2);
% ticks = tickMake(f,8);
amps = abs(n.con{conid}.C(ind,:));
if isempty(handle)
    figure;
else
    axes(handle);
end
plot(f,amps,'.-');axis tight;grid on;zoom xon;
switch n.fspac
    case 'log'
        if ~isempty(n.tick)
            set(gca,'xscale','log','xtick',n.tick);
        else
            set(gca,'xscale','log');
        end
    case 'lin'
        if ~isempty(n.tick)
            set(gca,'xtick',n.tick);
        end
end
title(sprintf('Amplitudes of connections to middle oscillator of network %d in matrix %d',netTo,conid));
xlabel('Oscillator natural frequency (Hz)');
ylabel('Amplitude');
drawnow;

%% Connection phases of middle row of connectivity matrix
function connectionPhases(M,netTo,conid,handle)
n = M.n{netTo};
f = n.f;
ind = ceil(length(f)/2);
% ticks = tickMake(f,8);
phases = angle(n.con{conid}.C(ind,:));
if isempty(handle)
    figure;
else
    axes(handle);
end
plot(f,phases,'.-');axis tight;grid on;zoom xon;
switch n.fspac
    case 'log'
        if ~isempty(n.tick)
            set(gca,'xscale','log','xtick',n.tick);
        else
            set(gca,'xscale','log');
        end
    case 'lin'
        if ~isempty(n.tick)
            set(gca,'xtick',n.tick);
        end
end
title(sprintf('Phases of connections to middle oscillator of network %d in matrix %d',netTo,conid));
xlabel('Oscillator natural frequency (Hz)');
ylabel('Phase');
drawnow;

%% Real values of middle row of connectivity matrix
function connectionReal(M,netTo,conid,handle)
n = M.n{netTo};
f = n.f;
ind = ceil(length(f)/2);
% ticks = tickMake(f,8);
realPart = real(n.con{conid}.C(ind,:));
if isempty(handle)
    figure;
else
    axes(handle);
end
plot(f,realPart,'.-');axis tight;grid on;zoom xon;
switch n.fspac
    case 'log'
        if ~isempty(n.tick)
            set(gca,'xscale','log','xtick',n.tick);
        else
            set(gca,'xscale','log');
        end
    case 'lin'
        if ~isempty(n.tick)
            set(gca,'xtick',n.tick);
        end
end
title(sprintf('Real part of connections to middle oscillator of network %d in matrix %d',netTo,conid));
xlabel('Oscillator natural frequency (Hz)');
ylabel('Real part');
drawnow;

%% Imaginary values of middle row of connectivity matrix
function connectionImag(M,netTo,conid,handle)
n = M.n{netTo};
f = n.f;
ind = ceil(length(f)/2);
% ticks = tickMake(f,8);
imagPart = imag(n.con{conid}.C(ind,:));
if isempty(handle)
    figure;
else
    axes(handle);
end
plot(f,imagPart,'.-');axis tight;grid on;zoom xon;
switch n.fspac
    case 'log'
        if ~isempty(n.tick)
            set(gca,'xscale','log','xtick',n.tick);
        else
            set(gca,'xscale','log');
        end
    case 'lin'
        if ~isempty(n.tick)
            set(gca,'xtick',n.tick);
        end
end
title(sprintf('Imaginary part of connections to middle oscillator of network %d in matrix %d',netTo,conid));
xlabel('Oscillator natural frequency (Hz)');
ylabel('Imaginary part');
drawnow;

%% function: Get axis limit for connection display
function axLim = getLim(n)
if strcmp(n.fspac, 'log')
    f1 = n.f(1);
    f2 = n.f(end);
    N = n.N;
    axMin = ((2*N-1)*f1*(f2/f1)^(-1/(2*(N-1))) + f2*(f2/f1)^(1/(2*(N-1))))/(2*N);
    axMax = (f1*(f2/f1)^(-1/(2*(N-1))) + (2*N-1)*f2*(f2/f1)^(1/(2*(N-1))))/(2*N);
    % Need to do this due to problems in using imagesc with log axis
else
    axMin = n.f(1);
    axMax = n.f(end);
end
axLim = [axMin axMax];

