Basketball Free Throws Scripts & Analysis
====

This repository contains R scripts, data, and results from Vance Zuo's semester
project for Yale's STAT 230 -- Introductory Data Analysis course. It is 
designed to analyze basketball free throws from data files from 
http://basketballvalue.com/.

The scripts themselves are located in the "scripts" directory. Data used
in the project is located under "data", and resulting tables, figures,
and other output under "result".

Requirements
----
* R version 2.15 or higher

Setup
----
The scripts require the R programming language to be run, which can be
downloaded from http://www.r-project.org/.

Usage
----
Although the scripts were programmed to study only one year's worth of
basketball free throw data, they should be easy to configure to analyze 
basketball data from http://basketballvalue.com/ for any season.

To run the scripts, change the strings in the lines in "Processing.R"

    playsURL <- "playbyplay20120510040.txt" # Change to appropriate path if needed
    
and
   
    playersURL <- "players20120510040.txt" # Change to appropriate path if needed

to the paths to play-by-play and players data files from 
http://basketballvalue.com/ for a given season, respectively. 
Currently, the paths specify 2011-2012 regular season data files that are
assumed to be in the same directory as the currently working directory
(usually the directory of the scripts themselves).

After that, run "Processing.R", which will produce a relatively raw CSV file
where each row represents a single free throw instance. 
This can be analyzed as is, but it is recommended to also run "Refining.R",
which computes some statistical parameters and produces a CSV ("ft clean.csv")
that prunes invalid rows. The user can then run "Analysis.R", which does
various statistical tests and produces graphical/textual results using 
"ft clean.csv" data, or they can run their own analyses.