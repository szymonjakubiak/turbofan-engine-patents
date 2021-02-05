library(shiny)
library(ggplot2)
library(readr)
options(warn=-1)

patents <- read_csv("patents.csv", col_types = cols(pub_date = col_date(format = "%Y-%m-%d")))
applicants_count_table <- table(patents$applicant)

# Define UI for app
ui <- fluidPage(
  navbarPage("Menu",
             tabPanel("Countries",
                      sidebarLayout(
                        sidebarPanel(
                          dateRangeInput("countryDateRange", "Date range", 
                                         min=min(patents$pub_date), start=min(patents$pub_date),
                                         language="en", separator="to"
                          ),
                          width = 2
                        ),
                        mainPanel(
                          plotOutput("countryPlot", height=800),
                          width = 10
                        )
                      )
             ),
             tabPanel("Applicants",
                      sidebarLayout(
                        sidebarPanel(
                          sliderInput("applicantCountSlider", "Number of published patents",
                                      min=1, max=max(applicants_count_table),
                                      value=c(10, max(applicants_count_table)), step=1
                          ),
                          width = 2
                        ),
                        mainPanel(
                          plotOutput("applicantPlot", height=800),
                          width = 10
                        )
                      )
             ),
             tabPanel("Annual",
                      sidebarLayout(
                        sidebarPanel(
                          sliderInput("annualDateRange", "Years range",
                                      min=as.numeric(format(min(patents$pub_date), '%Y')), max=as.numeric(format(max(patents$pub_date), '%Y')),
                                      value=c(as.numeric(format(min(patents$pub_date), '%Y')), max=as.numeric(format(max(patents$pub_date), '%Y'))),
                                      sep='', step=1
                          ),
                          sliderInput("annualCountSlider", "Total number of published patents (date independent)",
                                      min=1, max=max(applicants_count_table),
                                      value=c(36, max(applicants_count_table)), step=1
                          ),
                          width = 2
                        ),
                        mainPanel(
                          plotOutput("annualPlot", height=800),
                          width = 10
                        )
                      )
             ),
             tabPanel("Inventors",
                      sidebarLayout(
                        sidebarPanel(
                          sliderInput("inventorCountSlider", "Minimum number of patents (patent office independent)",
                                      min=1, max=max(applicants_count_table),
                                      value=10, step=1
                          ),
                          radioButtons("inventorCountryButtons", "Patent office",
                                             c("All" = "",
                                               "World Intellectual Property Organisation" = "WO",
                                               "European Patent Office" = "EP",
                                               "United States of America" = "US",
                                               "China" = "CN",
                                               "United Kingdom" = "GB",
                                               "Russian Federation" = "RU",
                                               "Japan" = "JP"
                                               )
                          ),
                          width = 2
                        ),
                        mainPanel(
                          plotOutput("inventorPlot", height=800),
                          width = 10
                        )
                      )
             )
  )
)


# Define server logic
server <- function(input, output) {
  output$countryPlot <- renderPlot({
    patents_country <- patents[patents$pub_date >= input$countryDateRange[1] & patents$pub_date <= input$countryDateRange[2], ]
    p_country <- ggplot(patents_country, aes(y=forcats::fct_rev(forcats::fct_infreq(stringr::str_wrap(country_name, 50)))))
    p_country +  geom_bar() + geom_text(stat = "count", aes(label = after_stat(count)), hjust = -1) +
      labs(x="Number of registered patents", y="Country", 
           title=sprintf("Number of registered patents by country, from %s to %s", input$countryDateRange[1], input$countryDateRange[2]))
  })
  
  output$applicantPlot <- renderPlot({
    patents_applicant <- subset(patents, applicant %in% names(applicants_count_table[
      applicants_count_table >= input$applicantCountSlider[1] & applicants_count_table <= input$applicantCountSlider[2]
      ]))
    p_corp <- ggplot(patents_applicant, aes(y=forcats::fct_rev(forcats::fct_infreq(stringr::str_wrap(applicant, 50)))))
    p_corp +  geom_bar() + geom_text(stat = "count", aes(label = after_stat(count)), hjust = -1) +
      labs(x="Number of registered patents", y="Applicant", title="Number of registered patents by applicant")
  })
  
  output$annualPlot <- renderPlot({
    patents_annual <- subset(patents, applicant %in% names(applicants_count_table[
      applicants_count_table >= input$annualCountSlider[1] & applicants_count_table <= input$annualCountSlider[2]
    ]))
    patents_annual$year <- format(patents_annual$pub_date,'%Y')
    patents_annual <- patents_annual[patents_annual$year >= input$annualDateRange[1] & patents_annual$year <= input$annualDateRange[2], ]
    ggplot(patents_annual, aes(x=year, fill=applicant)) + geom_bar(colour="black", width=0.5) + 
      labs(x="Year", y="Number of patents", title="Annual number of new patents", fill="Applicant") +
      theme(axis.text.x = element_text(angle = 40))
  })
  
  output$inventorPlot <- renderPlot({
    patents_inventor <- subset(patents, applicant %in% names(applicants_count_table[
      applicants_count_table >= input$inventorCountSlider
    ]))
    # Patent office selection
    if (input$inventorCountryButtons != "") {
      patents_inventor <- patents_inventor[patents_inventor$country_code == input$inventorCountryButtons, ]
    }
    p_corp <- ggplot(patents_inventor, aes(x=forcats::fct_rev(forcats::fct_infreq(applicant, 50)), y=inventors_nb))
    p_corp +  geom_boxplot() + coord_flip() + scale_y_continuous(breaks = scales::pretty_breaks(n = 20)) +
      labs(x="Applicant", y="Number of inventors", title=sprintf("Number of inventors per patent, by applicant %s", input$inventorCountryButtons))
  })
  
}


# Create Shiny app
shinyApp(ui = ui, server = server)