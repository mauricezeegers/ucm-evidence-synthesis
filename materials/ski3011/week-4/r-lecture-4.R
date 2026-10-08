### R lecture 4: Meta-analysis in R II
### UCM SKI3011 Evidence Synthesis 2 · https://ucm.meta-research.nl
### Run this script line by line: put the cursor on a line and press Cmd+Enter (Mac) or Ctrl+Enter (Windows).

# Packages ----

# Today we use two packages. metafor you know from last week. meta does the same with
# slightly different functions (metabin(), metacont(), metagen()) and makes nice forest
# plots. Many published reviews use one of the two.

# install.packages("meta")   # run once
library(metafor)
library(meta)
library(metadat)

# Binary outcomes: the data ----

# Nine trials on diuretics in pregnancy and the risk of pre-eclampsia (dat.collins1985b).
# For each trial we need the number of events and the group size in the treatment and the
# control group.

dat <- dat.collins1985b[, c("author", "year", "pre.xti", "pre.nti", "pre.xci", "pre.nci")]
dat

# Binary outcomes with metafor ----

# Instead of the four cells (ai, bi, ci, di) you can give the events and group sizes (ai,
# n1i, ci, n2i). The odds ratio is pooled on the log scale.

dat <- escalc(measure = "OR",
              ai = pre.xti, n1i = pre.nti,   # events and group size, treatment
              ci = pre.xci, n2i = pre.nci,   # events and group size, control
              data = dat, slab = paste(author, year))
res <- rma(yi, vi, data = dat)
predict(res, transf = exp, digits = 2)

# Diuretics lower the odds of pre-eclampsia (OR 0.60, 95% CI 0.38 to 0.92), but the
# prediction interval (0.19 to 1.90) shows that the effect in a new trial could be
# anything from strong protection to harm: the trials are very heterogeneous.

forest(res, atransf = exp, header = TRUE)

# Mantel-Haenszel ----

# The Mantel-Haenszel method is a fixed-effect method that works directly on the counts
# and handles small numbers of events well.

rma.mh(measure = "OR", ai = pre.xti, n1i = pre.nti, ci = pre.xci, n2i = pre.nci,
       data = dat, digits = 2)

# Binary outcomes with meta ----

# metabin() from the meta package gives the fixed-effect (called "common effect") and the
# random-effects result in one go. Studies with zero events in one group get a continuity
# correction of 0.5 (incr).

m_bin <- metabin(event.e = pre.xti, n.e = pre.nti,   # experimental group
                 event.c = pre.xci, n.c = pre.nci,   # control group
                 sm = "OR", data = dat,
                 studlab = paste(author, year))
summary(m_bin)

forest(m_bin)

# Published odds ratios with a confidence interval ----

# Often a paper only reports an odds ratio with its 95% CI. Then you calculate the log
# odds ratio and its standard error yourself: SE = [ln(upper) − ln(lower)] / 3.92.
# Example: 37 studies on passive smoking and lung cancer in women (dat.hackshaw1998).

smoke <- dat.hackshaw1998[, c("author", "year", "or", "or.lb", "or.ub")]
smoke$log_or <- log(smoke$or)
smoke$se_log_or <- (log(smoke$or.ub) - log(smoke$or.lb)) / 3.92   # SE from the 95% CI
head(smoke, 3)

# metagen() pools any pre-calculated effect size: TE is the effect (here the log OR) and
# seTE its standard error. With sm = "OR" the output is shown as odds ratios.

m_gen <- metagen(TE = log_or, seTE = se_log_or, sm = "OR",
                 data = smoke, studlab = paste(author, year))
summary(m_gen)$random    # random-effects result on the log scale
exp(c(m_gen$TE.random, m_gen$lower.random, m_gen$upper.random))   # as odds ratio

# Women exposed to environmental tobacco smoke have about 24% higher odds of lung cancer
# (OR 1.24, 95% CI 1.13 to 1.37).

# Continuous outcomes: mean difference ----

# Five studies comparing pain scores (NRS, 0 to 10) after two types of spinal fusion
# surgery, TLIF and PLIF. All studies use the same scale, so we pool the mean difference
# (MD).

Author   <- c("Yang", "Han", "Liu", "Yan", "Sakeb")
Year     <- c(2015, 2016, 2016, 2008, 2013)
N_TLIF   <- c(32, 36, 101, 91, 50)
NRS_TLIF <- c(1.33, 2.44, 2.84, 2.84, 1.83)
SD_TLIF  <- c(0.89, 1.42, 0.91, 0.91, 0.63)
N_PLIF   <- c(34, 26, 125, 85, 52)
NRS_PLIF <- c(1.26, 2.65, 2.84, 2.84, 2.00)
SD_PLIF  <- c(0.76, 1.26, 0.89, 0.89, 0.67)
pain <- data.frame(Author, Year, N_TLIF, NRS_TLIF, SD_TLIF, N_PLIF, NRS_PLIF, SD_PLIF)

m_cont <- metacont(n.e = N_TLIF, mean.e = NRS_TLIF, sd.e = SD_TLIF,   # TLIF group
                   n.c = N_PLIF, mean.c = NRS_PLIF, sd.c = SD_PLIF,   # PLIF group
                   sm = "MD", data = pain, studlab = paste(Author, Year))
summary(m_cont)

forest(m_cont, label.e = "TLIF", label.c = "PLIF", xlab = "Pain (NRS)")

# The pain scores hardly differ (MD −0.05, 95% CI −0.18 to 0.09) and there is no
# heterogeneity (I² = 0%).

# Continuous outcomes: standardised mean difference ----

# When studies measure the same outcome on different scales, use the standardised mean
# difference (SMD, Hedges' g): the difference in means divided by the pooled standard
# deviation. Example: length of hospital stay after stroke in specialist versus routine
# care (dat.normand1999).

stroke <- escalc(measure = "SMD",
                 m1i = m1i, sd1i = sd1i, n1i = n1i,   # specialist care
                 m2i = m2i, sd2i = sd2i, n2i = n2i,   # routine care
                 data = dat.normand1999, slab = source)
res_smd <- rma(yi, vi, data = stroke)
print(res_smd, digits = 2)

# The pooled SMD is −0.54 (95% CI −1.14 to 0.07): a moderate reduction in length of stay,
# but not statistically significant, and with very large heterogeneity (I² = 95%).

# Saving a forest plot ----

# To put a forest plot in your paper, save it as an image file. This is not run on the
# website.

png("forest_plot.png", width = 1000, height = 500)
forest(m_cont, label.e = "TLIF", label.c = "PLIF", xlab = "Pain (NRS)")
dev.off()

# Check yourself ----

# Go to the concept list and practice quiz of week 4 and try the practice quiz without
# looking at this page.
