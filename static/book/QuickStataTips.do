
*Code to accompany "Quick Stata Tips" version 1.0
*by Todd Jones

********************************************************************************
*fre
ssc install fre
sysuse auto2, clear
tab foreign
fre foreign

********************************************************************************
*mdesc
ssc install mdesc
sysuse lifeexp, clear
mdesc

********************************************************************************
*compare
sysuse auto2, clear
compare mpg trunk

********************************************************************************
*set scroll buffer size
set scrollbufsize 2048000

********************************************************************************
*ereplace
sysuse auto2, clear
*This next line doesn't work:
replace mpg = max(mpg)
*So you instead have to do something like:
egen mpg2 = max(mpg)
drop mpg
rename mpg2 mpg
*Here is the easier way:
ssc install ereplace
sysuse auto2, clear
ereplace mpg = max(mpg)

********************************************************************************
*r(table)
sysuse auto2, clear 
reg trunk weight 
matrix list r(table) 
local weight_lower_95ci = r(table)[5,1] 
di "`weight_lower_95ci'"

********************************************************************************
*ssc hot
ssc hot, n(100)

********************************************************************************
*opacity
sysuse sp500, clear 
replace high = high+80 
twoway (hist high, width(20) color(blue%50)) (hist low, width(20) color(red%50)), scheme(s1mono) legend(order(1 "Blue" 2 "Red"))

********************************************************************************
*sort by, but don't group with
sysuse census, clear
*keep the least-populous state within each region, so sort by pop * within each region:
bys region (pop): keep if _n==1

********************************************************************************
*isid
sysuse auto2, clear
isid foreign
isid foreign make

********************************************************************************
*texdoc
capture ssc install texdoc
sysuse auto2, clear
global spec1 "if foreign"
global spec2 "if !foreign"
global spec3 "if !foreign & _n>5"

local vars mpg headroom trunk weight length turn

foreach spec in 1 2 3 {
    reg price `vars' ${spec`spec'}
        foreach i in `vars' {
			local b_`i'_`spec': di %6.2fc _b[`i']
			local se_`i'_`spec': di %6.2fc _se[`i']
        
			qui test `i'=0
			local `i'_p_`spec': di %12.2fc r(p)
			local `i'_star_`spec'=cond(``i'_p_`spec''<.01,"***",cond(``i'_p_`spec''<.05,"**",cond(``i'_p_`spec''<.1,"*","")))		
		}
 
        local N=e(N)
        local N_`spec': di %12.0fc `N'
        scalar r2=e(r2)
        local r2_`spec': di %6.2fc r2
        
        sum price if e(sample)
        local ymean_`spec': di %12.2fc r(mean)
}
foreach i in `vars' {
	local b_`i' ""
	local se_`i' ""
	
	local lab: variable label `i'
	local tex_b_`i' "`lab'"
	local tex_se_`i' ""
}
local tex_Y_Mean "Y Mean"
local tex_Observations "N"
local tex_R_Squared "R-squared"
local tex_Sample "Sample"

foreach spec in 1 2 3 {
    foreach i in `vars' {
		local tex_b_`i' = "`tex_b_`i'' & `b_`i'_`spec''``i'_star_`spec''"
		local tex_se_`i' = "`tex_se_`i'' & (`se_`i'_`spec'')"
    }
	local tex_Y_Mean = "`tex_Y_Mean' & `ymean_`spec''"
    local tex_Observations = "`tex_Observations' & `N_`spec''"
    local tex_R_Squared = "`tex_R_Squared' & `r2_`spec''"
}

texdoc init "test_loc.tex", replace force
foreach i in `vars' {
	tex `tex_b_`i'' \\
	tex `tex_se_`i'' \\ \addlinespace
}
tex `tex_Y_Mean' \\
tex `tex_Observations' \\
tex `tex_R_Squared' \\
tex & Foreign & Not Foreign & Not foreign, rows 6+ 
texdoc close

********************************************************************************
*check if variable is constant within group
bys group (var): gen a = var[1]==var[_N]
tab a

