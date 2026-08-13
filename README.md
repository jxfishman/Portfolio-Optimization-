
# Quantum Portfolio Optimization 

## Introduction

This project compares the performance of D-Wave hybrid quantum annealing solvers to state of the art classical optimization programs by tasking both approaches with the optimization of financial portfolios.  In the era of NISQ computing, quantum annealing may be the best quantum computing option for portfolio optimization.  Gate based approaches employing QAOA and VQE are other possibilities, but the present hardware limitations of gate based systems present challenges to their use.<sup>1</sup>  The portfolio optimization model for this project conforms to the foundational and widely used standard: modern portfolio theory, in that its objective function maximizes returns and minimizes risk.  However, a third order constraint that limits the negative skew of the portfolio is added.  Skew is a third order moment which makes the problem a non convex, Mixed Integer Nonlinear Problem (MINLP).

## Theory

### Modern Portfolio Theory  

The portfolio optimization model for this project is the Markowitz mean-variance model, otherwise known as Modern Portfolio Theory or Markowitz Portfolio Theory(MPT).    In 1952, Harry Markowitz published the mathematics of MPT, an optimization approach based on the diversification of assets within a portfolio.<sup>2</sup>  Markowitz received the Nobel Prize in Economic Sciences for this foundational contribution to the field of wealth management.<sup>3</sup>  Key to MPT is the idea that the covariance of securities -  the extent to which securities track each other’s movements over time -  can be used to mitigate risk.<sup>4</sup> 
The model considers only the mean returns and variances of assets in its formulation.  Research into including additional parameters, such as skew (sometimes described as the difference between the median and the mean of the return distribution)  has not shown that additional complexity yields better returns.<sup>4</sup>   In the interest of investigating performance, the impacts of modifying the model by adding skew as a constraint are explored in this project.


### Problem Definition and Complexity

#### Portfolio Optimization Objective Function

Quantum annealers are designed to solve combinatorial optimization problems like portfolio optimization.  They are physical implementations of Ising models, which mathematically express how elements of a complex system respond to the couplings that exist between them and the external forces that are exerted on them. 
The objective function configures the energy state of the annealer so that it represents the parameters of the problem.  The annealer naturally minimizes its energy state to yield a combination of output values that correspond to an optimal solution.  Solutions are obtained by sampling low energy states at the end of the annealing process.  

Portfolio optimization is mathematically modeled as a Quadratic Unconstrained Binary Optimization (QUBO) problem -  converting QUBO equations to Ising form requires only a simple linear transformation.  

$$\min_{x \in \{0,1\}^n} \left( \sum_{i=1}^n \sum_{j=1}^n Q_{ij} x_i x_j + \sum_{i=1}^n b_i x_i \right)$$
$$\text{Eq. 1 Quadratic Unconstrained Binary Optimization (QUBO) problem}$$

Eq. 1 shows an example QUBO minimization equation.  A solver would choose values for binary variables in the vector x such that the sum of all the terms is minimized.  The first term in the QUBO problem incorporates the strengths of the couplings between elements into the equation.  For example, if  $$Q_ij$$ is highly negative, the system is incentivized to set  both $$x_i$$ and $$x_j$$ to 1.  The second term represents the cost or penalty for setting $$x_i$$ to 1.  If $$b_i$$ is high, the system is incentivized not to include $$x_i$$.

$$\min H' = \alpha \left( \sum_{i=1}^n \sum_{j=1}^n \sigma_{ij} p_i x_i p_j x_j \right) - \left( \sum_{i=1}^n \bar{r}_i p_i x_i \right) + \lambda \left( \sum_{i=1}^n p_i x_i - B \right)^2$$
$$\text{Eq. 2 Portfolio optimization QUBO}$$

