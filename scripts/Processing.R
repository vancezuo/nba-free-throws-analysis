# Processing.R
# By Vance Zuo
# Script for initial processing of NBA free throw data

print(paste("Working Directory: ", getwd()))

# Plays list contains play by plays for every game in the season
playsURL <- "playbyplay20120510040.txt" # Change to appropriate path if needed
plays <- read.csv(playsURL, sep = "\t", as.is=TRUE)
plays <- plays[order(plays$GameID, plays$LineNumber), ]  # Fixes line order

# Player list contains organized infomration about player's full name, 
# teams (including start/end dates), and position.
playersURL <- "players20120510040.txt" # Change to appropriate path if needed
players <- read.csv(playersURL, sep = "\t", as.is=TRUE)

# This is a quick test to see if there are PlayerName/TeamName3 combinations
# that repeat. There are none, meaning every individual pair is unique. This
# was not true of PlayerNames alone; some players with the same last name
# from different teams have the same PlayerName. Thus we also take into account
# their team. This proves important later when we try to extract the player
# name from a play-by-play.
playersUnique <- players[,c("PlayerName","TeamName3")]
isUnique <- !any(duplicated(playersUnique))
print(paste("Players can be uniquely identifed by name and team:", isUnique))

# EXTRACT FREE THROW DATA
# This column identifies the free throw play-by-plays
plays$isFreeThrow <- grepl("Free Throw", plays$Entry)
numFreeThrow <- sum(plays$isFreeThrow)

# Preallocating the different variables we'll record for each free throw:
# GameID, Date, Home/Away Team, Time Left, Player ID/Name/Team,
# Free Throw Cause/Number/Result, and the teams' Scores
gameID <- rep(NA, numFreeThrow)
date <- rep(NA, numFreeThrow)
homeTeam <- rep(NA, numFreeThrow)
awayTeam <- rep(NA, numFreeThrow)
timeLeft <- rep(NA, numFreeThrow)
playerID <- rep(NA, numFreeThrow)
player <- rep(NA, numFreeThrow)
playerFull <- rep(NA, numFreeThrow)
playerTeam <- rep(NA, numFreeThrow)
type <- rep(NA, numFreeThrow)
number <- rep(NA, numFreeThrow)
result <- rep(NA, numFreeThrow)
ownScore <- rep(NA, numFreeThrow)
oppScore <- rep(NA, numFreeThrow)

