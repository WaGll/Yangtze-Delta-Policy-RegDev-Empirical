/********************************************************************
03_spatial_weights.do

Spatial weight matrices and Moran's I.
********************************************************************/
do "scripts/stata/02_did_baseline.do"

* The shapefile folder should contain complete files: .shp .dbf .shx .prj .cpg
* Default location: data/raw/city_shapefile/

preserve
    cd "$raw/city_shapefile"
    cap shp2dta using "市.shp", data(data_db) coor(data_xy) genid(shape_id) gence(stub) replace
    use data_db, clear
    cap bys id: egen mean_pergdp = mean(人均gdp_元)
    cap keep if 年份 == 2020
    cap spwmatrix gecon y_stub x_stub, wname(W01) wtype(inv) alpha(1) rowstand xport(W01, txt) replace
    clear
    cap svmat W01
    cap save "$spatial/standardized_inverse_distance_weight.dta", replace
restore

preserve
    cd "$raw/city_shapefile"
    cap use data_db, clear
    cap bys id: egen mean_pergdp = mean(人均gdp_元)
    cap keep if 年份 == 2020
    cap spwmatrix gecon y_stub x_stub, wname(W02) wtype(inv) alpha(2) rowstand xport(W02, txt) replace
    clear
    cap svmat W02
    cap save "$spatial/standardized_inverse_distance_square_weight.dta", replace
restore

* Economic distance matrix template
preserve
    cd "$raw/city_shapefile"
    cap use data_db, clear
    cap bys id: egen mean_pergdp = mean(人均gdp_元)
    cap keep if 年份 == 2020
    cap keep id mean_pergdp
    cap sort id
    capture mata: st_view(mean_pergdp=., ., "mean_pergdp")
    capture mata: n = rows(mean_pergdp)
    capture mata: W = J(n, n, 0)
    capture mata: for (i = 1; i <= n; i++) {
    capture mata:     for (j = 1; j <= n; j++) {
    capture mata:         if (i != j) W[i, j] = 1 / abs(mean_pergdp[i] - mean_pergdp[j])
    capture mata:     }
    capture mata: }
    capture mata: rowsum = W * J(n, 1, 1)
    capture mata: for (i = 1; i <= n; i++) {
    capture mata:     if (rowsum[i] > 0) W[i, .] = W[i, .] / rowsum[i]
    capture mata: }
    capture mata: st_matrix("W03", W)
    clear
    cap svmat W03
    cap save "$spatial/standardized_economic_distance_weight.dta", replace
restore

* Moran's I trend template
preserve
    capture use "$spatial/standardized_inverse_distance_weight.dta", clear
    capture cap drop id
    capture mkmat _all, matrix(W_dist)
restore

preserve
    capture use "$spatial/standardized_economic_distance_weight.dta", clear
    capture cap drop id
    capture mkmat _all, matrix(W_econ)
restore

use "$processed/final_panel_for_spatial.dta", clear
capture tempfile moran_data
capture tempname memhold
capture postfile `memhold' int year double mi_dist double mi_econ using `moran_data', replace
capture levelsof year, local(years)
foreach y of local years {
    preserve
        keep if year == `y'
        sort id
        quietly egen z = std(lnpergdp)
        mkmat z, matrix(Z_vec)
        capture matrix I_d = Z_vec' * W_dist * Z_vec
        capture scalar m_d = I_d[1, 1] / (_N - 1)
        capture matrix I_e = Z_vec' * W_econ * Z_vec
        capture scalar m_e = I_e[1, 1] / (_N - 1)
        capture post `memhold' (`y') (m_d) (m_e)
    restore
}
capture postclose `memhold'

capture preserve
capture use `moran_data', clear
capture sort year
capture twoway (connected mi_dist year, lcolor(blue) mcolor(blue) msymbol(O) yaxis(1)) ///
    (connected mi_econ year, lcolor(cranberry) mcolor(cranberry) lpattern(dash) msymbol(T) yaxis(2)), ///
    title("Global Moran's I Trend", size(3.2)) xtitle("Year") ///
    ytitle("Moran's I: Inverse Distance", axis(1) size(small)) ///
    ytitle("Moran's I: Economic Distance", axis(2) size(small)) ///
    graphregion(color(white)) plotregion(lcolor(black))
capture graph export "$image/global_moran_trend.png", as(png) width(4000) replace
capture restore