Eq. 2 shows an example  of a portfolio optimization QUBO.
The variables are:
<table>
           <tr><td>$\alpha$ = risk aversion coefficient</td></tr>
           <tr><td>n = total number of stocks </td></tr>
           <tr><td>$r_i$ = average monthly percent return for stock i</td></tr>
           <tr><td>$\sigma$ = covariance of returns of stocks i and j </td></tr>
           <tr><td>$p_i$ = price of stock i</td></tr>
           <tr><td>$x_i$ = number of shares of stock i</td></tr>
           <tr><td>$\lambda$ = penalty term coefficient</td></tr>
           <tr><td>B = the budget - term is squared to force the solver to favor valid solutions</td></tr>
</table>
This equation requires the solver to find not only which assets in x should be included in the portfolio, but also how many shares of those assets are best.  To produce integer results for numbers of shares,  a binary expansion method must be used:
<br>  

$$x_i = \sum_{b=0}^{k_i - 1} 2^b z_{ib}$$
$$\text{Eq. 3 Binary Expansion of Integer}$$  

A typical portfolio optimization problem is quadratic due to the covariance term of the objective function and has only linear constraints, no cardinality and continuous variables.  

$$\alpha \left( \sum_{i=1}^n \sum_{j=1}^n \sigma_{ij} p_i x_i p_j x_j \right)$$
$$\text{Covariance term of objective function}$$

           

A large-scale problem of this type is reliably and efficiently solvable on a classical computer.<sup>5</sup> 
Three challenging constraints are added to make the problem a more challenging Mixed Integer NonLinear Problem (MINLP) type and increase optimization complexity.   

### Constraints

**Constraint 1: Cardinality**  
Limiting the number of assets in a portfolio reduces transaction costs, tax reporting complexity, and management effort.  However, allowing only a certain number of stocks in the portfolio out of the universe under consideration imposes a cardinality constraint on the problem, which has been shown to make it NP-complete - as the number of assets increases, the number of possible combinations for the portfolio grows exponentially. <sup>6</sup>

**Constraint 2: Skew**  
The skew of a distribution is the amount to which it has a positive or negative tail.  More technically, it is a distribution's third standardized moment:

$$\mu_3 = E \left[ \frac{X - \mu}{\sigma} \right]^3$$
$$\text{Eq. 4  Skew Equation for a distribution, E: expected value,  X: variable, } \mu \text{: mean, }\sigma\text{: std dev}$$

A positive skew manifests as a significant tail on the right side, and a negative skew as a tail on the left.  In the case of assets such as stocks, investors consider a returns distribution with a positive skew desirable, as it indicates a tendency toward a greater number of days with nominal or even dramatic positive returns.  

Considering coskew, a measure of how stocks skew together - similar to covariance being a measure of how the variance of a stock aligns with the variance of another stock - introduces a third order term to the portfolio optimization problem.  The skew of a portfolio is arrived at by summing all possible combinations of three stocks (out of those that are chosen for the portfolio)  multiplied by a coskew factor that quantifies how much the three stocks skew together.  

Highly performing individual stocks often have positively skewed return distributions but the same can not always be said for strong portfolios or markets.  This is because economic downturns or panics can spark extreme negative swings in aggregate returns, creating a negative tail, while positive movements on average are more restrained.

The N x N x N coskewness tensor is calculated using the formula:

$$S(X,Y,Z) = \frac{E[(X - E[X])(Y - E[Y])(Z - E[Z])]}{\sigma_X \sigma_Y \sigma_Z}$$
$$\text{Eq. 5  Coskew Equation, E: expected value,  X,Y,Z: variables, } \sigma \text{: std dev}$$ 



**Constraint 3: Maximum number of shares**
Constraining the maximum number of shares per stock puts a hard limit on the amount that can be invested in a single stock.


## Ocean SDK and D-Wave Models

The D-Wave Ocean software development kit is an open source Python based tool set for developing quantum annealing optimization applications.  It is compatible with Python versions 3.10 or higher and can be installed on Linux, Windows, and Mac systems.  It is cloud accessible on GitHub or any environment that implements development containers.  Up to 2,000,000 variables and constraints are supported.

