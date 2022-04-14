#!/bin/bash -f

# ///////////////////////////////////////////////////////////////////////////////////////////////////
# //                                                                                               //
# //  Copyright (2022) Patrick A. Bonnaud                                                          //
# //                                                                                               //
# //  This file is part of assign_amberff.sh                                                       //
# //                                                                                               //
# //  assign_amberff.sh is free software; you can redistribute it and/or modify                    //
# //  it under the terms of the GNU General Public License as published by                         //
# //  the Free Software Foundation; either version 2 of the License, or                            //
# //  (at your option) any later version.                                                          //
# //                                                                                               //
# //  assign_amberff.sh is distributed in the hope that it will be useful,                         //
# //  but WITHOUT ANY WARRANTY; without even the implied warranty of                               //
# //  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                                //
# //  GNU General Public License for more details.                                                 //
# //                                                                                               //
# //  You should have received a copy of the GNU General Public License                            //
# //  along with this program.  If not, see <http://www.gnu.org/licenses/>.                        //
# //                                                                                               //
# ///////////////////////////////////////////////////////////////////////////////////////////////////

echo 'Name of the file : '$1
echo

### Check that the name in input does not have the mol2 extension ##################################

SUB='.mol2'

if [[ "$1" == *"$SUB"* ]]; then

  echo 'Only the name of the file is needed as an input'
  echo
  echo 'Please remove ".mol2" from the file name in input'
  echo
  echo 'End of the script'

  exit 0

fi

### Set parameters for acdoctor #################################################################### 

### antechamber -dr no

###use_acdoctor='no'

### Set parameters for charge assignment ###########################################################

echo -n 'Please give the net charge in [e] of the current molecule and press [ENTER] : '

###net_molecular_charge=0

read net_molecular_charge

echo 'The net charge of the molecule is '$net_molecular_charge' [e]'
echo
echo
echo 'Availabe charge methods in antechamber : '
echo
echo 'charge method     abbre.  index | charge method      abbre. index'
echo '-----------------------------------------------------------------'  
echo 'RESP               resp     1  |  AM1-BCC            bcc     2   '
echo 'CM2                cm2      3  |  ESP (Kollman)      esp     4   '
echo 'Mulliken           mul      5  |  Gasteiger          gas     6   '
echo 'Read in Charge     rc       7  |  Write out charge   wc      8   '
echo '-----------------------------------------------------------------'
echo
echo 'Source: http://ambermd.org/antechamber/ac.html#am1bcc'
echo
echo -n 'Please choose the charge method (abbre.) for assigning partial charges and press [ENTER] : '

###charge_method='mul'

read charge_method

if [ $charge_method == 'gas' ]
then
    charge_method_full='Gasteiger'
elif [ $charge_method == 'mul' ]
then
    charge_method_full='Mulliken'
else
    echo 'Not implemented - End of the script'
    exit
fi

echo 'The charge method is '$charge_method_full
echo

### Use antechamber to generate a file in the amber format ######################################### 

### @<TRIPOS>MOLECULE
### @<TRIPOS>ATOM 
### atom_id(=atom index), atom_name, x, y, z, atom_type, subst_id=1, subst_name="noname", charge (integer)
### @<TRIPOS>BOND

input_file=$1'.mol2'

output_file=$1'_new.ac'

echo 'Input file name : '$input_file 
echo
echo 'Output file name : '$output_file
echo


###antechamber -i $input_file -fi mol2 -fo ac -o $output_file -c $charge_method -nc $net_molecular_charge
antechamber -i $input_file -fi mol2 -fo ac -o $output_file -c gas -nc $net_molecular_charge

###exit

### Use antechamber to generate prepi file for parmchk2 ############################################

output_file_prepi=$1'_new.prepi'

echo 'Output file prepi : '$output_file_prepi 
echo

antechamber -fi ac -fo prepi -i $output_file -o $output_file_prepi -c $charge_method -j 5 -at gaff -pf y -nc $net_molecular_charge 

output_file_frcmod=$1'_new.frcmod'

echo 'Output file frcmod : '$output_file_frcmod
echo

parmchk2 -i $output_file_prepi -o $output_file_frcmod -f prepi 


### Use antechamber to generate a pdb file for pdb4amber ###########################################

output_file_pdb=$1'_new.pdb'

echo 'Output file pdb : '$output_file_pdb
echo

###antechamber -fi prepi -fo pdb -i $output_file_prepi -o $output_file_pdb -c $charge_method -j 5 -at gaff -pf y -nc $net_molecular_charge 
antechamber -fi prepi -fo pdb -i $output_file_prepi -o $output_file_pdb -c gas -j 5 -at gaff -pf y -nc $net_molecular_charge 

output_file_pdb_1=$1'_new1.pdb'

### Generate a pdb file for tleap ##################################################################

### pdb4amber -i $output_file_pdb -o $output_file_pdb_1 --reduce --dry

### --reduce --> add hydrogen atoms in their optimal locations
### --dry    --> remove crystallographic waters

pdb4amber -i $output_file_pdb -o $output_file_pdb_1

mv $output_file_pdb_1 $output_file_pdb 

### Generate input file and run tleap ##############################################################

tleap_input=$1'_tleap.in'

echo 'tleap input : '$tleap_input
echo

rm -f $tleap_input

###echo 'source leaprc.protein.ff14SB              #Source leaprc file for ff14SB protein force field'
echo 'source leaprc.gaff                        #Source leaprc file for gaff'                            >  $tleap_input
echo 'loadamberprep    '$output_file_prepi'               #Load the prepi file for the ligand'           >> $tleap_input
echo 'loadamberparams '$output_file_frcmod'               #Load the additional frcmod file for ligand'   >> $tleap_input
echo 'mol = loadpdb '$output_file_pdb'                    #Load PDB file for protein-ligand complex'     >> $tleap_input
echo 'saveamberparm mol '$1'.prmtop '$1'.inpcrd     #Save AMBER topology and coordinate files'           >> $tleap_input
echo 'quit                                      #Quit tleap program'                                     >> $tleap_input

tleap -s -f $tleap_input > $1'_tleap.out'


echo 'End of script for amber tools'
echo