bysort group: assert var==var[1]

********************************************************************************
*remove leading and trailing spaces
clear all 
input str12 str 
"String A " 
" String B " 
" String C" 
end 
replace str = trim(str) 

********************************************************************************
*group

sysuse xtline1, clear 
egen grp = group(day) 
*check that it worked 
sort day

********************************************************************************
*tempfiles

sysuse auto2, clear
tempfile a
save `a'

*Later:

use `a', clear

*Or:

merge m:1 id using `a'

********************************************************************************
*control placement of new variable
sysuse auto2, clear
*create version of price in units of thousands
gen price_k = price/1000, before(price)

*create lower case version of make and place after make
gen make_lower = lower(make), after(make)

********************************************************************************
*substr

sysuse auto2, clear 
*get the first two letters of the string 
gen first = substr(make, 1, 2), after(make)
    ********************************************************************************
*browse if

sysuse auto2, clear
*browse only the cars that begin with "A"
br if substr(make,1,1)=="A"
*go back to browsing all data
br

********************************************************************************
*sysuse

sysuse dir 
*load one of them
sysuse citytemp, clear

********************************************************************************
*_n and _N

sysuse auto2, clear
keep rep78
sort rep78
*obs #:
gen n = _n
*obs # w/i group:
bys rep78: gen group_n = _n
*max obs #:
gen N = _N
*max obs # w/i group:
bys rep78: gen group_N = _N

********************************************************************************
*preserve

sysuse auto2, clear
*preserve the data to be used later
preserve
*change the data
keep if _n<5
scatter price mpg
*restore the data
restore

*preserve again
preserve
keep if _n<10
*cancel the prior preserve
restore, not
*preserve again
preserve

********************************************************************************
*capture
sysuse auto2, clear
capture restore, not
preserve

********************************************************************************
*tab1
sysuse auto2, clear 
*tabulate (separately) make, price, and mpg:
tab1 make price mpg 
*tabulate all variables:
tab1 *

********************************************************************************
*statastates
capture ssc install statastates 
sysuse census, clear 
keep state2 
statastates, abbreviation(state2) nogen 
replace state_name = strproper(state_name)

********************************************************************************
*compress
sysuse auto2, clear 
replace make = "This is a long string...." in 1 
replace make = substr(make, 1, 6) 
compress

********************************************************************************
*quietly
sysuse auto2, clear
quietly reg trunk weight

********************************************************************************
*set graphics off
set graphics off
set graphics on

********************************************************************************
*undocumented and previously documented command
help undocumented
help prdocumented

********************************************************************************
*getcensus
ssc install getcensus 
*replace XYZ w/ your key 
global censuskey XYZ 
*get population by county 
getcensus B01003, year(2015) sample(5) geography(county) clear

********************************************************************************
*graph at county level
ssc install getcensus 
*replace XYZ w/ your key 
global censuskey XYZ 
*get population by county 
getcensus B01003, year(2015) sample(5) geography(county) clear

ssc inst maptile 
ssc inst spmap 
maptile_install using "http://files.michaelstepner.com/geo_county2014.zip" 
drop county 
gen county = substr(g,10,5) 
destring county, replace 
maptile b01003_001e, geo(county2014) twopt(title(Population by County) legend(off)) fcolor(Blues)

********************************************************************************
*anmimated map

ssc install maptile 
ssc install spmap 
maptile_install using "http://files.michaelstepner.com/geo_state.zip" 
sysuse census, clear 
rename state q 
rename state2 state
gen year = _n+1900 
fillin state year

bys state: replace medage = 0 if medage==. 
forvalues i = 1914/1928 { 
	maptile medage if year==`i', geo(state) twopt(title(`i') legend(off)) 
	*graph export `i'.png, replace 
} 

*[Mac] Terminal - cd to dir, then: convert *.png a.gif

********************************************************************************
*animated graph
sysuse uslifeexp, clear 
forvalues i = 1900/1999 { 
	scatter le_male le_female if year==`i', title(`i') scheme(s1mono) yscale(r(35 80)) xscale(r(40 80)) ylabel(40(10)80) xlabel(40(10)80) 
	gr export `i'.png, replace 
} 

********************************************************************************
*mscatter
capture ssc inst mscatter 
capture ssc inst palettes 
sysuse sp500, clear 
mscatter change close if inrange(change, -30, 30), msymbol(O) msize(7) sch(s1mono) over(change) colorpalette(viridis)

********************************************************************************
*duplicates
sysuse auto2, clear
keep if _n<15
bys turn: keep if _n==1

sysuse auto2, clear 
keep if _n<15 
*not unique: 
duplicates r turn 
*unique: 
duplicates r gear_ratio turn 
*drop dups 
duplicates drop turn, force

********************************************************************************
*notifications
beep

ssc install statapush
help statapush

********************************************************************************
*iterations
local iterations = 1000
forvalues i=1/`iterations' {
	if mod(`i'/100, 1)==0 di "Iteration `i' of `iterations'" 
}

