library(tidyverse)
library(readxl)
library(toxEval)
library(here)
source(here("R/mixtures/mix_script.R"))

source(file = "read_chemicalSummary.R")

join_everything_fnx <- function(chemicalSummary){
  #################################################
  # AOP
  AOP_crosswalk <- data.table::fread(here("data/raw/AOP_crosswalk.csv")) %>%
    data.frame() %>%
    select(endPoint=Component.Endpoint.Name, ID=AOP.., 
           KE = KE., Key.Event.Name, KeyEvent.Type, AOP_shortname) %>%
    distinct()
  
  aop_summary <- chemicalSummary %>% 
    left_join(select(AOP_crosswalk, 
                     endPoint, ID, AOP_shortname), by="endPoint") %>% 
    filter(!is.na(ID)) %>% 
    select(-endPoint) %>% 
    mutate(endPoint = as.character(ID))
  
  
  ##########################################
  # Gene targets

  gene_info <- select(end_point_info,
                      endPoint = assay_component_endpoint_name,
                      geneID = intended_target_gene_id,
                      geneName = intended_target_gene_name,
                      geneSymbol = intended_target_gene_symbol)

  #Genes that don't have proper formatting:
  gene_info$geneName[which(gene_info$geneID == "321|322|1463|1477")] <- c("thyroid hormone receptor, alpha|thyroid hormone receptor, beta|thyroid hormone receptor, alpha | thyroid hormone receptor, beta",
                                                                          "thyroid hormone receptor, alpha|thyroid hormone receptor, beta|thyroid hormone receptor, alpha | thyroid hormone receptor, beta")

  gene_info$geneSymbol[which(gene_info$geneID == "321|322|1463|1477")] <- c("THRA|THRB|THRA|THRB",
                                                                            "THRA|THRB|THRA|THRB")
  gene_info$geneSymbol[which(gene_info$geneID == "183|1476")] <- c("JUN|FOS")
  gene_info$geneName[which(gene_info$geneID == "183|1476")] <- c("jun proto-oncogene|FBJ murine osteosarcoma viral oncogene homolog")

  gene_info_long <- gene_info %>%
    filter(!is.na(geneID)) %>%
    separate_rows(geneSymbol, 
                  geneName, sep = "\\|")
  
 
  gene <- select(gene_info_long,
                 endPoint,
                 gene = geneSymbol)
  
  gene_summary <- chemicalSummary %>% 
    left_join(gene, by="endPoint") %>%
    filter(!is.na(gene)) %>% 
    select(-endPoint) %>% 
    mutate(endPoint = gene)
  
  
  #######################################
  # Panther
  panther <- data.table::fread(here("panther_data/joined_genes.csv")) %>% 
    data.frame() %>% 
    select(gene = gene_abbr,
           pathway_accession,
           pathway_name) %>% 
    left_join(gene,  by="gene")
  
  panther_summary <- chemicalSummary %>% 
    left_join(panther, by="endPoint") %>%
    filter(!is.na(gene)) %>% 
    filter(pathway_accession != "") %>% 
    select(-endPoint) %>% 
    mutate(endPoint = pathway_name)
  
  join_everything <- chemicalSummary %>% 
    left_join(select(AOP_crosswalk, endPoint, AOP_shortname), by="endPoint") %>% 
    left_join(gene, by="endPoint") %>% 
    left_join(panther, by=c("endPoint","gene")) %>% 
    select(endPoint, gene, AOP_shortname, pathway_name) %>% 
    distinct() %>% 
    group_by(endPoint) %>% 
    summarise(AOPs = paste(unique(AOP_shortname[!is.na(AOP_shortname)]), collapse = ","),
              genes = paste(unique(gene[!is.na(gene)]), collapse = ","),
              pathways = paste(unique(pathway_name[!is.na(pathway_name)]), collapse = ","))
  
  return(join_everything)
}

