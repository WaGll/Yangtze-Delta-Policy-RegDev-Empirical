/********************************************************************
05_robustness_heterogeneity_mediation.do

Robustness, heterogeneity and mediation mechanisms.
********************************************************************/
do "scripts/stata/02_did_baseline.do"

capture spatwmat using "$spatial/standardized_inverse_distance_weight.dta", name(SW01) standardize
capture spatwmat using "$spatial/standardized_economic_distance_weight.dta", name(SW02_real) standardize

* Spatial robustness checks
capture xsmle lnpergdp did $L1_controls, model(sdm) wmat(SW01) effect fe type(both) vce(r) nolog
capture estadd scalar within_r2 = e(r2_w)
capture est store sdm_wdist_lnpergdp
capture xsmle lnpergdp did $L1_controls, model(sdm) wmat(SW02_real) effect fe type(both) vce(r) nolog
capture estadd scalar within_r2 = e(r2_w)
capture est store sdm_wecon_lnpergdp
capture xsmle lnactualgdp did $L1_controls, model(sdm) wmat(SW01) effect fe type(both) vce(r) nolog
capture estadd scalar within_r2 = e(r2_w)
capture est store sdm_wdist_lnactualgdp
capture xsmle lnactualgdp did $L1_controls, model(sdm) wmat(SW02_real) effect fe type(both) vce(r) nolog
capture estadd scalar within_r2 = e(r2_w)
capture est store sdm_wecon_lnactualgdp
capture xsmle lnpergdp did $L1_controls, model(sar) wmat(SW01) effect fe type(both) vce(r) nolog
capture estadd scalar within_r2 = e(r2_w)
capture est store sar_wdist_lnpergdp
capture xsmle lnpergdp did $L1_controls, model(sar) wmat(SW02_real) effect fe type(both) vce(r) nolog
capture estadd scalar within_r2 = e(r2_w)
capture est store sar_wecon_lnpergdp

capture esttab sdm_wdist_lnpergdp sdm_wecon_lnpergdp sdm_wdist_lnactualgdp sdm_wecon_lnactualgdp ///
    sar_wdist_lnpergdp sar_wecon_lnpergdp using "$result/spatial_robustness.rtf", replace ///
    b(%9.3f) z(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    stats(N within_r2, labels("N" "within-R2") fmt(%9.0f %9.4f))

* GML and cumulative GTFP outcomes
foreach yvar in gml gtfp_cum {
    capture reghdfe `yvar' did $L1_controls, absorb(id year) vce(cluster id)
    capture estadd local FE "City Year"
    capture est store did_`yvar'
    capture xsmle `yvar' did $L1_controls, model(sdm) wmat(SW01) effect fe type(both) vce(r) nolog
    capture estadd scalar within_r2 = e(r2_w)
    capture est store sdm_wdist_`yvar'
    capture xsmle `yvar' did $L1_controls, model(sdm) wmat(SW02_real) effect fe type(both) vce(r) nolog
    capture estadd scalar within_r2 = e(r2_w)
    capture est store sdm_wecon_`yvar'
    capture xsmle `yvar' did $L1_controls, model(sar) wmat(SW01) effect fe type(both) vce(r) nolog
    capture estadd scalar within_r2 = e(r2_w)
    capture est store sar_wdist_`yvar'
}

capture esttab did_gml did_gtfp_cum using "$result/gtfp_traditional_did_robustness.rtf", replace ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    stats(N r2_a F, labels("Obs" "Adj. R2" "F-stat"))

* Regional heterogeneity
cap drop sh js zj ah did_js did_zj did_ah
capture gen sh = (province == "上海市")
capture gen js = (province == "江苏省")
capture gen zj = (province == "浙江省")
capture gen ah = (province == "安徽省")
capture gen did_js = did * js
capture gen did_zj = did * zj
capture gen did_ah = did * ah
capture xsmle lnpergdp did did_js did_zj did_ah $L1_controls, model(sdm) wmat(SW02_real) effect fe type(both) iterate(200) nolog
capture estadd scalar within_r2 = e(r2_w)
capture est store region_sdm
capture reghdfe lnpergdp did did_js did_zj did_ah $L1_controls, absorb(id year) vce(cluster id)
capture est store region_did
capture esttab region_sdm region_did using "$result/regional_heterogeneity.rtf", replace ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) stats(N, labels("N"))

* Time heterogeneity
capture gen t1 = (year <= 2013)
capture gen t2 = (year >= 2014 & year <= 2018)
capture gen t3 = (year >= 2019 & year <= 2024)
capture gen did_t1 = did * t1
capture gen did_t2 = did * t2
capture gen did_t3 = did * t3
capture xsmle lnpergdp did_t2 did_t3 $L1_controls, model(sdm) wmat(SW02_real) effect fe type(both) vce(r) nolog
capture estadd scalar within_r2 = e(r2_w)
capture est store time_sdm
capture reghdfe lnpergdp did_t2 did_t3 $L1_controls, absorb(id year) vce(cluster id)
capture est store time_did
capture esttab time_sdm time_did using "$result/time_heterogeneity.rtf", replace ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) stats(N, labels("N"))

* Economic-level heterogeneity
capture gen pgdp_2013 = lnpergdp if year == 2013
capture bysort id: egen base_pgdp = max(pgdp_2013)
capture summarize base_pgdp, detail
capture scalar med_pgdp = r(p50)
capture gen eco_group = .
capture replace eco_group = 1 if base_pgdp >= med_pgdp & !missing(base_pgdp)
capture replace eco_group = 0 if base_pgdp < med_pgdp
capture label define eco_lbl 1 "High-Income" 0 "Low-Income", replace
capture label values eco_group eco_lbl
capture gen did_high = did * (eco_group == 1)
capture gen did_low = did * (eco_group == 0)
capture xsmle lnpergdp did_low did_high $L1_controls, model(sdm) wmat(SW02_real) fe effect type(both) vce(r) nolog
capture estadd scalar within_r2 = e(r2_w)
capture est store eco_sdm
capture reghdfe lnpergdp did_low did_high $L1_controls, absorb(id year) vce(cluster id)
capture est store eco_did
capture esttab eco_sdm eco_did using "$result/economic_level_heterogeneity.rtf", replace ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) stats(N, labels("N"))

* Mediation mechanism
local inter_vars lncompany lnpatent lnpop lnpopdens
local i = 1
foreach var of local inter_vars {
    capture xsmle `var' did $L1_controls, model(sdm) wmat(SW02_real) effect fe type(both) vce(r) nolog
    capture estadd scalar within_r2 = e(r2_w)
    capture estimates store inter_sdm`i'
    local i = `i' + 1
}
capture esttab inter_sdm1 inter_sdm2 inter_sdm3 inter_sdm4 using "$result/mediation_spatial_did.rtf", replace ///
    b(%9.3f) z(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    stats(N within_r2, labels("N" "within-R2") fmt(%9.0f %9.4f)) ///
    mtitle("lnCompany" "lnPatent" "lnPop" "lnPopdens")

local j = 1
foreach var of local inter_vars {
    capture reghdfe `var' did $L1_controls, absorb(id year) vce(cluster id)
    capture estimates store inter_did`j'
    local j = `j' + 1
}
capture esttab inter_did1 inter_did2 inter_did3 inter_did4 using "$result/mediation_traditional_did.rtf", replace ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    stats(N r2_a F, labels("Obs" "Adj. R2" "F-stat")) ///
    mtitle("lnCompany" "lnPatent" "lnPop" "lnPopdens")
