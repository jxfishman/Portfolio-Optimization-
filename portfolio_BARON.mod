set ASSETS ordered;  #do not alphabetize
param price {ASSETS} > 0;
param budget > 0;
param gamma default 0.9;      
param cov {ASSETS, ASSETS} default 0;             # covariance for all combinations of two stocks
param return_ind {ASSETS} default 0;              # return for each stock
param coskew {ASSETS, ASSETS, ASSETS} default 0;  # skew for all combinations of three stocks
param target_skew; 
     
var buy {i in ASSETS} binary;  				# 1 stock is bought, 0 if not
var shares {i in ASSETS} integer >= 0, <=1000;           # Number of shares must be between 0 and 100

# constraint to not allocate shares if shock was not chosen
subject to Limit_Shares {i in ASSETS}:
    shares[i] <= 100 * buy[i];

# constraint to buy at least 1 share
subject to Min_One_Share {i in ASSETS}:
    shares[i] >= buy[i];

# constraint to use all of allocated budget
subject to Full_Allocation:
    sum {i in ASSETS}  shares[i] * price[i] >= budget*0.90;

# constraint to not exceed budget
subject to Budget_Limit:
    sum {i in ASSETS}  shares[i] * price[i] <= budget;

# number of stocks constraint
subject to Exactly_20_Stocks:
    sum {i in ASSETS} buy[i] = 20;

# minimum skew constraint
subject to Min_Skew:
    sum {i in ASSETS, j in ASSETS, k in ASSETS: ord(i) <= ord(j) <= ord(k)} 
        ( shares[i]*price[i]/budget) * (shares[j]*price[j]/budget) *  (shares[k]*price[k]/budget) * coskew[i,j,k] >= target_skew;

# minimize risk (Variance) 
# minimize Portfolio_Variance:
#    sum {i in ASSETS, j in ASSETS} (shares[i]*price[i]/budget) * (shares[j]*price[j]/budget) * cov[i,j];

#minimize risk minus return
minimize Risk_Adjusted_Return:
gamma * (sum {i in ASSETS, j in ASSETS} ( shares[i]*price[i]/budget) * ( shares[j]*price[j]/budget) * cov[i,j])  
     - (1 - gamma) * (sum {i in ASSETS} (shares[i]*price[i]/budget) * return_ind[i]);