library(rredis)
library(data.table)
library(binancer)
library(ggplot2)
library(slackr)
library(botor)
library(dplyr)
library(logger)
library(scales)

redisConnect()

# Botor and slack customization
botor(region = 'eu-west-1')
token <- ssm_get_parameter('slack')
slackr_setup(username = 'Ozzy Oz', 
             bot_user_oauth_token = token, 
             icon_emoji = ':hatched_chick:')

records <- redisMGet(redisKeys('symbol:*'))
df <- data.table(coin = gsub('symbol:', '', names(records)), count = as.numeric(records))
df <- df[order(-count)]
df[, B := substr(coin, 1, 3)]
df <- df[, .(count, B)]
df <- aggregate(count ~ B, data = df, FUN = sum)

df <- merge(df, binance_coins_prices(), by.x = 'B', by.y = 'symbol', all.x = TRUE)
df <- as.data.table(df)
df[, volume := count * usd]
df <- df[order(-volume)]


slackr_msg(text = paste0("It seems that our volume is ", dollar(df[, sum(volume)])), 
           channel = '#bots-final-project')

slackr_msg(text = "Let's take a look at some visuals as well", 
           channel = '#bots-final-project')

graph_1 <- ggplot(df) + 
  geom_col(aes(x = factor(df$B, levels = df$B), y = volume/10^6), fill="steelblue", width = 0.5) + 
  labs(x = "Coin", y = "Volume in mm USD", title = "Transaction Volume for the Given Coin") +
  theme_bw()

ggslackr(plot = graph_1, channels = '#bots-final-project', width = 12)

slackr_msg(text = paste0("The bulk of the volume seems to be driven by transactions on ", df$B[1], 
                         " where its price being ", dollar(df$usd[1])), 
           channel = '#bots-final-project')


graph_2 <- ggplot(df, aes(x = count, y = volume/10^6)) + geom_point(color = "dark blue") + 
  labs(x = "Trade Count", y = "Volume in mm USD", title = "Volume per Trade Count")
graph_2.5 <- ggplot(df[B != "BTC"], aes(x = count, y = volume/10^6)) + geom_point(color = "dark blue") + 
  labs(x = "Trade Count", y = "Volume in mm USD", title = "Volume per Trade Count (-BTC)")


slackr_msg(text = "Looking at a simple scatterplot", 
           channel = '#bots-final-project')


ggslackr(plot = graph_2, channels = '#bots-final-project', width = 12)

slackr_msg(text = "Removing BTC", 
           channel = '#bots-final-project')


ggslackr(plot = graph_2.5, channels = '#bots-final-project', width = 12)


