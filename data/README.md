# Data

## 1. External Data

本目录用于记录外部数据来源、下载链接、数据口径说明和授权信息。

### (1) Statistical Data

- 国家统计局
- 中国城市统计年鉴
- 各省市统计年鉴
- 地方统计公报
- EPS平台

### (2) Geographic Data

- 国家基础地理信息中心
- GADM
- Natural Earth
- OpenStreetMap

### (3) Innovation and Industry Data

- 国家专利数据库
- 天眼查 / CSMAR / Wind 等商业数据库
- 中国汽车工业年鉴、节能与新能源汽车年鉴

### (4) Policy Data

- 北大法宝数据库

## 2. Interim Data

本目录保存中间处理数据，例如缺失值插补后的面板数据。

由以下脚本生成：

```bash
python scripts/python/01_raw_to_interim.py
```

典型输出：

```text
panel_interpolated.xlsx
```

## 3. Processed Data

本目录保存最终建模数据和中间估计结果。

典型输出包括：

```text
panel_constructed.xlsx
sbm_gml_result.xlsx
final_panel_for_stata.xlsx
final_panel_for_stata.dta
```

## 4. Raw Data

### (1) Required Panel File

`reg.xlsx`：
城市层面面板数据

### (2) Spatial Data

城市行政区划 shapefile ：

```text
data/raw/city_shapefile/
```