********************************************************************************
*timer
capture ssc install etime
etime, start
forvalues i=1/1000000 { 
	quietly di "`i'" 
} 
etime

timer clear 
timer on 1 
forvalues i=1/1000000 { 
	quietly di "`i'" 
} 
timer off 1 
timer list

set rmsg on
*to do this permanently
*set rmsg on, permanently
forvalues i=1/1000000 { 
	quietly di "`i'" 
} 

********************************************************************************
*loop over all variables
sysuse census, clear 
	foreach var of varlist _all { 
	rename `var' `var'_42 
}

********************************************************************************
*calculate total

sysuse auto2, clear  
gen one = 1  
egen total = total(one)

********************************************************************************
*xtile
sysuse auto2, clear 
keep turn
*quartiles 
xtile turn_quartile = turn, nq(4) 
*deciles 
xtile turn_decile = turn, nq(10)

********************************************************************************
*remove elements from local
sysuse auto2, clear 
ds 
local vars `r(varlist)' 
di "`vars'" 
local remove_vars "make" 
local vars_new: list vars - remove_vars 
di "`vars_new'"

********************************************************************************
*add elements to a macro
local loc a b c 
di "`loc'" 
*add d & e 
local loc `loc' d e 
di "`loc'" 

global glo v w x 
di "$glo" 
*add y & z 
global glo $glo y z 
di "$glo"

