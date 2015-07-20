function rounded_number = RoundDec( number, nDecimals )
%ROUNDDEC shortened the length of decimals.
%   number: the decimal number to round (e.g. 0.3457).
%   nDecimals: the number of decimals to keep (e.g. 2 => 0.35).

coefficient = 10 ^ nDecimals;
rounded_number = round(number.*coefficient)/coefficient;

end