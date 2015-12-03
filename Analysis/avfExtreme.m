%% avfExtreme
% [r, drdt] = avfExtreme(alpha, beta1, beta2, epsilon)
%
% Gets amplitude (r) and time derivative (drdt) at local extremes of
% the amplitude vector field of an autonomous canonical oscillator
%
% See also AVFGUI

%%
function [r, drdt] = avfExtreme(alpha, beta1, beta2, epsilon)

rext = sqrt(roots([3*epsilon^2*(beta1-beta2),... % Get local extremes
  epsilon*(epsilon*alpha-6*beta1+5*beta2),...
  -2*epsilon*alpha+3*beta1, alpha]));

ind = intersect(find(imag(rext)==0),find(rext > 0));
r = sort(rext(ind)); % Take only real positive values

if epsilon && beta2 % Take values within bound for nonzero beta2, epsilon
  r = r((r < 1/sqrt(epsilon)));
end

drdt = alpha*r + beta1*r.^3 + beta2*epsilon*r.^5./(1-epsilon*r.^2);
