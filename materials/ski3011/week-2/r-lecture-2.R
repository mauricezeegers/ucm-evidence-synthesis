### R lecture 2: R basics
### UCM SKI3011 Evidence Synthesis 2 · https://ucm.meta-research.nl
### Run this script line by line: put the cursor on a line and press Cmd+Enter (Mac) or Ctrl+Enter (Windows).

# Why R? ----

# R is a program for statistical computing, not just for meta-analyses. To learn to do a
# meta-analysis in R, we first need the basics. A general principle of responsible
# research: keep only two files, the raw data file and the script. Never change the raw
# data by hand without logging it: every change is a line in the script.

# R as a calculator ----

4 + 3
4 * 2
4^2
log(4)    # natural logarithm
exp(4)    # the inverse of log()
sqrt(4)

# Vectors and functions ----

# A vector combines values that belong together, like a column in a spreadsheet: the ages
# of participants, or the effect sizes of the studies in a meta-analysis. c() stands for
# combine. A function such as mean() takes arguments between brackets. Use ? to open the
# help page of a function.

c(9, 3, 6)
mean(c(9, 3, 6))
sd(c(9, 3, 6))
sort(c(9, 3, 6), decreasing = TRUE)   # an extra argument changes what the function does
# ?sort                               # remove the # to open the help page

# Objects ----

# A vector, a dataset or a single value can be stored in an object with <-. You choose the
# name yourself. The object appears in the Environment window (top right in RStudio).

a <- c(9, 3, 6)
a
b <- 2 + 2
a / b      # every value of a is divided by b
z <- a / b
z

# Data frames ----

# A data frame is a table: one row per study, one column per variable. Here we make the
# meta-analysis dataset you know from SKI3010 by hand: 11 studies on environmental tobacco
# smoke at home and bladder cancer, with the log odds ratio and its standard error.

lnOR <- c(-0.223143551, -0.198450939, -0.162518929, -0.162518929, -0.116533816, 0.009950331,
          0.086177696, 0.139761942, 0.165514438, 0.336472237, 0.457424847)
se <- c(0.38457745, 0.301271952, 0.200831965, 0.279480271, 0.359347184, 0.428673775,
        0.247347883, 0.162072911, 0.251023247, 0.3350916, 0.293754916)
firstauthor <- c("Alberg (2)", "Bjerregaard", "Jiang", "Burch", "NLCS", "Kabat",
                 "Baris", "Zheng", "Samanic", "Alberg (1)", "Tao")
year <- c(2007, 2006, 2007, 1989, 2002, 1986, 2009, 2012, 2006, 2007, 2010)
dat <- data.frame(firstauthor, year, lnOR, se)
dat
names(dat)                # the column names
dat$lnOR                  # $ selects one column
dat$year[2]               # [ ] selects an element: the second year
dat[dat$year > 2006, ]    # the rows of studies published after 2006
round(exp(dat$lnOR), 2)   # back from log odds ratios to odds ratios
# View(dat)               # opens the data in a spreadsheet view

# Reading a csv file ----

# Most of your data will come from a spreadsheet saved as csv. Download the practice file
# bcg.csv and put it in the folder where you keep your script. getwd() shows the folder R
# works in; in RStudio you can change it via Session, Set Working Directory, To Source
# File Location.

# European csv files use a semicolon as separator and a comma as decimal sign. If you
# forget that, R reads everything into one column:

# getwd()                    # which folder is R working in?
wrong <- read.csv("bcg.csv")
head(wrong, 2)               # one column, everything glued together

# Tell R which separator and decimal sign the file uses:

bcg <- read.csv("bcg.csv", sep = ";", dec = ",")
head(bcg, 3)
dim(bcg)        # number of rows (studies) and columns (variables)

# Data types ----

# R distinguishes numeric values (for calculations), logical values (TRUE or FALSE),
# character values (text) and factors (categories). class() tells you which type an object
# is.

a <- 44 / 5
class(a)
b <- 7 > 4
b
class(b)
class(bcg$author)
pets <- c("cat", "dog", "cat", "bird", "cat")
class(pets)
pets <- as.factor(pets)   # a factor: a categorical variable with levels
levels(pets)

# Some simple statistics ----

# R has built-in datasets. airquality contains daily air measurements in New York. Does
# ozone concentration depend on temperature? In lm() the tilde ~ separates the outcome
# from the explanatory variable.

dim(airquality)
head(airquality, 3)
fit <- lm(Ozone ~ Temp, data = airquality)
summary(fit)

# Plots ----

# The built-in dataset iris has flower measurements of three species. Arguments such as
# main, xlab, pch and col change the title, axis labels, symbols and colours.

hist(iris$Petal.Length, main = "Histogram of petal length", xlab = "Petal length")

boxplot(Petal.Length ~ Species, data = iris,
        main = "Petal length by species", xlab = "Species", ylab = "Petal length")

plot(iris$Petal.Length, iris$Sepal.Length, pch = 20, col = "darkorange",
     main = "Petal length and sepal length", xlab = "Petal length", ylab = "Sepal length")
abline(lm(Sepal.Length ~ Petal.Length, data = iris))   # add the regression line

# Saving your data ----

# write.csv() saves a data frame as a csv file in your working directory; read.csv() reads
# it back. This line is not run on the website.

write.csv(bcg, "my_bcg_data.csv", row.names = FALSE)
my_data <- read.csv("my_bcg_data.csv")

# Now your own data ----

# Import your own extraction sheet (saved as csv) with read.csv() and check it with
# head(), dim() and class().

# Check yourself ----

# Go to the concept list and practice quiz of week 2 and try the practice quiz without
# looking at this page.
