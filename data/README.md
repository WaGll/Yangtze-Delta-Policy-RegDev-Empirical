# data

## External Data

本目录用于记录外部数据来源、下载链接、数据口径说明和授权信息。

建议不要直接上传受版权限制的数据，而是记录来源和复现方法。# Suggested External Data Sources

### Statistical Data

- 国家统计局
- 中国城市统计年鉴
- 各省市统计年鉴
- 地方统计公报

### Geographic Data

- 国家基础地理信息中心
- GADM
- Natural Earth
- OpenStreetMap

### Innovation and Industry Data

- 专利数据库
- 企查查 / 天眼查 / CSMAR / Wind 等商业数据库

# Interim Data

本目录保存中间处理数据，例如缺失值插补后的面板数据。

由以下脚本生成：

```bash
python scripts/python/01_raw_to_interim.py
```

典型输出：

```text
panel_interpolated.xlsx
```

## Processed Data

本目录保存最终建模数据和中间估计结果。

典型输出包括：

```text
panel_constructed.xlsx
sbm_gml_result.xlsx
final_panel_for_stata.xlsx
final_panel_for_stata.dta
```

这些文件由 Python 数据流水线自动生成，供 Stata 计量脚本读取。

## Raw Data

请将原始面板数据放置为：

```text
data/raw/reg.xlsx
```

建议不要将真实原始数据上传到公开 GitHub 仓库，除非你确认数据授权允许公开。

### Required Panel File

- `reg.xlsx`：城市层面面板数据，至少应包含城市、年份、GDP、人口、产业结构、财政、金融、外资、污染排放、能源、政策处理时间等变量。

### Spatial Data

城市行政区划 shapefile 请放入：

```text
data/raw/city_shapefile/
```