The SDK offers four main mathematical model types with which the QUBO may be implemented. The four model  types and their use cases are shown in Table 1.  The Constrained Quadratic (CQM)  and Non-Linear(NLM) models natively support the encoding of constraints, rather than requiring them to be added to the objective function as penalty terms, as is the case with the BQM and DQ types. 7  CQM does not support third order terms, NLM does.
 
Model
Use Cases
Binary Quadratic (BQM)
Binary decision problems
Constrained Quadratic (CQM)
Real world optimization
Discrete Quadratic (DQ)
Problems with integer variables or categories (map coloring)
Non-Linear (NLM)
Mixed integer nonlinear optimization and complex math

Table 1


 Hybrid solvers utilize both quantum and classical hardware. The parts of the problem that are best solved classically are handled by CPUs or GPUs, leaving the rest for the annealer’s Quantum Processing Unit(QPU).8   



## Method

### Stock Universe and Historical Data

A list of equities was compiled using Yahoo Finance screeners.  I diversified asset types by including Exchange Traded Funds (ETFs) that are limited to different types of bonds (government and corporate included) and EFTs that track the commodity prices of gold and silver.  From the over 10,000 equities with available data on Yahoo Finance, I filtered for bond ETFs, two ETFs that tracked the metals gold and silver, and all stocks listed on the  Dow, S & P, and  Russell 2000 indexes.  Unfortunately, I was constrained by the size of the RAM of the virtual machine I was using on my Github codespace (16 GB).  The coskew tensor grows exponentially O(n^3) with the number of equities and is a NumPy array that I believe must exist in a contiguous memory block.  I didn’t have enough time to find a work around, but I did try exhaustively to find out why Github would not give me the option for a higher performance machine with at least 32GB RAM.  I upgraded to Enterprise level and still was not offered a better machine option.  I therefore filtered the stocks based on several parameters to exclude higher risk companies.  Historical daily closing price data for the filtered set of equities over the three year period from 1/1/2021 to 12/31/2023 were downloaded using the YFinance python library.  The mean returns, covariance matrix, and coskewness tensor were calculated for all stocks using Python libraries including NumPy and Pandas.
<table>
  <thead>
    <tr>
      <th style="text-align: left;">Filter Metric</th>
      <th style="text-align: left;">Requirement</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Price (Intraday)</td>
      <td>&gt; $10</td>
    </tr>
    <tr>
      <td>Index</td>
      <td>Dow, S&amp;P, Russell 2000</td>
    </tr>
    <tr>
      <td>Employees (FY)</td>
      <td>&gt; 200</td>
    </tr>
    <tr>
      <td>Market Cap (Intraday)</td>
      <td>&gt; $1B</td>
    </tr>
    <tr>
      <td>Avg Vol (3 month)</td>
      <td>&gt; 500K</td>
    </tr>
    <tr>
      <td>Cash on Hand</td>
      <td>&gt; $20M</td>
    </tr>
    <tr>
      <td>Debt/Equity (D/E) %</td>
      <td>&lt; 200%</td>
    </tr>
    <tr>
      <td>Short % of Shares Outstanding</td>
      <td>&lt; 15%</td>
    </tr>
    <tr>
      <td>% of Shares Outstanding Held by Insider</td>
      <td>&lt; 30%</td>
    </tr>
  </tbody>
</table>



### Objective Function and Constraints 

A QUBO was formulated to serve as the objective function of the optimization problem.  Both the classical BARON model and the D-Wave NL model implemented this same objective function:

$$\gamma \left( \sum_{i,j} \left( \frac{\text{shares}_i \cdot \text{price}_i}{\text{budget}} \right) \left( \frac{\text{shares}_j \cdot \text{price}_j}{\text{budget}} \right) \text{cov}_{i,j} \right) - (1 - \gamma) \left( \sum_i \left( \frac{\text{shares}_i \cdot \text{price}_i}{\text{budget}} \right) \text{return}_i \right)$$


