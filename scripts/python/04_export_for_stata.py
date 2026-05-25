# -*- coding: utf-8 -*-
"""
Step 04: Export processed data for Stata.

输入：data/processed/sbm_gml_result.xlsx
输出：
- data/processed/final_panel_for_stata.xlsx
- data/processed/final_panel_for_stata.dta（若安装 pyreadstat）
"""
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
IN_PATH = ROOT / "data" / "processed" / "sbm_gml_result.xlsx"
OUT_XLSX = ROOT / "data" / "processed" / "final_panel_for_stata.xlsx"
OUT_DTA = ROOT / "data" / "processed" / "final_panel_for_stata.dta"

RENAME_MAP = {
    "年份": "year",
    "城市": "city",
    "lnPerGDP": "lnpergdp",
    "lnActualGDP": "lnactualgdp",
    "Patent": "patent",
    "Company": "company",
    "IS": "is",
    "Tech_Rate": "tech_rate",
    "Energy_Inten": "energy_inten",
    "K_Intensity": "k_intensity",
    "PopDens": "popdens",
    "Gov_Rate": "gov_rate",
    "Fin_Level": "fin_level",
    "FDI_Rate": "fdi_rate",
    "GML": "gml",
    "GTFP_cum": "gtfp_cum",
    "EC": "ec",
    "TC": "tc",
}


def main() -> None:
    if not IN_PATH.exists():
        raise FileNotFoundError(f"SBM-GML result not found: {IN_PATH}")
    df = pd.read_excel(IN_PATH)
    df = df.rename(columns={k: v for k, v in RENAME_MAP.items() if k in df.columns})
    if "id" not in df.columns and "city" in df.columns:
        df["id"] = pd.factorize(df["city"])[0] + 1
    OUT_XLSX.parent.mkdir(parents=True, exist_ok=True)
    df.to_excel(OUT_XLSX, index=False)
    try:
        import pyreadstat
        pyreadstat.write_dta(df, OUT_DTA)
        print(f"Saved Stata DTA to: {OUT_DTA}")
    except Exception as exc:
        print(f"DTA export skipped: {exc}")
    print(f"Saved Stata-ready Excel to: {OUT_XLSX}")


if __name__ == "__main__":
    main()
