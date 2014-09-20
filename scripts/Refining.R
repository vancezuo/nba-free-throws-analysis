# Analysis.R
# By Vance Zuo
# Script for cleaning up and computing additional parameters for analysis
# of the results from Processing.R.

# REFINING DATA
# Computes some parameters for statistical anaylsis
ft <- read.csv("output.csv")

# Seconds left
overtime.multiplier <- ifelse(grepl("-[.]*", ft$timeLeft), -1, 1)
timeLeft.c <- as.character(ft$timeLeft)
ft$secondsLeft <- sapply(strsplit(timeLeft.c,":"),
                         function(x) {
                           x <- as.numeric(x)
                           x[2]*60 + x[3]
                         }
)
ft$secondsLeft <- ft$secondsLeft * overtime.multiplier
ft$minutesLeft <- floor(ft$secondsLeft / 60) # For graphical purposes

# Free throw number and total as seperate numeric values
# Previous tries (free throw # minus 1)
ft$thisNumber <- substr(ft$number, 1, 1)
ft$prevTries <- as.numeric(ft$thisNumber) - 1
ft$totalNumber <- substr(ft$number, 6, 6)

# Boolean home team parameter
ft$isHomeTeam <- ft$playerTeam == ft$homeTeam

# The opposing team
ft$otherTeam <- ifelse(ft$isHomeTeam, 
                       as.character(ft$awayTeam), 
                       as.character(ft$homeTeam))

# The resulting/previous score differencial, boolean success parameter,
# and closeness (absolute score difference)
ft$ownScore <- as.numeric(as.character(ft$ownScore))
ft$oppScore <- as.numeric(as.character(ft$oppScore))
ft$resultScoreDiff <- ft$ownScore - ft$oppScore 

ft$success <- ft$result == "Made"
ft$prevScoreDiff <- ft$resultScoreDiff - ft$success
ft$closeness <- abs(ft$prevScoreDiff) 

# Some additional boolean parameters
ft$ahead <- ft$prevScoreDiff > 0
ft$under5min <- ft$secondsLeft < 300
ft$within5 <- abs(ft$prevScoreDiff) <= 5
ft$clutch55 <- ft$under5min & ft$within5

ft$overtime <- ft$secondsLeft < 0
ft$down1 <- ft$prevScoreDiff == -1
ft$tie <- ft$prevScoreDiff == 0

# SAVING DATA
write.csv(ft, "ft all.csv", row.names=FALSE)

# The data without NA player rows
cleanedData <- ft[!is.na(ft$player),]
write.csv(cleanedData, "ft clean.csv", row.names=FALSE)

# The data containing just the NA players rows
naData <- ft[is.na(ft$player),]
write.csv(naData, "ft na.csv", row.names=FALSE)