The problem involves  two sets of decision variables, “shares” and “stocks”.  In the above equation, the  integer variable “shares” holds the number of shares to be bought for each stock under consideration.  A binary variable, labeled  “stocks” in the constraints holds a 1 if the stock is chosen for the portfolio and a 0 if it is not.
Both models imposed the following constraints: 


1. Do not allocate shares if stock was not chosen and do not allocate more than 100 shares to any stock:
   $$shares_i <= 100* stocks_i$$
2. If a stock is selected, buy at least one share:        $$shares_i  >= stocks_i$$ 
3. Use at least 90% of the allocated budget.          $$\sum_{i}^n \left(shares_i*price_i \right) >= 0.90 * budget$$    
4. Do not exceed the specified budget:                $$\sum_{i}^n \left(shares_i*price_i \right) <= budget$$
5. Choose exactly 20 stocks for the portfolio:        $$\sum_{i}^n stocks_i = 20$$
6. The skew of the portfolio should be greater than a minimum target skew of -0.15.
       

### Classical Solvers

State of the art classical MINLP solvers use branch and bound algorithms to find optimal solutions.  Branch and bound outperforms brute force search by pruning branches of the search space that are determined to be unable to produce an optimal result.  Meta heuristics like simulated annealing and genetic algorithms, are used in tandem with branch and bound to further improve efficiency.9
I did not perform an exhaustive search for the best classical model to use for comparison.  The BARON solver handles MINLPs, outperforms or matches the performance of other comparable solvers against benchmarks and is widely regarded as state of the art.10  CPLEX and IPOPT solvers were also tested with problems that did not include skew.  I used CPLEX to test out my problem before submitting it to NEOS or to the D-Wave hybrid solvers so that I didn’t waste my allocated hybrid solver time.  
For the BARON model,  the objective function and constraints were encoded in AMPL and submitted to the UW-Madison NEOS server.   The BARON and D-Wave NLM implementations share all the same constraints and have equivalent objective functions.


### D-Wave Implementation

Two D-Wave model types were implemented:  CQM and NLM.  The CQM does not support third order terms so the skew constraint was not included in its implementation.  Models were run on D-Wave’s hybrid solvers. D-Wave had me attend a Zoom meeting with a salesman and technical advisor before approving me for the 3 month launch program.  The Leap dashboard indicates that I have an hour of solver time.  I don’t know if that is an hour of time for the month or an hour of time for the entire trial period.  


### Code

The Data_Collection_CPLEX_AMPL.ipynb file contains Python functions for a number of purposes:
1. Downloading YFinance data: get_stocks_from_screener()
2. Calculating mean, covariance, and coskew: get_stock_info()
3. Running the CPLEX solver: run_CPLEX()
4. Backtesting solutions (calculating return, risk, and Sharpe ratio for a portfolio): backtest(), risk()
5. Generating AMPL .dat file to submit to the NEOS servers: generate_ampl_dat()
   
Portfolio_BARON.mod is the AMPL model that was submitted to BARON.  Portfolio_BARON.dat is the AMPL data file that was generated with the Python function generate_ampl_dat() found in Data_Collection_CPLEX_AMPL.ipynb.

The GitHub codespace is derived from  a D-Wave template codespace.  The template provides a preconfigured development environment with all Ocean libraries already installed.  The CQM model generating function, build_cqm() is found in CQM_Model.py.  The function portfolio_opt() found in NonLinear_Model.py builds the NL model. 

All data collecting and gathering code can be found in Data_Collection_CPLEX_AMPL.ipynb.  

Files included in classical_methods folder:

