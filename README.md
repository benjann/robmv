# robmv
Stata module for robust multivariate estimation of location and covariance.

To install `robmv`, type

    . net install robmv, replace from(https://raw.githubusercontent.com/benjann/robmv/main/

in Stata. Stata version 11 or newer is required. Furthermore, `moremata` is 
required. To install `moremata`, type

    . ssc install moremata, replace

or

    . net install moremata, replace from(https://raw.githubusercontent.com/benjann/moremata/master/)


---

Main changes:

    01jan2021 (version 1.0.2)
    - robreg mm added
    - robreg s failed to fully optimize the final candidates; this is fixed

    28dec2020 (version 1.0.1)
    - added option -whilferty- in -robmv s-

    27dec2020 (version 1.0.0)
    - robmv released on GitHub
