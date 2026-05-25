# data

## External Data

本目录用于记录外部数据来源、下载链接、数据口径说明和授权信息。

建议不要直接上传受版权限制的数据，而是记录来源和复现方法。# Suggested External Data Sources

### Statistical Data

- 国家统计局
- 中国城市统计年鉴
- 各省市统计年鉴
- 地方统计公报
- EPS平台

### Geographic Data

- 国家基础地理信息中心
- GADM
- Natural Earth
- OpenStreetMap

### Innovation and Industry Data

- 国家专利数据库
- 天眼查 / CSMAR / Wind 等商业数据库

## Interim Data

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


## Raw Data

存放原始回归数据以及地理经纬度数据

### Required Panel File

- `reg.xlsx`：城市层面面板数据，至少应包含城市、年份、GDP、人口、产业结构、财政、金融、外资、污染排放、能源、政策处理时间等变量。

### Spatial Data

城市行政区划 shapefile 请放入：

```text
data/raw/city_shapefile/
```
