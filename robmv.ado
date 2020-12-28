*! version 1.0.1  28dec2020  Ben Jann

capt findfile lmoremata.mlib
if _rc {
    di as error "the {bf:moremata} package is required; type {stata ssc install moremata, replace}"
    error 499
}

program robmv, eclass properties(svyb svyj)
    version 11
    if replay() {
        Display `0'
        exit
    }
    local version : di "version " string(_caller()) ":"
    gettoken subcmd : 0, parse(", ")
    if `"`subcmd'"'=="sd" {
        Check_sd_vce `0'
    }
    `version' _vce_parserun robmv, wtypes(pw iw aw fw) noeqlist: `0'
    if "`s(exit)'" != "" {
        ereturn local cmdline `"robmv `0'"'
        exit
    }
    gettoken subcmd 0 : 0, parse(", ")
    if `"`subcmd'"'==substr("classic", 1, max(2, strlen(`"`subcmd'"'))) {
        local subcmd "classic"
    }
    local cmdlist "classic m s mve mcd sd"
    if !`:list subcmd in cmdlist' {
        di as err `"invalid subcommand: `subcmd'"'
        exit 198
    }
    Estimate_`subcmd' `0' // returns diopts
    ereturn local cmdline `"robmv `subcmd'`0'"'
    if `"`e(nofit)'"'=="" {
        Display, `diopts'
    }
    if `"`e(generate)'"'!="" {
        di as txt _n "Stored variables" _c
        describe `e(generate)', fullnames
        Return_clear
    }
end

program Check_sd_vce
    _parse comma anything 0 : 0
    syntax [, vce(passthru) GENerate(passthru) nofit * ]
    if `"`vce'"'!="" {
        if `"`generate'"'!="" {
            di as err "{bf:vce()} and {bf:generate()} not both allowed"
            exit 198
        }
        if `"`fit'"'!="" {
            di as err "{bf:vce()} and {bf:nofit} not both allowed"
            exit 198
        }
    }
end

program Display
    syntax [, noHEader noTABle Level(passthru) * ]
    _get_diopts diopts, `options'
    if `"`e(cmd)'"'!="robmv" {
        di as err "last robmv results not found"
        exit 301
    }
    if `"`level'"'=="" local level level(`e(level)')
    if `"`header'"'=="" {
        _coef_table_header, nomodeltest
        local c1 _col(23)
        local c2 _col(35)
        local wfmt0 7
        local c3 _col(49)
        local c4 _col(67)
        local wfmt 10
        if `"`e(subcmd)'"'=="m" {
            di as txt `c3' "Winsorizing (%)" `c4' "= " as res %`wfmt'.0g e(ptrim)
            di as txt `c3' "Tuning constant" `c4' "= " as res %`wfmt'.0g e(k)
        }
        else if `"`e(subcmd)'"'=="s" {
            if `"`e(whilferty)'"'!="" di as txt `c3' "Tuning const (wh)" _c
            else                      di as txt `c3' "Tuning constant" _c
            di `c4' "= " as res %`wfmt'.0g e(k)
            di as txt `c3' "Scale" `c4' "= " as res %`wfmt'.0g e(scale)
            di as txt `c3' "Algorithm" `c4' "= " as res %`wfmt's e(method)
            di as txt `c3' "Candidates" `c4' "= " as res %`wfmt'.0g e(nsamp)
            di as txt `c3' "Candidate C-steps" `c4' "= " as res %`wfmt'.0g e(csteps)
            di as txt `c3' "Final candidates" `c4' "= " as res %`wfmt'.0g e(nkeep)
        }
        else if `"`e(subcmd)'"'=="mcd" {
            di as txt `c3' "Size of H-subset" `c4' "= " as res %`wfmt'.0fc e(h)
            di as txt `c3' "MCD (log)"   `c4' "= " as res %`wfmt'.0g ln(e(MCD))
            if `"`e(method)'"'!="classical" {
                if `"`e(method)'"'=="exact-h" {
                    di as txt `c3' "Algorithm" `c4' "= " as res %`wfmt's e(method)
                    di as txt `c3' "Candidates" `c4' "= " as res %`wfmt'.0g e(nsamp)
                }
                else {
                    di ""
                    di as txt "Algorithm = " as res e(method) _c
                    di as txt `c1' "Candidates" `c2' "= " as res %`wfmt0'.0g e(nsamp) _c
                    di as txt `c3' "Candidate C-steps" `c4' "= " as res %`wfmt'.0g e(csteps)
                    di as txt `c1' "Final cand." `c2' "= " as res %`wfmt0'.0g e(nkeep) _c
                    if `"`e(relax)'"'!="" local iter "%`wfmt'.0g e(iterate)"
                    else                  local iter `"%`wfmt's "converge""'
                    di as txt `c3' "Final C-steps" `c4' "= " as res `iter'
                    if (e(ksub)>0 & e(ksub)<.) {
                        di as txt `c1' "Subsamples" `c2' "= " as res %`wfmt0'.0g e(ksub) _c
                        di as txt `c3' "Merged subs. size" `c4' "= " as res %`wfmt'.0g e(nmerged)
                    }
                }
            }
        }
        else if `"`e(subcmd)'"'=="mve" {
            di as txt `c3' "Size of H-subset" `c4' "= " as res %`wfmt'.0fc e(h)
            di as txt `c3' "MVE"   `c4' "= " as res %`wfmt'.0g e(MVE)
            if `"`e(method)'"'!="classical" {
                di as txt `c3' "Algorithm" `c4' "= " as res %`wfmt's e(method)
                di as txt `c3' "Candidates" `c4' "= " as res %`wfmt'.0g e(nsamp)
            }
        }
        else if `"`e(subcmd)'"'=="sd" {
            di as txt `c3' "Algorithm" `c4' "= " as res %`wfmt's e(method)
            if `"`e(method)'"'!="univar" {
                di as txt `c3' "Candidates" `c4' "= " as res %`wfmt'.0g e(nsamp)
            }
            if `"`e(method)'"'=="exact" {
                di as txt `c3' "  - feasible" `c4' "= " as res %`wfmt'.0g e(nsamp)-e(nskip)
                di as txt `c3' "  - discarded" `c4' "= " as res %`wfmt'.0g e(nskip)
            }
            di as txt `c3' "Cutoff" `c4' "= " as res %`wfmt'.0g e(cutoff)
            di as txt `c3' "N of outliers" `c4' "= " as res %`wfmt'.0g e(Nout)
            di as txt `c3' "Weight function" `c4' "= " as res %`wfmt's e(wftype)
        }
        di ""
    }
    if `"`table'"'=="" {
        capt confirm matrix e(b)
        if _rc {
            di as txt "(no estimates of location and covariance found)"
            exit
        }
        eret di, `level' `options'
        if e(rank)<e(nvars) {
            di as txt "(covariance matrix is singular; rank = " ///
                as res e(rank) as txt ")"
        }
        if inlist(`"`e(subcmd)'"', "mcd", "mve") {
            if e(nhyper)>0 {
                di _n as txt "Singularity encountered; " as res e(nhyper) ///
                    as txt " observations lie on a hyperplane defined by"
                di _n as txt "    (x_i - m)' * gamma = 0"
                di _n as txt "with gamma as follows:"
                matlist e(gamma), border(top bottom) 
            }
        }
        else if `"`e(subcmd)'"'=="sd" {
            if `"`e(controls)'"'!="" {
                di as txt `"controls: `e(controls)'"'
            }
        }
    }
end

