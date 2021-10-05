%
% Author, Rajesh Rao 
% 
% Accrued interest of security with periodic interest payments 
% ------------------------------------------------------------------------
% 
% Inputs:
%   :param: IssueDate (type datetime)
%       Issue date of the security being observed
%   :param: Settlement (type datetime)
%       Settlement date of the security being observed, take this to be
%       the current date in the timeseries
%   :param: FirstCouponDate (type datetime)
%       First cupon data of the security being observed
%   :param: FaceValue (type float)
%       Face value of the security, we default to 100
%   :param: Coupon (type float)
%       Coupon rate of the security being observed
% 
% Output:
%   :param: acrI (type float) - 1x1
%       The accrued interest of the calculated security 
% 

function [acrI] = accrued_interest(IssueDate, Settlement, ...
    FirstCouponDate, FaceValue, Coupon)
    
    % check to see Issue date before first coupon and settlement
    if (IssueDate <= Settlement) && (IssueDate <= FirstCouponDate)

        % compute accrued interest and map to correct index
        % 2 = semi-annual coupon, 0 = ACT/ACT day count basis
        acrI = acrubond(IssueDate, Settlement, FirstCouponDate, ...
            FaceValue, Coupon, 2, 0); 
        
    else
        acrI = 0;   % default to Zero accrued interest
    end
                
end
