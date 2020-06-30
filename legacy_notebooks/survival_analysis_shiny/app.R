#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# define UI for app
ui <- fluidPage(

    # applica title
    titlePanel("enter_title"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectInput(
                inputId = "cohort",
                label = "Select cohort",
                choices = c(
                    "Negative Control", 
                    "Inverse Probablity of Treatment Weighting",
                    "Exact Matching",
                    "Propensity Score Matching")
                ),
            selectInput(
                InputID = "outcome",
                label = "Select outcome",
                choices = c(
                    "≥ 15 ETDRS letters",
                    "≥ 10 ETDRS letters",
                    "< -15 ETDRS letters"
                )
            )
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("density"),
           
           plotOutput("km")
        )
    )
)

# define server logic 
server <- function(input, output) {

    output$density <- renderPlot({
    })
    
    output$km
}

# Run the application 
shinyApp(ui = ui, server = server)
