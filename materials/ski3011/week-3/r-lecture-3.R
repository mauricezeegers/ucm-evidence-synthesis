### SKI3011 r-lecture-3
### Explanation and output: https://ucm.meta-research.nl/ski3011/r-lecture-3.html
### Type and run every line yourself.

# install.packages(c("metafor", "metadat"))   # once on your computer
library(metafor)   # meta-analysis functions: escalc(), rma(), forest()
library(metadat)   # example datasets, such as dat.bcg

head(dat.bcg[, c("author", "year", "tpos", "tneg", "cpos", "cneg", "ablat")], 4)

dat <- escalc(measure = "RR",
              ai = tpos, bi = tneg, ci = cpos, di = cneg,
              data = dat.bcg,
              slab = paste(author, year))
head(dat[, c("author", "year", "yi", "vi")], 4)

res <- rma(yi, vi, data = dat)
print(res, digits = 2)

predict(res, transf = exp, digits = 2)

forest(res, atransf = exp, header = TRUE)

res_fe <- rma(yi, vi, data = dat, method = "FE")
predict(res_fe, transf = exp, digits = 2)

dat_pr <- escalc(measure = "PR", xi = xi, ni = ni, data = dat.hannum2020)
res_pr <- rma(yi, vi, data = dat_pr)
print(res_pr, digits = 2)

dat_r <- escalc(measure = "ZCOR", ri = ri, ni = ni, data = dat.molloy2014)
res_r <- rma(yi, vi, data = dat_r)
predict(res_r, transf = transf.ztor, digits = 2)
