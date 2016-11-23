function bestparam = fitfunc(xdata,ydata,func,initparam)

 
 %% Here the minimization internal routine (fminsearch) is called
 options = [];
 options = optimset(options,'MaxFunEvals',6000,'TolFun',1e-9,'MaxIter',10000,'MaxFunEvals',10000,'TolX', 1.000000e-006);
[bestparam, sumsqres, exitflag, output] = fminsearch(@itera,initparam,options,xdata,ydata,func);
 %%
 
 algorithm = output.algorithm ;
 %output.funcCount
 iterations = output.iterations ;
 message = output.message ;
 
       switch func
        
        case 1
            y = bestparam(2)*exp(-(xdata-bestparam(1)).^2/(2*bestparam(3).^2)) + bestparam(4) ;

        case 2
            y = bestparam(2)*sech(((xdata-bestparam(1))/bestparam(3))).^2 + bestparam(4) ;
            
       end
 

 
 function sumsqres = itera(initparam,xdata,ydata,func)

     switch func

         case 1
             yfit = initparam(2)*exp(-(xdata-initparam(1)).^2/(2*initparam(3).^2)) + initparam(4) ;

         case 2
             yfit = initparam(2)*sech(((xdata-initparam(1))/initparam(3))).^2 + initparam(4) ;
     end
 
sumsqres = 0 ;

    DIFF = ydata - yfit ; % Calcule the residuals
    SQ_DIFF = DIFF.^2; % Square of residuals
    sumsqres = 1e12*sum(SQ_DIFF);
initparam ;
sumsqres ;