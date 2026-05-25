# -*- coding: utf-8 -*-
"""
Step 01: Raw data to interim data.

输入：data/raw/reg.xlsx
输出：data/interim/panel_interpolated.xlsx

功能：
1. 读取原始城市面板数据；
2. 按城市和年份排序；
3. 对数值型变量进行城市组内线性插补。
"""
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
RAW_PATH = ROOT / "data" / "raw" / "reg.xlsx"
OUT_PATH = ROOT / "data" / "interim" / "panel_interpolated.xlsx"
CITY_COL = "城市"
YEAR_COL = "年份"


def interpolate_by_city(df: pd.DataFrame) -> pd.DataFrame:
    df = df.sort_values([CITY_COL, YEAR_COL]).reset_index(drop=True)
    numeric_cols = df.select_dtypes(include=["number"]).columns.tolist()
    for col in numeric_cols:
        df[col] = df.groupby(CITY_COL)[col].transform(
            lambda x: x.interpolate(method="linear", limit_direction="both")
        )
    return df


def main() -> None:
    if not RAW_PATH.exists():
        raise FileNotFoundError(f"Raw data not found: {RAW_PATH}")
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df = pd.read_excel(RAW_PATH)
    df = interpolate_by_city(df)
    df.to_excel(OUT_PATH, index=False)
    print(f"Saved interim data to: {OUT_PATH}")


if __name__ == "__main__":
    main()
