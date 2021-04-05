#!/bin/bash
################################################################################
#                              scriptTemplate                                  #
#                                                                              #
# Use this template as the beginning of a new program. Place a short           #
# description of the script here.                                              #
#                                                                              #
# Change History                                                               #
# 05/04/2021  ASayal    Original code.                                         #
#                                                                              #
#                                                                              #
################################################################################
################################################################################
#                                                                              #
#  Alexandre Sayal                                                             #
#  2021                                                                        #
#                                                                              #
################################################################################
################################################################################

# --------------------------------------------------------------------------------
#  Help function
# --------------------------------------------------------------------------------
Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: scriptTemplate [-g|h|t|v|V]"
   echo "options:"
   echo "g     Print the GPL license notification."
   echo "h     Print this Help."
   echo "v     Verbose mode."
   echo "V     Print software version and exit."
   echo
}

# --------------------------------------------------------------------------------
#  Process the input options.
# --------------------------------------------------------------------------------

while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
     \?) # incorrect option
         echo "Error: Invalid option"
         exit;;
   esac
done

echo "Hello world!"