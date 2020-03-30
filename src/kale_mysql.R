# script to connet to kale mysql server

library(keyring)

kale <- DBI::dbConnect(RMySQL::MySQL(),
                        user = key_list("kale_mysql")[1, 2], 
                        password = key_get("kale_mysql", 
                                           key_list("kale_mysql")[1, 2]),
                        dbname = "NOVA6", 
                        host = "127.0.0.1",
                        port = 9999)