program Estimate_classic, eclass
    // syntax
    syntax varlist(numeric fv) [if] [in] [pw aw iw fw/], [ ///
        CORRelation Level(cilevel) noHEader noTABle ///
        weights(varname) /// undocumented; used by -robmv sd-
        noRMColl * ]
    local levelopt level(`level')
    _get_diopts diopts, `options'
    c_local diopts `header' `table' `levelopt' `diopts'
    
    // sample and weights
    marksample touse
    if "`weights'"!="" {
        markout `touse' `weights'
    }
    if "`weight'"!="" {
        local exp0 `"= `exp'"'
        capt confirm variable `exp'
        if _rc {
            tempvar exp
            qui gen double `exp' `exp0'
        }
    }
    else local exp0
    if "`weight'"=="fweight" {
        su `exp' if `touse', meanonly
        local N = r(sum)
    }
    else {
        qui count if `touse'
        local N = r(N)
    }
    if `N'==0 error 2000
    
    // varlist
    if "`rmcoll'"!="" {
        fvexpand `varlist' if `touse'
    }
    else {
        _rmcoll `varlist' if `touse' [`weight'`exp0'], expand
    }
    local varlist "`r(varlist)'"
    local varlist0 "`varlist'"
    
    // compute classic estimate
    tempname mu Cov
    if "`correlation'"!="" tempname Corr
    mata: st_classic()  // updates varlist!
    mat coln `mu'  = `varlist'
    mat coln `Cov' = `varlist'
    mat rown `Cov' = `varlist'
    if "`correlation'"!="" {
        mat coln `Corr' = `varlist'
        mat rown `Corr' = `varlist'
    }

    // return results
    tempname b tmp
    local target = cond("`correlation'"!="", "Corr", "Cov")
    local i 0
    foreach v of local varlist {
        local ++i
        mat `tmp' = ``target''[`i', `i'...]
        mat coleq `tmp' = `v'
        mat `b' = nullmat(`b'), `tmp'
    }
    mat `tmp' = `mu'
    mat coleq `tmp' = "@location"
    mat `b' = `b', `tmp'
    eret post `b' [`weight'`exp0'], esample(`touse') obs(`N')
    local title             "Classic estimate"
    eret local title        "`title'"
    eret local cmd          "robmv"
    eret local subcmd       "classic"
    if "`correlation'"!="" eret local depvar "Corr"
    else                   eret local depvar "Cov"
    eret local varlist      "`varlist'"
    eret local varlist0     "`varlist0'" // varlist including base levels
    eret local correlation  "`correlation'"
    eret local predict      "robmv_p"
    eret scalar nvars     = `nvars'
    eret scalar rank      = `rank'
    eret matrix mu        = `mu'
    eret matrix Cov       = `Cov'
    if "`correlation'"!="" {
        eret matrix Corr = `Corr'
    }
    Return_clear
end

program Estimate_m, eclass
    // syntax
    syntax varlist(numeric fv) [if] [in] [pw aw iw fw/], [ ///
        CORRelation                     /// report correlations, not covariances
        k(numlist >=0 max=1)            /// tuning constant
        ptrim(numlist >=0 <100 max=1)   /// "winsorizing" percentage
        c(numlist max=1)                /// consistency correction factor
        cemp                            /// determine c() empirically
        TOLerance(real 1e-12)           /// tolerance
        ITERate(integer `c(maxiter)')   /// max number of iterations
        relax                           /// do not return error if failure to converge
        /// display options
        Level(cilevel) noHEader noTABle *           ///
        ]
    if "`k'"!="" & "`ptrim'"!="" {
        di as err "k() and ptrim() not both allowed"
        exit 198
    }
    local levelopt level(`level')
    _get_diopts diopts, `options'
    c_local diopts `header' `table' `levelopt' `diopts'
    
    // sample and weights
    marksample touse
    if "`weight'"!="" {
        local exp0 `"= `exp'"'
        capt confirm variable `exp'
        if _rc {
            tempvar exp
            qui gen double `exp' `exp0'
        }
    }
    else local exp0
    if "`weight'"=="fweight" {
        su `exp' if `touse', meanonly
        local N = r(sum)
    }
    else {
        qui count if `touse'
        local N = r(N)
    }
    if `N'==0 error 2000
    
    // varlist
    _rmcoll `varlist' if `touse' [`weight'`exp0'], expand
    local varlist "`r(varlist)'"
    local varlist0 "`varlist'"
    
    // compute m-estimate
    tempname mu Cov K PTRIM BP C
    if "`correlation'"!="" tempname Corr
    mata: st_huber()
    mat coln `mu'  = `varlist'
    mat coln `Cov' = `varlist'
    mat rown `Cov' = `varlist'
    if "`correlation'"!="" {
        mat coln `Corr' = `varlist'
        mat rown `Corr' = `varlist'
    }

    // return results
    tempname b tmp
    local target = cond("`correlation'"!="", "Corr", "Cov")
    local i 0
    foreach v of local varlist {
        local ++i
        mat `tmp' = ``target''[`i', `i'...]
        mat coleq `tmp' = `v'
        mat `b' = nullmat(`b'), `tmp'
    }
    mat `tmp' = `mu'
    mat coleq `tmp' = "@location"
    mat `b' = `b', `tmp'
    eret post `b' [`weight'`exp0'], esample(`touse') obs(`N')
    local bppct = strofreal(`BP', "%5.3g")
    local title             "Huber M-estimate (`bppct'% BP)"
    eret local title        "`title'"
    eret local cmd          "robmv"
    eret local subcmd       "m"
    if "`correlation'"!="" eret local depvar "Corr"
    else                   eret local depvar "Cov"
    eret local varlist      "`varlist'"
    eret local varlist0     "`varlist0'"
    eret local correlation  "`correlation'"
    eret local cemp         "`cemp'"
    eret local relax        "`relax'"
    eret local predict      "robmv_p"
    eret scalar nvars     = `nvars'
    eret scalar rank      = `rank'
    eret scalar bp        = `BP'
    eret scalar ptrim     = `PTRIM'
    eret scalar k         = `K'
    eret scalar c         = `C'
    eret scalar tolerance = `tolerance'
    eret scalar iterate   = `iterate'
    eret scalar niter     = `niter'
    eret matrix mu        = `mu'
    eret matrix Cov       = `Cov'
    if "`correlation'"!="" {
        eret matrix Corr = `Corr'
    }
    Return_clear
end

program Estimate_s, eclass
    // syntax
    syntax varlist(numeric fv) [if] [in] [pw aw iw fw/], [ ///
        CORRelation                     /// report correlations, not covariances
        k(numlist >0 max=1)             /// tuning constant
        bp(numlist >=1 <=50 max=1)      /// breakdown point
        WHilferty                       /// use Wilson-Hilferty transformation
        Nsamp(int 500)                  /// number of trial candidates
        CSTEPs(int 2)                   /// number of C-steps for refinement of trial candidates
        NKeep(int 10)                   /// number of "best" candidates to keep for final refinement
        TOLerance(real 1e-12)           /// tolerance
        ITERate(integer `c(maxiter)')   /// max number of iterations
        relax                           /// do not return error if failure to converge
        NOEE                            /// do not use exact enumeration even if comb(N, p+1)<=nsamp()
        /// display options
        Level(cilevel) noHEader noTABle *           ///
        ]
    if "`k'"!="" & "`bp'"!="" {
        di as err "k() and bp() not both allowed"
        exit 198
    }
    local levelopt level(`level')
    _get_diopts diopts, `options'
    c_local diopts `header' `table' `levelopt' `diopts'
    
    // sample and weights
    marksample touse
    if "`weight'"!="" {
        local exp0 `"= `exp'"'
        capt confirm variable `exp'
        if _rc {
            tempvar exp
            qui gen double `exp' `exp0'
        }
    }
    else local exp0
    if "`weight'"=="fweight" {
        su `exp' if `touse', meanonly
        local N = r(sum)
    }
    else {
        qui count if `touse'
        local N = r(N)
    }
    if `N'==0 error 2000
    
    // varlist
    _rmcoll `varlist' if `touse' [`weight'`exp0'], expand
    local varlist "`r(varlist)'"
    local varlist0 "`varlist'"
    
    // compute s-estimate
    tempname mu Cov BP K SCALE
    if "`correlation'"!="" tempname Corr
    mata: st_mvS()
    mat coln `mu'  = `varlist'
    mat coln `Cov' = `varlist'
    mat rown `Cov' = `varlist'
    if "`correlation'"!="" {
        mat coln `Corr' = `varlist'
        mat rown `Corr' = `varlist'
    }

    // return results
    tempname b tmp
    local target = cond("`correlation'"!="", "Corr", "Cov")
    local i 0
    foreach v of local varlist {
        local ++i
        mat `tmp' = ``target''[`i', `i'...]
        mat coleq `tmp' = `v'
        mat `b' = nullmat(`b'), `tmp'
    }
    mat `tmp' = `mu'
    mat coleq `tmp' = "@location"
    mat `b' = `b', `tmp'
    eret post `b' [`weight'`exp0'], esample(`touse') obs(`N')
    local bppct = strofreal(`BP', "%5.3g")
    local title             "S-estimate (`bppct'% BP)"
    eret local title        "`title'"
    eret local cmd          "robmv"
    eret local subcmd       "s"
    if "`correlation'"!="" eret local depvar "Corr"
    else                   eret local depvar "Cov"
    eret local varlist      "`varlist'"
    eret local varlist0     "`varlist0'"
    eret local correlation  "`correlation'"
    eret local cemp         "`cemp'"
    eret local noee         "`noee'"
    eret local relax        "`relax'"
    eret local method       "`method'"
    eret local whilferty    "`whilferty'"
    eret local predict      "robmv_p"
    eret scalar nvars     = `nvars'
    eret scalar rank      = `rank'
    eret scalar bp        = `BP'
    eret scalar k         = `K'
    eret scalar scale     = `SCALE'
    eret scalar nsamp     = `nsamp'
    eret scalar csteps    = `csteps'
    eret scalar nkeep     = `nkeep'
    eret scalar tolerance = `tolerance'
    eret scalar iterate   = `iterate'
    eret matrix mu        = `mu'
    eret matrix Cov       = `Cov'
    if "`correlation'"!="" {
        eret matrix Corr = `Corr'
    }
    Return_clear
end

program Estimate_mcd, eclass
    // syntax
    syntax varlist(numeric fv) [if] [in] [pw aw iw/], [         ///
        CORRelation                     /// report correlations, not covariances
        bp(numlist >=0 <=50 max=1)      /// breakdown point
        noREweight                      /// report MCD estimate (no re-weighting)
        alpha(real 2.5)                 /// cutoff for reweighted estimate
        calpha(numlist max=1)           /// consistency correction factor for MCD
        cdelta(numlist max=1)           /// consistency correction factor for reweighted estimate
        nosmall                         /// omit small sample correction
        Nsamp(int 500)                  /// number of trial candidates
        nsub(numlist max=1 int miss)    /// minimum size of subsamples
        ksub(int 5)                     /// maximum number of subsamples
        CSTEPs(int 2)                   /// number of C-steps for refinement of trial candidates
        NKeep(int 10)                   /// number of "best" candidates to keep for final refinement
        TOLerance(real 1e-12)           /// tolerance for final refinement
        ITERate(integer `c(maxiter)')   /// max number of iterations (C-steps) for final refinement
        relax                           /// do not return error if failure to converge
        NOEE                            /// do not use exact enumeration even if comb(N, h)<=nsamp()
        NOUNIvar                        /// use standard algorithm even if p=1
        /// display options
        Level(cilevel) noHEader noTABle *           ///
        ]
    local levelopt level(`level')
    _get_diopts diopts, `options'
    c_local diopts `header' `table' `levelopt' `diopts'
    if "`bp'"=="" local bp 50
    if `alpha'<0 | `alpha'>50 {
        di as err "alpha() must be in [0, 50]"
        exit 198
    }
    if `nsamp'<0 {
        di as err "nsamp() must be positive"
        exit 198
    }
    local nkeep = min(`nkeep', `nsamp')
    if `ksub'<2 {
        di as err "ksub() must be >= 2"
        exit 198
    }
    if "`nsub'"=="." local ksub 0
    
    // sample and weights
    marksample touse
    if "`weight'"!="" {
        local exp0 `"= `exp'"'
        capt confirm variable `exp'
        if _rc {
            tempvar exp
            qui gen double `exp' `exp0'
        }
    }
    else local exp0
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000
    
    // varlist
    _rmcoll `varlist' if `touse' [`weight'`exp0'], expand
    local varlist "`r(varlist)'"
    local varlist0 "`varlist'"
    
    // compute mcd
    tempname MCD mu0 mu Cov0 Cov h CALPHA SALPHA CDELTA SDELTA gamma
    if "`correlation'"!="" tempname Corr0 Corr
    mata: st_mcd()
    foreach rtype in "0" "" {
        mat coln `mu`rtype''  = `varlist'
        mat coln `Cov`rtype'' = `varlist'
        mat rown `Cov`rtype'' = `varlist'
        if "`correlation'"!="" {
            mat coln `Corr`rtype'' = `varlist'
            mat rown `Corr`rtype'' = `varlist'
        }
    }

    // return results
    tempname b tmp
    local target = cond("`correlation'"!="", "Corr", "Cov")
    local i 0
    foreach v of local varlist {
        local ++i
        mat `tmp' = ``target''[`i', `i'...]
        mat coleq `tmp' = `v'
        mat `b' = nullmat(`b'), `tmp'
    }
    mat `tmp' = `mu'
    mat coleq `tmp' = "@location"
    mat `b' = `b', `tmp'
    eret post `b' [`weight'`exp0'], esample(`touse') obs(`N')
    local title "MCD estimate (`bp'% BP"
    if "`reweight'"=="" {
        local rwpct = strofreal(100-`alpha', "%5.3g")
        local title "`title'; `rwpct'% reweighting)"
    }
    else local title "`title')"
    eret local title        "`title'"
    eret local cmd          "robmv"
    eret local subcmd       "mcd"
    if "`correlation'"!="" eret local depvar "Corr"
    else                   eret local depvar "Cov"
    eret local varlist      "`varlist'"
    eret local varlist0     "`varlist0'"
    eret local correlation  "`correlation'"
    eret local noreweight   "`reweight'"
    eret local nosmall      "`small'"
    eret local noee         "`noee'"
    eret local nounivar     "`nounivar'"
    eret local relax        "`relax'"
    eret local method       "`method'"
    eret local predict      "robmv_p"
    eret scalar nvars     = `nvars'
    eret scalar rank      = `rank'
    eret scalar MCD       = `MCD'
    eret scalar h         = `h'
    eret scalar bp        = `bp'
    eret scalar alpha     = `alpha'
    eret scalar calpha    = `CALPHA'
    eret scalar salpha    = `SALPHA'
    if "`reweight'"==""  {
        eret scalar cdelta = `CDELTA'
        eret scalar sdelta = `SDELTA'
    }
    eret scalar nsamp     = `nsamp'
    eret scalar nsub      = `nsub'
    eret scalar ksub      = `ksub'
    eret scalar nmerged   = `nmerged'
    eret scalar csteps    = `csteps'
    eret scalar nkeep     = `nkeep'
    eret scalar tolerance = `tolerance'
    eret scalar iterate   = `iterate'
    eret scalar nhyper    = `nhyper'
    if `nhyper'>0 {
        mat coln `gamma' = "gamma"
        mat rown `gamma' = `varlist'
        eret matrix gamma = `gamma'
    }
    foreach rtype in "0" "" {
        eret matrix mu`rtype'  = `mu`rtype''
        eret matrix Cov`rtype' = `Cov`rtype''
        if "`correlation'"!="" {
            eret matrix Corr`rtype' = `Corr`rtype''
        }
    }
    Return_clear
end

program Estimate_mve, eclass
    // syntax
    syntax varlist(numeric fv) [if] [in] [pw aw iw/], [         ///
        CORRelation                     /// report correlations, not covariances
        bp(numlist >=0 <=50 max=1)      /// breakdown point
        noREweight                      /// report MCD estimate (no re-weighting)
        alpha(real 2.5)                 /// cutoff for reweighted estimate
        calpha(numlist max=1)           /// consistency correction factor for MCD
        cdelta(numlist max=1)           /// consistency correction factor for reweighted estimate
        Nsamp(int 500)                  /// number of trial candidates
        NOEE                            /// do not use exact enumeration even if comb(N, p+1)<=nsamp()
        /// display options
        Level(cilevel) noHEader noTABle *           ///
        ]
    local levelopt level(`level')
    _get_diopts diopts, `options'
    c_local diopts `header' `table' `levelopt' `diopts'
    if "`bp'"=="" local bp 50
    if `alpha'<0 | `alpha'>50 {
        di as err "alpha() must be in [0, 50]"
        exit 198
    }
    if `nsamp'<0 {
        di as err "nsamp() must be positive"
        exit 198
    }
    
    // sample and weights
    marksample touse
    if "`weight'"!="" {
        local exp0 `"= `exp'"'
        capt confirm variable `exp'
        if _rc {
            tempvar exp
            qui gen double `exp' `exp0'
        }
    }
    else local exp0
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000
    
    // varlist
    _rmcoll `varlist' if `touse' [`weight'`exp0'], expand
    local varlist "`r(varlist)'"
    local varlist0 "`varlist'"
    
    // compute mcd
    tempname MVE mu0 mu Cov0 Cov h gamma CALPHA CDELTA
    if "`correlation'"!="" tempname Corr0 Corr
    mata: st_mve()
    foreach rtype in "0" "" {
        mat coln `mu`rtype''  = `varlist'
        mat coln `Cov`rtype'' = `varlist'
        mat rown `Cov`rtype'' = `varlist'
        if "`correlation'"!="" {
            mat coln `Corr`rtype'' = `varlist'
            mat rown `Corr`rtype'' = `varlist'
        }
    }

    // return results
    tempname b tmp
    local target = cond("`correlation'"!="", "Corr", "Cov")
    local i 0
    foreach v of local varlist {
        local ++i
        mat `tmp' = ``target''[`i', `i'...]
        mat coleq `tmp' = `v'
        mat `b' = nullmat(`b'), `tmp'
    }
    mat `tmp' = `mu'
    mat coleq `tmp' = "@location"
    mat `b' = `b', `tmp'
    eret post `b' [`weight'`exp0'], esample(`touse') obs(`N')
    local title "MVE estimate (`bp'% BP"
    if "`reweight'"=="" {
        local rwpct = strofreal(100-`alpha', "%5.3g")
        local title "`title'; `rwpct'% reweighting)"
    }
    else local title "`title')"
    eret local title        "`title'"
    eret local cmd          "robmv"
    eret local subcmd       "mve"
    if "`correlation'"!="" eret local depvar "Corr"
    else                   eret local depvar "Cov"
    eret local varlist      "`varlist'"
    eret local varlist0     "`varlist0'"
    eret local correlation  "`correlation'"
    eret local noreweight   "`reweight'"
    eret local noee         "`noee'"
    eret local method       "`method'"
    eret local predict      "robmv_p"
    eret scalar nvars     = `nvars'
    eret scalar rank      = `rank'
    eret scalar MVE       = `MVE'
    eret scalar h         = `h'
    eret scalar bp        = `bp'
    eret scalar alpha     = `alpha'
    eret scalar calpha    = `CALPHA'
    if "`reweight'"==""  {
        eret scalar cdelta = `CDELTA'
    }
    eret scalar nsamp     = `nsamp'
    eret scalar nhyper    = `nhyper'
    if `nhyper'>0 {
        mat coln `gamma' = "gamma"
        mat rown `gamma' = `varlist'
        eret matrix gamma = `gamma'
    }
    foreach rtype in "0" "" {
        eret matrix mu`rtype'  = `mu`rtype''
        eret matrix Cov`rtype' = `Cov`rtype''
        if "`correlation'"!="" {
            eret matrix Corr`rtype' = `Corr`rtype''
        }
    }
    Return_clear
end

program Estimate_sd, eclass
    // syntax
    syntax varlist(numeric fv) [if] [in] [pw aw iw fw/], [ ///
        Nsamp(int 500)                    /// number of trial candidates
        NOEE                              /// do not use exact enumeration even if comb(N, p)<=nsamp()
        nmax(numlist >0 int max=1)        /// maximum number of trial candidates before deciding that data is collinear
        EXPAND                            /// expand singular candidate by adding observations
        ASYMmetric ASYMmetric2(numlist max=1 >0 <25) /// use asymmetric distances
        nostd                             /// do not standardize the data for the projections
        alpha(numlist max=1 >=0 <=50)     /// outlier percentage under normality
        CUToff(numlist max=1 >0)          ///
        CONTROLs(str)                     /// variables to be partialled out within the projections
        Huber                             /// Huber type estimate
        CORRelation                       /// report correlations, not covariances
        nofit                             ///
        GENerate(namelist max=3) Replace  ///
        /// display options
        Level(cilevel) noHEader noTABle * ///
        ]
    local levelopt level(`level')
    _get_diopts diopts, `options'
    c_local diopts `header' `table' `levelopt' `diopts'
    if `nsamp'<1 {
        di as err "{bf:nsamp()} must be larger than 0"
        exit 198
    }
    if "`nmax'"=="" local nmax = max(`nsamp', 1000)
    if `nmax'<1 {
        di as err "{bf:nmax()} must be larger than 0"
        exit 198
    }
    if "`asymmetric2'"!="" local asymmetric asymmetric2
    if "`asymmetric'"!="" {
        if "`asymmetric2'"=="" local asymmetric2 10
    }
    if "`generate'"!="" {
        if "`replace'"=="" confirm new variable `generate'
        local rd:       word 1 of `generate'
        local outlier:  word 2 of `generate'
        local hweights: word 3 of `generate'
    }
    if "`alpha'"=="" local alpha 2.5
    Estimate_sd_parse_controls `controls'
    if "`controls'"!="" {
        if "`controls_k'"=="" & "`controls_eff'"=="" {
            local controls_eff = min(max(100 - `alpha',63.7),99.9)
        }
    }

    // sample and weights
    marksample touse
    if "`controls'"!="" {
        markout `touse' `controls'
    }
    if "`weight'"!="" {
        local exp0 `"= `exp'"'
        capt confirm variable `exp'
        if _rc {
            tempvar exp
            qui gen double `exp' `exp0'
        }
    }
    else local exp0
    if "`weight'"=="fweight" {
        su `exp' if `touse', meanonly
        local N = r(sum)
    }
    else {
        qui count if `touse'
        local N = r(N)
    }
    if `N'==0 error 2000
    
    // varlist
    _rmcoll `varlist' if `touse' [`weight'`exp0'], expand
    local varlist "`r(varlist)'"
    if "`controls'"!="" {
        _rmcoll `controls' if `touse' [`weight'`exp0'], expand
        local controls "`r(varlist)'"
    }
    local fitvarlist `varlist'
    if "`controls_incl'"!="" {
        local fitvarlist `fitvarlist' `controls'
    }
    
    // compute Stahel-Donoho distance
    tempvar D
    qui gen double `D' = .
    mata: st_sd_distance() // returns nsamp, nskip, method, nxvars, ncontrols
    if `nskip'>0 {
        if `nskip'==1 local tmp "candidate"
        else          local tmp "candidates"
        if "`method'"=="exact" {
             di as txt "({bf:`nskip'} `tmp' discarded due to collinearity)"
        }
        else {
            di as txt "(additional {bf:`nskip'} `tmp' discarded due to collinearity)"
        }
    }
    
    // identify outliers
    tempname C
    if "`cutoff'"!="" {
        scalar `C' = `cutoff'
    }
    else {
        if "`asymmetric'"=="" {
            scalar `C' = sqrt(invchi2(`nxvars', 1 - `alpha'/100))
        }
        else {
            robbox `D' if `touse', nograph notable ///
                delta(0) bp(`asymmetric2') alpha(`=`alpha'*2') 
            scalar `C' = el(e(whiskers),2,1)
        }
    }
    tempvar O
    qui gen byte `O' = `D' > `C' if `touse' & `D'<.
    _nobs `O' [`weight'`exp0'] if `touse', min(0)
    local Nout = r(N)
    
    // generate weights
    tempvar W
    if "`huber'"=="" {
        qui gen byte `W' = 1 - `O' if `touse'
    }
    else {
        qui gen double `W' = min(1, (`C' / `D')^2) if `touse' & `D'<.
    }
    
    // compute location/scale based on SD results
    if "`fit'"=="" {
        if "`huber'"=="" {
            if (`N'-`Nout')<1 {
                di as txt "(all observations classified as outliers;" /*
                    */ " cannot compute estimate of location and covariance)"
                local fit nofit
            }
        }
    }
    if "`fit'"=="" {
        Estimate_classic `fitvarlist' [`weight'`exp0'] if `touse', ///
            weights(`W') normcoll `correlation'
        local fitvarlist "`e(varlist)'"
        local fitvarlist0 "`e(varlist0)'"
        local rank = e(rank)
        local nvars = e(nvars)
        tempname b mu Cov
        matrix `b'   = e(b)
        matrix `mu'  = e(mu)
        matrix `Cov' = e(Cov)
        if "`correlation'"!="" {
            tempname Corr
            matrix `Corr' = e(Corr)
        }
    }
    
    // post results in e()
    eret post `b' [`weight'`exp0'], esample(`touse') obs(`N')
    local title             "Stahel-Donoho estimate"
    if "`asymmetric'"!=""   local title "Generalized `title'"
    eret local title        "`title'"
    eret local cmd          "robmv"
    eret local subcmd       "sd"
    eret local method       "`method'"
    eret local noee         "`noee'"
    eret local nostd        "`nostd'"
    eret local asymmetric   "`asymmetric'"
    eret local xvars        "`varlist'"
    eret local controls     "`controls'"
    eret local include      "`controls_incl'"
    eret local predict      "robmv_p"
    eret local nofit        "`fit'"
    eret local generate     "`generate'"
    if "`method'"!="univar" {
        eret scalar nsamp     = `nsamp'
        eret scalar nmax      = `nmax'
        eret scalar nskip     = `nskip'
    }
    eret scalar nxvars     = `nxvars'
    if "`controls'"!="" {
        eret scalar ncontrols = `ncontrols'
    }
    eret scalar alpha     = `alpha'
    eret scalar cutoff    = `C'
    eret scalar Nout      = `Nout'
    if "`huber'"!="" eret local wftype "huber"
    else             eret local wftype "rectangle"
    if "`fit'"=="" {
        eret local varlist      "`fitvarlist'"
        eret local varlist0     "`fitvarlist0'"
        eret local correlation  "`correlation'"
        if "`correlation'"!="" eret local depvar "Corr"
        else                   eret local depvar "Cov"
        eret scalar nvars     = `nvars'
        eret scalar rank      = `rank'
        eret matrix mu        = `mu'
        eret matrix Cov       = `Cov'
        if "`correlation'"!="" {
            eret matrix Corr = `Corr'
        }
    }

    // return Stahel-Donoho distance
    if "`rd'"!="" {
        capt confirm new variable `rd'
        if _rc drop `rd'
        rename `D' `rd'
        lab var `rd' "Stahel-Donoho robust distance"
    }
    // return Stahel-Donoho outlier indicator
    if "`outlier'"!="" {
        capt confirm new variable `outlier'
        if _rc drop `outlier'
        rename `O' `outlier'
        lab var `outlier' "Stahel-Donoho outlier"
    }
    // return Stahel-Donoho weights
    if "`hweights'"!="" {
        capt confirm new variable `hweights'
        if _rc drop `hweights'
        rename `W' `hweights'
        lab var `hweights' "Stahel-Donoho weight"
    }

    Return_clear
end

program Estimate_sd_parse_controls
    syntax [varlist(numeric fv default=none)] [,  ///
        INCLude                                   ///
        EFFiciency(numlist >=63.7 <=99.9 max=1)   ///
        K(numlist >0 max=1)                       ///
        TOLerance(numlist >=0 max=1)              ///
        ITERate(numlist integer >=0)              ///
        TOLerance(real 1e-10)                     ///
        ITERate(integer `c(maxiter)')             ///
        ]
    if `"`varlist'"'=="" {
        c_local controls ""
        exit
    }
    if "`efficiency'"!="" & "`k'"!="" {
        di as err "only one of {bf:efficiency()} and {bf:k()} allowed"
        exit 198
    }
    c_local controls      `varlist'
    c_local controls_incl `include'
    c_local controls_eff  `efficiency'
    c_local controls_k    `k'
    c_local controls_tol  `tolerance'
    c_local controls_iter `iterate'
end

program Return_clear, rclass
    local x
end

version 11
mata mata set matastrict on
mata:

/* ------------------------------------------------------------------------- */
/* Helper functions for progress dots                                        */
/* ------------------------------------------------------------------------- */

struct dot_struct {
    real scalar reps, r, d, i, j, pcti, pctj
}

struct dot_struct scalar _dot_init(
    string scalar msg,
    real scalar   reps)
{
    struct dot_struct scalar dot
    
    printf(msg+" 0%%", reps)
    displayflush()
    dot.reps = reps
    dot.r    = 5 // display progress in steps of 1/5 = 20%
    dot.d    = 4 // print (dot.d-1) dots in between
    dot.i    = 1
    dot.pcti = dot.i / (dot.r * dot.d)
    dot.j    = 1
    dot.pctj = dot.j / dot.r
    return(dot)
}

void _dot(struct dot_struct scalar dot, real scalar i)
{
    while (i>=(dot.reps*dot.pcti)) {
        if (mod(dot.i, dot.d)==0) {
            printf("%g%%", dot.pctj*100)
            if (dot.pctj>=1) printf("\n")
            dot.j = dot.j + 1
            dot.pctj = dot.j / dot.r
        }
        else printf(".")
        dot.i = dot.i + 1
        dot.pcti = dot.i / (dot.r * dot.d)
    }
    displayflush()
}

void _dot_flush(struct dot_struct scalar dot, real scalar i, 
    real scalar to)
{
    for (; i<=to; i++) {
        _dot(dot, i)
    }
}

/* ------------------------------------------------------------------------- */
/* Classic Estimate                                                          */
/* ------------------------------------------------------------------------- */

void st_classic()
{
    real scalar      n, p, rank
    real rowvector   m
    real colvector   w
    real matrix      X, V
    pragma unset     X
    
    // data
    robmv_st_view(X, "varlist", "touse") // will update local varlist
    p = cols(X)
    st_local("nvars", strofreal(p))
    if (st_local("weight")!="") {
        w = st_data(., st_local("exp"), st_local("touse"))
        if (st_local("weight")!="fweight") {
            n = rows(X)
            w = w / sum(w) * n // normalize
        }
        else n = sum(w)
    }
    else {
        w = 1
        n = rows(X)
    }
    
    // take account of weights() option (undocumented; used by -robmv sd-)
    if (st_local("weights")!="") {
         w = w :* st_data(., st_local("weights"), st_local("touse"))
         w = w / sum(w) * n // normalize such that sum(w) = n
    }

    // compute raw M estimate and apply consistency correction
    V = meanvariance(X, w)
    m = V[1,.]
    V = editmissing(V[|2,1 \ .,.|],0)
    rank = p - diag0cnt(invsym(V))

    // return results
    st_local("rank", strofreal(rank))
    st_matrix(st_local("mu"),   m)
    st_matrix(st_local("Cov"),  V)
    if (st_local("correlation")!="") st_matrix(st_local("Corr"), robmv_corr(V))
}

/* ------------------------------------------------------------------------- */
/* Monotone M-Estimate                                                       */
/* ------------------------------------------------------------------------- */

struct huber_struct {
    real scalar     n, N, p, rank, wgt, k, ptrim, bp, tol, iter, niter, relax, 
                    corr, c, cemp
    real rowvector  m
    real colvector  w
    real matrix     X, V, C
}

// collect data and options, apply consistence correction and return results to Stata
void st_huber()
{
    real scalar rc
    struct huber_struct scalar S
    
    // data 
    S.X = robmv_st_data("varlist", "touse") // will update local varlist
    S.p = cols(S.X)
    st_local("nvars", strofreal(S.p))
    S.n = rows(S.X)
    if (S.p>=S.n) exit(error(2001)) // insufficient observations
    if (st_local("weight")!="") {
        S.w = st_data(., st_local("exp"), st_local("touse"))
        S.wgt = 1
        if (st_local("weight")=="fweight") S.N = sum(S.w)
        else {
            S.w = S.w / sum(S.w) * S.n // normalize weights so that sum(w)=N
            S.N = S.n
        }
    }
    else {
        S.w = 1
        S.wgt = 0
        S.N = S.n
    }
    
    // settings
    if (st_local("ptrim")!="") {
        S.ptrim = strtoreal(st_local("ptrim"))/100
        if (S.ptrim>=chi2tail(S.p, S.p)) {
            printf("{err}ptrim() must be smaller than (1-chi2(%g, %g))*100 = %g\n", 
                S.p, S.p, chi2tail(S.p, S.p)*100)
            exit(error(498))
        }
        S.k = sqrt(invchi2tail(S.p, S.ptrim))
    }
    else if (st_local("k")!="") {
        S.k = strtoreal(st_local("k"))
        if (S.k^2<=S.p) {
            printf("{err}k() must be larger than sqrt(%g) = %g\n", 
                S.p, sqrt(S.p))
            exit(error(498))
        }
        S.ptrim = 1 - chi2(S.p, S.k^2)
    }
    else {
        S.k = sqrt(S.p + 1)
        S.ptrim = 1 - chi2(S.p, S.k^2)
    }
    S.bp = min((1/S.k^2, 1-S.p/S.k^2))
    S.tol     = strtoreal(st_local("tolerance"))
    S.iter    = strtoreal(st_local("iterate"))
    S.relax   = (st_local("relax")!="")
    S.c       = strtoreal(st_local("c"))
    S.cemp    = (st_local("cemp")!="")
    S.corr    = (st_local("correlation")!="")

    // compute raw M estimate and apply consistency correction
    rc = huber(S)
    if (rc) {
        display("{err}covariance matrix collapsed to zero")
        exit(error(498))
    }
    S.rank = S.p - diag0cnt(invsym(S.V))
    if (S.c>=.) {
        S.c = huber_c(S, S.cemp)
    }
    S.V = S.V * S.c
    if (S.corr) S.C = robmv_corr(S.V)
    
    // return results
    st_local("rank", strofreal(S.rank))
    st_numscalar(st_local("K"), S.k)
    st_numscalar(st_local("PTRIM"), S.ptrim*100)
    st_numscalar(st_local("BP"), S.bp*100)
    st_numscalar(st_local("C"), S.c)
    st_matrix(st_local("mu"),   S.m)
    st_matrix(st_local("Cov"),  S.V)
    if (S.corr) st_matrix(st_local("Corr"), S.C)
    st_local("niter", strofreal(S.niter))
}

// compute monotone M-estimate estimate
real scalar huber(struct huber_struct scalar S)
{
    real scalar    i
    real rowvector m
    real colvector w
    real matrix    V
    
    // initial estimate (median, MADN^2 on diagonal)
    printf("{txt}computing initial estimate ... ")
    displayflush()
    S.m = mm_median(S.X, S.w)
    S.V = (1/invnormal(0.75))^2 * diag(mm_median(abs(S.X:-S.m), S.w):^2)
    printf("{txt}done\n")
    // reweighting algorithm
    printf("{txt}iterating M-estimate ... ")
    displayflush()
    for (i=1; i<=S.iter; i++) {
        m = S.m
        V = S.V
        w = huber_w(S)
        S.m = mean(S.X, S.w :* w)
        S.V = crossdev(S.X, S.m, S.w :* w:^2, S.X, S.m) / (S.N - 1)
        if (mreldif(S.m, m) <= S.tol) {
            if (mreldif(S.V, V) <= S.tol) break
        }
        if (i==S.iter) {
            if (S.relax) break
            display("")
            _error(3360, "failure to converge")
        }
    }
    S.niter = i
    printf("{txt}done (%g iterations)\n", S.niter)
    displayflush()
    return(allof(S.V, 0))
}

// weighting function: W1 = huber_w(), W2 = huber_w()^2
real colvector huber_w(struct huber_struct scalar S)
{
    if (S.ptrim==0) return(J(S.n,1,1)) // classical estimate
    return(mm_huber_w(sqrt(robmv_maha(S.X, S.m, S.V)), S.k)) 
}

// consistency correction
real scalar huber_c(struct huber_struct scalar S, real scalar empirical)
{
    if (S.ptrim==0) return(1) // classical estimate
    if (empirical) return(_huber_c_empirical(S))
    return(1 / mm_finvert(S.p, &_huber_c_int(), 1e-10, 1, 0, 1000, 
        (S.p, S.k)))
}
real scalar _huber_c_empirical(struct huber_struct scalar S)
{
    real colvector d2 
    d2 = robmv_maha(S.X, S.m, S.V)
    return(mm_median(d2, S.w) / invchi2(S.p,.5))
}
real scalar _huber_c_int(real scalar c, real rowvector args)
{
    real scalar p, k
    
    p = args[1]; k = args[2]
    return(mm_integrate_sr(&_huber_c_int_eval(), 0, invchi2tail(p, 1e-6), 
        10000, 0, c, p, k))
}
real colvector _huber_c_int_eval(real colvector z, real scalar c, 
    real scalar p, real scalar k)
{
    real scalar d
    
    d = z/c
    return(((k^2:/d):^(1:-(d:<=k^2))) :* d :* chi2den(p, z))
}

/* ------------------------------------------------------------------------- */
/* Minimum Covariance Determinant                                            */
/* ------------------------------------------------------------------------- */

struct mcd_struct {
    string scalar   method
    real scalar     s, D, R, n, p, wgt, bp, h, nsamp, csteps, nkeep, tol, iter,
                    relax, noee, nouni, rew, alpha, calpha, cdelta, small,
                    corr, nhyper, singfit
    real rowvector  m, DD, RR
    real colvector  w, gamma
    real matrix     X, V, iV, C
    pointer (real rowvector) vector mm
    pointer (real matrix)    vector VV
    // for S estimation
    real scalar     c, b, sc
    real colvector  u
    // additional variables for large-N algorithm
    real scalar                     nsub, ksub, nmerged, n0, h0, nsamp0
    real rowvector                  DD0, RR0
    real colvector                  w0
    real matrix                     X0
    pointer (real rowvector) vector mm0
    pointer (real matrix)    vector VV0
}

// collect data and options, apply correction factors and reweighting, and 
// return results to Stata
void st_mcd()
{
    real scalar    rc, salpha, sdelta
    real colvector wt
    struct mcd_struct scalar S
    
    // data
    S.X = robmv_st_data("varlist", "touse") // will update local varlist
    S.p = cols(S.X)
    st_local("nvars", strofreal(S.p))
    S.n = rows(S.X)
    if (S.p>=S.n) exit(error(2001)) // insufficient observations
    if (st_local("weight")!="") {
        S.w = st_data(., st_local("exp"), st_local("touse"))
        S.w = S.w / sum(S.w) * S.n // normalize weights so that sum(w)=N
        S.wgt = 1
    }
    else {
        S.w = 1
        S.wgt = 0
    }
    
    // settings
    S.nouni    = (st_local("nounivar")!="")
    S.bp       = strtoreal(st_local("bp"))/100
    S.alpha    = strtoreal(st_local("alpha"))/100
    S.h        = floor((S.n - S.p - 1)*(1-S.bp) + S.p + 1)
    st_numscalar(st_local("h"), S.h)
    S.nsamp    = strtoreal(st_local("nsamp"))
    if (st_local("nsub")!="") S.nsub = strtoreal(st_local("nsub"))
    else {
        S.nsub = max((S.p*50, 300))
        st_local("nsub",  strofreal(S.nsub))
    }
    S.nsub     = strtoreal(st_local("nsub"))
    S.ksub     = strtoreal(st_local("ksub"))
    S.csteps   = strtoreal(st_local("csteps"))
    S.nkeep    = strtoreal(st_local("nkeep"))
    S.tol      = strtoreal(st_local("tolerance"))
    S.iter     = strtoreal(st_local("iterate"))
    S.relax    = (st_local("relax")!="")
    S.noee     = (st_local("noee")!="")
    S.calpha   = strtoreal(st_local("calpha"))
    S.cdelta   = strtoreal(st_local("cdelta"))
    S.corr     = (st_local("correlation")!="")
    S.rew      = (st_local("reweight")=="")
    S.small    = (st_local("small")=="")
    S.nhyper   = 0
    S.singfit  = 0

    // compute initial mcd
    rc = mcd(S)
    if (rc) {
        if (S.method=="classical") {
            S.nhyper = S.n
            S.gamma = mcd_hplane(S)
        }
        else {
            if (S.singfit==0) mcd_hplane_V(S)
            S.rew = 0
            st_local("reweight", "noreweight")
        }
    }
    if (S.corr) S.C = robmv_corr(S.V)
    
    // return initial mcd
    st_local("method", S.method)
    st_local("nsamp", strofreal(S.nsamp))
    st_numscalar(st_local("MCD"), S.D)
    st_matrix(st_local("mu0"),   S.m)
    st_matrix(st_local("Cov0"),  S.V)
    if (S.corr) st_matrix(st_local("Corr0"), S.C)
    st_local("ksub", strofreal(S.ksub))
    st_local("nmerged", strofreal(S.nmerged))
    st_local("nhyper", strofreal(S.nhyper))
    if (S.nhyper>0) {
        st_matrix(st_local("gamma"), S.gamma)
    }
    st_local("rank", strofreal(S.R))
    
    // if classical estimate
    if (S.method=="classical") {
        st_local("reweight", "noreweight")
        st_local("CALPHA", "1")
        st_numscalar(st_local("SALPHA"), 1)
        st_matrix(st_local("mu"),   S.m)
        st_matrix(st_local("Cov"),  S.V)
        if (S.corr) st_matrix(st_local("Corr"), S.C)
        return
    }
    
    // apply correction factors, reweight, and return final results
    if (S.calpha>=.) {
        S.calpha = mcd_cfactor(S.h/S.n, S.p)
    }
    if (S.small) salpha = mcd_small_alpha(1-S.bp, S.p, S.n)
    else         salpha = 1
    st_numscalar(st_local("CALPHA"), S.calpha)
    st_numscalar(st_local("SALPHA"), salpha)
    S.V = S.calpha * salpha * S.V
    if (S.rew) {
        wt = robmv_maha(S.X, S.m, S.V) :< invchi2(S.p, 1-S.alpha)
        if (S.cdelta>=.) {
            S.cdelta = mcd_cfactor(sum(wt)/S.n, S.p)
        }
        if (S.small) sdelta = mcd_small_delta(1-S.bp, S.p, S.n)
        else         sdelta = 1
        st_numscalar(st_local("CDELTA"), S.cdelta)
        st_numscalar(st_local("SDELTA"), sdelta)
        S.V = meanvariance(S.X, S.w :* wt)
        S.m = S.V[1,.]
        S.V = S.cdelta * sdelta * S.V[|2,1 \ .,.|]
    }
    if (S.corr) S.C = robmv_corr(S.V)
    st_matrix(st_local("mu"),   S.m)
    st_matrix(st_local("Cov"),  S.V)
    if (S.corr) st_matrix(st_local("Corr"), S.C)
}

// compute initial (raw and uncorrected) MCD estimate
real scalar mcd(struct mcd_struct scalar S)
{
    // full sample estimate if h=n
    if (S.h==S.n) {
        S.ksub = 0
        S.nmerged = S.n
        return(mcd_classical(S))
    }

    // univariate case
    if (S.p==1 & S.nouni==0) {
        S.ksub = 0
        S.nmerged = S.n
        return(mcd_univar(S))
    }
    
    // exact enumeration of h-subsets (number of h-subsets <= nsamp)
    if (comb(S.n, S.h)<=S.nsamp & S.noee==0) {
        S.ksub = 0
        S.nmerged = S.n
        return(mcd_hexact(S))
    } 
    
    // p-subset algorithm
    return(mcd_psub(S))
}

// compute classical estimate
real scalar mcd_classical(struct mcd_struct scalar S)
{
    S.method = "classical"
    S.nsamp  = 0
    S.V = meanvariance(S.X, S.w)
    S.m = S.V[1,.]
    S.V = S.V[|2,1 \ .,.|]
    return(mcd_detinv(S))
}

// compute univariate estimate
real scalar mcd_univar(struct mcd_struct scalar S)
{
    real scalar     i, j, imin, jmin, C, Vmin, W, wi, xi
    real colvector  H
    struct dot_struct scalar dot

    S.method = "univar"
    S.nsamp  = S.n - S.h + 1
    if (S.wgt) {
        H = order((S.X, S.w), (1,2)) // arbitrary decision how to sort w
        _collate(S.w, H)
        _collate(S.X, H)
    }
    else _sort(S.X, 1)
    dot = _dot_init("{txt}enumerating {res}%g{txt} H-subsets", S.nsamp)
    imin = i = 1; jmin = j = S.h
    H = (i \ j)
    S.V = meanvariance(S.X[|H|], (S.wgt ? S.w[|H|] : S.w))
    S.m = S.V[1]
    S.D = S.V = S.V[2]
    if (S.D==0) {
        _dot_flush(dot, i, S.nsamp)
        S.R = 0
        return(1)
    }
    wi = 1
    W = (S.wgt ? sum(S.w[|H|]) : S.h)
    C = S.V * ((W-1)/W) + S.m^2 // expand V to CP/n
    Vmin = S.V
    _dot(dot, i)
    while (j<S.n) {
        // remove first x of last h-subset
        if (S.wgt) wi = S.w[i]
        W  = W - wi
        xi = S.X[i]
        S.m  = S.m - (xi - S.m) * (wi/W)
        C  = C - (xi^2 - C) * (wi/W)
        // append next x to form new h-subset
        i++; j++
        if (S.wgt) wi = S.w[j]
        W  = W + wi
        xi = S.X[j]
        S.m  = S.m + (xi - S.m) * (wi/W)
        C  = C + (xi^2 - C) * (wi/W)
        // compute variance in new h-subset
        S.D = S.V = (C - S.m^2) * (W/(W-1))
        if (S.D==0) {
            _dot_flush(dot, i, S.nsamp)
            S.R = 0
            return(1)
        }
        if (S.V<Vmin) {
            Vmin = S.V; imin = i; jmin = j
        }
        _dot(dot, i)
    }
    // precise mean and variance of best h-subset
    H = (imin \ jmin)
    S.V = meanvariance(S.X[|H|], (S.wgt ? S.w[|H|] : S.w))
    S.m = S.V[1]
    S.D = S.V = S.V[2]
    S.R = (S.D!=0)
    return(S.D==0)
}

// compute MCD estimate based on exact enumeration of all h-subsets
real scalar mcd_hexact(struct mcd_struct scalar S)
{
    real scalar     i, D, R
    real rowvector  m
    real colvector  H
    real matrix     V
    transmorphic    info
    struct dot_struct scalar dot
    pragma unset    D
    
    S.method = "exact-h"
    S.nsamp = comb(S.n, S.h)
    dot = _dot_init("{txt}enumerating {res}%g{txt} candidates", S.nsamp)
    info = mm_subsetsetup(S.n, S.h)
    i = 0
    while ((H=mm_subset(info)) != J(0,1,.)) {
        i++
        mcd_meanvar(S, H)
        if (mcd_detinv(S)) {
            _dot_flush(dot, i, S.nsamp)
            return(1)
        }
        if (S.D < D) {
            D = S.D; R = S.R; m = S.m; V = S.V
        }
        _dot(dot, i)
    }
    S.D = D; S.R = R; S.m = m; S.V = V
    return(0)
}

// compute MCD estimate based on p-subsets
real scalar mcd_psub(struct mcd_struct scalar S)
{
    real scalar rc, i

    // initialize containers for best solutions
    S.DD = S.RR = J(1, S.nkeep, .)
    S.mm = S.VV = J(1, S.nkeep, NULL)
    for (i=1; i<=S.nkeep; i++) {
        S.mm[i] = &.; S.VV[i] = &.
    }
    
    // exact enumeration of p-subsets
    if (comb(S.n, S.p+1)<=S.nsamp & S.noee==0) {
        S.ksub = 0
        S.nmerged = S.n
        rc = mcd_psub_exact(S)
        if (rc) return(1)
        return(mcd_psub_final(S))
    }
    
    // enumerate random p-subsets without subsampling
    if (S.n<(2*S.nsub)) {
        S.ksub = 0
        S.nmerged = S.n
        rc = mcd_psub_rnd1(S)
        if (rc) return(1)
        return(mcd_psub_final(S))
    }
    
    // enumerate random p-subsets with subsampling
    rc = mcd_psub_rnd2(S)
    if (rc) return(1)
    return(mcd_psub_final(S))
}

// exact enumeration of all p-subsets
real scalar mcd_psub_exact(struct mcd_struct scalar S)
{
    real scalar    max, i, j, D0
    real colvector H
    transmorphic   info
    struct dot_struct scalar  dot
    
    S.method = "exact-p"
    S.nsamp = comb(S.n, S.p+1)
    dot = _dot_init("{txt}enumerating {res}%g{txt} candidates", S.nsamp)
    info = mm_subsetsetup(S.n, S.p+1)
    i = 0; max = .
    while ((H=mm_subset(info)) != J(0,1,.)) {
        i++
        mcd_meanvar(S, H)
        if (!mcd_detinv(S)) {
            // apply C-steps to determine h-subset
            for (j=0; j<=S.csteps; j++) {
                D0 = S.D
                H = order(_robmv_maha(S.X, S.m, S.iV), 1)[|1 \ S.h|]
                mcd_meanvar(S, H)
                if (mcd_detinv(S)) { // singularity encountered
                    _dot_flush(dot, i, S.nsamp)
                    return(1)
                }
                if (reldif(S.D, D0) <= S.tol) break
            }
            // keep h-subset if D is small enough
            if (max>=.) max = 1
            if (S.D<S.DD[max]) {
                S.DD[max] = S.D; S.RR[max] = S.R
                *S.mm[max] = S.m; *S.VV[max] = S.V
                // find new maximum
                max = 1
                for (j=1; j<=S.nkeep; j++) {
                    if (S.DD[j] > S.DD[max]) max = j
                }
            }
        }
        _dot(dot, i)
    }
    return(max>=.) // all p-subsets were singular
}

// enumeration of random p-subsets (without subsampling)
real scalar mcd_psub_rnd1(struct mcd_struct scalar S)
{
    real scalar    max, i, j, D0, rc
    real colvector H, P
    struct dot_struct scalar dot
    
    S.method = "random"
    dot = _dot_init("{txt}enumerating {res}%g{txt} candidates", S.nsamp)
    S.ksub = 0
    S.nmerged = S.n
    P = 1::S.n  // permutation vector for fast subsampling
    max = 1
    for (i=1; i<=S.nsamp; i++) {
        // get p-subset variance matrix
        H = robmv_subset(P, S.p+1)
        mcd_meanvar(S, H)
        if (rc=mcd_detinv(S)) {
            if ((S.p+1)<S.h) rc = mcd_subset_expand(S, P)
        }
        if (rc) { // singularity encountered
            _dot_flush(dot, i, S.nsamp)
            return(1)
        }
        // apply C-steps to determine h-subset
        for (j=0; j<=S.csteps; j++) {
            D0 = S.D
            H = order(_robmv_maha(S.X, S.m, S.iV), 1)[|1 \ S.h|]
            mcd_meanvar(S, H)
            if (mcd_detinv(S)) { // singularity encountered
                _dot_flush(dot, i, S.nsamp)
                return(1)
            }
            if (reldif(S.D, D0) <= S.tol) break
        }
        // keep h-subset if D is small enough
        if (S.D<S.DD[max]) {
            S.DD[max] = S.D; S.RR[max] = S.R
            *S.mm[max] = S.m; *S.VV[max] = S.V
            // find new maximum
            max = 1
            for (j=1; j<=S.nkeep; j++) {
                if (S.DD[j] > S.DD[max]) max = j
            }
        }
        _dot(dot, i)
    }
    return(0)
}

// enumeration of random p-subsets (with subsampling)
real scalar mcd_psub_rnd2(struct mcd_struct scalar S)
{
    real scalar    rc, i, j
    real rowvector DD, RR, reps, split
    real colvector P
    pointer (real rowvector) vector mm
    pointer (real matrix)    vector VV
    struct dot_struct scalar        dot
    
    // setup
    if (floor(S.nsub * (S.h / S.n))<(S.p+1)) {
        display("{err}nsub() too small")
        exit(error(2001))
    }
    S.method  = "random"
    S.nmerged = min((S.n, S.ksub*S.nsub))
    S.ksub    = min((trunc(S.n/S.nsub), S.ksub))
    if (S.nsamp < S.nkeep*S.ksub) {
        display("{err}nsamp() too small; must be >= nkeep()*ksub()")
        exit(error(498))
    }
    DD = RR   = J(1, S.ksub*S.nkeep, .)
    mm = VV   = J(1, S.ksub*S.nkeep, NULL)
    reps      = (0, round((1..S.ksub)/S.ksub*S.nsamp))
    split     = (0, round((1..S.ksub)/S.ksub*S.nmerged))

    // permutation vector for subsamples
    P = robmv_subset(1::S.n, S.nmerged)

    // enumerate p-subsets within subsamples
    dot = _dot_init("{txt}enumerating {res}%g{txt} candidates", S.nsamp)
    mcd_psub_rnd2_backup(S)
    S.w = 1
    for (i=1; i<=S.ksub; i++) {
        S.X = S.X0[P[|split[i]+1 \ split[i+1]|],]
        if (S.wgt) S.w = S.w0[P[|split[i]+1 \ split[i+1]|]]
        S.DD = S.RR = J(1, S.nkeep, .)
        S.mm = S.VV = J(1, S.nkeep, NULL)
        for (j=1; j<=S.nkeep; j++) { // assign new addresses
            S.mm[j] = &.; S.VV[j] = &.
        }
        S.n = split[i+1] - split[i]
        S.h = floor(S.n * (S.h0 / S.n0))
        S.nsamp = reps[i+1] - reps[i]
        rc = mcd_psub_rnd2_i(S, dot, reps[i])
        if (rc) {
            mcd_psub_rnd2_restore(S)
            return(1)
        }
        DD[|(i-1)*S.nkeep+1 \ i*S.nkeep|] = S.DD
        RR[|(i-1)*S.nkeep+1 \ i*S.nkeep|] = S.RR
        mm[|(i-1)*S.nkeep+1 \ i*S.nkeep|] = S.mm
        VV[|(i-1)*S.nkeep+1 \ i*S.nkeep|] = S.VV
    }

    // select 10 best candidates
    if (S.nmerged<S.n0) {
        S.X = S.X0[P,]
        if (S.wgt) S.w = S.w0[P]
        S.h = floor(S.nmerged * (S.h0 / S.n0))
        S.n = S.nmerged
    }
    else {
        swap(S.X, S.X0)
        swap(S.w, S.w0)
        S.h = S.h0
        S.n = S.n0
    }
    S.DD = DD; S.RR = RR
    S.mm = mm; S.VV = VV
    rc = mcd_psub_rnd2_best(S)
    mcd_psub_rnd2_restore(S)
    return(rc)
}
void mcd_psub_rnd2_backup(struct mcd_struct scalar S)
{
    swap(S.n0, S.n)
    swap(S.h0, S.h)
    swap(S.nsamp0, S.nsamp)
    swap(S.X0, S.X)
    swap(S.w0, S.w)
    swap(S.DD0, S.DD)
    swap(S.RR0, S.RR)
    swap(S.mm0, S.mm)
    swap(S.VV0, S.VV)
}
void mcd_psub_rnd2_restore(struct mcd_struct scalar S)
{
    if (S.n<S.n0) {
        swap(S.X, S.X0)
        swap(S.w, S.w0)
    }
    swap(S.n, S.n0)
    swap(S.h, S.h0)
    swap(S.nsamp, S.nsamp0)
    swap(S.DD, S.DD0)
    swap(S.RR, S.RR0)
    swap(S.mm, S.mm0)
    swap(S.VV, S.VV0)
}

// enumeration of random p-subsets in subsample i
real scalar mcd_psub_rnd2_i(
    struct mcd_struct scalar S,
    struct dot_struct scalar dot,
    real scalar              offset)
{
    real scalar    max, i, j, D0, nsing, rc
    real colvector H, P

    P = 1::S.n  // permutation vector for subsampling
    max = 1; nsing = 0; rc = 0
    for (i=1+offset; i<=(S.nsamp+offset); i++) {
        if (nsing>=S.nkeep) { // exit if nkeep singular solutions encountered
            _dot_flush(dot, i, S.nsamp+offset)
            return(0)
        }
        // get p-subset variance matrix
        H = robmv_subset(P, S.p+1)
        mcd_meanvar(S, H)
        if (rc = mcd_detinv(S)) {
            if ((S.p+1)<S.h) rc = mcd_subset_expand(S, P)
        }
        if (rc) { // singularity encountered
            rc = mcd_hplane_fullsample(S)
            if (rc==1) { // full sample has singularity >= h
                _dot_flush(dot, i, dot.reps)
                return(1)
            }
            if (rc==2) { // subsample is fully singular
                S.DD[max] = S.D; S.RR[max] = S.R
                *S.mm[max] = S.m; *S.VV[max] = S.V
                _dot_flush(dot, i, S.nsamp+offset)
                return(0)
            }
            nsing++
        }
        else {
            // apply C-steps to determine h-subset
            for (j=0; j<=S.csteps; j++) {
                D0 = S.D
                H = order(_robmv_maha(S.X, S.m, S.iV), 1)[|1 \ S.h|]
                mcd_meanvar(S, H)
                if (mcd_detinv(S)) { // singularity encountered
                    rc = mcd_hplane_fullsample(S)
                    if (rc==1) { // full sample has singularity >= h
                        _dot_flush(dot, i, dot.reps)
                        return(1)
                    }
                    if (rc==2) { // subsample is fully singular
                        S.DD[max] = S.D; S.RR[max] = S.R
                        *S.mm[max] = S.m; *S.VV[max] = S.V
                        _dot_flush(dot, i, S.nsamp+offset)
                        return(0)
                    }
                    nsing++
                    break
                }
                if (reldif(S.D, D0) <= S.tol) break
            }
        }
        // keep h-subset if D is small enough
        if (S.D<S.DD[max]) {
            S.DD[max] = S.D; S.RR[max] = S.R
            *S.mm[max] = S.m; *S.VV[max] = S.V
            // find new maximum
            max = 1
            for (j=1; j<=S.nkeep; j++) {
                if (S.DD[j] > S.DD[max]) max = j
            }
        }
        _dot(dot, i)
    }
    return(0)
}

// select best candidates in merged subsample
real scalar mcd_psub_rnd2_best(struct mcd_struct scalar S)
{
    real scalar    max, i, j, D0, rc, nsing
    real colvector H
    
    printf("{txt}selecting {res}%g{txt} best candidates ", S.nkeep)
    displayflush()
    max = 1; nsing = 0; rc = 0
    for (i=1; i<=(S.nkeep*S.ksub); i++) {
        if (nsing>=S.nkeep) { // exit if nkeep singular solutions encountered
            printf("{txt}. done\n")
            displayflush()
            return(0)
        }
        if (S.RR[i]>=.) { // skip empty slots
            if (mod(i, S.ksub)==0) {
                printf(".")
                displayflush()
            }
            continue
        }
        S.D = S.DD[i]; S.R = S.RR[i]
        S.m = *S.mm[i]; S.V = *S.VV[i]
        // update V because subsample was singular
        if (S.R<S.p) mcd_hplane_V_h(S)
        if (mcd_detinv(S)) {
            rc = mcd_hplane_fullsample(S)
            if (rc==1) { // full sample has singularity >= h
                printf("{txt}. done\n")
                displayflush()
                return(1)
            }
            if (rc==2) { // merged sample is fully singular
                S.DD0[max] = S.D; S.RR0[max] = S.R
                *S.mm0[max] = S.m; *S.VV0[max] = S.V
                printf("{txt}. done\n")
                printf("{err}\nWarning: merged sample is collinear; ")
                printf("should try again with different seed{txt}\n\n")
                displayflush()
                return(0)
            }
            nsing++
        }
        else {
            // apply C-steps to determine h-subset
            for (j=0; j<=S.csteps; j++) {
                D0 = S.D
                H = order(_robmv_maha(S.X, S.m, S.iV), 1)[|1 \ S.h|]
                mcd_meanvar(S, H)
                if (mcd_detinv(S)) { // singularity encountered
                    rc = mcd_hplane_fullsample(S)
                    if (rc==1) { // full sample has singularity >= h
                        printf("{txt}. done\n")
                        displayflush()
                        return(1)
                    }
                    if (rc==2) { // merged sample is fully singular
                        S.DD0[max] = S.D; S.RR0[max] = S.R
                        *S.mm0[max] = S.m; *S.VV0[max] = S.V
                        printf("{txt}. done\n")
                        printf("{err}\nWarning: merged sample is collinear; ")
                        printf("should try again with different seed{txt}\n\n")
                        displayflush()
                        return(0)
                    }
                    nsing++
                    break
                }
                if (reldif(S.D, D0) <= S.tol) break
            }
        }
        // keep h-subset if D is small enough
        if (S.D<S.DD0[max]) {
            S.DD0[max] = S.D; S.RR0[max] = S.R
            *S.mm0[max] = S.m; *S.VV0[max] = S.V
            // find new maximum
            max = 1
            for (j=1; j<=S.nkeep; j++) {
                if (S.DD0[j] > S.DD0[max]) max = j
            }
        }
        if (mod(i, S.ksub)==0) {
            printf(".")
            displayflush()
        }
    }
    printf("{txt} done\n")
    displayflush()
    return(0)
}

// refine best candidates
real scalar mcd_psub_final(struct mcd_struct scalar S)
{
    real scalar    min, i, j, D0, Dmin
    real colvector H
    
    printf("{txt}refining {res}%g{txt} best candidates ", S.nkeep)
    displayflush()
    min = 1; Dmin = .
    for (i=1; i<=S.nkeep; i++) {
        // skip if same address as last candidate
        if (S.RR[i]>=.) { // skip empty slots
            printf(".")
            displayflush()
            continue
        }
        S.D = S.DD[i]; S.R = S.RR[i]
        S.m = *S.mm[i]; S.V = *S.VV[i]
        // update V if fit from merged sample was singular
        if (S.R<S.p) mcd_hplane_V_h(S)
        if (mcd_detinv(S)) {
            printf("{txt}. done\n")
            displayflush()
            return(1)
        }
        // refine results until convergence
        for (j=1; j<=S.iter; j++) {
            D0 = S.D
            H = order(_robmv_maha(S.X, S.m, S.iV), 1)[|1 \ S.h|]
            mcd_meanvar(S, H)
            if (mcd_detinv(S)) { // singularity encountered
                printf("{txt}. done\n")
                displayflush()
                return(1)
            }
            if (reldif(S.D, D0) <= S.tol) break
            if (j==S.iter) {
                if (S.relax) break
                display("")
                _error(3360, "failure to converge")
            }
        }
        // update index identifying best solution
        if (S.D < Dmin) {
            min = i
            Dmin = S.D
            S.DD[i] = S.D; S.RR[i] = S.R
            *S.mm[i] = S.m; *S.VV[i] = S.V
        }
        printf(".")
        displayflush()
    }
    printf("{txt} done\n")
    displayflush()
    // return best solution
    S.D = S.DD[min]; S.R = S.RR[min]
    S.m = *S.mm[min]; S.V = *S.VV[min]
    return(0)
}

// compute compute means and covariances in subset
void mcd_meanvar(struct mcd_struct scalar S, real colvector H)
{
    S.V = meanvariance(S.X[H,], (S.wgt ? S.w[H] : S.w))
    S.m = S.V[1,.]
    S.V = S.V[|2,1 \ .,.|]
}

// compute determinant and inverse of V; return 1 if singular
real scalar mcd_detinv(struct mcd_struct scalar S)
{
    S.iV = invsym(S.V)
    S.R = S.p - diag0cnt(S.iV)
    S.D = det(S.V)
    if (S.R<S.p) return(1)
    return(0)
}
// expand random subset until non-singular (without replacement)
real scalar mcd_subset_expand(struct mcd_struct scalar S, real colvector P)
{
    real scalar    W, wi, p, i, j, k
    real rowvector xi
    real matrix    C

    p = S.p + 1
    k = S.n - p
    W = (S.wgt ? sum(S.w[P[|k+1 \ .|]]) : p)
    C = S.V * ((W-1)/W) + S.m'S.m     // expand V to CP/n
    while (p<S.h) {
        ++p
        // draw next observation and update permutation vector
        j = ceil(uniform(1,1)*k)
        i = P[j]
        xi = S.X[i,]
        wi = (S.wgt ? S.w[i] : 1)
        P[j] = P[k]; P[k] = i
        k--
        // update results
        W  = W + wi
        S.m  = S.m + (xi - S.m)*(wi/W)        // update means
        C  = C + (xi'xi - C)*(wi/W)           // update CP/n
        S.V  = (C - S.m'S.m)*(W/(W-1))        // update V
        if (!mcd_detinv(S)) return(0)
    }
    return(1)
}

// compute coefficients of hyperplane in singular variance matrix
real colvector mcd_hplane(struct mcd_struct scalar S)
{
    real scalar    L
    real colvector X
    pragma unset   L
    pragma unset   X
    
    symeigensystemselecti(S.V, (S.p, S.p), X, L)
    return(X)
}

// compute variance matrix from all observations on hyperplane
void mcd_hplane_V(struct mcd_struct scalar S)
{
    real colvector wt
    
    S.gamma = mcd_hplane(S)
    wt = abs((S.X:-S.m)*S.gamma) :< 1e-8                            // ok?
    S.nhyper = sum(wt)
    S.V = meanvariance(S.X, S.w :* wt)
    S.m = S.V[1,.]
    S.V = S.V[|2,1 \ .,.|]
    S.singfit = 1
}

// compute variance matrix from h obs with smallest distances to hyperplane
void mcd_hplane_V_h(struct mcd_struct scalar S)
{
    real colvector H
    
    S.gamma = mcd_hplane(S)
    H = order(abs((S.X:-S.m)*S.gamma), 1)[|1 \ S.h|]
    mcd_meanvar(S, H)
}

// check hyperplane in full sample and, if necessary, update variance matrix
real scalar mcd_hplane_fullsample(struct mcd_struct scalar S)
{
    real scalar    nhyper
    real colvector gamma, wt
    
    gamma = mcd_hplane(S)
    wt = abs((S.X0:-S.m)*gamma) :< 1e-8                              // ok?
    nhyper = sum(wt)
    if (nhyper>=S.h0) {
        S.nhyper = nhyper
        S.gamma = gamma
        S.V = meanvariance(S.X0, S.w0 :* wt)
        S.m = S.V[1,.]
        S.V = S.V[|2,1 \ .,.|]
        S.singfit = 1
        return(1)
    }
    if (nhyper>=S.n) return(2)
    return(0)
}

// normal consistency correction factor
real scalar mcd_cfactor(real scalar alpha, real scalar p)
{
    if (alpha==1) return(1)
    return(alpha / chi2(p+2, invchi2(p, alpha)))
}

// small-sample correction factor for raw MCD estimate
real scalar mcd_small_alpha(real scalar alpha, real scalar p, real scalar n)
{   // based on MCDcnp2 in covMcd.R from robustbase v0.92-5
    real scalar f
    real matrix f500, f875
    
    if (p==1) {
        f500 = 1 - exp( 0.262024211897096) / n^0.604756680630497
        f875 = 1 - exp(-0.351584646688712) / n^1.01646567502486
    }
    else if (p == 2) {
        f500 = 1 - exp( 0.673292623522027) / n^0.691365864961895
        f875 = 1 - exp( 0.446537815635445) / n^1.06690782995919
    }
    else {
        f500 = (-1.42764571687802,  1.26263336932151, 2) \ 
               (-1.06141115981725,  1.28907991440387, 3)
        f500 = lusolve((J(2,1,1), -ln(f500[,3]*p^2)), ln(-f500[,1] :/ p:^f500[,2]))
        f500 = 1 - exp(f500[1]) / n^f500[2]
        f875 = (-0.455179464070565, 1.11192541278794, 2) \
               (-0.294241208320834, 1.09649329149811, 3)
        f875 = lusolve((J(2,1,1), -ln(f875[,3]*p^2)), ln(-f875[,1] :/ p:^f875[,2]))
        f875 = 1 - exp(f875[1]) / n^f875[2]
    }
    if (alpha<=.875) f = f500 + (f875 - f500)/0.375 * (alpha - 0.5)
    else             f = f875 + (1 - f875)/0.125 * (alpha - 0.875)
    return(1/f)
}

// small-sample correction factor for reweighted estimate
real scalar mcd_small_delta(real scalar alpha, real scalar p, real scalar n)
{   // based on MCDcnp2.rew in covMcd.R from robustbase v0.92-5
    real scalar f
    real matrix f500, f875
    
    if (p==1) {
        f500 = 1 - exp( 1.11098143415027) / n^1.5182890270453
        f875 = 1 - exp(-0.66046776772861) / n^0.88939595831888
    }
    else if (p == 2) {
        f500 = 1 - exp( 3.11101712909049) / n^1.91401056721863
        f875 = 1 - exp( 0.79473550581058) / n^1.10081930350091
    }
    else {
        f500 = (-1.02842572724793,  1.67659883081926, 2) \ 
               (-0.26800273450853,  1.35968562893582, 3)
        f500 = lusolve((J(2,1,1), -ln(f500[,3]*p^2)), ln(-f500[,1] :/ p:^f500[,2]))
        f500 = 1 - exp(f500[1]) / n^f500[2]
        f875 = (-0.544482443573914, 1.25994483222292, 2) \
               (-0.343791072183285, 1.25159004257133, 3)
        f875 = lusolve((J(2,1,1), -ln(f875[,3]*p^2)), ln(-f875[,1] :/ p:^f875[,2]))
        f875 = 1 - exp(f875[1]) / n^f875[2]
    }
    if (alpha<=.875) f = f500 + (f875 - f500)/0.375 * (alpha - 0.5)
    else             f = f875 + (1 - f875)/0.125 * (alpha - 0.875)
    return(1/f)
}

/* ------------------------------------------------------------------------- */
/* Minimum Volume Ellipsoid                                                  */
/* ------------------------------------------------------------------------- */

// collect data and options, apply correction factors and reweighting, and 
// return results to Stata
void st_mve()
{
    real scalar    rc
    real colvector wt
    struct mcd_struct scalar S
    
    // data 
    S.X = robmv_st_data("varlist", "touse") // will update local varlist
    S.p = cols(S.X)
    st_local("nvars", strofreal(S.p))
    S.n = rows(S.X)
    if (S.p>=S.n) exit(error(2001)) // insufficient observations
    if (st_local("weight")!="") {
        S.w = st_data(., st_local("exp"), st_local("touse"))
        S.w = S.w / sum(S.w) * S.n // normalize weights so that sum(w)=N
        S.wgt = 1
    }
    else {
        S.w = 1
        S.wgt = 0
    }
    
    // settings
    S.bp       = strtoreal(st_local("bp"))/100
    S.alpha    = strtoreal(st_local("alpha"))/100
    S.h        = floor((S.n - S.p - 1)*(1-S.bp) + S.p + 1)
    st_numscalar(st_local("h"), S.h)
    S.nsamp    = strtoreal(st_local("nsamp"))
    S.noee     = (st_local("noee")!="")
    S.calpha   = strtoreal(st_local("calpha"))
    S.cdelta   = strtoreal(st_local("cdelta"))
    S.corr     = (st_local("correlation")!="")
    S.rew      = (st_local("reweight")=="")
    S.nhyper   = 0
    S.singfit  = 0

    // compute initial mve
    rc = mve(S)
    if (rc) {
        if (S.method=="classical") {
            S.nhyper = S.n
            S.gamma = mcd_hplane(S)
        }
        else {
            if (S.singfit==0) mcd_hplane_V(S)
            S.rew = 0
            st_local("reweight", "noreweight")
        }
    }
    if (S.corr) S.C = robmv_corr(S.V)
    
    // return initial mve
    st_local("method", S.method)
    st_local("nsamp", strofreal(S.nsamp))
    st_numscalar(st_local("MVE"), S.D)
    st_matrix(st_local("mu0"),   S.m)
    st_matrix(st_local("Cov0"),  S.V)
    if (S.corr) st_matrix(st_local("Corr0"), S.C)
    st_local("nhyper", strofreal(S.nhyper))
    if (S.nhyper>0) {
        st_matrix(st_local("gamma"), S.gamma)
    }
    st_local("rank", strofreal(S.R))
    
    // if classical estimate
    if (S.method=="classical") {
        st_local("reweight", "noreweight")
        st_local("calpha", "1")
        st_matrix(st_local("mu"),   S.m)
        st_matrix(st_local("Cov"),  S.V)
        if (S.corr) st_matrix(st_local("Corr"), S.C)
        return
    }
    
    // apply correction factors, reweight, and return final results
    if (S.calpha>=.) {
        //S.calpha = mcd_cfactor(S.h/S.n, S.p)
        S.calpha = mm_median(robmv_maha(S.X, S.m, S.V), S.w) / invchi2(S.p,.5)
    }
    st_numscalar(st_local("CALPHA"), S.calpha)
    S.V = S.calpha * S.V
    if (S.rew) {
        wt = robmv_maha(S.X, S.m, S.V) :< invchi2(S.p, 1-S.alpha)
        if (S.cdelta>=.) S.cdelta = mcd_cfactor(sum(wt)/S.n, S.p)
        st_numscalar(st_local("CDELTA"), S.cdelta)
        S.V = meanvariance(S.X, S.w :* wt)
        S.m = S.V[1,.]
        S.V = S.cdelta * S.V[|2,1 \ .,.|]
    }
    if (S.corr) S.C = robmv_corr(S.V)
    st_matrix(st_local("mu"),   S.m)
    st_matrix(st_local("Cov"),  S.V)
    if (S.corr) st_matrix(st_local("Corr"), S.C)
}

// compute initial (raw and uncorrected) MVE estimate
real scalar mve(struct mcd_struct scalar S)
{
    // full sample estimate if h=n
    if (S.h==S.n) return(mcd_classical(S))
    
    // exact enumeration of p-subsets
    if (comb(S.n, S.p+1)<=S.nsamp & S.noee==0) return(mve_exact(S))
    
    // random p-subset algorithm
    return(mve_random(S))
}

// exact enumeration of all p-subsets
real scalar mve_exact(struct mcd_struct scalar S)
{
    real scalar    i, s, D, R
    real colvector H
    real rowvector m
    real matrix    V
    transmorphic   info
    struct dot_struct scalar  dot
    pragma unset   s
    
    S.method = "exact"
    S.nsamp = comb(S.n, S.p+1)
    dot = _dot_init("{txt}enumerating {res}%g{txt} candidates", S.nsamp)
    info = mm_subsetsetup(S.n, S.p+1)
    i = 0
    while ((H=mm_subset(info)) != J(0,1,.)) {
        i++
        mcd_meanvar(S, H)
        if (!mcd_detinv(S)) {
            // apply improvement step (Maronna et al. 2006, p. 198)
            H = order(_robmv_maha(S.X, S.m, S.iV), 1)[|1 \ S.h|]
            mcd_meanvar(S, H)
            if (mcd_detinv(S)) { // singularity encountered
                S.s = 0
                _dot_flush(dot, i, S.nsamp)
                return(1)
            }
            // compute scale (order statistic h of normalized distances)
            S.s = order(_robmv_maha(S.X, S.m, S.iV), 1)[S.h]
            S.s = S.s * (S.D)^(1/S.p)
            // keep solution if s is small enough
            if (S.s<s) {
                s = S.s; D = S.D; R = S.R; m = S.m; V = S.V
            }
        }
        _dot(dot, i)
    }
    if (R>=.) { // all p-subsets were singular
        S.s = 0
        return(1)
    }
    S.s = s; S.D = D; S.R = R; S.m = m; S.V = V
    return(0) 
}

// enumeration of random p-subsets (without subsampling)
real scalar mve_random(struct mcd_struct scalar S)
{
    real scalar    i, s, D, R, rc
    real colvector H, P
    real rowvector m
    real matrix    V
    struct dot_struct scalar  dot
    pragma unset   s
    
    S.method = "random"
    dot = _dot_init("{txt}enumerating {res}%g{txt} candidates", S.nsamp)
    P = 1::S.n  // permutation vector for fast subsampling
    for (i=1; i<=S.nsamp; i++) {
        // get p-subset variance matrix
        H = robmv_subset(P, S.p+1)
        mcd_meanvar(S, H)
        if (rc=mcd_detinv(S)) {
            if ((S.p+1)<S.h) rc = mcd_subset_expand(S, P)
        }
        if (rc) { // singularity encountered
            S.s = 0
            _dot_flush(dot, i, S.nsamp)
            return(1)
        }
        // apply improvement step (Maronna et al. 2006, p. 198)
        H = order(_robmv_maha(S.X, S.m, S.iV), 1)[|1 \ S.h|]
        mcd_meanvar(S, H)
        if (mcd_detinv(S)) { // singularity encountered
            S.s = 0
            _dot_flush(dot, i, S.nsamp)
            return(1)
        }
        // compute scale (order statistic h of normalized distances)
        S.s = order(_robmv_maha(S.X, S.m, S.iV), 1)[S.h]
        S.s = S.s * (S.D)^(1/S.p)
        // keep solution if s is small enough
        if (S.s<s) {
            s = S.s; D = S.D; R = S.R; m = S.m; V = S.V
        }
        _dot(dot, i)
    }
    S.s = s; S.D = D; S.R = R; S.m = m; S.V = V
    return(0)
}

/* ------------------------------------------------------------------------- */
/* S estimate                                                                */
/* ------------------------------------------------------------------------- */

// collect data and options, estimate, and return results to Stata
void st_mvS()
{
    real scalar    rc
    struct mcd_struct scalar S
    
    // data 
    S.X = robmv_st_data("varlist", "touse") // will update local varlist
    S.p = cols(S.X)
    st_local("nvars", strofreal(S.p))
    S.n = rows(S.X)
    if (S.p>=S.n) exit(error(2001)) // insufficient observations
    if (st_local("weight")!="") {
        S.w = st_data(., st_local("exp"), st_local("touse"))
        S.w = S.w / sum(S.w) * S.n // normalize weights so that sum(w)=N
        S.wgt = 1
    }
    else {
        S.w = 1
        S.wgt = 0
    }
    
    // settings
    S.nsamp    = strtoreal(st_local("nsamp"))
    S.csteps   = strtoreal(st_local("csteps"))
    S.nkeep    = strtoreal(st_local("nkeep"))
    S.tol      = strtoreal(st_local("tolerance"))
    S.iter     = strtoreal(st_local("iterate"))
    S.relax    = (st_local("relax")!="")
    S.noee     = (st_local("noee")!="")
    S.corr     = (st_local("correlation")!="")
    
    // parameters
    S.c = strtoreal(st_local("k"))
    if (S.c>=.) {
        S.bp = strtoreal(st_local("bp"))
        if (S.bp>=.) S.bp = 50
        if (st_local("whilferty")!="") S.c = mvS_c_from_bp_wh(S.bp, S.p)
        else                           S.c = mvS_c_from_bp(S.bp/100, S.p)
        S.b = mvS_b_from_c(S.c, S.p)
    }
    else {
        S.b = mvS_b_from_c(S.c, S.p)
        if (st_local("whilferty")!="") S.bp = mvS_bp_from_c_wh(S.c, S.p)
        else                           S.bp = S.b / (S.c^2/6) * 100
    }
    
    // compute s-estimate
    rc = mvS_psub(S)
    if (rc) {
        display("{err}... error ...")
        exit(error(498))
    }
    S.R = S.p - diag0cnt(invsym(S.V))
    if (S.corr) S.C = robmv_corr(S.V)

    // return results
    st_local("method", S.method)
    st_local("nsamp", strofreal(S.nsamp))
    st_numscalar(st_local("BP"), S.bp)
    st_numscalar(st_local("K"), S.c)
    st_numscalar(st_local("SCALE"), S.sc)
    st_matrix(st_local("mu"),   S.m)
    st_matrix(st_local("Cov"),  S.V)
    st_local("rank", strofreal(S.R))
    if (S.corr) st_matrix(st_local("Corr"), S.C)
}

// find tuning constant from breakdown point
real scalar mvS_c_from_bp(real scalar bp, real scalar p)
{
    real scalar tol, i, c, c0
    
    i   = 1000
    tol = 1e-12
    c0  = 1.5476 // starting value does not really matter much
    for (;i;i--) {
        c = sqrt(6 * mvS_b_from_c(c0, p) / bp)
        if (reldif(c, c0)<=tol) break
        c0 = c
    }
    return(c)
}

// find tuning constant from bp using Wilson-Hilferty transformation
real mvS_c_from_bp_wh(bp, p)
{
    real scalar k, d
    
    k = mm_biweight_k_bp(bp)
    d = 2 / (9 * p)
    return(sqrt(p * (k * sqrt(d) + (1-d))^3))
}

// find bp from tuning constant using Wilson-Hilferty transformation
real mvS_bp_from_c_wh(c, p)
{
    real scalar k, d
    
    d = 2 / (9 * p)
    k = ((c^2/p)^(1/3) + d - 1) / sqrt(d)
    return(mm_biweight_bp(k)*100)
}

// compute target b from tuning constant (normal model)
real scalar mvS_b_from_c(real scalar c, real scalar p)
{
    return(p/2 * (chi2(p+2, c^2)
            - (p+2)/c^2 * (chi2(p+4, c^2)
                - (p+4)/(3*c^2) * chi2(p+6, c^2)))
        + c^2/6 * (1 - chi2(p, c^2)))
}


// compute S estimate based on p-subsets
real scalar mvS_psub(struct mcd_struct scalar S)
{
    real scalar rc, i

    // initialize containers for best solutions
    S.DD = J(1, S.nkeep, .)
    S.mm = S.VV = J(1, S.nkeep, NULL)
    for (i=1; i<=S.nkeep; i++) {
        S.mm[i] = &.; S.VV[i] = &.
    }
    
    // exact enumeration of p-subsets
    if (comb(S.n, S.p+1)<=S.nsamp & S.noee==0) {
        rc = mvS_psub_exact(S)
        if (rc) return(1)
        return(mvS_psub_final(S))
    }
    
    // enumerate random p-subsets without subsampling
    rc = mvS_psub_rnd(S)
    if (rc) return(1)
    return(mvS_psub_final(S))
}

// exact enumeration of all p-subsets
real scalar mvS_psub_exact(struct mcd_struct scalar S)
{
    real scalar    i, max
    real colvector H
    transmorphic   info
    struct dot_struct scalar dot
    
    S.method = "exact"
    S.nsamp = comb(S.n, S.p+1)
    dot = _dot_init("{txt}enumerating {res}%g{txt} candidates", S.nsamp)
    info = mm_subsetsetup(S.n, S.p+1)
    i = 0; max = .
    while ((H=mm_subset(info)) != J(0,1,.)) {
        i++
        mcd_meanvar(S, H)
        if (!mcd_detinv(S)) {
            mvS_psub_isteps(S)
            mvS_psub_keep(S, max) // updates max
        }
        _dot(dot, i)
    }
    return(max>=.) // all p-subsets were singular
}

// enumeration of random p-subsets (without subsampling)
real scalar mvS_psub_rnd(struct mcd_struct scalar S)
{
    real scalar    max, i, rc
    real colvector H, P
    struct dot_struct scalar dot
    
    S.method = "random"
    dot = _dot_init("{txt}enumerating {res}%g{txt} candidates", S.nsamp)
    P = 1::S.n  // permutation vector for fast subsampling
    max = .
    for (i=1; i<=S.nsamp; i++) {
        // get p-subset variance matrix
        H = robmv_subset(P, S.p+1)
        mcd_meanvar(S, H)
        if (rc=mcd_detinv(S)) {
            if ((S.p+1)<S.h) rc = mcd_subset_expand(S, P)
        }
        if (rc) { // singularity encountered
            _dot_flush(dot, i, S.nsamp)
            return(1)
        }
        mvS_psub_isteps(S)
        mvS_psub_keep(S, max) // updates max
        _dot(dot, i)
    }
    return(0)
}

void mvS_psub_isteps(struct mcd_struct scalar S)
{
    real scalar j
    
    S.V  = S.D^(-1/S.p) * S.V  // compute Gamma
    S.iV = S.D^(1/S.p)  * S.iV // (inverse of Gamma)
    S.u  = sqrt(_robmv_maha(S.X, S.m, S.iV))
    S.sc = mm_median(S.u, S.w)
    for (j=1; j<=S.csteps; j++) {
        _mvS_psub_istep(S)
    }
}

void _mvS_psub_istep(struct mcd_struct scalar S)
{
    real colvector w
    
    S.sc = S.sc * sqrt(mean(mm_biweight_rho(S.u/S.sc, S.c), S.w) / S.b)
    w    = S.u / S.sc
    w    = mm_biweight_psi(w, S.c) :/ w :* S.w
    w    = w * (S.n / quadsum(w))
    S.V  = meanvariance(S.X, w)
    S.m  = S.V[1,.]
    S.V  = S.V[|2,1 \ .,.|]
    S.V  = det(S.V)^(-1/S.p) * S.V  // compute Gamma
    S.u  = sqrt(robmv_maha(S.X, S.m, S.V))
}

void mvS_psub_keep(struct mcd_struct scalar S, real scalar max)
{
    real scalar j, sc0
    
    if (max>=.) max = 1
    else if (S.DD[S.nkeep]<.) { // (skip this for first nkeep candidates)
        if (mean(mm_biweight_rho(S.u/S.DD[max], S.c), S.w)>=S.b) {
            // candidate can be dropped; do not need to optimize scale
            return
        }
    }
    // improve scale until convergence
    for (j=1; j<=S.iter; j++) {
        sc0  = S.sc
        S.sc = S.sc * sqrt(mean(mm_biweight_rho(S.u/S.sc, S.c), S.w) / S.b)
        if (reldif(S.sc, sc0)<=S.tol) break
    }
    if (S.relax==0) {
        if (j>S.iter) {
            display("")
            _error(3360, "failure to converge")
        }
    }
    // check whether candidate is among the nkeep smallest
    if (S.sc>=S.DD[max]) return
     S.DD[max] = S.sc
    *S.mm[max] = S.m
    *S.VV[max] = S.V
    // find new maximum
    max = 1
    for (j=1; j<=S.nkeep; j++) {
        if (S.DD[j] > S.DD[max]) max = j
    }
}

// refine best candidates
real scalar mvS_psub_final(struct mcd_struct scalar S)
{
    real scalar min, i, j, sc0, scmin
    
    printf("{txt}refining {res}%g{txt} best candidates ", S.nkeep)
    displayflush()
    min = 1; scmin = .
    for (i=1; i<=S.nkeep; i++) {
        if (S.DD[i]>=.) { // skip empty slots
            printf(".")
            displayflush()
            continue
        }
        S.sc = S.DD[i]
        S.m  = *S.mm[i]
        S.V  = *S.VV[i]
        S.u  = sqrt(robmv_maha(S.X, S.m, S.V))
        // refine results until convergence
        for (j=1; j<=S.iter; j++) {
            sc0 = S.sc
            _mvS_psub_istep(S)
            if (reldif(S.sc, sc0)<=S.tol) break
        }
        if (S.relax==0) {
            if (j>S.iter) {
                display("")
                _error(3360, "failure to converge")
            }
        }
        // update index identifying best solution
        if (S.sc < scmin) {
            min = i
            scmin = S.sc
            S.DD[i] = S.sc
            *S.mm[i] = S.m
            *S.VV[i] = S.V
        }
        printf(".")
        displayflush()
    }
    printf("{txt} done\n")
    displayflush()
    // return best solution
    S.sc = S.DD[min]
    S.m = *S.mm[min]
    S.V = *S.VV[min] * S.sc^2
    return(0)
}

/* ------------------------------------------------------------------------- */
/* Stahel-Donoho                                                             */
/* ------------------------------------------------------------------------- */

void st_sd_distance()
{
    real scalar      n, p, nsamp, ee, nskip
    real colvector   D, w, P
    real matrix      X
    pointer vector   C    // for controls
    pragma unset     D
    pragma unset     C
    
    // data
    if (st_local("weight")!="") {
        w = st_data(., st_local("exp"), st_local("touse"))
        w = w / sum(w) * rows(w) // normalize weights so that sum(w)=N
    }
    else w = 1
    X = robmv_st_data("varlist", "touse") // updates local varlist
    if (st_local("std")=="") sd_standardize(X, w)
    p = cols(X)
    st_local("nxvars", strofreal(p))
    if (st_local("controls")!="") {
        C = &robmv_st_data("controls", "touse"), // updates local controls
            &(st_local("controls_k")!="" ? strtoreal(st_local("controls_k")) : 
                mm_huber_k(strtoreal(st_local("controls_eff")))),
            &strtoreal(st_local("controls_tol")),
            &strtoreal(st_local("controls_iter"))
        st_local("ncontrols", strofreal(cols(*C[1])))
    }
    
    // setup
    if (p>=rows(X)) exit(error(2001)) // insufficient observations
    P = sd_getidunique(X)             // get IDs of unique observations
    ee = 0
    if (p==1) {
        nsamp = 1
        st_local("method", "univar")
        st_local("nsamp", "0")
    }
    else {
        n = rows(P)
        if (n<p) {
            printf("{err}data must contain at least %g unique observations\n", p)
            exit(error(2001))
        }
        nsamp = strtoreal(st_local("nsamp"))
        if (comb(n, p)<nsamp & st_local("noee")=="") {
            ee = 1
            nsamp = comb(n, p)
            st_local("nsamp", strofreal(nsamp))
            st_local("method", "exact")
        }
        else {
            st_local("method", "random")
        }
    }

    // compute distances
    nskip = 0
    sd_distance(D, X, w, nsamp, P, ee, st_local("asymmetric")!="", C, 
        strtoreal(st_local("nmax")), nskip, st_local("expand")!="")
    st_store(., st_local("D"), st_local("touse"), D)
    st_local("nskip", strofreal(nskip))
}

void sd_distance(real colvector D, real matrix X, real colvector w,
    real scalar nsamp, real colvector P, real scalar ee, real scalar asym, 
    pointer vector C, real scalar nmax, real scalar nskip, real scalar expand)
{
    real scalar    i, j, p, med, N, hasC
    real colvector b, d, s, q
    transmorphic   info
    struct dot_struct scalar dot
    pragma unset   b
    
    hasC = length(C)
    if (rows(w)==1) N = rows(X) * w
    else            N = quadsum(w)
    p = cols(X)
    q = (N + p - 1) / (2 * N) // for df-adjusted quantiles
    if (asym) q = (0.5 * (1 - q) \ 0.5 * (1 + q))
    if (p>1) dot = _dot_init("{txt}enumerating {res}%g{txt} candidates", nsamp)
    D = J(rows(X),1,0)
    if (ee) info = mm_subsetsetup(rows(P), p)
    for (i=1; i<=nsamp; i++) {
        // exact enumeration
        if (ee) { 
            if (sd_subset_fit(b, X[P[mm_subset(info)],])) {
                nskip++
                if (nskip==nsamp) {
                    _dot(dot, nsamp)
                    display("{err:no feasible candidate found; data may be collinear}")
                    exit(error(498))
                }
                _dot(dot, i)
                continue
            }
            d = X * b
        }
        // random p-subset
        else if (p>1) {
            if (expand) {
                if (sd_subset_fit_expand(b, X, P, p)) {
                    _dot(dot, nsamp)
                    display("{err:no feasible candidate found; data may be collinear}")
                    exit(error(498))
                }
            }
            else {
                j = 0
                while (sd_subset_fit(b, X[robmv_subset(P, p),])) {
                    nskip++
                    if (++j==nmax) {
                        _dot(dot, nsamp)
                        display("{err:no feasible candidate found; data may be collinear}")
                        exit(error(498))
                    }
                }
            }
            d = X * b
        }
        // univariate
        else d = X
        // partial out controls
        if (hasC) {
            d = d - robmv_yhat(*C[1], robmv_huber(d, *C[1], w, *C[2], *C[3], *C[4]))
        }
        // normalize distances
        med = mm_median(d, w)
        d = d :- med
        if (!asym) {
            // MADN standardized deviation from median
            d = abs(d)
            s = mm_quantile(d, w, q) / invnormal(0.75)
            if (missing(s) | s==0) {
                printf("{err:solution discarded; scale of deviations is zero or missing}")
                if (p>1) _dot(dot, i)
                continue
            }
            d = d / s
        }
        else {
            // deviation from median normalized by rescaled IQR, where IQR is 
            // computed separately for positive and negative deviations
            s = mm_quantile(d, w, q) / (invnormal(0.75)-invnormal(0.5))
            if (missing(s) | anyof(s,0)) {
                printf("{err:solution discarded; scale of deviations is zero or missing}")
                if (p>1) _dot(dot, i)
                continue
            }
            d = (d:<0) :* (d/s[1]) + (d:>=0) :* (d/s[2])
        }
        D = rowmax((D,d))
        if (p>1) _dot(dot, i)
    }
}

void sd_standardize(real matrix X, real colvector w)
{   // computes X = (X - med) / MADN
    // rescaling will be skipped if MADN=0
    X = X :- mm_median(X, w)
    X = X :/ editvalue(mm_quantile(abs(X), w, .5) / invnormal(0.75), 0, 1)
}

real colvector sd_getidunique(real matrix X)
{
    real scalar    i, ii, n
    real colvector p, o
    real matrix    x, x0
    
    n = rows(X)
    if (n==0) return(J(0,1,.))  // no obs
    if (n==1) return(1)         // only 1 obs
    p = J(n,1,1)
    o = order(X, 1..cols(X))
    x0 = J(0,0,.)
    for (i=n; i; i--) {
        ii = o[i]
        x = X[ii,]
        if (x==x0) p[ii] = 0
        swap(x0, x)
    }
    return(select(1::n, p)) // could use selectindex() in newer Stata versions
}

real scalar sd_subset_fit(real colvector b, real matrix x)
{
    real matrix    xx
    real colvector xy
    
    xx = quadcross(x, x)
    if (diag0cnt(invsym(xx))) return(1)   // collinear subset
    xy = quadcolsum(x)' // equal to quadcross(x, y) with y = J(n,1,1)
    b = lusolve(xx, xy)
    if (min(abs(b)) < 1e-10) {
        // some data constellations lead to coefficients that are essentially 
        // zero; do not use these solutions
        return(1)
    }
    return(0)
}

real scalar sd_subset_fit_expand(real colvector b, real matrix X, real colvector P, 
    real scalar p)
{
    real scalar    n, i, j, k
    real matrix    xi, xx, xy
    pragma unset   xx
    pragma unset   xy

    // fit p-subset
    xi = X[robmv_subset(P, p),]
    if (_sd_subset_fit(b, xi, xx, xy)==0) return(0)
    // p-subset not feasible; add observations one by one until ok
    if (xy==J(0,0,.)) xy = quadcolsum(xi)'
    xx = xx / p; xy = xy / p // rescale: total -> mean
    n = rows(P)
    k = n - p
    while (k) {
        // draw next observation and update permutation vector
        j = ceil(uniform(1,1)*k)
        i = P[j]
        xi = X[i,]
        P[j] = P[k]; P[k] = i
        k--
        // update xx and xy (mean updating)
        xx = xx + (xi'xi - xx)/(n-k)
        xy = xy + (xi'   - xy)/(n-k)
            //mreldif(xx, quadcross(X[P[|k+1\.|],], X[P[|k+1\.|],])/(n-k))
            //mreldif(xy, quadcolsum(X[P[|k+1\.|],])'/(n-k))
        // fit and return if feasible
        if (_sd_subset_fit(b, ., xx, xy)==0) {
                // real colvector b0
                // b0 = b
                // (void) _sd_subset_fit(b, X[P[|k+1\.|],])
                // mreldif(b0, b)
            return(0)
        }
    }
    return(1)
}
real scalar _sd_subset_fit(real colvector b, real matrix x,
    | real matrix xx, real matrix xy)
{
    if (xx==J(0,0,.)) xx = quadcross(x, x)
    if (diag0cnt(invsym(xx))) return(1)   // collinear subset
    if (xy==J(0,0,.)) xy = quadcolsum(x)' // equal to quadcross(x, y) with y = J(n,1,1)
    b = lusolve(xx, xy)
    if (min(abs(b)) < 1e-10) {
        // some data constellations lead to coefficients that are essentially 
        // zero; do not use these solutions
        return(1)
    }
    return(0)
}

/* ------------------------------------------------------------------------- */
/* Common functions                                                          */
/* ------------------------------------------------------------------------- */

// get data excluding omitted, base, and empty variables and update local varlist
// (the trick is to first read the complete data and then remove columns that
// are not needed; this is necessary because Mata will read the data
// differently if base levels are not included in the variable list; to be
// precise, Mata will automatically treat one of the provided levels as the
// base level and will set X to 0 for this variable; this is not what we want)
// Note: In Stata 16 we could -set fvbase off- before importing the data into
//       Mata and and directly read the data using the varlist from which
//       omitted terms have been removed
real matrix robmv_st_data(string scalar varlist, string scalar touse)
{
    string rowvector vlist
    real rowvector   vindx
    
    vlist = tokens(st_local(varlist))
    vindx = indx_non_omitted(vlist)
    st_local(varlist, invtokens(vlist[vindx]))  // !!!
    return(st_data(., vlist, st_local(touse))[,vindx])
}
void robmv_st_view(real matrix X, string scalar varlist, string scalar touse)
{
    string rowvector vlist
    real rowvector   vindx
    real matrix      X0
    pragma unset     X0
    
    vlist = tokens(st_local(varlist))
    vindx = indx_non_omitted(vlist)
    st_local(varlist, invtokens(vlist[vindx]))  // !!!
    st_view(X0, ., vlist, st_local(touse))
    st_subview(X, X0, ., vindx)
}
real rowvector indx_non_omitted(string rowvector varlist)
{   // based on suggestion by Jeff Pitblado
    real scalar   c, k
    string scalar tm

    c = cols(varlist)
    if (c==0) return(J(1, 0, .))
    tm = st_tempname()
    st_matrix(tm, J(1, c, 0))
    st_matrixcolstripe(tm, (J(c, 1, ""), varlist'))
    stata(sprintf("_ms_omit_info %s", tm))
    k = st_numscalar("r(k_omit)")
    if (k==0) return(1..c)
    if (k==c) return(J(1, 0, .))
    return(select(1..c, st_matrix("r(omit)"):==0))
}

// compute (squared) Mahalanobis distance
real colvector robmv_maha(real matrix X, real rowvector m, real matrix V) 
{
    return(_robmv_maha(X, m, invsym(V)))
}
real colvector _robmv_maha(real matrix X, real rowvector m, real matrix inv)
{
    real matrix Xm

    Xm = (X:-m)
    return(rowsum((Xm * inv) :* Xm, 1))
}

// compute correlation matrix from covariance matrix
// convention if SD=0: diagonal element = 1, off-diagonal elements = 0
real matrix robmv_corr(real matrix V)
{
    real scalar    i, j, p
    real colvector sd
    real matrix    C
    
    p = rows(V)
    C = I(p)
    sd = sqrt(diagonal(V))
    for (i=1; i<=p; i++) {
        for (j=1; j<=i; j++) {
            if (sd[i]*sd[j]!=0) {
                C[i,j] = C[j,i] = V[i,j] / (sd[i]*sd[j])
            }
        }
    }
    return(C)
}

// get random subset of size p (without replacement)
real colvector robmv_subset(real colvector P, real scalar p) 
{
    real scalar i, j, k, n, tmp
    
    n = rows(P)
    k = n
    for (i=1; i<=p; i++) {
        j = ceil(uniform(1,1)*k)
        tmp = P[j]; P[j] = P[k]; P[k] = tmp
        k--
    }
    return(P[|n-p+1 \ .|])
}

// Huber M regression
real colvector robmv_huber(real colvector y, real matrix X, real colvector w, 
    real scalar k, real scalar tol, real scalar maxiter)
{
    real scalar    i, N, p, s
    real colvector r
    real colvector b0, b
    
    if (rows(w)==1) N = rows(X) * w
    else            N = quadsum(w)
    p  = cols(X)
    b0 = J(p, 1, 0) \ mm_median(y, w)
    r  = abs(y :- b0[p+1])
    //b0 = robmv_ls(y, X, w)    // => use OLS estimate for initial coefs
    //r  = abs(y - robmv_yhat(X,b0))
    i  = 0
    while (1) {
        i++
        s = mm_quantile(r, w, (N+p)/(2*N)) / invnormal(0.75)
            // (N+p)/(2*N) is used instead of 0.5 to account for df
        b = robmv_ls(y, X, w :* mm_huber_w(r, s*k))
        if (mreldif(b0,b)<=tol) break
        if (i==maxiter) _error(3360, "failure to converge")
        r = abs(y - robmv_yhat(X,b))
        swap(b0, b)
    }
    return(b)
}

// least squares regression
real colvector robmv_ls(real colvector y, real matrix X, real colvector w)
{
    real scalar     ymean, intercept
    real colvector  ybar, p, Xy, beta, b
    real rowvector  means
    real matrix     Xbar, XX, S
    
    if (cols(X)==0) return(mean(y, w))
    means = mean(X, w)
    Xbar = X :- means
    XX = quadcross(Xbar, w, Xbar)
    S = invsym(XX)
    p = select(1::cols(X), diagonal(S):!=0)
    if (length(p)>0) {
        Xbar = Xbar[,p]
        XX = XX[p,p]
        means = means[p]
    }
    ymean = mean(y, w) 
    ybar = y :- ymean
    Xy = quadcross(Xbar, w, ybar)
    beta = lusolve(XX, Xy)
    intercept = ymean - quadcross(means', beta)
    b = J(cols(X), 1, 0)
    b[p] = beta
    return((b \ intercept))
}

real colvector robmv_yhat(real matrix X, real colvector b)
{
    real scalar p
    
    p = cols(X)
    if (p+1==length(b)) return(X * b[|1\p|] :+ b[p+1]) // has cons
    return(X * b)
}

end
exit
