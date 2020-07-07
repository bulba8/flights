library(tidyverse)
library(shiny)
library(geosphere)
library(ggplot2)
library(sp)

shinyServer(function(input, output, session) {
  #render map
  output$map <- renderLeaflet({
    leaflet() %>% addProviderTiles(providers$Wikimedia)%>%
      setView(lng = -95, lat = 40, zoom = 4)
  })
  #select only desired data
  observe({
    if(input$month==""){f <- function(dados,pos)subset(dados,TAIL_NUMBER ==input$tail_number)}
    else
      f <- function(dados,pos)subset(dados,TAIL_NUMBER ==input$tail_number & MONTH==input$month) #selecionando apenas dados do v?o de interesse
    
    #read data  
    dados <- read_csv_chunked("data/flights.csv",callback = DataFrameCallback$new(f),chunk_size = 10000)
    
    #airports coordinates
    path1 <- file.path("data/airports.csv")
    aeroportos <- read_csv(path1)
    dados <- dados %>% 
      left_join(aeroportos, by = c("ORIGIN_AIRPORT" = "IATA_CODE")) %>% 
      rename(lng_org = LONGITUDE, lat_org = LATITUDE) %>% 
      left_join(aeroportos, by = c("DESTINATION_AIRPORT" = "IATA_CODE")) %>% 
      rename(lng_dest = LONGITUDE, lat_dest = LATITUDE) %>% drop_na(lng_org,lng_dest,lat_dest,lat_org)
    
    #color palette
    
    tam <- nrow(dados)
    gradientFunction <- colorRampPalette(c("#12c2e9","#c471ed","#f64f59"))
    colorGradient <- gradientFunction(dim(dados)[1])
    gc_routes <- gcIntermediate(dados[c("lng_org","lat_org")],
                                dados[c("lng_dest","lat_dest")],
                                n = tam, addStartEnd = TRUE,sp = TRUE, 
                                breakAtDateLine = TRUE)
    gc_routes <- SpatialLinesDataFrame(gc_routes, 
                                       data.frame(
                                         colorido=colorGradient,
                                         stringsAsFactors = FALSE))
    
    
    #icons
    
    icone <- makeIcon(
      iconUrl = "https://image.flaticon.com/icons/svg/565/565360.svg",
      iconWidth = 8, iconHeight = 30)
    aviaosubindo <- makeIcon(
      iconUrl = "https://image.flaticon.com/icons/svg/579/579268.svg",
      iconWidth = 20, iconHeight = 45)
    chegadaicone <- makeIcon(
      iconUrl = "https://image.flaticon.com/icons/svg/1505/1505471.svg",
      iconWidth = 20, iconHeight = 45)
    html_legend <- "<img src='https://image.flaticon.com/icons/svg/579/579268.svg'
style='width:10px;height:10px;'>First Airport<br/>
<img src='https://image.flaticon.com/icons/svg/1505/1505471.svg'
style='width:10px;height:10px;'>Last Airport" 
    
    #first and last airports coord
    saida <- data.frame(lng=dados[1,"lng_org"],lat=dados[1,"lat_org"])
    chegada <- data.frame(lng=dados[nrow(dados),"lng_dest"],lat=dados[nrow(dados),"lat_dest"])
    
    #render final map
    leafletProxy("map") %>% clearMarkers() %>% clearControls() %>% clearShapes() %>% addPolylines(data=gc_routes,weight = 1,color=colorGradient) %>%
      addMarkers(dados$lng_org, dados$lat_org,icon=icone ,popup = paste(dados$CITY.x,",",dados$STATE.x), label = dados$AIRPORT.x) %>%
      addMarkers(data=saida,saida$lng,saida$lat,icon = aviaosubindo,popup = paste(dados[1,"CITY.x"],",",dados[1,"STATE.x"]), label = dados[1,"AIRPORT.x"])  %>%
      addMarkers(data=chegada,chegada$lng,chegada$lat,icon = chegadaicone,popup = paste(dados[tam,"CITY.y"],",",dados[tam,"STATE.y"]), label = dados[tam,"AIRPORT.y"]) %>%
      addControl(html = html_legend, position = "bottomleft")
  })})