- BARON_results_DOW30.txt - Direct output from BARON for DOW 30 problem
- Bond ETFs.csv - Yahoo screener file for bond etfs
- Commands.run - Command file used when submitting BARON model to NEOS
- Data_Collection_CPLEX_AMPL.ipynb - Data collection and processing, CPLEX code
- portfolio_BARON.dat - BARON data submitted to NEOS for 80 stock problem
- portfolio_BARON.mod - BARON model submitted to NEOS
- Real_Estate.csv - Yahoo screener file for real estate etfs
- The Dow The Dow The Dow Right Now.csv - Yahoo screener file for the DOW 30

### Backtesting
Portfolios produced by the classical and D-Wave solvers were backtested over a time period from 1/1/24 to 4/14/2026.  The return, risk, and sharp ratio were computed for the backtested portfolios.


## Results
**Universe: DOW 30**
**Budget:$10,000, Coskew limit: -0.15, maximum shares per stock: 100**
#### Overall Performance

<table>
        <thead>
            <tr>
                <th>Solver</th>
                <th>Number of Stocks</th>
                <th>Number of Variables</th>
                <th>Number of Constraints</th>
                <th>Execution Time</th>
                <th>QPU Access Time*</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>BARON</td>
                <td>30</td>
                <td>60</td>
                <td>64</td>
                <td>4 m : 43 s</td>
                <td>n/a</td>
            </tr>
            <tr>
                <td>D-Wave hybrid NL</td>
                <td>30</td>
                <td>60</td>
                <td>64</td>
                <td>1 m : 02 s</td>
                <td>1.5 s</td>
            </tr>
        </tbody>
</table>


<table>
        <thead>
            <tr>
                <th>Solver</th>
                <th>Number of Stocks Chosen (Constrained to exactly 20)</th>
                <th>Amount of $10,000 Budget Spent</th>
                <th>Portfolio Return %</th>
                <th>Portfolio Risk %</th>
                <th>Sharp Ratio</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>BARON</td>
                <td>14</td>
                <td>$8,672.83</td>
                <td>43.56</td>
                <td>26.02</td>
                <td>1.52</td>
            </tr>
            <tr>
                <td>D-Wave hybrid NL</td>
                <td>20</td>
                <td>$9,923.40</td>
                <td>79.74</td>
                <td>24.04</td>
                <td>3.15</td>
            </tr>
        </tbody>
</table>

*QPU Access Time:  the time to execute a single quantum machine instruction on a QPU.  Quantum anneal times are shown in green. There are multiple sampling cycles and so multiple annealing times.

