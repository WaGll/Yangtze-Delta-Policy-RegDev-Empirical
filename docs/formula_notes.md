# Formula Notes

本文实证部分涉及变量构建、SBM-GML 测算、多期 DID 和空间计量模型。以下为主要公式说明。

## 1. 资本存量：永续盘存法

设城市 \(i\) 在年份 \(t\) 的资本存量为 \(K_{it}\)，固定资产投资为 \(I_{it}\)，折旧率为 \(\delta\)。

\[
K_{i0}=\frac{I_{i0}}{\delta}
\]

\[
K_{it}=I_{it}+(1-\delta)K_{i,t-1}
\]

代码中默认折旧率为：

\[
\delta=0.096
\]

## 2. 比例衔接口径调整

若某变量在 2013 年前后存在统计口径变化，使用 2010–2012 与 2013–2015 的城市均值比值进行衔接：

\[
\theta_i=\frac{\overline{X}_{i,2010-2012}}{\overline{X}_{i,2013-2015}}
\]

对 2010–2012 年变量修正为：

\[
X^{adj}_{it}=\theta_i X_{it}
\]

## 3. SBM 模型：包含非期望产出

投入向量、期望产出和非期望产出分别表示为：

\[
x \in R_+^m,\quad y^g \in R_+^{s_1},\quad y^b \in R_+^{s_2}
\]

其中，期望产出越多越好，非期望产出越少越好。

包含非期望产出的 SBM 非径向效率测度可写为：

\[
\rho = \frac{1-\frac{1}{m}\sum_{i=1}^{m}\frac{s_i^-}{x_{i0}}}
{1+\frac{1}{s_1+s_2}\left(\sum_{r=1}^{s_1}\frac{s_r^g}{y^g_{r0}}+\sum_{k=1}^{s_2}\frac{s_k^b}{y^b_{k0}}\right)}
\]

## 4. GML 指数

全局 Malmquist-Luenberger 指数定义为：

\[
GML_{t}^{t+1}=\frac{1+D_G(x_t,y_t^g,y_t^b)}{1+D_G(x_{t+1},y_{t+1}^g,y_{t+1}^b)}
\]

若：

\[
GML>1
\]

说明绿色全要素生产率提高；若：

\[
GML<1
\]

说明绿色全要素生产率下降。

## 5. GML 分解

\[
GML = EC \times TC
\]

其中，\(EC\) 表示效率变化，\(TC\) 表示技术进步。

## 6. 多期 DID 模型

基准双向固定效应模型为：

\[
Y_{it}=\alpha+\beta DID_{it}+\gamma X_{it}+\mu_i+\lambda_t+\varepsilon_{it}
\]

其中：

- \(Y_{it}\)：被解释变量，例如人均 GDP 对数；
- \(DID_{it}\)：政策处理变量；
- \(X_{it}\)：控制变量；
- \(\mu_i\)：城市固定效应；
- \(\lambda_t\)：年份固定效应。

## 7. 空间杜宾模型 SDM

空间杜宾模型为：

\[
Y_{it}=\rho WY_{it}+\beta DID_{it}+\theta W DID_{it}+X_{it}\gamma+WX_{it}\eta+\mu_i+\lambda_t+\varepsilon_{it}
\]

其中：

- \(W\)：空间权重矩阵；
- \(WY\)：被解释变量空间滞后项；
- \(WX\)：解释变量空间滞后项；
- \(\rho\)：空间自相关系数。

## 8. Moran's I

全局 Moran 指数为：

\[
I=\frac{n}{\sum_i\sum_j w_{ij}}\frac{\sum_i\sum_j w_{ij}(x_i-\bar{x})(x_j-\bar{x})}{\sum_i(x_i-\bar{x})^2}
\]

若 Moran's I 显著为正，说明变量存在正向空间集聚。
