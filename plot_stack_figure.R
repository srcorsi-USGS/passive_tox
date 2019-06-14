library(drake)
library(tidyverse)
library(toxEval)
library(ggpubr)

loadd(chemicalSummary)
loadd(site_info)
loadd(tox_list)
source(file = "R/report/stack_plots.R")
source(file = "R/report/combo_plot2.R")
color_map <- class_colors(tox_list)
font_size <- 5

full_plot <- whole_stack(chemicalSummary, site_info, title=NA,
                         tox_list, color_map, font_size, 
                         category = "Chemical Class")

pdf("plots/stack_full.pdf", width = 4.5, height = 5.5, onefile=FALSE)
ggarrange(
  full_plot$chem_count,
  full_plot$no_axis +
    ylab("Sum of Maximum EAR Values"),
  widths = c(1.3,5),
  common.legend = TRUE, legend = "bottom"
)
dev.off()


classes <- unique(tox_list$chem_info$Class)
num_chem_to_keep <- 5
font_size <- 5
pdf("plots/classes_split.pdf", width = 4.5, height = 5.5, onefile=TRUE)
for(i in classes){

  chem_i <- dplyr::filter(chemicalSummary, Class == i)
  if(nrow(chem_i) == 0){
    next
  }
  chem_i$chnm <- droplevels(chem_i$chnm)
  
  if(length(levels(chem_i$chnm)) > num_chem_to_keep){
    too_small <- levels(chem_i$chnm)[1:(length(levels(chem_i$chnm))-num_chem_to_keep)]
    just_right <- levels(chem_i$chnm)[(length(levels(chem_i$chnm))-num_chem_to_keep+1):length(levels(chem_i$chnm))]
    too_small_text <- paste0("Other [",length(too_small),"]")
    chem_i$chnm <- as.character(chem_i$chnm)
    chem_i$chnm[chem_i$chnm %in% too_small] <- too_small_text
    chem_i$chnm <- factor(chem_i$chnm, levels = c(rev(just_right), too_small_text))
    
  }

  color_i <- colorspace::rainbow_hcl(length(unique(chem_i$chnm)), 
                                     start = -360, end = -55, c = 100, l = 64)
  
  names(color_i) <- levels(chem_i$chnm)
  
  if(grepl("Other",names(color_i)[length(color_i)])){
    color_i[length(color_i)] <- "grey77"
  }
  
  class_plot <- whole_stack(chem_i, site_info, tox_list,
                            color_i, font_size, 
                            category = "Chemical",
                            title = i)
  
  i <- gsub("/","_",i)
  # pdf(paste0(i,".pdf"), width = 4.5, height = 5.5, onefile=FALSE)
  
  print(
  ggarrange(
    class_plot$chem_count,
    class_plot$no_axis +
      ylab("Sum of Maximum EAR Values"),
    widths = c(1.3,5),
    common.legend = TRUE, legend = "bottom"
  ))
  
}

dev.off()

class_plots <- list()
font_size <- 9

for(i in classes){
  
  chem_i <- dplyr::filter(chemicalSummary, Class == i)
  if(nrow(chem_i) == 0){
    next
  }
  chem_i$chnm <- droplevels(chem_i$chnm)
  
  if(length(levels(chem_i$chnm)) > num_chem_to_keep){
    too_small <- levels(chem_i$chnm)[1:(length(levels(chem_i$chnm))-num_chem_to_keep)]
    just_right <- levels(chem_i$chnm)[(length(levels(chem_i$chnm))-num_chem_to_keep+1):length(levels(chem_i$chnm))]
    too_small_text <- paste0("Other [",length(too_small),"]")
    chem_i$chnm <- as.character(chem_i$chnm)
    chem_i$chnm[chem_i$chnm %in% too_small] <- too_small_text
    chem_i$chnm <- factor(chem_i$chnm, levels = c(rev(just_right), too_small_text))
    
  }
  
  color_i <- colorspace::rainbow_hcl(length(unique(chem_i$chnm)), 
                                     start = -360, end = -55, 
                                     c = 100, l = 64)
  
  names(color_i) <- levels(chem_i$chnm)
  
  if(grepl("Other",names(color_i)[length(color_i)])){
    color_i[length(color_i)] <- "grey77"
  }
  
  class_plots[[i]] <- whole_stack(chem_i, site_info, tox_list,
                            color_i, font_size, 
                            category = "Chemical",
                            title = i)
}


library(cowplot)

general_lp <- c(0.15,0.87)

pdf("plots/MoreChemicalStacks.pdf", width = 10, height = 8)

plot_grid(
  class_plots[[1]]$chem_count,
  class_plots[[1]]$no_axis +
    theme(legend.position = general_lp,
          strip.text.y =  element_blank()) +
    ylab(""),
  class_plots[[2]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[2]]$no_axis +
    theme(legend.position = c(0.15,0.92) ,
          strip.text.y =  element_blank()) +
    ylab(""),
  class_plots[[3]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[3]]$no_axis +
    theme(legend.position = general_lp,
          strip.text.y =  element_blank()) +
    ylab("Sum of Maximum EAR Values"),
  class_plots[[4]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[4]]$no_axis +
    theme(legend.position = general_lp,
          strip.text.y =  element_blank()) +
    ylab(""),
  class_plots[[5]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[5]]$no_axis +
    theme(legend.position = c(0.15,0.84),
          strip.text.y = element_text(size = 0.75*font_size)) +
    ylab(""),
  rel_widths = c(3,3,rep(c(1,3),4)),
  nrow = 1
)

plot_grid(
  class_plots[[6]]$chem_count,
  class_plots[[6]]$no_axis +
    theme(legend.position = general_lp,
          strip.text.y =  element_blank()) +
    ylab(""),
  class_plots[[7]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[7]]$no_axis +
    theme(legend.position = general_lp ,
          strip.text.y =  element_blank()) +
    ylab(""),
  class_plots[[8]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[8]]$no_axis +
    theme(legend.position = general_lp,
          strip.text.y =  element_blank()) +
    ylab("Sum of Maximum EAR Values"),
  class_plots[[9]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[9]]$no_axis +
    theme(legend.position = general_lp,
          strip.text.y =  element_blank()) +
    ylab(""),
  class_plots[[10]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[10]]$no_axis +
    theme(legend.position = c(0.15,0.84),
          strip.text.y = element_text(size = 0.75*font_size)) +
    ylab(""),
  rel_widths = c(3,3,rep(c(1,3),4)),
  nrow = 1
)

plot_grid(
  class_plots[[11]]$chem_count,
  class_plots[[11]]$no_axis +
    theme(legend.position = general_lp,
          strip.text.y =  element_blank()) +
    ylab(""),
  class_plots[[12]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[12]]$no_axis +
    theme(legend.position = general_lp ,
          strip.text.y =  element_blank()) +
    ylab(""),
  class_plots[[13]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[13]]$no_axis +
    theme(legend.position = c(0.15,0.93),
          strip.text.y =  element_blank()) +
    ylab("Sum of Maximum EAR Values"),
  class_plots[[14]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[14]]$no_axis +
    theme(legend.position = general_lp,
          strip.text.y =  element_blank()) +
    ylab(""),
  class_plots[[15]]$chem_count +
    theme(axis.text.y = element_blank()),
  class_plots[[15]]$no_axis +
    theme(legend.position = c(0.15,0.84),
          strip.text.y = element_text(size = 0.75*font_size)) +
    ylab(""),
  rel_widths = c(3,3,rep(c(1,3),4)),
  nrow = 1
)

dev.off()