<img src = "images/QPU_access_time.png" alt = "Operation and Timing image" width = 200px height = 200px>
Source: D-Wave, ![Operation and Timing](https://docs.dwavequantum.com/en/latest/quantum_research/operation_timing.html?)



<table>
        <thead>
            <tr>
                <th rowspan="2">Stock</th>
                <th colspan="2">Number of Shares</th>
                <th rowspan="2">Price per share on 1/01/2024</th>
                <th rowspan="2">Cost D-Wave NLH</th>
                <th rowspan="2">Cost BARON</th>
                <th rowspan="2">Price per share on 4/02/2026</th>
                <th rowspan="2">Return D-Wave</th>
                <th rowspan="2">Return BARON</th>
            </tr>
            <tr>
                <th>D-Wave NLH</th>
                <th>BARON</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td >AAPL</td>
                <td>2</td>
                <td>0</td>
                <td>$183.73</td>
                <td>$381.10</td>
                <td>$0.00</td>
                <td>$255.92</td>
                <td>$144.38</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >AMGN</td>
                <td>3</td>
                <td>1</td>
                <td>$277.64</td>
                <td>$806.69</td>
                <td>$268.90</td>
                <td>$347.94</td>
                <td>$210.89</td>
                <td>$70.30</td>
            </tr>
            <tr>
                <td >AMZN</td>
                <td>2</td>
                <td>0</td>
                <td>$149.93</td>
                <td>$303.88</td>
                <td>$0.00</td>
                <td>$209.77</td>
                <td>$119.68</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >AXP</td>
                <td>4</td>
                <td>1</td>
                <td>$183.11</td>
                <td>$728.67</td>
                <td>$182.17</td>
                <td>$300.18</td>
                <td>$468.27</td>
                <td>$117.07</td>
            </tr>
            <tr>
                <td >BA</td>
                <td>0</td>
                <td>0</td>
                <td>$251.76</td>
                <td>$0.00</td>
                <td>$0.00</td>
                <td>$208.22</td>
                <td>$0.00</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >CAT</td>
                <td>1</td>
                <td>1</td>
                <td>$283.14</td>
                <td>$286.00</td>
                <td>$286.00</td>
                <td>$717.22</td>
                <td>$434.08</td>
                <td>$434.08</td>
            </tr>
            <tr>
                <td >CRM</td>
                <td>1</td>
                <td>0</td>
                <td>$252.42</td>
                <td>$259.33</td>
                <td>$0.00</td>
                <td>$186.71</td>
                <td>-$65.71</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >CSCO</td>
                <td>12</td>
                <td>1</td>
                <td>$47.18</td>
                <td>$566.25</td>
                <td>$47.19</td>
                <td>$79.02</td>
                <td>$382.10</td>
                <td>$31.84</td>
            </tr>
            <tr>
                <td >CVX</td>
                <td>0</td>
                <td>9</td>
                <td>$135.63</td>
                <td>$0.00</td>
                <td>$1,218.06</td>
                <td>$198.97</td>
                <td>$0.00</td>
                <td>$570.06</td>
            </tr>
            <tr>
                <td >DIS</td>
                <td>1</td>
                <td>0</td>
                <td>$88.91</td>
                <td>$88.50</td>
                <td>$0.00</td>
                <td>$96.61</td>
                <td>$7.70</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >GS</td>
                <td>0</td>
                <td>0</td>
                <td>$369.59</td>
                <td>$0.00</td>
                <td>$0.00</td>
                <td>$863.04</td>
                <td>$0.00</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >HD</td>
                <td>1</td>
                <td>0</td>
                <td>$326.45</td>
                <td>$327.84</td>
                <td>$0.00</td>
                <td>$321.63</td>
                <td>-$4.82</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >HON</td>
                <td>1</td>
                <td>0</td>
                <td>$187.81</td>
                <td>$188.45</td>
                <td>$0.00</td>
                <td>$229.45</td>
                <td>$41.64</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >IBM</td>
                <td>3</td>
                <td>5</td>
                <td>$151.08</td>
                <td>$458.99</td>
                <td>$764.98</td>
                <td>$248.16</td>
                <td>$291.25</td>
                <td>$485.41</td>
            </tr>
            <tr>
                <td >JNJ</td>
                <td>0</td>
                <td>1</td>
                <td>$149.66</td>
                <td>$0.00</td>
                <td>$146.64</td>
                <td>$243.04</td>
                <td>$0.00</td>
                <td>$93.38</td>
            </tr>
            <tr>
                <td >JPM</td>
                <td>10</td>
                <td>1</td>
                <td>$163.01</td>
                <td>$1,611.34</td>
                <td>$161.13</td>
                <td>$293.10</td>
                <td>$1,300.91</td>
                <td>$130.09</td>
            </tr>
            <tr>
                <td >KO</td>
                <td>9</td>
                <td>1</td>
                <td>$56.00</td>
                <td>$496.49</td>
                <td>$55.17</td>
                <td>$76.72</td>
                <td>$186.49</td>
                <td>$20.72</td>
            </tr>
            <tr>
                <td >MCD</td>
                <td>0</td>
                <td>5</td>
                <td>$281.83</td>
                <td>$0.00</td>
                <td>$1,406.62</td>
                <td>$307.14</td>
                <td>$0.00</td>
                <td>$126.56</td>
            </tr>
            <tr>
                <td >MMM</td>
                <td>1</td>
                <td>1</td>
                <td>$86.86</td>
                <td>$86.32</td>
                <td>$86.32</td>
                <td>$144.47</td>
                <td>$57.61</td>
                <td>$57.61</td>
            </tr>
            <tr>
                <td >MRK</td>
                <td>0</td>
                <td>20</td>
                <td>$105.46</td>
                <td>$0.00</td>
                <td>$2,030.53</td>
                <td>$120.87</td>
                <td>$0.00</td>
                <td>$308.27</td>
            </tr>
            <tr>
                <td >MSFT</td>
                <td>2</td>
                <td>1</td>
                <td>$364.59</td>
                <td>$739.34</td>
                <td>$369.67</td>
                <td>$373.46</td>
                <td>$8.87</td>
                <td>$8.87</td>
            </tr>
            <tr>
                <td >NKE</td>
                <td>0</td>
                <td>0</td>
                <td>$101.67</td>
                <td>$0.00</td>
                <td>$0.00</td>
                <td>$44.19</td>
                <td>$0.00</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >NVDA</td>
                <td>35</td>
                <td>15</td>
                <td>$48.14</td>
                <td>$1,732.21</td>
                <td>$742.38</td>
                <td>$177.39</td>
                <td>$4,523.80</td>
                <td>$1,938.77</td>
            </tr>
            <tr>
                <td >PG</td>
                <td>2</td>
                <td>1</td>
                <td>$140.39</td>
                <td>$276.64</td>
                <td>$138.32</td>
                <td>$143.12</td>
                <td>$5.45</td>
                <td>$2.73</td>
            </tr>
            <tr>
                <td >SHW</td>
                <td>0</td>
                <td>0</td>
                <td>$299.04</td>
                <td>$0.00</td>
                <td>$0.00</td>
                <td>$318.00</td>
                <td>$0.00</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >TRV</td>
                <td>0</td>
                <td>1</td>
                <td>$184.31</td>
                <td>$0.00</td>
                <td>$183.42</td>
                <td>$293.99</td>
                <td>$0.00</td>
                <td>$109.68</td>
            </tr>
            <tr>
                <td >UNH</td>
                <td>1</td>
                <td>1</td>
                <td>$514.26</td>
                <td>$501.99</td>
                <td>$501.99</td>
                <td>$277.26</td>
                <td class="negative">-$237.00</td>
                <td class="negative">-$237.00</td>
            </tr>
            <tr>
                <td >V</td>
                <td>0</td>
                <td>0</td>
                <td>$254.57</td>
                <td>$0.00</td>
                <td>$0.00</td>
                <td>$300.80</td>
                <td>$0.00</td>
                <td>$0.00</td>
            </tr>
            <tr>
                <td >VZ</td>
                <td>1</td>
                <td>1</td>
                <td>$33.02</td>
                <td>$32.02</td>
                <td>$32.02</td>
                <td>$48.67</td>
                <td>$15.64</td>
                <td>$15.64</td>
            </tr>
            <tr>
                <td >WMT</td>
                <td>1</td>
                <td>1</td>
                <td>$51.86</td>
                <td>$51.33</td>
                <td>$51.33</td>
                <td>$125.79</td>
                <td>$73.93</td>
                <td>$73.93</td>
            </tr>
            <tr >
                <td >Totals:</td>
                <td>93</td>
                <td>68</td>
                <td></td>
                <td>$9,923.38</td>
                <td>$8,672.84</td>
                <td></td>
                <td>$7,794.03</td>
                <td>$4,358.01</td>
            </tr>
        </tbody>
    </table>

         
**Universe:** 80 equities

60 Bond ETFs, Gold ETF, Silver ETF, Dow 30, 30 dividend paying real estate stocks (model does not account for dividends)

**Budget:** $1,000,000, **Coskew limit:** -0.15, **maximum shares per stock:** 10000

`dwave.cloud.exceptions.SolverFailureError: The size of the states must not exceed 786432000.`

With this problem I got an error from dwave. I tried reimplementing the NL model in a more memory efficient way but got poor results as can be seen in the chart below. I have not been able to resolve this poor performance. This model performed similarly to the first NL implementation on the DOW 30 problem .

### Overall Performance

| Solver | Number of Stocks | Number of Variables | Number of Constraints | Execution Time | QPU Access Time* |
| :--- | :---: | :---: | :---: | :---: | :---: |
| BARON | 80 | 160 | 164 | 3 m 30 s . | n/a |
| D-Wave hybrid NL | 80 | 160 | 164 | 1 m 0.34 s | 1.738 s |

<br>

| Solver | Number of Stocks Chosen (Constrained to exactly 20) | Amount of $1,000,000 Budget Spent | Portfolio Return % | Portfolio Risk % | Sharp Ratio |
| :--- | :---: | :---: | :---: | :---: | :---: |
| BARON | 20 | $1,001,829.99 | 48.87% | 15.04 | 2.98 |
| D-Wave hybrid NL | 20 | $900,005.03 | 12.41% | 16.87% | 0.5 |


## Discussion

The D-Wave hybrid NL solver performed well compared to the BARON model for my small 30 stock MINLP test case. It delivered a portfolio that had greater return, lower risk, and met the cardinality constraint of the problem (BARON missed it significantly). For the experiments with the larger universe of 590 stocks, the D-Wave CQM respected the cardinality constraint better than CPLEX did with being asked to choose 100 stocks from a universe of 590 stocks, but produced a substantially poorer performing portfolio. I could not get the CPLEX solver to choose more than 30 to 40 stocks for this case, so it is hard to fairly compare the two. However, when asked to choose 30 out of 590, the CQM only chose 19, while CPLEX chose the full 30. I could not find any constraints that would make it infeasible for the CQM to choose the entire number of 30 stocks.

Coskewness dramatically changes the problem and can not be handled for large problem sizes with the limited computing power I have access to. The size of the coskew tensor grows exponentially with the number of stocks and limited the size of the problem that I could run. For a problem size of n stocks, there are \(\frac{(k+n-1)!}{k!(n-1)!}\) combinations, k = 3. For 30 stocks, this number of coskewness coefficients is 4960. For 1500 stocks it is 5.64 E+8. If 32 bit floating point numbers are used, 1500 stocks require 2.3 GB of memory. NEOS limits uploaded file size to 16 MB, so I could not compare performance to BARON using more than around 250 stocks.

Adding the quadratic covariance term of my QUBO to the CQM objective function using the Ocean SDK was quite slow if working with more than 100 or so stocks. I tried using only 32 bit NumPy arrays and finding more efficient implementations, (trying to avoid inefficient nested for loops when possible) which did deliver a speed up, but was not successful in getting the D-Wave models to build quickly on the GitHub codespace. The largest problem size I solved consistently using the CQM (no coskew) is 590 stocks. Adding the coskewness constraint makes matters even worse. I was able to optimize the nonlinear model building code, but it still took 2 minutes to execute for a problem of around 80 stocks.

I spoke with a D-Wave technical advisor, Ken Robbins, when I signed up for the LaunchPad account. His opinion was that portfolio optimization is not an area in which quantum annealing will excel over classical solvers. The limited results of this project support that this does seem to be the case. Classical solvers appear to more than adequately meet the real world demands of investment managers. The annealer, however, did outperform BARON with the coskewness third order MINLP, so perhaps there is some utility in the area of finance or another field in which a MINLP like this may occur. Robbins suggested a trade timing project, but I was already committed to portfolio optimization. There is a lot of exploration that can be done using the different D-Wave models and adjusting parameters and constraints. Code optimization skills are needed to accelerate the processing of large problems. It was interesting to experiment with the models and see how their portfolios changed under the different constraints. Further investigation would help with understanding more about the strengths and weaknesses of D-Wave’s hybrid quantum solvers in the context of MINLPs. The work that I have done, although it required a lot of research and time, did not sufficiently enlighten me.
