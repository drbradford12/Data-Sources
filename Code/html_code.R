library(rvest)
library(RSelenium)
library(htmltab)
library(XML)
library(dplyr)
library(purrr)
library(DBI)
library(rstudioapi)
library(RMySQL)
library(skimr)
library(keyring)

#Using Splash
#install_splash()    # run this once to install the docker image
#sp <- start_splash()
#pg <- render_html(url = 'https://dhs.iowa.gov/iqrs/providers/homes') #https://dhs.iowa.gov/iqrs/providers/centers
#stop_splash(sp)

#Using Selenium
#For the Homes Data
rd <- rsDriver(browser=c("chrome"), chromever="85.0.4183.83")
rd$client$navigate('https://dhs.iowa.gov/iqrs/providers/homes')
h <- rd$client$getPageSource()

nodes <- h[[1]] %>% 
     read_html() %>% 
     html_nodes(xpath = "/html/body/div[4]/div[2]/div[2]/div[2]/div/div/div/div/div[1]/div/div/div/table[2]")
  
homes_data <- html_table(nodes, fill = TRUE)[[1]]
#str(homes_data)

names(homes_data) <- homes_data[1, ]
homes_data <- homes_data[-1, c(1:6)]

rd$client$close()
rd$server$stop()
rm(rd)
#For the Child Center Tables
rd <- rsDriver(browser=c("chrome"), chromever="85.0.4183.83")
rd$client$navigate('https://dhs.iowa.gov/iqrs/providers/centers')
h <- rd$client$getPageSource()

nodes <- h[[1]] %>% 
  read_html() %>% 
  html_nodes(xpath = "/html/body/div[4]/div[2]/div[2]/div[2]/div/div/div/div/div[1]/div/div/div/table")

child_center_data <- html_table(nodes, fill = TRUE)[[1]]
str(child_center_data)

names(child_center_data) <- child_center_data[1, ]
child_center_data <- child_center_data[-1,]

rd$client$close()
rd$server$stop()
rm(rd)
#Write data to the database

conn <- DBI::dbConnect(RMySQL::MySQL(), 
                       host = "srvanderplas.com",
                       dbname = "scc",
                       user = "remote",
                       password = keyring::key_get("MY_SECRET"))
 #                      password = rstudioapi::askForPassword("Database password"))


dbWriteTable(conn = conn,
             name = "homes_data",
             value = homes_data)

dbWriteTable(conn = conn,
             name = "child_center_data",
             value = child_center_data)

#Check for duplicate columns
skim(dbReadTable(conn, "homes_data"))
