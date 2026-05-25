# -*- coding: utf-8 -*-
"""
Step 03: SBM-GML estimation with undesirable outputs.

输入：data/processed/panel_constructed.xlsx
输出：data/processed/sbm_gml_result.xlsx
"""
from pathlib import Path
import warnings
import numpy as np
import pandas as pd
import pulp
from joblib import Parallel, delayed
from tqdm import tqdm

warnings.filterwarnings("ignore")
ROOT = Path(__file__).resolve().parents[2]
DATA_PATH = ROOT / "data" / "processed" / "panel_constructed.xlsx"
OUTPUT_PATH = ROOT / "data" / "processed" / "sbm_gml_result.xlsx"
YEAR_COL = "年份"
DMU_COL = "城市"
INPUTS = ["劳动投入_万人", "资本投入_万元", "能源投入_万千瓦时"]
GOOD_OUTPUTS = ["期望产出_GDP"]
BAD_OUTPUTS = ["工业烟粉尘排放量_万吨", "工业二氧化硫排放量_万吨", "工业废水排放量_万吨"]


def solve_sbm(x0, yg0, yb0, x_ref, yg_ref, yb_ref, vrs=True, time_limit=60) -> float:
    x0 = np.asarray(x0, dtype=float)
    yg0 = np.asarray(yg0, dtype=float)
    yb0 = np.asarray(yb0, dtype=float)
    x_ref = np.asarray(x_ref, dtype=float)
    yg_ref = np.asarray(yg_ref, dtype=float)
    yb_ref = np.asarray(yb_ref, dtype=float)

    m, n = x_ref.shape
    s1 = yg_ref.shape[0]
    s2 = yb_ref.shape[0]
    eps = 1e-9

    if n == 0 or np.any(x0 <= 0) or np.any(yg0 <= 0) or np.any(yb0 <= 0):
        return np.nan

    prob = pulp.LpProblem("SBM_undesirable", pulp.LpMinimize)
    t = pulp.LpVariable("t", lowBound=eps)
    lam = [pulp.LpVariable(f"lambda_{j}", lowBound=0) for j in range(n)]
    sx = [pulp.LpVariable(f"sx_{i}", lowBound=0) for i in range(m)]
    syg = [pulp.LpVariable(f"syg_{r}", lowBound=0) for r in range(s1)]
    syb = [pulp.LpVariable(f"syb_{k}", lowBound=0) for k in range(s2)]

    prob += t - (1 / m) * pulp.lpSum(sx[i] / x0[i] for i in range(m))
    prob += t + (1 / (s1 + s2)) * (
        pulp.lpSum(syg[r] / yg0[r] for r in range(s1)) +
        pulp.lpSum(syb[k] / yb0[k] for k in range(s2))
    ) == 1

    for i in range(m):
        prob += t * x0[i] == pulp.lpSum(lam[j] * x_ref[i, j] for j in range(n)) + sx[i]
    for r in range(s1):
        prob += t * yg0[r] == pulp.lpSum(lam[j] * yg_ref[r, j] for j in range(n)) - syg[r]
    for k in range(s2):
        prob += t * yb0[k] == pulp.lpSum(lam[j] * yb_ref[k, j] for j in range(n)) + syb[k]
    if vrs:
        prob += pulp.lpSum(lam) == t

    solver = pulp.PULP_CBC_CMD(msg=False, timeLimit=time_limit, threads=1)
    prob.solve(solver)
    if pulp.LpStatus[prob.status] != "Optimal":
        return np.nan
    return float(pulp.value(prob.objective))


def compute_efficiencies(df, inputs, good_outputs, bad_outputs, vrs=True, n_jobs=-1, time_limit=60):
    x_all = df[inputs].to_numpy(dtype=float).T
    yg_all = df[good_outputs].to_numpy(dtype=float).T
    yb_all = df[bad_outputs].to_numpy(dtype=float).T
    years = df[YEAR_COL].to_numpy()

    def single_task(idx: int):
        row = df.iloc[idx]
        x0 = row[inputs].to_numpy(dtype=float)
        yg0 = row[good_outputs].to_numpy(dtype=float)
        yb0 = row[bad_outputs].to_numpy(dtype=float)
        global_score = solve_sbm(x0, yg0, yb0, x_all, yg_all, yb_all, vrs=vrs, time_limit=time_limit)
        same_year = np.flatnonzero(years == row[YEAR_COL])
        current_score = solve_sbm(
            x0, yg0, yb0,
            x_all[:, same_year], yg_all[:, same_year], yb_all[:, same_year],
            vrs=vrs, time_limit=time_limit,
        )
        return global_score, current_score

    results = Parallel(n_jobs=n_jobs, backend="loky")(
        delayed(single_task)(i) for i in tqdm(range(len(df)), desc="计算 SBM 效率")
    )
    global_eff, current_eff = zip(*results)
    return np.asarray(global_eff, dtype=float), np.asarray(current_eff, dtype=float)


def decompose_gml(group: pd.DataFrame) -> pd.DataFrame:
    group = group.sort_values(YEAR_COL).copy()
    group["D_global"] = (1 - group["Global_Eff"]) / group["Global_Eff"]
    group["D_current"] = (1 - group["Current_Eff"]) / group["Current_Eff"]
    group["GML"] = (1 + group["D_global"].shift(1)) / (1 + group["D_global"])
    group["EC"] = (1 + group["D_current"].shift(1)) / (1 + group["D_current"])
    group["TC"] = group["GML"] / group["EC"]
    group["GTFP_cum"] = group["GML"].fillna(1).cumprod()
    return group


def main() -> None:
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Processed panel not found: {DATA_PATH}")
    df = pd.read_excel(DATA_PATH)
    needed = [YEAR_COL, DMU_COL] + INPUTS + GOOD_OUTPUTS + BAD_OUTPUTS
    df = df.dropna(subset=needed)
    for col in INPUTS + GOOD_OUTPUTS + BAD_OUTPUTS:
        df = df[df[col] > 0]
    df["Global_Eff"], df["Current_Eff"] = compute_efficiencies(
        df, INPUTS, GOOD_OUTPUTS, BAD_OUTPUTS, vrs=True, n_jobs=-1, time_limit=60
    )
    result = df.groupby(DMU_COL, group_keys=False).apply(decompose_gml)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    result.to_excel(OUTPUT_PATH, index=False)
    print(f"Saved SBM-GML results to: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
