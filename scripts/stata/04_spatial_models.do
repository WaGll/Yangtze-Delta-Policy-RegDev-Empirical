/********************************************************************
04_spatial_models.do

Spatial model selection and baseline Spatial Durbin DID model.
********************************************************************/
do "scripts/stata/02_did_baseline.do"

capture spatwmat using "$spatial/standardized_inverse_distance_weight.dta", name(SW01) standardize
capture spatwmat using "$spatial/standardized_economic_distance_weight.dta", name(SW02_real) standardize

* LM tests
reg lnpergdp did $L1_controls
capture spatdiag, weights(SW01)
capture spatdiag, weights(SW02_real)

* Hausman tests
capture xsmle lnpergdp did $L1_controls, hausman model(sdm) wmat(SW01) type(both)
capture xsmle lnpergdp did $L1_controls, hausman model(sar) wmat(SW01) type(both)
capture xsmle lnpergdp did $L1_controls, hausman model(sdm) wmat(SW02_real) type(both)
capture xsmle lnpergdp did $L1_controls, hausman model(sar) wmat(SW02_real) type(both)

* LR tests for fixed effects
capture xsmle lnpergdp did $L1_controls, fe model(sdm) wmat(SW01) type(ind)
capture est store ind
capture xsmle lnpergdp did $L1_controls, fe model(sdm) wmat(SW01) type(time)
capture est store time
capture xsmle lnpergdp did $L1_controls, fe model(sdm) wmat(SW01) type(both)
capture est store both
capture lrtest both ind, df(10)
capture lrtest both time, df(10)

* Wald tests: SDM vs SAR/SEM
capture xsmle lnpergdp did $L1_controls, model(sdm) wmat(SW01) fe type(both)
capture test [Wx]did = [Wx]L1_is = [Wx]L1_fdi_rate = [Wx]L1_tech_rate = [Wx]L1_k_intensity = ///
    [Wx]L1_popdens = [Wx]L1_gov_rate = [Wx]L1_fin_level = [Wx]L1_energy_inten = 0
capture testnl ([Wx]did = -[Spatial]rho * [Main]did) ///
    ([Wx]L1_is = -[Spatial]rho * [Main]L1_is) ///
    ([Wx]L1_fdi_rate = -[Spatial]rho * [Main]L1_fdi_rate) ///
    ([Wx]L1_tech_rate = -[Spatial]rho * [Main]L1_tech_rate) ///
    ([Wx]L1_k_intensity = -[Spatial]rho * [Main]L1_k_intensity) ///
    ([Wx]L1_popdens = -[Spatial]rho * [Main]L1_popdens) ///
    ([Wx]L1_gov_rate = -[Spatial]rho * [Main]L1_gov_rate) ///
    ([Wx]L1_fin_level = -[Spatial]rho * [Main]L1_fin_level) ///
    ([Wx]L1_energy_inten = -[Spatial]rho * [Main]L1_energy_inten)

* Baseline SDM-DID
capture xsmle lnpergdp did $L1_controls, model(sdm) wmat(SW01) effect fe type(both) vce(r) nolog
capture estadd scalar within_r2 = e(r2_w)
capture est store sdm_base
capture estat impact
