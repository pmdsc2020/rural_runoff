# RuralRunoff

Offline Flutter mobile calculation tool for estimating peak surface runoff discharge in rural and agricultural catchments.

## Theoretical Basis

### Rational Formula
Discharge formula:
$$Q = \frac{C \cdot I \cdot A}{3.6}$$

Parameters:
- Q = Peak discharge rate in cubic meters per second (m3/s)
- C = Dimensionless catchment runoff coefficient
- I = Rainfall intensity in millimeters per hour (mm/hr) for storm duration equal to catchment time of concentration
- A = Catchment watershed area in square kilometers (km2)
- 3.6 = Metric unit conversion constant

### Time of Concentration (Kirpich Equation)
$$t_c = 0.01947 \cdot L^{0.77} \cdot S^{-0.385}$$

Parameters:
- tc = Time of concentration in minutes
- L = Longest hydraulic flow path in meters (m)
- S = Dimensionless average watershed slope (elevation drop / length in m/m)

### Intensity-Duration-Frequency (IDF) Formula
$$I = \frac{a \cdot T^m}{(t_c + b)^n}$$

Parameters:
- I = Rainfall intensity (mm/hr)
- T = Design return period (years)
- tc = Duration equal to time of concentration (minutes)
- a, b, m, n = Empirical regional rainfall coefficients

## Runoff Coefficients (C)

Recommended rural preset values:
- Cultivated flat land: 0.30 to 0.40
- Cultivated rolling land: 0.40 to 0.50
- Pasture and grassland: 0.20 to 0.35
- Forest cover: 0.10 to 0.25
- Barren or rocky land: 0.60 to 0.80
- Rural settlements / villages: 0.50 to 0.70

Composite coefficient equation:
$$C_{composite} = \frac{\sum (C_i \cdot A_i)}{\sum A_i}$$

## Application Limits

- Valid for small rural catchments under 25 km2.
- Assumes uniform rainfall distribution across the basin.
- Assumes storm duration equals or exceeds tc.
- For catchments larger than 25 km2, switch to SCS-CN (NRCS) or empirical flood formulas (Dickens / Ryves).