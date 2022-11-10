The notebook code assumes that the current working directory contains the
directory air_quality_macrox with the same file structure as in the google cloud bucket.

The notebooks (or the one R script) should be run in the order presented since they
usually depend on csv's created by the previous notebook.


create_official_df_by_pollutant.ipynb

Creates 4 csv's for each pollutant, NO2, SO2, PM2.5, and CO, separately
using the "air_quality_macrox/official_air_pollution_IN" city data.
This is daily data from January 1, 2018 to August 21, 2022.
Histograms of the pollutant values are made.
Missing values of the dataframes for each pollutant are visualized.
For each pollutant, stations are removed that had missing data for the first month of 2018.
note: This consolidation of data was slow so these csv's are included in the folder
output:
  no2_official_red.csv
  so2_official_red.csv
  pm_official_red.csv
  co_official_red.csv


  
combine_official_and_satellite.ipynb

Histograms were made of the satellite data for each pollutant.
18 extreme outliers were removed from the SO2 data and changed to NaN
(these will later be imputed with matrix completion)
Missing values were visualized for each pollutant's (NO2, SO2, and CO) data.
CO missing value patterms were anomolous and CO satellite data was determined
to be to unreliable for further analysis.
The official station time series data and satellite time series data were combined.
This is daily data from January 1, 2018 to August 21, 2022.
This combined dataset was split by date into a generate api, training, and validation set
so that each of these could have missing values imputed in the next step (using R)
output:
  generate_api_data.csv
  training.csv
  validation.csv



missing_imputation.R

The R library, softImpute, is used to perform matrix completion on the combined time series data.
The missing values are filled with this method and the optimal
minimum rank (a hyperparameter for this method) is determined.
note: It is also assumed that the current working directory for the missing_imputation.R
script will be the working directory of the python notebooks so that the csv's are available.
output:
  training_no_na.csv
  validation_no_na.csv
  generate_api_data_no_na.csv




backfill_api_data.ipynb

The data from Openweathermap.org (api) is consolidated for each pollutant (NO2, SO2, PM2.5, and CO)
Differences in city names between response and features are resolved.
Random forest is used to backfill the Openweathermap data from January 1, 2018 to November 23, 2020.
hyperparameter optimization used the validation set
Data sets with pollutant values backfilled are created. These include pollutant concentrations for all
the cities form January 2018 to July 25, 2022.
prediction data and feature importance data is also exported for future investigation
primary output:
  no2_api_backfill.csv
  so2_api_backfill.csv
  pm_api_backfill.csv
  co_api_backfill.csv



economy_vs_air_quality_model.ipynb

Random forest is used to create models for all the cities of the relationship
between unemployment rate and the concentration of NO2, SO2, PM2.5 and CO from the
backfilled Openweathermap.org data.
Three cities are not considered since they have missing unemployment rate numbers
Differences in city names are resolved.
Ten random forest models are created for each city because of the small sample size
can lead to differences in feature importance.Feature importance is therefore averaged
over all ten models for each city.
To take into consideration the time aspect, the monthly change in concentration of pollutants
is also used as a feature 
(features then become NO2, SO2, PM2.5, CO, delta-NO2, delta-SO2, delta-PM2.5, and delta-CO).
A city that was removed is used as a test of a the model from a nearby city.
A method for consolidating daily pollutant concentrations into a monthly number
to match the monthly unemployment rate data is developed using individual threshold
for each pollutants using a rectifier function.
output:
  city_unemployment_rates.csv (consolidated csv with all cities unemployment rates per month)
  random_forest_importance.csv
  random_forest_std_dev_importance.csv



visualize_feature_importance.ipynb

To incorporate an independent method of feature importance, mutual information regression was used
to create a visual representation of the feature importance for each city.
This method was used to investigate using different thresholds for the aggregation of daily
pollutant data into monthly data.



visualize_economy_vs_aqi.ipynb

Feature importance from random forest models are used to create a weighted AQI 
Features more important to predicting the economy are used to weight the
contribution of each pollutant concentration to the AQI.
Animations showing the unemployment rate vs this AQI for 51 cities are created.
Time Series for each city are also made.
The cities_51_and_their_state.csv in the folder was created manually for the animation.