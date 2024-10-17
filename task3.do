////////////////////////////////////////////////////////////
// table: mean forward citations of secret patents

// load data
use "data__patent_citations.dta", clear

// run regressions using xtreg
foreach v in fcites fciters fclasses fother fself {

  eststo est_`v': ///
    areg `v' secret secrecy_eval i.grant_year, ///
    fe cluster(uspto_class)
    
  qui summ `v' if e(sample)==1, d
  local DVm=string(r(mean),"%9.2f")
  local DVsd=string(r(sd),"%9.2f")
  qui estadd local DVm "`DVm'"
  qui estadd local DVsd "`DVsd'"
  qui estadd local grantyrFE "Y"
  qui estadd local classyrFE "Y"
}

// output results to table
esttab est_fcites est_fciters est_fclasses est_fother est_fself ///
using "C:\Users\10345\Desktop\3.tex", replace ///
cells(b (star fmt(3)) se(par fmt(3) abs)) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(N r2 grantyrFE classyrFE DVm DVsd, fmt(%9.0f %9.2f %-3s %-3s %9.2f %9.2f) ///
labels("N" "\$R^2$" "Grant year FEs" "Class-year FEs" "Mean of DV" "s.d. of DV")) ///
mgroups("Outcomes:", pattern(1 0 0 0 0) ///
span prefix(\multicolumn{@span}{c}{) suffix(})) ///
mtitles("Cites" "Citers" "Citing classes" "Non-self" "Self") ///
eqlabels(none) collabels(,none) nonumbers label varwidth(24) ///
varlabels(secret "Secrecy ordered" secrecy_eval "Secrecy evaluated") ///
keep(secret secrecy_eval)

eststo clear
