# Optimisation of Flow Rate Algorithms for Ultrasonic Flow Meters in Different Flow Regimes

---

## 📄 Publication Information

| Item | Details |
|------|---------|
| **Title** | Optimisation of Flow Rate Algorithms for Ultrasonic Flow Meters in Different Flow Regimes |
| **Authors** | Wang Yue, Liu Xiaodong*, Wu Guifeng |
| **Affiliation** | School of Electrical and Energy & Power Engineering, Yangzhou University, Yangzhou 225000, China |
| **Journal** | Journal of Electronic Measurement and Instrumentation (电子测量与仪器学报) |
| **Volume** | 39, No. 12 |
| **DOI** | [10.13382/j.jemi.B2508365](https://doi.org/10.13382/j.jemi.B2508365) |
| **Received** | 2025-05-07 |
| **Classification** | TN64 TB937 A |

---

## 🙏 Special Acknowledgments

I extend my heartfelt gratitude to **Professor Du Guangsheng** and his research team at **Shandong University** .

- **Prompt and thoughtful responses** to our data inquiry emails
- **Generous sharing of PIV data** that was critical to this research
- **Willingness to help young researchers** despite the passage of time

### Personal Reflections

Professor Du Guangsheng's willingness to recall experimental data from his doctoral dissertation years ago and generously share it with a young student like me is truly touching and admirable. This act of mentorship exemplifies the best traditions of academic collaboration and has been instrumental in the successful publication of this paper.

Such generosity from senior scholars not only advances scientific knowledge but also inspires the next generation of researchers to pay it forward when they themselves become established academics.

---

## 📋 Table of Contents

1. [Abstract](#1-abstract)
2. [Introduction](#2-introduction)
3. [Theoretical Background](#3-theoretical-background)
4. [Velocity Distribution Models](#4-velocity-distribution-models)
5. [Ultrasonic Flow Meter Principle](#5-ultrasonic-flow-meter-principle)
6. [Integral Time-Difference Method](#6-integral-time-difference-method)
7. [Correction Factor Determination](#7-correction-factor-determination)
8. [Experimental Setup](#8-experimental-setup)
9. [Code Structure](#9-code-structure)
10. [Algorithm Implementation](#10-algorithm-implementation)
11. [Running the Code](#11-running-the-code)
12. [Results and Discussion](#12-results-and-discussion)
13. [References](#13-references)

---

## 1. Abstract

To reduce the calculation errors of ultrasonic flowmeters using the traditional time-difference method under different flow states, a correction method for flow velocity calculation is proposed. The flow field is classified into three states according to the Reynolds number (Re):

- **Laminar flow**: Re < 2,000
- **Transitional flow**: 2,000 < Re < 4,000
- **Turbulent flow**: Re > 4,000

Correction factors are added to the linear velocity distribution formula of the ideal flow state to address errors caused by different flow states. A water circulation system and a PIV (Particle Image Velocimetry) system are used to collect flow rate data at Re = 2,000 and Re = 4,000 as calibration values.

The linear velocity distribution formula with correction factors is combined with the integral time-difference method to calculate flow velocity and rate. By adjusting the correction factors and minimizing the errors between calculated and calibrated values, the correction factors for laminar and turbulent linear velocity distributions are determined as **k_c = 1.8471** and **k_t = 1.4368**, respectively.

Results show that the calculation error for transitional flow (Re 2,000-4,000) is about **0.2%** relative to the experimental error, and for high-Re turbulent flow, the relative error is around **0.45%**. This proves that the method of combining correction factors with the integral time-difference method via Reynolds number classification is effective and yields more accurate results.

**Keywords:** flow field state judgement, linear velocity distribution for different flow regimes, integral time difference method, correction factor

---

## 2. Introduction

### 2.1 Research Background

Ultrasonic flow meters based on the transit-time method are widely used in industrial applications due to their non-invasive nature and high accuracy. However, the traditional time-difference method exhibits significant errors when measuring across different flow regimes because:

1. The velocity profile varies significantly between laminar and turbulent flows
2. The relationship between measured line-average velocity and actual area-average velocity changes with flow regime
3. Transitional flow (2,000 < Re < 4,000) is particularly challenging to model

### 2.2 Methodology Overview

The proposed method follows this structural framework:

![Methodology Flowchart](Methodology%20Flowchart.png)

### 2.3 Contribution Summary

1. **Reynolds number-based classification**: Three distinct flow states with specific correction factors
2. **Calibrated correction factors**: k_c = 1.8471 for laminar, k_t = 1.4368 for turbulent
3. **Transitional flow handling**: Linear interpolation between calibrated models
4. **Validated accuracy**: 0.2% error for transitional flow, 0.45% for turbulent flow

---

## 3. Theoretical Background

### 3.1 Reynolds Number

The Reynolds number determines the flow regime:

$$Re = \frac{\rho v D}{\mu}$$

Where:
- $\rho$ = fluid density (kg/m³)
- $v$ = characteristic velocity (m/s)
- $D$ = pipe inner diameter (m)
- $\mu$ = dynamic viscosity (Pa·s)

### 3.2 Flow Regime Classification

| Flow Regime | Reynolds Number | Characteristics |
|-------------|-----------------|-----------------|
| **Laminar** | Re < 2,000 | Parabolic velocity profile, stable flow |
| **Transitional** | 2,000 ≤ Re ≤ 4,000 | Unstable, fluctuating profile |
| **Turbulent** | Re > 4,000 | Flat core, steep gradient near wall |

### 3.3 Problem Statement

The transit-time ultrasonic method measures along a chord path, producing a weighted average that differs from the area-average velocity required for volumetric flow calculation. Different flow regimes require different correction factors to achieve accurate measurements.

---

## 4. Velocity Distribution Models

### 4.1 Ideal Velocity Distribution (Without Correction)

**Laminar flow (Equation 2):**

$$u_c = u_{max}\left(1 - \frac{r}{R}\right)^2$$

**Turbulent flow (Equation 3):**

$$u_t = u_{max}\left(1 - \frac{r}{R}\right)^{1/n}$$

Where the exponent $n$ is given by:

$$n = 1.85\lg Re - 1.7 \quad (for \; Re > 10,000)$$

### 4.2 Corrected Velocity Distribution (With Correction Factors)

**Laminar flow (Equation 5):**

$$\boxed{u_c = k_c \cdot u_{max}\left(1 - \frac{r}{R}\right)^2}$$

**Turbulent flow (Equation 5):**

$$\boxed{u_t = k_t \cdot u_{max}\left(1 - \frac{r}{R}\right)^{1/n}}$$

Where $k_c$ and $k_t$ are correction factors calibrated using PIV experimental data.

### 4.3 Transitional Flow Model (Equation 6)

For 2,000 ≤ Re ≤ 4,000, linear interpolation between laminar and turbulent profiles:

$$\boxed{u_g = \frac{Re - 2000}{4000 - 2000} \cdot (u_t - u_c) + u_c}$$

### 4.4 Velocity Profile Visualization

The pipe profile velocity at different Reynolds numbers is shown in **Figure 13** of the paper, demonstrating the transition from parabolic (laminar) to flatter (turbulent) profiles.

---

## 5. Ultrasonic Flow Meter Principle

### 5.1 Transit-Time Measurement

The ultrasonic flow meter detection principle is illustrated in **Figure 3**. Two transducers P1 and P2 are placed at angle θ (typically 15°) to the pipe axis.

**Downstream transit time (Equation 7):**

$$t_d = \frac{L}{c + v\cos\theta}$$

**Upstream transit time (Equation 7):**

$$t_u = \frac{L}{c - v\cos\theta}$$

**Time difference (Equation 7):**

$$\Delta T = t_u - t_d$$

### 5.2 Velocity Calculation (Equation 8)

$$v = \frac{L}{2\cos\theta} \cdot \frac{T_2 - T_1}{T_1 \cdot T_2}$$

### 5.3 Differential Time Increment (Equation 9)

For continuous velocity profile:

$$\frac{dT_2 - dT_1}{dL} = \frac{1}{c - u\cos\theta} - \frac{1}{c + u\cos\theta}$$

With $dL = 2dr\sin\theta$ (Equation 10), the time difference becomes:

---

## 6. Integral Time-Difference Method

### 6.1 General Integral Equation (Equation 11)

$$\Delta T = \int_0^R \left[\frac{1}{c - u\cos\theta} - \frac{1}{c + u\cos\theta}\right] \cdot \frac{2\sin\theta}{1} dr$$

### 6.2 Simplified Form (Equation 12)

$$\Delta T = \frac{L \cdot 2v\cos\theta}{c^2 - u^2\cos^2\theta}$$

For $v << c$ (Equation 13):

$$\Delta T = \frac{L \cdot 2u\cos\theta}{c^2}$$

### 6.3 Line-Average Velocity (Equation 14)

$$u = \frac{c^2 \cdot \Delta T \cdot \sin\theta}{4R \cdot \cos\theta}$$

### 6.4 Laminar Flow Integration (Equation 15)

$$\Delta T = \frac{2R}{u_m\sin\theta\cos\theta \cdot k_c} \int_0^1 \left[\frac{1}{K - k_c(1-s^2)} - \frac{1}{K + k_c(1-s^2)}\right] ds$$

Where $K = \dfrac{c}{u_m\sin\theta\cos\theta}$

### 6.5 Simplified Laminar Equation (Equation 16)

When $\dfrac{K}{k_c} >> \dfrac{1-s^2}{2}$:

$$\boxed{\Delta T = \frac{8R\cos\theta \cdot u_m \cdot k_c}{3c^2\sin\theta}}$$

### 6.6 Turbulent Flow Integration (Equation 17)

$$\Delta T = \frac{2R}{u_m\sin\theta\cos\theta \cdot k_t} \int_0^1 \left[\frac{2(1-s)^{1/n}}{K^2 - k_t^2(1-s)^{2/n}}\right] ds$$

### 6.7 Simplified Turbulent Equation (Equation 18)

When $\dfrac{K}{k_t} >> \dfrac{1-s^2}{2}$:

$$\boxed{\Delta T = \frac{n}{n+1} \cdot \frac{4R \cdot u_m \cdot \cos\theta \cdot k_t}{c^2 \cdot \sin\theta}}$$

---

## 7. Correction Factor Determination

### 7.1 Calibration Method

The correction factors are determined using PIV experimental data:

1. Measure velocity profiles at Re = 2,000 and Re = 4,000
2. Apply Equations 14, 16, 17 to calculate theoretical ΔT
3. Minimize the error between calculated and measured values
4. Iterate until error e = 0 (Equation 19)

$$e = v_{actual} - v = 0$$

### 7.2 Calibrated Correction Factors

| Parameter | Value | Description |
|-----------|-------|-------------|
| **k_c** | **1.8471** | Laminar flow correction factor |
| **k_t** | **1.4368** | Turbulent flow correction factor |

### 7.3 Physical Interpretation

- **k_c > 1**: The laminar correction factor accounts for the difference between the ideal parabolic profile and the actual transit-time measured velocity
- **k_t > 1**: The turbulent correction factor adjusts for the flatter profile and measurement path effects

---

## 8. Experimental Setup

### 8.1 Experimental Equipment

| Equipment | Description |
|-----------|-------------|
| **PIV System** | Particle Image Velocimetry for velocity profile measurement |
| **Water Circulation System** | Controlled flow generation |
| **Ultrasonic Flow Meter** | Transit-time measurement |
| **Test Pipe** | Inner diameter d = 40 mm |

### 8.2 Measurement Conditions

| Parameter | Value |
|-----------|-------|
| Pipe diameter | 40 mm |
| Temperature range | 10.3 - 12 °C |
| Reynolds number range | 2,000 - 20,000 |

### 8.3 Experimental Data Table

The data logging form (Table 1) contains measurements at multiple Reynolds numbers:

| Re | T (°C) | v (m/s) | Q (m³/h) | Q₂ | Q₃ | Q₄ |
|----|--------|---------|----------|-----|-----|-----|
| 2,000 | 12 | 0.062 | 0.280 | 0.280 | 0.281 | 0.280 |
| 2,200 | 12 | 0.068 | 0.309 | 0.309 | 0.309 | 0.309 |
| 2,400 | 12 | 0.074 | 0.337 | 0.338 | 0.337 | 0.337 |
| ... | ... | ... | ... | ... | ... | ... |
| 4,000 | 12 | 0.124 | 0.561 | 0.561 | 0.561 | 0.561 |
| ... | ... | ... | ... | ... | ... | ... |
| 11,800 | 11.2 | 0.374 | 1.694 | 1.692 | 1.691 | 1.692 |
| 12,000 | 11.2 | 0.380 | 1.717 | 1.719 | 1.720 | 1.719 |
| ... | ... | ... | ... | ... | ... | ... |
| 19,600 | 10.3 | 0.636 | 2.880 | 2.878 | 2.879 | 2.879 |
| 19,800 | 10.3 | 0.643 | 2.907 | 2.908 | 2.907 | 2.905 |
| 20,000 | 10.3 | 0.649 | 2.936 | 2.936 | 2.935 | 2.937 |

### 8.4 Flow Rate Calculation (Equation 20)

$$Q = 3600 \cdot \pi R^2 \cdot v$$

---

## 9. Code Structure

### 9.1 Directory Structure

```
project_root/
├── README.md                                # This file
├── Correction Algorithm.m                    # Main correction algorithm
├── Error Comparison_Includes Data Table.m   # Experimental comparison
└── Reflecting on and analysing code/         # Analysis scripts
    ├── chengzhongfa.m                       # Centroid method
    ├── chuangxin.m                          # Innovative approaches
    ├── fenduan.m                            # Segmented analysis
    ├── fenduanxxh.m                         # Segmented analysis (variant)
    ├── guanbi.m                             # Boundary conditions
    ├── huatu.m                              # Visualization
    ├── liusu.m                              # Flow rate calculations
    ├── meihua.m                             # Optimization
    ├── tuanliu.m                            # Turbulent flow
    ├── tuanliu22.m                          # Turbulent flow (v2)
    ├── untitled*.m                          # Experimental scripts
    └── xiuzhen.m                            # Correction refinements
```

### 9.2 Main Program: `Correction Algorithm.m`

**Functionality:**
1. Define physical parameters (D, ν, c, θ)
2. Calibrate correction factors k_c and k_t
3. Calculate velocity for all flow regimes
4. Generate velocity profile visualizations
5. Output flow rate data tables

### 9.3 Error Analysis: `Error Comparison_Includes Data Table.m`

**Functionality:**
1. Load experimental data
2. Compare with theoretical calculations
3. Compute relative errors
4. Generate error distribution plots

---

## 10. Algorithm Implementation

### 10.1 Physical Parameters (from code)

| Parameter | Symbol | Value | Unit |
|-----------|--------|-------|------|
| Pipe Inner Diameter | D | 0.04 | m |
| Pipe Radius | R | 0.02 | m |
| Kinematic Viscosity | ν | 1.007×10⁻⁶ | m²/s |
| Speed of Sound | c | 1482 | m/s |
| Propagation Angle | θ | 45 | degrees |
| Radial Points | N | 1000 | - |

### 10.2 Correction Factors (from paper)

| Factor | Value | Purpose |
|--------|-------|---------|
| k_c | 1.8471 | Laminar flow correction |
| k_t | 1.4368 | Turbulent flow correction |

### 10.3 Core Functions

#### `fit_correction_factor`

```matlab
function error = fit_correction_factor(factor, u_m, v_S_target, D, nu, N, flow_type, c, theta)
    [v_S_calc, ~] = calculate_v_S(factor, u_m, D, nu, N, flow_type, c, theta);
    error = v_S_calc - v_S_target;
end
```

#### `calculate_v_S`

```matlab
function [v_S, DeltaT] = calculate_v_S(factor, u_m, D, nu, N, flow_type, c, theta)
    R = D / 2;
    r = linspace(0, R, N);
    s = r / R;

    switch flow_type
        case 'laminar'
            % k_c = 1.8471
            u = factor * u_m * (1 - s.^2);
        case 'turbulent'
            % k_t = 1.4368
            Re = (u_m * D) / nu;
            n = 1.85*log10(Re) - 1.7;
            u = factor * u_m * (1 - s).^(1/n);
    end

    [v_S, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta);
end
```

#### `calculate_velocity_from_deltat`

```matlab
function [v_S, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta)
    R = max(r);
    theta_rad = deg2rad(theta);
    K = c / (u_m * cos(theta_rad));
    s = r / R;
    integrand = (1 ./ (K - u/u_m) - 1 ./ (K + u/u_m));
    DeltaT = (2 * R / (u_m * sin(theta_rad) * cos(theta_rad))) * trapz(s, integrand);
    v_L = (DeltaT * c^2 * sin(theta_rad)) / (4 * max(r) * cos(theta_rad));
    v_S = trapz(r, v_L .* r) * 2 / R^2;
end
```

### 10.4 Transitional Flow Interpolation

```matlab
% For 2000 < Re < 4000
weight = (Re - 2000) / (4000 - 2000);
[u_laminar, ~] = calculate_v_S(k_c, u_m, D, nu, N, 'laminar', c, theta);
[u_turbulent, ~] = calculate_v_S(k_t, u_m, D, nu, N, 'turbulent', c, theta);
u_g = (1 - weight) * u_laminar + weight * u_turbulent;
```

---

## 11. Running the Code

### 11.1 Environment Requirements

- **MATLAB R2016b or higher**
- Core MATLAB functions only (no additional toolboxes required)

### 11.2 Execution Steps

1. Open `Correction Algorithm.m`
2. Press F5 or click Run
3. View console output for correction factors and validation
4. View generated figures

### 11.3 Expected Output

**Console:**
```
Correction Factors:
k_c (Laminar) = 1.8471
k_t (Turbulent) = 1.4368

Validation Results:
Laminar: Target v_S = 0.062, Calculated v_S = 0.062, Error < 0.01%
Turbulent: Target v_S = 0.124, Calculated v_S = 0.124, Error < 0.01%
```

**Figures:**
| Figure | Content |
|--------|---------|
| 1 | Velocity vs Reynolds number |
| 2 | Flow rate vs Reynolds number |
| 3 | Laminar velocity profile (Re=2000) |
| 4 | Turbulent velocity profile (Re=4000) |
| 5 | Normalized velocity distributions |
| 6 | Transitional flow profile (Re=3000) |

---

## 12. Results and Discussion

### 12.1 Error Analysis Summary

| Flow Region | Re Range | Relative Error | Notes |
|-------------|----------|----------------|-------|
| **Transitional** | 2,000 - 4,000 | **~0.2%** | Excellent accuracy |
| **Turbulent** | 11,800 - 12,000 | ~1% | Good accuracy |
| **Turbulent** | 19,800 - 20,000 | **~0.45%** | Very good accuracy |

### 12.2 Velocity Profile Results

The paper presents several key figures:

| Figure | Description |
|--------|-------------|
| Fig. 4 | Comparison of error between actual and calculated values at transition flow |
| Fig. 5 | Comparison of error for larger Reynolds numbers |
| Fig. 6 | Box line plot of relative error in flow rate |
| Fig. 7 | Relative error distribution of transition flow velocity |
| Fig. 8 | Relative error distribution of turbulent flow velocity |
| Fig. 9 | Turbulent linear velocity distribution (Re=4000) |
| Fig. 10 | Laminar flow linear velocity distribution (Re=2000) |
| Fig. 11 | Transitional flow line velocity distribution (Re=2000-4000) |
| Fig. 12 | Curves of flow rate with Reynolds number |
| Fig. 13 | Pipe profile velocity at different Reynolds numbers |

### 12.3 Key Findings

1. **Classification effectiveness**: Reynolds number classification provides clear boundaries for correction factor application

2. **Calibration accuracy**: Using PIV data at Re=2000 and Re=4000 provides reliable correction factors

3. **Transitional flow performance**: Linear interpolation achieves ~0.2% error, suitable for most industrial applications

4. **Turbulent flow performance**: The k_t correction achieves ~0.45% error for high Re flows

5. **Validation scope**: 80% of measurements fall within 0.2% error for transitional flow

---

## 13. References

[1] YAO L, WANG R D, ZUO F Q, et al. Research on segemental correction method of measurement characteristics of monoacoustic ultrasonic water meter[J]. Journal of Metrology, 2013, 34(5): 441-445.

[2] SHAO Z F. Experimental and DNS study of the flow regime in the generalised transition region of a circular tube[D]. Jinan: Shandong University, 2013.

[3] WANG F F, ZENG Y, ZHANG Z K, et al. Influencing factors and correction analysis of ultrasonic flow measurement error in large pipe diameter[J]. Chinese Journal of Scientific Instrument, 2019, 40(3): 146-153.

[4] FAN S H, SHI W J, HUANG Y Z H, et al. Research and application of ultrasonic Doppler flowmeter transducer[J]. Foreign Electronic Measurement Technology, 2014, 33(2): 84-88.

[5] HUANG X H, YIN Y F, XU X F, et al. Improved ApFFT algorithm and its application in ultrasonic flowmeter[J]. Journal of Electronic Measurement and Instrumentation, 2019, 33(11): 44-49.

[6] LI D, SUN J T, DU G S H, et al. Research on the influence of structural parameters on the water flow characteristics of ultrasonic flowmeter[J]. Chinese Journal of Scientific Instrument, 2016, 37(4): 945-951.

[7] LIU Q, ZHAO J K, CAO J Y, et al. Ultrasonic time difference measurement system based on auxiliary impedance matching branch[J]. Chinese Journal of Scientific Instrument, 2024, 45(5): 179-187.

[8] YANG R F, ZHU Y D, GUO C H X, et al. Compensation of accuracy of ultrasonic flowmeter with inter-crossing time[J]. Electronic Measurement Technology, 2021, 44(5): 63-67.

[9] SU B, ZHANG P F, CHENG D X, et al. Research review on temperature compensation algorithm of ultrasonic flowmeter[J]. Modern Electronic Technique, 2023, 46(13): 115-120.

[10] LI M. Large eddy simulation of turbulent flow in a circular tube with power-law fluid[D]. Daqing: Northeast Petroleum University, 2020.

[11] LIU B, XU K J, MU L B, et al. Echo energy integral based signal processing method for ultrasonic gas flow meter[J]. Sensors and Actuators A: Physical, 2018, 277: 181-189.

[12] ZHOU J, WANG P, WANG R, et al. Signal processing method of ultrasonic gas flowmeter based on transit-time mathematical characteristics[J]. Measurement, 2025, 239: 115485.

[13] SMITH L, GREENSHIELDS D, BURTON R, et al. Simultaneous data acquisition for improved performance in transit time difference ultrasonic flowmeters[J]. Flow Measurement and Instrumentation, 2023, 91: 102345.

[14] YUAN X M, ZHU X, HOU Z X, et al. Fluent-based simulation study of laminar flow in circular tube[J]. Machine Tools and Hydraulics, 2019, 47(11): 155-158, 187.

[15] ZHANG H, GUO C, LIN J. Effects of velocity profiles on measuring accuracy of transit-time ultrasonic flowmeter[J]. Applied Sciences, 2019, 9(8): 1648.

[16] LI J, ZHANG J G. Compensation algorithm and implementation in gas ultrasonic flow measurement[J]. Industrial Instrumentation and Automation Device, 2024(4): 110-113, 119.

[17] ZHANG X H, LI S, HOU X Y. Research on ultrasonic flowmeter using surface fitting algorithm[J]. Mechanical Design and Manufacturing, 2025(1): 31-35.

[18] JIA H Q, WANG C H Y, DANG R R. Influence of fluid flow velocity on ultrasonic flow measurement accuracy and calibration[J]. Chinese Journal of Scientific Instrument, 2020, 41(7): 1-8.

[19] ZHENG D, ZHAO D, MEI J. Improved numerical integration method for flowrate of ultrasonic flowmeter based on Gauss quadrature for non-ideal flow fields[J]. Flow Measurement and Instrumentation, 2015, 41: 28-35.

[20] GUO S, XIANG N, LI B, et al. Integration method of multipath ultrasonic flowmeter based on velocity distribution[J]. Measurement, 2023, 207: 112388.

[21] FERRARI A, PIZZO P, RUNDO M. Modelling and experimental studies on a proportional valve using an innovative dynamic flow-rate measurement in fluid power systems[J]. Proceedings of the Institution of Mechanical Engineers Part C: Journal of Mechanical Engineering Science, 2018, 232(13): 2404-2418.

[22] ZHENG G L, GUANG S H D, ZHU F S, et al. Measurement of transitional flow in pipes using ultrasonic flowmeters[J]. Fluid Dynamics Research, 2014, 46(5): 055501.

[23] WESTERWEEL J, DRAAD A A, VAN DER HOEVEN J G T, et al. Measurement of fully-developed turbulent pipe flow with digital particle image velocimetry[J]. Experiments in Fluids, 1996, 20(3): 165-177.

---

## Citation

```bibtex
@article{Wang2025UltrasonicFlow,
  title={Optimisation of Flow Rate Algorithms for Ultrasonic Flow Meters in Different Flow Regimes},
  author={Wang, Yue and Liu, Xiaodong and Wu, Guifeng},
  journal={Journal of Electronic Measurement and Instrumentation},
  volume={39},
  number={12},
  pages={138-146},
  year={2025},
  doi={10.13382/j.jemi.B2508365}
}
```

---

## 📧 Contact

- **Author**: Yue Wang（王玥）
- **Email**: 2574414382@qq.com/233302124@stu.yzu.edu.cn
- **Institution**: College of Electrical, Energy and Power Engineering, Yangzhou University
- **Address**: Yangzhou 225000, China

---

*Last updated: July 2026*
