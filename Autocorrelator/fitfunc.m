function [func fwhm bestparam] = fitfunc(actualpos,expfun,param,type)

options = [] ;
options = optimset(options,'MaxFunEvals',1000,'TolFun',1e-5); % Set fitting options
[bestparam, ~, ~, output] = fminsearch(@itera,param,options,actualpos,expfun,type); % Pass initparam, options and data to fitting function

[func fwhm] = buildfun(actualpos,bestparam,type); % Build fitted array with best param


function sumsqres = itera(param,x,y,type)

yfit = buildfun(x,param,type);
DIFF = y - yfit; % Calcule the residuals
SQ_DIFF = DIFF.^2; % Square of residuals

sumsqres = 10000*sum(SQ_DIFF);

function [func fwhm] = buildfun(actualpos,param,type)

c = 299.792458; % in um/ps

if strcmp('Gaussian',type)
    func = param(1)*exp(-(actualpos-param(2)).^2/(2*param(3)^2))+param(4);
    correctionfactor = sqrt(2); % Autocorrelation trace is longer that the pulse by this factor
    fwhm = 2*(2*sqrt(log(4))*param(2))/(c*correctionfactor);
else
    func = param(1)*sech((actualpos-param(2))/param(3)).^2 + param(4);
    correctionfactor = 1.54; % Autocorrelation trace is longer that the pulse by this factor
    fwhm = 2*(2*asech(sqrt(1/2))*param(2))/(c*correctionfactor);
    
end