# The following loop extracts the free throw information we seek from the 
# raw play-by-play data. Unfortunately, it is unable to discern player 
# information for some 1% of play-by-play entries.
#
# The time it took for it to run:
#  user  system elapsed 
# 32.71    0.02   32.67 
ftIndex <- which(plays$isFreeThrow)
system.time( # START system.time
for (i in 1:numFreeThrow) {
  # The play-by-play text entry
  entryIndex <- ftIndex[i]
  entry <- plays$Entry[entryIndex]
  
  # Game ID is directly copied from the Plays list
  gameID[i] <- as.character(plays$GameID[entryIndex])
  
  # The Date is hidden in the Game ID, and extracted accordingly.
  date[i] <- paste(substr(gameID[i], 1, 4),  # Year
                   substr(gameID[i], 5, 6),  # Month
                   substr(gameID[i], 7, 8),  # Day
                   sep = "-")
  
  # The teams are also located in the Game ID. A quick check on NBA.com 
  # reveals the the format also has the Away Team on the left, followed
  # by the Home Team's symbol
  homeTeam[i] <- substr(gameID[i], 12, 14)
  awayTeam[i] <- substr(gameID[i], 9, 11)
  
  # The time remaining is taken directly from the Plays List
  timeLeft[i] <- as.character(plays$TimeRemaining[entryIndex])

  # Play-by-play entries start with "[XXX".... In the case of free throws, 
  # XXX refers to the team of the player shooting the free throws.
  playerTeam[i] <- substr(entry, 2, 4)    
  
  # To find the player's name in a play-by-play, we search the entry for names
  # from the Player list, limiting our search to players part of the team
  # identified in the entry. It turns out in the players list, every player can 
  # be uniquely identified by their team and PlayerName, so this algorithm
  # will never give a false positive. 
  #
  # HOWEVER, some play-by-plays are ambiguous, causing the function to 
  # write NA. For example, free throw 5249 just has the name "Williams", which 
  # can refer to D. Williams or J. Williams. The original source on NBA.com has 
  # the same ambiguity. It's not clear how to resolve this problem, because
  # both players had free throws that game, so we can't tell which player shot
  # which free throws.
  pTeamRows <- players[players$TeamName3 == playerTeam[i], ]
  pIndex <- match(TRUE, sapply(pTeamRows$PlayerName, grepl, entry))
  playerID[i] <- pTeamRows$PlayerID[pIndex]
  player[i] <- as.character(pTeamRows$PlayerName[pIndex])
  playerFull[i] <- as.character(pTeamRows$PlayerTrueName[pIndex])
  
  # Not all free throws are made equal. The play-by-play data identifies 3
  # types of free throws based on whether they originated from a technical,
  # flagrant, or other foul. Since it's there, I figured I would record it.
  # The free throw number (e.g. whether the shot is the first or second
  # of two) is also recorded.
  if (grepl("Technical", entry)) {
    type[i] <- "Technical"
    number[i] <- "1 of 1"
  } else if (grepl("Flagrant", entry)) { 
    type[i] <- "Flagrant"
    number[i] <- regmatches(entry, regexpr("[1-3] of [1-3]", entry))
  } else {
    type[i] <- "Normal"
    number[i] <- regmatches(entry, regexpr("[1-3] of [1-3]", entry))
  }
  
  # We determine the free throw result by noting that missed free throws are 
  # marked "Missed" in the play-by-play.
  result[i] <- ifelse(grepl("Missed", entry), "Missed", "Made")

  # When a free throw is made, the play-by-play includes an update of the
  # score in the beginning of the entry, between the brackets. The player's
  # team's score is always listed on the left--simple enought to extract.
  #
  # When a free throw is missed, no score data appears in the entry. So we
  # check the previous entries in sequence until we find a entry with scores,
  # or reach the beginning of the game (in which case the score would be 0-0).
  scoreIndex <- entryIndex
  scoreEntry <- entry
  noScore <- FALSE  # Indicates whether score is 0-0 or not
  # rightBracketIndex equals 5 when we have [XXX], >16 with [XXX COACH LINE-...
  rightBracketIndex <- regexpr("]", scoreEntry)
  while (rightBracketIndex <= 5 | rightBracketIndex > 16) {
    # Go to the previous entry
    scoreIndex <- scoreIndex - 1
    scoreEntry <- plays$Entry[scoreIndex]
    # Checks to see if we still in the same game (not a different game's entry)
    if (gameID[i] != plays$GameID[scoreIndex]) {
      noScore <- TRUE  # Score is 0-0
      break
    }
    rightBracketIndex <- regexpr("]", scoreEntry)
  } 
  # At this point we've reached an entry with a score, or the start of the game.
  if (noScore) {
    ownScore[i] <- 0
    oppScore[i] <- 0
  } else {
    # Entry with new scores begins like "[XXX YY-", where XXX is the team
    # with possession's name, and YY is that team's new score. Since YY is 
    # variable length, its bounds are determined relative to the "-" after it.
    dashIndex <- regexpr("-", scoreEntry)
    thisTeam <- substr(scoreEntry, 2, 4)  # The team identified in this entry
    thisScore <- substr(scoreEntry, 6, dashIndex - 1)
    otherScore <- substr(scoreEntry, dashIndex + 1, rightBracketIndex - 1)         
    if (thisTeam == playerTeam[i]) {
      ownScore[i] <- thisScore
      oppScore[i] <- otherScore
    } else {
      ownScore[i] <- otherScore
      oppScore[i] <- thisScore
    }
  }
  
  # This simply displays the progress at regular intervals.
  if (i %% 100 == 0) {
    print(paste("Processed free throw", i, "@ entry", entryIndex))
  }
}
) # END system.time

# SAVE DATA
# Compiles the data into one data frame
freeThrowData <- data.frame(gameID, date, homeTeam, awayTeam, timeLeft, 
                            playerID, player, playerFull, playerTeam, type, 
                            number, result, ownScore, oppScore)
write.csv(freeThrowData, "output.csv", row.names=FALSE)