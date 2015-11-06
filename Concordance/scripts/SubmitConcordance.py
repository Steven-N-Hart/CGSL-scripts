import sys
import os
import subprocess
from optparse import OptionParser
from random import randint
from subprocess import call
import time

#######################################################################

'''This program SubmitsConcordance scripts according to a given config file

Usage: python SubmitConcordance.py -c <ConfigFile> -r <Run.sh path> -o <outputPath>

Author: Jagadheshwar Balan, Saranya Sanakaranarayanan
Contact: balan.jagadheshwar@mayo.edu, Sankaranarayanan.Saranya@mayo.edu

'''

#######################################################################

usage = "python SubmitConcordance.py -c <ConfigFile> -r <Run.sh path> -o <outputPath>"
parser = OptionParser(usage = usage)
parser.add_option("-r", "--runSH", dest = "run", help = "The path for run script")
parser.add_option("-c", "--CFile", dest = "config", help = "The config file of VCFs")
parser.add_option("-o", "--outDir", dest = "output", help = "The output file for the ")
(options, args) = parser.parse_args()

if(len(sys.argv) < 7):
	print("python SubmitConcordance.py -c <ConfigFile> -r <Run.sh path> -o <outputPath>")
	sys.exit()


Configpath = os.path.abspath(options.config)
RunSh = os.path.abspath(options.run)
OutputPath = os.path.abspath(options.output)
if os.path.isdir(OutputPath) == False:
	os.makedirs(OutputPath)


time.sleep(1)

ScriptPath = RunSh.replace(RunSh.split("/")[-1],"")[:-1]

print "Running Concordance Scripts"
Cmd = RunSh + " " + os.path.abspath(options.config) + " " + OutputPath + " " + ScriptPath

subprocess.call([Cmd], shell=True)

