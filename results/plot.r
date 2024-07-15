library(ggplot2)
library(dplyr)
library(patchwork)
library(stringr)
library(tikzDevice)

use_tikz = TRUE

file_main = "results-prepared-main.csv"
file_app = "results-prepared-appendix.csv"

if (use_tikz) {
  lpos_main = c(0.15, 0.80)
  lpos_app = c(0.17, 0.80)
} else {
  lpos = c(0.075, 0.85)
}

if (file.exists(file_main)) {
  data_main = read.csv(file = file_main, sep=",", dec=".")

  data_main["algo"][data_main["algo"] == "naive"] = "Naive"
  data_main["algo"][data_main["algo"] == "decor"] = "DECOR"
  data_main = rename(data_main, "Algorithm" = "algo")

  if (use_tikz) {
    tikz("plot-avg.tex", standAlone = FALSE, width = 3.3, height = 1.6)
  } else {
    pdf(file = "plot-avg.pdf", height = 2.4)
  }

  p <- ggplot(data_main, aes(x=n, y=mean_t, group=Algorithm, color=Algorithm)) +
    geom_line(aes(group=Algorithm, linetype=Algorithm, color=Algorithm)) +
    geom_point(aes(group=Algorithm, shape=Algorithm, color=Algorithm)) +
    xlab("$n$") +
    ylab("time (ms)") +
    scale_y_log10(breaks = c(1, 100, 10000)) +
    theme_classic() +
    theme(
      axis.line.x = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
      axis.line.y = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
      legend.position = lpos_main,
      legend.title = element_blank(),
      legend.text = element_text(size=8),
      legend.background = element_rect(fill = NA),
      legend.spacing.y = unit(0, 'mm')
    ) +
    guides(fill = "none") +
    scale_color_manual(values=c(
      rgb(247,192,26, maxColorValue=255),
      rgb(37,122,164, maxColorValue=255)
    )) +
    scale_fill_manual(values=c(
      rgb(247,192,26, maxColorValue=255),
      rgb(37,122,164, maxColorValue=255)
    ))

  print(p)
  dev.off()
}

if (file.exists(file_app)) {
  data_app = read.csv(file = file_app, sep=",", dec=".")

  data_app["algo"][data_app["algo"] == "naive"] = "Naive"
  data_app["algo"][data_app["algo"] == "decor"] = "DECOR"
  data_app = rename(data_app, "Algorithm" = "algo")

  data_filtered_k0 = filter(data_app, k == 0)
  data_filtered_k1 = filter(data_app, k == 2)
  data_filtered_k2 = filter(data_app, k == floor(log2(n)))
  data_filtered_k3 = filter(data_app, k == floor(n/2))
  data_filtered_k4 = filter(data_app, k == n-1)
  data_filtered_k5 = filter(data_app, k == n)

  data_filtered_all = list(
    data_filtered_k0,
    data_filtered_k1,
    data_filtered_k2,
    data_filtered_k3,
    data_filtered_k4,
    data_filtered_k5
  )
  ks = c(
    "0",
    "2",
    "log2n",
    "ndiv2",
    "nsub1",
    "n"
  )

  i <- 0
  for (d in data_filtered_all) {
    i <- i+1
    if (use_tikz) {
      tikz(paste("plot-k=", ks[i], ".tex", sep=""), standAlone = FALSE, width = 2.9, height = 1.6)
    } else {
      pdf(file = paste("plot-k=", ks[i], ".pdf", sep=""), height = 2.4)
    }

    p <- ggplot(d, aes(x=n, y=mean_t, group=Algorithm, color=Algorithm)) +
      geom_line(aes(group=Algorithm, linetype=Algorithm, color=Algorithm)) +
      geom_point(aes(group=Algorithm, shape=Algorithm, color=Algorithm)) +
      xlab("$n$") +
      ylab("time (ms)") +
      scale_y_log10(breaks = c(1, 100, 10000)) +
      theme_classic() +
      theme(
        axis.line.x = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
        axis.line.y = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
        legend.position = lpos_app,
        legend.title = element_blank(),
        legend.text = element_text(size=8),
        legend.background = element_rect(fill = NA),
        legend.spacing.y = unit(0, 'mm')
      ) +
      guides(fill = "none") +
      scale_color_manual(values=c(
        rgb(247,192,26, maxColorValue=255),
        rgb(37,122,164, maxColorValue=255)
      )) +
      scale_fill_manual(values=c(
        rgb(247,192,26, maxColorValue=255),
        rgb(37,122,164, maxColorValue=255)
      ))
    
    print(p)
    dev.off()
  }
}