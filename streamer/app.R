#!/usr/bin/Rscript
library(logger)
log_appender(appender_file('app.log'))
library(AWR.Kinesis)
library(methods)
library(jsonlite)

kinesis_consumer(
  
  initialize = function() {
    log_info('Hello')
    library(rredis)
    redisConnect(nodelay = FALSE)
    log_info('Connected to Redis')
  },
  
  processRecords = function(records) {
    log_info(paste('Received', nrow(records), 'records from Kinesis'))
    for (record in records$data) {
      symbol <- fromJSON(record)$s
      log_info(paste('Found 1 transaction on', symbol))
      redisIncr(paste('symbol', symbol, sep = ':'))
    }
  },
  
  updater = list(
    list(1/6, function() {
      log_info('Checking overall counters')
      symbols <- redisMGet(redisKeys('symbol:*'))
      log_info(paste(sum(as.numeric(symbols)), 'records processed so far'))
    })),
  
  shutdown = function()
    log_info('Bye'),
  
  checkpointing = 1,
  logfile = 'app.log')