# -*- coding: utf-8 -*-
"""
Step 02: Variable construction.

输入：data/interim/panel_interpolated.xlsx
输出：data/processed/panel_constructed.xlsx

功能：
1. 对统计口径变化变量进行比例衔接；
2. 使用永续盘存法测算资本存量；
3. 统一单位；
4. 构建核心变量、控制变量和 SBM-GML 所需投入产出变量。
"""
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
IN_PATH = ROOT / "data" / "interim" / "panel_interpolated.xlsx"
OUT_PATH = ROOT / "data" / "processed" / "panel_constructed.xlsx"
CITY_COL = "城市"
YEAR_COL = "年份"


def calculate_capital(df_city: pd.DataFrame, depreciation: float = 0.096) -> pd.DataFrame:
    df_city = df_city.sort_values(YEAR_COL).copy()
    investment = df_city["固定资产投资额_亿元"].to_numpy(dtype=float)
    capital = np.zeros(len(investment))
    capital[0] = investment[0] / depreciation
    for t in range(1, len(investment)):
        capital[t] = investment[t] + (1 - depreciation) * capital[t - 1]
    df_city["CapitalStock"] = capital
    return df_city


def ratio_link(df: pd.DataFrame, var: str, city: str = CITY_COL, year: str = YEAR_COL) -> pd.DataFrame:
    before = df[df[year].between(2010, 2012)].groupby(city)[var].mean()
    after = df[df[year].between(2013, 2015)].groupby(city)[var].mean()
    ratio = before / after

    def adjust(row):
        if 2010 <= row[year] <= 2012 and row[city] in ratio.index:
            return row[var] * ratio.loc[row[city]]
        return row[var]

    df[var + "_衔接"] = df.apply(adjust, axis=1)
    return df


def construct_variables(df: pd.DataFrame) -> pd.DataFrame:
    df = ratio_link(df, var="城镇非私营单位人员从业数_万人")
    df = df.groupby(CITY_COL, group_keys=False).apply(calculate_capital)

    df["CapitalStock"] = df["CapitalStock"] * 10000
    df["全社会用电量_万千瓦时"] = df["全社会用电量_亿千瓦小时"] * 10000
    df["工业烟粉尘排放量_万吨"] = df["工业烟（粉）尘排放量_吨"] / 10000
    df["工业二氧化硫排放量_万吨"] = df["工业二氧化硫排放量_吨"] / 10000

    df["ActualGDP"] = df.groupby(CITY_COL)["地区生产总值（万元）"].transform(
        lambda x: x.iloc[0] * (1 + df.loc[x.index, "地区生产总值增长率（%）"] / 100).cumprod()
    )
    df["PerGDP"] = df.groupby(CITY_COL)["人均地区生产总值（万元）"].transform(
        lambda x: x.iloc[0] * (1 + df.loc[x.index, "地区生产总值增长率（%）"] / 100).cumprod()
    )

    df["lnPerGDP"] = np.log(df["PerGDP"] + 1)
    df["lnActualGDP"] = np.log(df["ActualGDP"] + 1)
    df["Patent"] = df["新能源汽车产业专利申请量"]
    df["Company"] = df["新能源汽车企业数量_个"]
    df["IS"] = df["第三产业增加值占 GDP 比重（%）"] / df["第二产业增加值占 GDP 比重（%）"]
    df["Tech_Rate"] = df["科学技术支出_万元"] / df["地方一般公共预算支出_万元"]
    df["Energy_Inten"] = df["全社会用电量_万千瓦时"] / df["地区生产总值（万元）"]
    df["K_Intensity"] = df["CapitalStock"] / df["ActualGDP"]
    df["PopDens"] = df["人口密度_人/平方公里"]
    df["Gov_Rate"] = df["地方一般公共预算支出_万元"] / df["地区生产总值（万元）"]
    df["Fin_Level"] = df["年末金融机构各项贷款余额_万元"] / df["地区生产总值（万元）"]
    df["FDI_Rate"] = df["实际使用外资金额_万美元"] * df["人民币兑美元年平均汇率"] / df["地区生产总值（万元）"]

    df["劳动投入_万人"] = df["城镇非私营单位人员从业数_万人_衔接"]
    df["资本投入_万元"] = df["CapitalStock"]
    df["能源投入_万千瓦时"] = df["全社会用电量_万千瓦时"]
    df["期望产出_GDP"] = df["ActualGDP"]
    return df


def main() -> None:
    if not IN_PATH.exists():
        raise FileNotFoundError(f"Interim data not found: {IN_PATH}")
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df = pd.read_excel(IN_PATH)
    df = construct_variables(df)
    df.to_excel(OUT_PATH, index=False)
    print(f"Saved constructed panel to: {OUT_PATH}")


if __name__ == "__main__":
    main()
