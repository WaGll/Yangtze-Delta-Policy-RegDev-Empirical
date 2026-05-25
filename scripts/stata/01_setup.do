/********************************************************************
01_setup.do

Define paths, create output folders, and load the processed panel data.
********************************************************************/
clear all
set more off
set maxvar 10000

* If running from repository root, keep this as ".".
global root "."
global data "$root/data"
global processed "$data/processed"
global raw "$data/raw"
global interim "$data/interim"
global result "$root/results/tables"
global image "$root/figures"
global spatial "$data/processed/spatial"

cap mkdir "$result"
cap mkdir "$image"
cap mkdir "$spatial"

capture confirm file "$processed/final_panel_for_stata.dta"
if _rc == 0 {
    use "$processed/final_panel_for_stata.dta", clear
}
else {
    import excel "$processed/final_panel_for_stata.xlsx", firstrow clear
}

rename *, lower
capture destring year, replace force
capture encode city, gen(city_id)
capture confirm variable id
if _rc != 0 {
    gen id = city_id
}
xtset id year

save "$processed/final_panel_for_stata_loaded.dta", replace
