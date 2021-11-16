# International Real Yields

## 1	Introduction
The project fits the Nelson-Siegel or Svensson curve to sovereign bond data (Real & Nominal) for various countries. We are interested in creating a zero curve from the data over the length of the bond's price series, stretching from 1y to 30y maturities to be used in further analysis.  

## 2	Software Dependencies
* MATLAB 2020a with the following toolboxes (Econometrics, Optimization, Financial Instruments)
* Bloomberg Professional Services for historical data
* MATLAB system environment with at least 10 GB of memory

## 3	File Structure

### 3.1 	`/Code`

All project code is stored in the `/Code` folder for generating figures and performing analysis. Refer to the headline comment string in each file for a general description of the purpose of the script in question.

* `/.../lib/` stores functions derived from academic papers or individual use to compute statistical tests or perform complex operations
    
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

* **YIELDS.mat** a MATLAB data file storing the computed yield curves – both zero and par curves – for all fitted sovereign bond issues (Real/Nominal)

## 4	Running Code

The steps required prior to running the code base are quite extensive, and require a fair bit of work with Bloomberg. Nonetheless, once all data within the `Input` folder has been updated, we will freely be able to call the `main.m` file to generate yields data. 

I. Update the Bond Overview Sheets

1. Login into your Bloomberg Professional Service account, you will need it to retrieve historical data.

2. Type <SRCH> (Fixed Income Search) in the Bloomberg search bar. Add a field called <TICKER> and precede to enter the following individually to pull either Nominal or Real bond issuances. Note the structure of the *XXX_bond_overview.xlsx* sheets as we will be aiming to replicate the structure found within these worksheets, that being each sheet is reserved for one country. 

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

3. After a ticker is entered into **TICKER** field, click on the <SEARCH> icon and you should have entries populated on the screen. We now will need to retrieve the correct columns, which we will use to filter our data even further.

4. Locate the <SETTINGS> tab and click on <EDIT COLUMNS>, you should now see a GUI with specific columns names on the left and right hand sides. The columns names requested are as follows:

|Issuer Name|Ticker|Cpn|Yld to Mty (Bid)|Maturity|Mty Type|Currency|Country/Region (Full Name)|First Cpn Date|Cpn Freq Des|Coupon Type|ISIN|Amt Issued|Amt Out|Issue Date|Security Name|Par Amount|Day Count|CUSIP|Inflation Index Ratio
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

NOTE: The some bond tickers in **Step. 2** share identical ticker symbols for both nominal and real issues (see italicized). In order to distinguish the two we need to filter issues that contain a value in the column field **Inflation Index Ratio**. Sovereign issues with a ratio value (i.e., non-null) are "Inflation linked" and will be considered "Real Bonds," while those that lack such a ratio (i.e., null) will be considered "Nominal Bonds." 

5. Once data fields are correctly retrieved we export the series and copy paste values to the corresponding sheet for each correct bond type (e.g., nominal_bond_overview -> FRA) 
    
II. Pull New Price Data
    
1. Once you've collected the proper bonds, with accompanying fields and stored them in their corresponding overview sheets (e.g., nominal_bond_overview.xlsx) we will begin the tedious process of updating the price series. 
    
2. Begin by copying the CUSIPS from each bond overview excel file (e.g., nominal_bond_overview.xlsx) onto the corresponding country excel sheet with matching bond type (i.e., nominal_bond_overview -> UK sheet -> nominal_bond_prices.xlsx -> UK Sheet) and concatenate each with the " Govt" string to the end of each CUSIP. These strings will be the Bloomberg IDs used to retrieve historical prices. 

3. In the same excel file, transpose the vertical array of CUSIPS in cell `A1` and with an active Bloomberg Session, continue with the following: 

  1. Click on the Spreadsheet Builder from the Bloomberg tab and select the Historical Data Table.
  2. Select all securities that you have copied and transposed over from the first Sheet as the Selected Securities.
  3. Search for the Last Price field from the search box and select it, this will return the last traded price for the security.
  4. Enter the furthest date you would like to retrieve prices for, this is our start date.
  5. Select only to Show Date and Show Security from the preview screen and press the finish button.

4. After retrieving historical prices, "Copy" the entire data series and "Paste Values" at the same location. Follow by performing a Find and Replace on `#N/A N/A` (Bloomberg parse error). This process will take a long time to complete and may cause excel to not respond in the process, depending on the number of securities queried. In future this process WILL be improved
  
5. Finally, save each price series set for the accompanying security for each country and bond type (e.g., nominal_bond_prices -> FRA)
    
**III. Run the `main.m` script**

1. Finally modify the variable `countries` on line 29 of the `main.m` file with the corresponding country tickers that we would like to exmaine, e.g., countries = {'UK', 'FRA'};
    
2. Once all data has been updated you are free to run the entire project base. You may opt to run the main.m file in a MATLAB interactive session or via terminal on your local machine or HPC cluster.
  ```
  % %    e.g., running code via batch on the FRBNY RAN HPC Cluster
  $ matlab20a-batch-withemail 10 main.m 
  ```

## 5	Possible Extensions
* Work on addressing issues with fitting the zero-rate curve to the observed bond data, there is a persistent postive bias when fitting longer maturities for nominal and real bond yields that grossly overestimate yields
* Work on a method to automatically pull central bank fitted zero rates from Haver (work in progress in excel)
* Work to improve the collection process for Bloomberg price data to be more efficient, and less suceptible to hard data querying limits

## 6	Contributors
* [Rajesh Rao](https://github.com/raj-rao-rr) (Sr. Research Analyst)
