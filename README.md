# International Real Yields

## 1	Introduction
The project fits the Nelson-Siegel or Svensson curve to sovereign bond data (Real & Nominal) for various countries. We are interested in creating a zero curve from the data over the length of the bond's price series, stretching from 2y to 20y maturities.  

## 2	Software Dependencies
* MATLAB 2020a with the following toolboxes (Econometrics, Optimization, Financial Instruments)
* Bloomberg Professional Services for historical data
* MATLAB system environment with at least 5 GB of memory

## 3	File Structure

### 3.1 	`/Code`

All project code is stored in the `/Code` folder for generating figures and performing analysis. Refer to the headline comment string in each file for a general description of the purpose of the script in question.

* `/.../library/` stores functions derived from academic papers or individual use to compute statistical tests or perform complex operations
    
### 3.2 	`/Input`

Folder for all unfiltered, raw input data for financial information.

* **nominal_bond_overview.xlsx** an excel file containing all historical nominal bonds to trade for a given country (e.g. US)
* **nominal_bond_prices.xlsx** an excel file containing historical price information corresponding to nominal bonds traded for a given country (e.g. US)
* **real_bond_overview.xlsx** an excel file containing all historical real bonds to trade for a given country (e.g. US)
* **real_bond_prices.xlsx** an excel file containing historical price information corresponding to real bonds traded for a given country (e.g. US)

### 3.3 	`/Temp`

Folder for storing data files after being read and cleaned of missing/obstructed values.

* **FITS.mat** a MATLAB data file storing the nominal and real curve fits for sovereign bond issues. We attach a noise series in addition to the curve fits, which is simply the difference between the realized yields and fitted curve over tenors. Refer to the struct variable `fitted_n` for nominal bond fits and `fitted_r` for real bond fits. 
* **NOMINAL.mat** a MATLAB data file storing all traded nominal bonds and corresponding price series for tradable bonds in the sovereign issuer's life time. Variables are named according, with price and bond series being names [COUNTRY NAME]_Prices and [COUNTRY NAME]_Bonds respectively. 
* **REAL.mat** a MATLAB data file storing all traded real bonds and corresponding price series for tradable bonds in the sovereign issuer's life time. Variables are named according, with price and bond series being names [COUNTRY NAME]_Prices and [COUNTRY NAME]_Bonds respectively. 

### 3.4 	`/Output`

* **YIELDS.mat** a MATLAB data file storing the computed yield curves (zero-curves) for all fitted sovereign bond issues (Real/Nominal)

## 4	Running Code

The steps required prior to running the code base are quite extensive, and require a fair bit of work with Bloomberg. Nonetheless, once all data within the `Input` folder has been updated, we will freely be able to call the `main.m` file to generate yields data. 

1. Login into your Bloomberg Professional Service account, you will need it to retrieve historical data.

2. Type <SRCH> (Fixed Income Search) in the Bloomberg search bar. Add a field called <TICKER> and precede to enter the following individually.

Nominal Bonds
* *Australia Government Bond = ACGB*
* Canadian Government Bond = CAN
* *French Republic Government Bond OAT = FRTR*
* Bundesrepublik Deutschland Bundesanleihe = DBR
* Korea Treasury Bond = KTB
* Japan Government Bond = JGB
* Sweden Government Bond = SGB
* United Kingdom Gilt = UKT
* Italy Buoni Poliennali Del Tesoro = BTPS
* United States Treasury Note/Bond = T

Inflation Linked Bonds	
* *Australia Government Bond = ACGB*
* Canadian Government Real Return Bond = CANRRB
* *French Republic Government Bond OAT = FRTR*
* Deutsche Bundesrepublik Inflation Linked Bond = DBRI
* Inflation Linked Korea Treasury Bond = KTBI
* Japanese Government CPI Linked Bond = JGBI
* Sweden Inflation Linked Bond = SGBI
* United Kingdom Inflation-Linked Gilt = UKTI
* *Italy Buoni Poliennali Del Tesoro = BTPS*
* United States Treasury Inflation Indexed Bonds = TII

3. After a ticker is entered into the specified field hit <SEARCH> and you should have entries populated on the screen. We now will need to retrieve the correct columns, which we will use to filter our data even further.

4. Locate the <SOMETHING> tab and click on <EDIT COLUMNS>, you should now see a GUI with specific columns names on the left and right hand sides. The columns names requested are as follows

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|Issuer Name|Ticker|Cpn|Yld to Mty (Bid)|Maturity|Mty Type|Currency|Country/Region (Full Name)|First Cpn Date|Cpn Freq Des|Coupon Type|ISIN|Amt Issued|Amt Out|Issue Date|Security Name|Par Amount|Day Count|CUSIP|Inflation Index Ratio
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

NOTE: The some bond tickers in **Step. 2** share identical ticker symbols for both nominal and real issues (see italicized). In order to distinguish the two we need to filter issues that contain a value in the column field **Inflation Index Ratio**. Sovereign issues with a ratio value are "Inflation linked" and will be considered "Real Bonds", while those that lack such a ratio (i.e., NaN) will be considered "Nominal Bonds." 

5. Once you've collected the proper bonds, with accompanying fields 

## 5	Possible Extensions
* Work to automate the bond recovery process for each sovereign issuer 

## 6	Contributors
* [Rajesh Rao](https://github.com/raj-rao-rr) (Sr. Research Analyst)