
/// Question 2.Effect of compulsory secrecy on follow-on innovation

// 2.1 Plot PDF distributions required in Q2
use "C:\Users\10345\OneDrive\博士\IPEN_5140\replication1\replication\replication_package\regressions\data__patent_citations.dta"
twoway (kdensity fcites if secret == 1, color(red) lwidth(medium) lpattern(dash) legend(label(1 "Patents with Compulsory Secrecy"))) ///
       (kdensity fcites if secret == 0, color(black) lwidth(medium) lpattern(solid) legend(label(2 "Patents without Compulsory Secrecy"))), ///
       title("PDF of Forward Citations received by the patents with different Secrecy States") ///
       xlabel(0(30)150) ylabel(, angle(horizontal)) legend(order(1 2) position(11)) ///
	   xtitle("Forward Citations", size(large)) ///
	   ytitle("Density", size(large))
	   
	   // Provide statistical analysis between diverse forward citations 

summarize fcites if secret == 1, detail 
summarize fcites if secret == 0, detail

// Perform t test betweem 2 citations
ttest fcites, by(secret)

// 2.2 Repalce the dependent variable in Table 6 with use of poisson regressions
// create lists of variable and programs for regressions

capture program drop postStats
program define postStats
  local DV=e(depvar)
  qui summ `DV' if e(sample)==1, d
  local DVm=string(r(mean),"%9.2f")
  local DVsd=string(r(sd),"%9.2f")
  qui estadd local DVm "`DVm'"
  qui estadd local DVsd "`DVsd'"
end

local secrecy_vars_ext = "secret secrecy_eval"
local secrecy_vars_int = "secret secret_19* secrecy_eval secrecy_eval_19*"
local triplediff_vars = "all_secret* osrd_secret* all_secrecy_eval* osrd_secrecy_eval*"
local triplediff_vars = "`triplediff_vars' osrd_contractor"

local ctrls_base = "i.grant_year"
local ctrls_patent = "i.num_pages i.num_drawings i.num_inventors"
local ctrls_assignee = "assignee_firm assignee_indiv i.assignee_pats_1930s"
local ctrls_other = ""


// column 1: all assignees, column 2: non-osrd contractors only, column 3: osrd contractors only, columns 4-5: triple difference
eststo: ppmlhdfe fcites `secrecy_vars_int' , absorb(grant_year class_yr) cluster(uspto_class)
eststo: ppmlhdfe fcites `secrecy_vars_int' if osrd_contractor==0, absorb(grant_year class_yr) cluster(uspto_class)
eststo: ppmlhdfe fcites `secrecy_vars_int' if osrd_contractor==1, absorb(grant_year class_yr) cluster(uspto_class)
eststo: ppmlhdfe fcites `triplediff_vars' , absorb(grant_year class_yr) cluster(uspto_class)

// Add the FE flags
quietly {
forval x=1/4 {
  estimates restore est`x'
  if `x'<=4 postStats // post info on DV
  estadd local grantyrFE "Y"
  estadd local classyrFE "Y"
}
}

// 修改后的 esttab 代码，保存为 tex 格式
esttab est1 est2 est3 est4 /// 
using "C:\Users\10345\Desktop\2.tex", replace /// 
cells(b(star fmt(3)) se(par fmt(3) abs)) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(N r2 grantyrFE classyrFE DVm DVsd, fmt(%9.0f %9.2f %-3s %-3s %9.2f %9.2f) ///
labels("N" "\$R^2$" "Grant Year FEs" "Class-Year FEs" "Mean of DV" "s.d. of DV")) ///
mtitles("All" "Non-OSRD" "OSRD" "Triple Diff.") ///
eqlabels(none) collabels(, none) nonumbers label varwidth(24) ///
varlabels(secret "Secrecy Ordered" secrecy_eval "Secrecy Evaluated" ///
secret_1940 " * Filed in 1940" secrecy_eval_1940 " * Filed in 1940" ///
secret_1941 " * Filed in 1941" secrecy_eval_1941 " * Filed in 1941" ///
secret_1942 " * Filed in 1942" secrecy_eval_1942 " * Filed in 1942" ///
secret_1943 " * Filed in 1943" secrecy_eval_1943 " * Filed in 1943" ///
secret_1944 " * Filed in 1944" secrecy_eval_1944 " * Filed in 1944" ///
secret_1945 " * Filed in 1945" secrecy_eval_1945 " * Filed in 1945" ///
_cons "Constant") keep(`secrecy_vars_int' `triplediff_vars')

eststo clear

