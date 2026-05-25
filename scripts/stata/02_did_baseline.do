/********************************************************************
02_did_baseline.do

Multi-period DID, descriptive statistics, parallel trend test and placebo test.
********************************************************************/
do "scripts/stata/01_setup.do"

* Multi-period DID variables
cap drop did treat rel_year
gen did = 0
replace did = 1 if year >= gvar & !missing(gvar)
label var did "Multi-period DID treatment"

gen treat = 0
replace treat = 1 if gvar > 0 & !missing(gvar)
label var treat "Treatment group"

gen rel_year = year - gvar if gvar != 0
replace rel_year = -999 if gvar == 0

* Lagged controls
global L1_controls ""
local controls is tech_rate energy_inten k_intensity popdens gov_rate fin_level fdi_rate
foreach v of local controls {
    cap drop L1_`v'
    gen L1_`v' = L1.`v'
    global L1_controls $L1_controls L1_`v'
}

keep if year > 2010

cap gen lnpop = lnactualgdp - lnpergdp
foreach v in company patent popdens {
    cap gen ln`v' = ln(`v' + 1)
    cap gen L_`v' = L.`v'
    cap gen L_ln`v' = L.ln`v'
}

cap which winsor2
if _rc == 0 {
    winsor2 lnpergdp lnactualgdp gml gtfp_cum $L1_controls, cuts(1 99) replace
}

* Descriptive statistics
estpost tabstat lnpergdp lnactualgdp did patent company gml gtfp_cum ///
    is tech_rate energy_inten k_intensity popdens gov_rate fin_level fdi_rate, ///
    statistics(n mean sd p50 min max) columns(statistics)
esttab . using "$result/descriptive_statistics.rtf", replace ///
    cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) p50(fmt(3)) min(fmt(3)) max(fmt(3))") ///
    nonumber nomtitle noobs label

* Baseline DID regressions
xtreg lnpergdp did i.year, fe r
est store m1
xtreg lnpergdp did L1_is L1_tech_rate L1_energy_inten i.year, fe r
est store m2
xtreg lnpergdp did L1_is L1_tech_rate L1_energy_inten L1_k_intensity L1_popdens i.year, fe r
est store m3
xtreg lnpergdp did L1_is L1_tech_rate L1_energy_inten L1_k_intensity L1_popdens L1_gov_rate L1_fin_level i.year, fe r
est store m4
xtreg lnpergdp did $L1_controls i.year, fe r
est store m5

esttab m1 m2 m3 m4 m5 using "$result/baseline_did_results.rtf", replace ///
    star(* 0.1 ** 0.05 *** 0.01) b(%9.4f) se(%9.3f) ///
    stats(N r2_a F p, labels("N" "Adj R2" "F" "Prob>F")) compress nogap

* Parallel trend test
foreach i of numlist -5/5 {
    if `i' < 0 {
        local name "pre_`=-`i''"
    }
    else {
        local name "post_`i'"
    }
    cap drop `name'
    gen `name' = (rel_year == `i')
}

reghdfe lnpergdp pre_5 pre_4 pre_3 pre_2 post_0 post_1 post_2 post_3 post_4 post_5 ///
    $L1_controls, absorb(id year) vce(cluster id)
coefplot, keep(pre_5 pre_4 pre_3 pre_2 post_0 post_1 post_2 post_3 post_4 post_5) ///
    vertical yline(0, lp(dash) lc(gs10)) xline(4.5, lp(solid) lc(gs13)) ///
    recast(connect) lcolor(black) lwidth(medium) mcolor(black) msymbol(circle) ///
    ciopts(recast(rcap) lcolor(gs8) lwidth(thin)) graphregion(color(white)) ///
    plotregion(color(white)) title("") ytitle("Estimated Coefficients", size(small)) ///
    xtitle("Years Relative to Policy", size(small)) ///
    rename(pre_5="-5" pre_4="-4" pre_3="-3" pre_2="-2" post_0="0" ///
    post_1="1" post_2="2" post_3="3" post_4="4" post_5="5") ///
    grid(none) xlabel(, labsize(small)) ylabel(, labsize(small))
graph export "$image/parallel_trend.png", as(png) width(4000) replace

save "$processed/final_panel_for_spatial.dta", replace
