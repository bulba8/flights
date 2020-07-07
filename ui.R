library(shiny)
library(data.table)
library(leaflet)

#input variables
fnumb <- fread("data/flights.csv",sep = ",", select = c("TAIL_NUMBER"))
fnumb <- unique(fnumb)
month <- c(
  "All"="",
  "January" = "1",
  "February" = "2",
  "March" = "3",
  "April" = "4",
  "May" = "5",
  "June" ="6",
  "July" = "7",
  "August" = "8",
  "September"="9",
  "October" = "10",
  "November" = "11",
  "December" ="12"
)

shinyUI(navbarPage("Flights", id="flg", 
           #map panel
           tabPanel("Map",
                    div(class="outer",
                        
                        tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}")
                    ),
                    leafletOutput("map"),
                    
                    #imput panel
                    absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                  draggable = TRUE, top = 60, left = "auto", right = 10, bottom = "auto",
                                  width = 250, height = "auto",
                                  
                                  h2(),
                                  
                                  selectInput("tail_number", " Fligh number",fnumb),
                                  selectInput("month", "Month",month)
                    )
           ),
           conditionalPanel("false", icon("crosshair"))
))
