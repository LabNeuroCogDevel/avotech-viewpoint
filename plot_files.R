
library(ggplot2)
pdir <- getwd()
# https://github.com/LabNeuroCogDevel/autoeyescore
setwd("/Volumes/Hera/Projects/autoeyescore")
source("score_arrington.R")
setwd(pdir)

rmwf <- function(f) gsub('.*/sub-will|_.*','',f)
load_files <- function(eyetxts, fn_fname=rmwf) {
#eyetxts <- Sys.glob("~/scratch/sub-will*.txt")
tracking_list <- lapply(eyetxts, \(f) read_arr(f) %>%
        # msg is 'iti' or like '1 dot .9'
        separate(msg,c("trial","event","pos"),sep=" ") %>%
        mutate(event=ifelse(is.na(event), 'iti',event),
               trial=as.numeric(trial),
               pos=round(as.numeric(pos),2),
               # include where data comes from
               fname=fn_fname(f)) %>%
        fill(trial, pos, .direction="up") %>%
        group_by(trial) %>%
        mutate(t=TotalTime-first(TotalTime)))
}

fix_norm_from_list <- function(tracking_list) {
  d_all <- tracking_list %>% bind_rows %>% filter(!is.na(trial))
  d_median <- d_all %>%
    group_by(fname,trial,event,pos) %>%
    summarise(x_median=median(X_CorrectedGaze,na.rm=T))
  
  sd_vals <- d_all %>%
    group_by(fname,trial, pos) %>%
    summarise(se=sd(X_CorrectedGaze)/sqrt(n()))
  
  med_vals <- d_median %>%
    spread(event,x_median) %>%
    inner_join(sd_vals) %>%
    inner_join(d_median) %>%
    mutate(dist=iti-dot) %>%
    mutate(type=case_when(
             grepl('_tape', fname)~ 'Tape',
             grepl('notape', fname)~ 'No Tape',
             grepl('64', fname)~ '64 channel coil',
             grepl('32', fname)~ '32 channel coil',
             grepl('ideal', fname)~ 'ideal',
             TRUE ~ 'oops'))
  
  med_all <- d_all %>% inner_join(med_vals) %>%
   mutate(x_norm = iti - X_CorrectedGaze,
          side=ifelse(pos<0, 'left', 'right'),
          loc=abs(pos))
}


plot_ideal_vs_dot <- function(med_all){
  p_distside <- med_all %>%
    filter(event=='dot') %>%
   ggplot() +
   aes(x=x_norm, fill=fname) +
   cowplot::theme_cowplot() +
   geom_density(alpha=.4)+
    facet_grid(side~loc) +
    geom_vline(xintercept=0) +
    labs(x="median iti - x pos",
        title="distirubtion of x gaze during dot",
        fill="data from")
  
  p_distfname <- med_all %>%
    filter(event=='dot') %>%
   ggplot() +
   aes(x=x_norm, fill=as.factor(pos)) +
   cowplot::theme_cowplot() +
    geom_density(alpha=.4)+
    facet_grid(~fname) +
    geom_vline(xintercept=0) +
    labs(x="median iti - x pos",
        title="",
        fill="stim position")
  
  cowplot::plot_grid(p_distside, p_distfname, nrow=2)
}


p_med_ideal <- function(med_all) {
  # hacky way to get med_vals back from med_val
  # so we only have to push around one dataframe
  med_vals <- med_all %>%
      group_by(pos,fname,type,se) %>%
      filter(row_number()==1) %>% 
    list(data.frame(
        type='ideal',
        fname='ideal', pos=c(-.9,.9),
        dist=c(.5-.05, .5-.95))) %>% bind_rows

  ggplot(med_vals) +
  aes(x=pos, y=dist, color=fname, linetype=type) +
  geom_hline(yintercept=0, alpha=.5) +
  geom_errorbar(aes(ymin=dist-se, ymax=dist+se, linetype=NULL),
                width=.025, alpha=.5) +
  geom_point() +
  geom_line(aes(group=fname)) +
  scale_linetype_manual(values=c(5,3,1)) +
  cowplot::theme_cowplot() +
  labs(x="presented dot's horz. position (-1 left, 1 right)",
       y="median center fix (iti) - median dot fix",
       linetype="head coil",
       color="data from",
       title="horz gaze side discrimination")
}

plot_raw <- function(med_all) {
d_median <- med_all %>%
    group_by(trial,event,fname,x_median) %>%
    filter(row_number()==1)

ggplot(med_all) +
   aes(x=t, y=X_CorrectedGaze, color=event) +
   geom_point(size=.5) +
   facet_grid(fname~pos) +
   geom_hline(data=d_median,aes(yintercept=x_median, linetype=event)) +
   lims(y=c(-1.5,1.5), x=c(1,3)) +
   cowplot::theme_cowplot() +
   labs(y="eye x pos (corrected)", x="time (s)",
        title="[VGS] Per trial-position horz. eye time series; median event lines")
}