********************************************************************************
*save value label to local
sysuse auto2, clear 
fre foreign
local foreign_0: label (foreign) 0 
local foreign_1: label (foreign) 1 
di "`foreign_0'" 
di "`foreign_1'" 
scatter price displacement if foreign==0, title(`foreign_0')

********************************************************************************
*return
sysuse auto2, clear 
reg weight gear_ratio
ereturn list, all 
return list, all 
matrix list r(table) 
creturn list 
di "`c(pi)'"

********************************************************************************
*convert between real and string
sysuse pop2000, clear
keep if _n>2
gen age = real(substr(agest, 1, 2)), after(agestr)
gen age_string = string(age), after(age)

********************************************************************************
*version control
*global output "/Users/me/Research/projectName/output/12-25-2023/"

*graph export "${output}/a.png"

********************************************************************************
*asgen
capture ssc install asgen
sysuse census, clear
bys region: asgen weighted_medage = medage, weight(pop)
 
********************************************************************************
*collapse
sysuse census, clear
gen N = 1
collapse (mean) medage (sum) N, by(region)

sysuse census, clear
collapse (mean) medage [aweight=pop], by(region)

********************************************************************************
*seq
capture ssc install seq
sysuse auto2, clear
*repeat 1 2 3
seq rep1, from(1) to(3)
*repeat 1 1 2 2 3 3
seq rep2, from(1) to(3) block(2)

********************************************************************************
*add a leading zero to a number
clear all 
set obs 15 
gen fips = _n 
tostring fips, gen(fips2) 
replace fips2 = "0" + fips2 if strlen(fips2)==1

********************************************************************************
*main effects and interaction terms
sysuse auto2, clear
gen b = _n<10
gen b_weight = b*weight

*These are all equivalent: (note the i. is redundant b/c b is binary):
reg price i.b weight b_weight
reg price i.b weight b#c.weight
reg price b##c.weight

********************************************************************************
*keepusing
webuse nhanes2, clear
tempfile nh
save `nh'

use sampl houssiz using `nh', clear
merge 1:1 sampl using `nh', keepusing(height weight)

********************************************************************************
*geodist

capture ssc install geodist
clear
input double lat lon
34.043026 -118.26694
39.74915 -105.00740
end
geodist 42.366570 -71.06186 lat lon, gen(dist) miles

********************************************************************************
*geonear

capture ssc install geonear
clear
set obs 20
set seed 1
gen n2=_n
gen la2=39+5*rt(5)
gen lo2=-99+9*rt(5)
tempfile a
save `a'
rename n2 n
gen la=la2+3*rt(3)
gen lo=lo2+4*rt(4)
drop *2
geonear n la lo using `a', n(n2 la2 lo2)

********************************************************************************
*georoute
ssc install georoute
help georoute

********************************************************************************
*heatplot
capture ssc install heatplot
webuse nhanes2, clear
heatplot weight height

********************************************************************************
*colorvar
sysuse auto2, clear
scatter weight length, colorvar(turn)

********************************************************************************
*binscatterhist
capture ssc install binscatterhist
sysuse auto2, clear
binscatterhist weight length, hist(weight length) ymin(1100)  xhistbarheight(30) yhistbarheight(13)

********************************************************************************
*sankey
capture ssc install sankey
help sankey
use "https://github.com/asjadnaqvi/stata-sankey/blob/main/data/sankey2.dta?raw=true", clear
sankey value, from(source) to(destination) by(layer) noval showtot palette(CET C6) laba(0) labpos(3) labg(-1) offset(10)

********************************************************************************
*readhtml
capture net install readhtml, from(https://ssc.wisc.edu/sscc/stata/)
capture ssc install statastates 
capture ssc install maptile
capture ssc install spmap
capture maptile_install using "http://files.michaelstepner.com/geo_state.zip"
readhtmltable https://en.wikipedia.org/wiki/Forest_cover_by_state_and_territory_in_the_United_States, varnames
gen st=substr(S,7,30)
drop if inlist(_n,3,4,16,18,24,40,57)
gen forest=substr(Percent_forest_2,1,length(Percent_forest_2)-2)
destring forest, replace
keep st forest
statastates, name(st)
rename state_abbrev state
maptile forest, geo(state) fcolor(Greens) twopt(title("Percent Forest"))

********************************************************************************
*Choose which variables and observations to load
sysuse auto2, clear
tempfile a
save `a'
use make turn using `a' in 2/9
use `a' if length>200

********************************************************************************
*datasets from internet
help dta_manuals

help q_base

use https://www.stata-press.com/data/r18/apple.dta

********************************************************************************
*omit group from regression 
sysuse auto2, clear
*view values of rep78
fre rep78
*default:
reg mpg i.rep78
*omit category 3 (average)
reg mpg ib3.rep78

********************************************************************************
*fillin
clear all
input year str1 state value 
1 "A" 6
2 "A" 3
4 "A" 5
3 "B" 1
end
fillin year state

********************************************************************************
*levelsof
sysuse auto2, clear
levelsof mpg
levelsof trunk
*put it into a local
levelsof trunk, local(trunklevels)
di "`trunklevels'"

sysuse auto2, clear
levelsof rep78, missing local(rep78_levels)
foreach i of local rep78_levels {
	sum price
}

*string
levelsof make
levelsof make, clean

********************************************************************************
*increment local
local b = 1
local b = `b' + 1
di "`b'"
*Equivalent:
local a = 1
local ++a
di "`a'"

********************************************************************************
*labelbook
sysuse auto2, clear
labelbook

********************************************************************************
*twoway
sysuse auto2, clear
twoway scatter mpg length || ///
	   scatter mpg displacement, ///
	   scheme(s1color) legend(label(1 "Length") label(2 "Displacement"))

********************************************************************************
*rowtotal
sysuse auto2, clear
gen sum1 = price + mpg + rep78
egen sum2 = rowtotal(price mpg rep78)
egen sum3 = rowtotal(price-rep78)

********************************************************************************
*random numbers
sysuse auto, clear
gen r=runiform()

********************************************************************************
*set seed
sysuse auto, clear
set seed 42
gen r=runiform()

********************************************************************************
*length of string
local loc "How long is this?"
local loc_words : word count `loc'
di "`loc_words'"

local loc_chars = strlen("`loc'")
di "`loc_chars'"

********************************************************************************
*clonevar
sysuse auto2, clear
*this does not create an exact copy:
gen foreign2 = foreign
*this does:
clonevar foreign3 = foreign

********************************************************************************
*Label values based on value labels of another variables
sysuse auto2, clear
set seed 1
gen new = round(runiform()*4+1)
describe rep78
label values new repair 
ssc install fre
fre new

********************************************************************************
*find do files
ssc install find
ssc install rcd
rcd "/Users/Todd/Google Drive": find *.do, match(sysuse auto2) show

********************************************************************************
*commas in large numbers
sysuse voter, clear
format pop %15.0fc
scatter pop frac, scheme(s1mono)

********************************************************************************
*highlight selected bars in bar chart
sysuse auto2, clear
keep if price>=10000

separate price, by(make=="Linc. Continental")

graph hbar (asis) price0 price1, nofill over(make, sort(price) desc) legend(off) scheme(s1color)

********************************************************************************
*keeporder
ssc install keeporder

*old way
sysuse auto2, clear
keep foreign rep78 make
order foreign rep78 make

*new way
sysuse auto2, clear
keeporder foreign rep78 make

********************************************************************************
*program/function
capture program drop s_pr
program s_pr, rclass
args x y
*access args as locals
gen sum = `x' + `y', after(`y')
end

