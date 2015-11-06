#!/usr/bin/python
import sys
import re
import random
from decimal import *
import sys
import os
import subprocess
from optparse import OptionParser
from random import randint
from subprocess import call
import time

#######################################################################

'''This program prepares the wrapper script for ALK-ROS-RET LIKE pipeline and submits it

Usage: python PrepareConcordanceConfigFile.py -i <inputBedFile> -v1 <VCF1_File> -v2 <VCF_File2> -o <OutputPath> -t <Analysis_Type> -c <Config_FilePath>

Author: Jagadheshwar Balan, Saranya Sanakaranarayanan
Contact: balan.jagadheshwar@mayo.edu, Sankaranarayanan.Saranya@mayo.edu

'''

#######################################################################

usage = "python PrepareConcordanceConfigFile.py -i <inputBedFile> -a <VCF_File1> -b <VCF_File2> -o <OutputPath> -t <Analysis_Type> -c <Config_File>"
parser = OptionParser(usage = usage)
parser.add_option("-i", "--inpBed", dest = "bed", help = "The path to the bed file")
parser.add_option("-a", "--inpVcf1", dest = "vcf1", help = "The path to the vcf 1 file")
parser.add_option("-b", "--inpVcf2", dest = "vcf2", help = "The path to the vcf  2 file")
parser.add_option("-o", "--outVcf", dest = "out", help = "The path to the output vcf file")
parser.add_option("-t", "--AType", dest = "type", help = "The type of analysis")
parser.add_option("-c", "--CFile", dest = "config", help = "The config file output to concordance scripts")
(options, args) = parser.parse_args()

if(len(sys.argv) < 13) :
	print("python PrepareConcordanceConfigFile.py -i <inputBedFile> -a <VCF1_File> -b <VCF_File2> -o <OutputPath> -t <Analysis_Type> -c <Config_File>")
	sys.exit()

BedPath = os.path.abspath(options.bed)
VCF1Path = os.path.abspath(options.vcf1)
VCF2Path = os.path.abspath(options.vcf2)
OutputPath = os.path.abspath(options.out)
FileExists = 0
if os.path.isdir(OutputPath) == False:
	os.makedirs(OutputPath)
if os.path.isfile(os.path.abspath(options.config)):
	FileExists = 1
	ConfigFile = open(os.path.abspath(options.config),"a")
else:
	ConfigFile = open(options.config,"w")
Analysis_Type = options.type
BedFile = open(BedPath,"r")
VCF1File = open(VCF1Path,"r")
VCF2File = open(VCF2Path,"r")

print "Preparing VCF Files and config Files..."
def CheckWithinGeneBed(CurChr,CurChrStart,CurChrEnd,KnownGenes):
	WithinFlag = 0
	for eachGene in KnownGenes:
		ChrCoordinates_Split = KnownGenes[eachGene].split(":")
		Chromosome = ChrCoordinates_Split[0]
		Coordinates_Split = ChrCoordinates_Split[1].split("-")
		ChrStart = int(Coordinates_Split[0])
		ChrEnd = int(Coordinates_Split[1])
		if CurChr in Chromosome:
			if CurChrStart>= ChrStart and CurChrEnd<=ChrEnd:
				WithinFlag = 1
	if WithinFlag == 0:
		return 0
	else:
		return 1

KnownGenes = {}
for eachLine in BedFile:
	if len(eachLine) < 4:
		continue
	eachLine_split = eachLine.split("\t")
	Gene_Tr = eachLine_split[3]
	Exon = eachLine_split[4]
	Chr = eachLine_split[0]
	ChrStart  = int(eachLine_split[1])-30
	ChrEnd = int(eachLine_split[2])+30
	Chr_Req_Str = Chr+":"+str(ChrStart)+"-"+str(ChrEnd)
	Gene_Exon = Gene_Tr + "ex" + Exon
	KnownGenes[Gene_Exon] = Chr_Req_Str



def VCFFileHandler(VCFFile,KnownGenes):
	VCFHeader = ""
	VCFEntries = ""
	for eachLine in VCFFile:
		if len(eachLine) < 4:
			continue
		if eachLine[0] in "#":
			VCFHeader += eachLine
		else:
			eachLine_split = eachLine.split("\t")
			VCF_Chr = eachLine_split[0]
			VCF_Start = int(eachLine_split[1])
			VCF_Stop = int(VCF_Start)
			CheckWithinFlag = CheckWithinGeneBed(VCF_Chr,VCF_Start,VCF_Stop,KnownGenes)
			if CheckWithinFlag == 1:
				VCFEntries += eachLine
	return (VCFHeader,VCFEntries)
	
def VCFWriter(VCFHeader,VCFEntries,Number):
	VCFHeadersSplit = VCFHeader.split("\r")
	Sample = VCFHeadersSplit[-1].split("\t")[-1].split("_")[0].strip()
	Sample = Sample.split(" ")[0]
	VCFHeader = VCFHeader.replace(VCFHeadersSplit[-1].split("\t")[-1],Sample+"_"+Number+"\n")
	OutputFile = open(OutputPath+"/"+Sample+"_"+Number+"_"+Analysis_Type+".vcf","w")
	VCFOutputPath = OutputPath+"/"+Sample+"_"+Number+"_"+Analysis_Type+".vcf"
	OutputFile.write(VCFHeader)
	OutputFile.write(VCFEntries)
	OutputFile.close()
	return (VCFOutputPath,Sample+"_"+Number)

ConfigFile_Str = Analysis_Type.strip()

VCF1_Header,VCF1_Entries = VCFFileHandler(VCF1File,KnownGenes)
VCF2_Header,VCF2_Entries = VCFFileHandler(VCF2File,KnownGenes)
VCF1Output,Sample1 = VCFWriter(VCF1_Header,VCF1_Entries,"1")
VCF2Output,Sample2 = VCFWriter(VCF2_Header,VCF2_Entries,"2")

ConfigFile_Str = ConfigFile_Str + " " + VCF1Output + " " + VCF2Output + " " + Sample1 + " " + Sample2+"\n"
ConfigFile.write(ConfigFile_Str)
ConfigFile.close()
	


