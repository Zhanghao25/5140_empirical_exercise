// 加载回归样本数据
use "data__assignee__nber_cat.dta", replace

// 循环处理不同企业类型
forval a=0/2 {

  if      `a'==0 local subsample="1==1" // 全样本
  else if `a'==1 local subsample="osrd_contractor==0" // 非OSRD承包商
  else if `a'==2 local subsample="osrd_contractor==1" // OSRD承包商
  
  // 循环处理不同的进入条件（Incumbency Conditions）
  if `a'==0 local I=5
  else local I=1
  forval i=1/`I' {
  
         if `i'==1 local cond_incumbency="self_incat_pre1939>=1" // 本地企业，有战前专利
    else if `i'==2 local cond_incumbency="self_incat_pre1939>=1 & self_total_pre1939>=01 & self_total_pre1939<=20"  // 小型企业
    else if `i'==3 local cond_incumbency="self_incat_pre1939>=1 & self_total_pre1939>=21 & self_total_pre1939<=1e6" // 大型企业
    else if `i'==4 local cond_incumbency="self_incat_pre1939==0 & year>=1940" // 本地新进入者，无战前专利
    else if `i'==5 local cond_incumbency="self_total_pre1939==0 & year>=1940" // 全球新进入者，无战前专利
    
    preserve
    
    // 一些过滤条件加快处理
    keep if `cond_incumbency'
    if inlist(`i',1,2,3) {
      local absorb="assignee_cat"
      local fe1="Y"
      local fe2=""
    }
    else if inlist(`i',4,5) {
      drop if year<=1939
      capture drop *period1 *t1
      capture drop *1931 *1932 *1933
      capture drop *1934 *1935 *1936
      capture drop *1937 *1938 *1939
      capture drop self_incat_secrate_q2
      capture drop self_incat_secrate_q3
      local absorb="ones"
      local fe1=""
      local fe2="Y"
    }
    
	// Q1a: 使用逻辑回归估计，标准误差聚类
	eststo self_incat__cont__a`a'_i`i': ///
	logit any_patent self_incat_secrate_t* self_incat_secrate period* `ctrls1a' if ///
	`cond_incumbency'       & /// incumbency condition
	self_incat_midwar>=1    & /// had midwar patents in given cat
	self_incat_secrate>0    & /// had midwar secrecy orders in given cat
	(year<=1939 | year>=1946) & `subsample', /// 
	cluster(assignee)

	estadd local fe1 "`fe1'"
	estadd local fe2 "`fe2'"

    
    restore
  }

}

// 准备固定效应标签
if "nber_cat"=="uspto_class" {
  local FEs1="Assignee x USPC FEs"
  local FEs2="USPC FEs"
}
else if "nber_cat"=="nber_cat" {
  local FEs1="Assignee x NBER Cat FEs"
  local FEs2="NBER Cat FEs"
}

// 准备变量标签
local Q1a="(0,0.25]"
local Q2a="(0.25,0.75]"
local Q3a="(0.75,1]"

// 保存逻辑回归结果为 CSV 格式
esttab ///
self_incat__cont__a0_i1 /// 
self_incat__cont__a1_i1 /// 
self_incat__cont__a2_i1 /// 
self_incat__cont__a0_i2 /// 
self_incat__cont__a0_i3 /// 
self_incat__cont__a0_i4 /// 
self_incat__cont__a0_i5 /// 
using "C:/Users/10345/Desktop/1.tex", replace ///
cells(b (star fmt(3)) se(par fmt(3) abs)) starlevels(* 0.1 ** 0.05 *** 0.01) ///
stats(N r2 fe1 fe2, fmt(%9.0f %9.2f %-3s %-3s) labels("N" "\$R^2$" "`FEs1'" "`FEs2'")) ///
mtitles("All" "Non-OSRD" "OSRD" "Small" "Large" "Entrant" "Entrant") ///
eqlabels(none) collabels(,none) numbers label varwidth(48) ///
varlabels( ///
  self_incat_secrate_t1 "Wartime Sec. Rate * (1935-39)" ///
  self_incat_secrate_t2 "Wartime Sec. Rate * (1940-45)" ///
  self_incat_secrate_t3 "Wartime Sec. Rate * (1946-50)" ///
  self_incat_secrate_t4 "Wartime Sec. Rate * (1951-55)" ///
  self_incat_secrate_t5 "Wartime Sec. Rate * (1956-60)") ///
drop(self_incat_secrate period* _cons)


eststo clear