*run program; x=length, y=trunk
sysuse auto2, clear
s_pr length turn

********************************************************************************
*gsort 
sysuse auto2, clear
*sort ascending
gsort mpg
*sort descending 
gsort -mpg

********************************************************************************
*sort descending with bysort

sysuse auto2, clear
*doesn't work:
bys foreign (-turn): gen n=_n
*instead:
gsort foreign -turn
by foreign: gen n = _n

*If the sorting variable is non-string, you can do:
sysuse auto2, clear
gen turn_rev = -turn
bys foreign (turn_rev): gen n=_n
drop turn_rev

********************************************************************************
*moreobs
ssc install moreobs
sysuse auto2, clear
moreobs 10
sort make

********************************************************************************
*coefplot
sysuse auto2, clear
reg price mpg length displacement weight trunk
coefplot, drop(_cons) vertical

********************************************************************************
*expand
sysuse auto2, clear
expand 2
sort make

********************************************************************************
*destring and tostring
sysuse auto2, clear
tostring turn, replace
destring turn, replace

********************************************************************************
*nvals
sysuse auto2, clear
egen headroom_unique_values = nvals(headroom)
sum headroom_unique_values

********************************************************************************
*regsave
capture ssc install regsave
tempfile coefficients
sysuse auto2, clear
reg price mpg headroom turn length gear_ratio
regsave using `coefficients', replace

use `coefficients', clear

********************************************************************************
*access certain rows of a variable
sysuse auto2, clear
gen lag_length = length[_n-1], after(length)
gen lead_length = length[_n+1], after(lag_length)

********************************************************************************
*refer to observations by row number
sysuse auto2, clear
*a single observation
replace trunk = 1 in 1
*multiple observations
replace trunk = 0 in 2/5

********************************************************************************
*colorpalette
capture ssc inst mscatter 
capture ssc inst palettes 
sysuse sp500, clear 
foreach i in Zissou1 cividis icefire Blues { 
	mscatter change close if inrange(change, -30, 30), msymbol(O) msize(7) sch(s1mono) over(change) colorpalette(`i') 
}









