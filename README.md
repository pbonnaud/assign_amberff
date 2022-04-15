# assign_amberff
A script that uses ambertools software to assign the AMBER force field to a molecular model originally in the mol2 format

# Pre-requist:

1. Linux with a bash environment
2. The ambertools software is installed (https://ambermd.org/AmberTools.php)

# Expected input file:

name_of_the_molecular_model.mol2    |-->  The Script is written to use a single mol2 file as input
                                          The use of multiple mol2 files as inputs is not taken into account by the script
                                          Only the mole2 file format can be used for this script

# Expected outputs:

name_of_the_molecular_model.inpcrd  |-->  The script will generate an inpcrd file and a prmtop file using ambertools
name_of_the_molecular_model.prmtop  |

# How to run the script:

1. As an input, the script need coordinates of a molecular model of a molecule. Free available software can be used for this step. For example, one can use:

    - Avogadro    (https://avogadro.cc/)
    - Avogadro2   (https://www.openchemistry.org/downloads/)
    - VMD         (https://www.ks.uiuc.edu/Research/vmd/)

2. Run the script with the following command:

    $ ./assign_amberff.sh name_of_the_molecular_model

Here, the full name of the file containing coordinates is name_of_the_molecular_model.mol2
