#!/bin/bash

# createRunDir.sh: Create GEOS-Chem Classic run directory
#
# Optional argument: run directory name
#
# If optional run directory name argument is not passed then the user
# will be prompted to enter a name interactively, or choose to use the
# default name gc_{met}_{sim_name}.
#
# Usage: ./createRunDir.sh [rundirname]
#
# Initial version: M. Sulprizio, 6/24/2020 (based off GCHP/createRunDir.sh)

srcrundir=$(pwd -P)
cd ${srcrundir}
cd ../..
gcdir=$(pwd -P)
cd ../../
wrapperdir=$(pwd -P)
cd ${srcrundir}

# Load file with utility functions to setup configuration files
. ${gcdir}/run/shared/setupConfigFiles.sh

# Initialize Run Directory Initialization (RDI) variables
RDI_VARS=""
RDI_VARS+="RDI_GC_MODE='GCClassic'\n"

# Define separator lines
thickline="\n===========================================================\n"
thinline="\n-----------------------------------------------------------\n"

printf "${thickline}GEOS-CHEM RUN DIRECTORY CREATION${thickline}"

#-----------------------------------------------------------------
# Export data root path in ~/.geoschem/config if file exists
#-----------------------------------------------------------------
if [[ -f ${HOME}/.geoschem/config ]]; then
    source ${HOME}/.geoschem/config
    if [[ ! -d ${GC_DATA_ROOT} ]]; then
	printf "\nWarning: Default root data directory does not exist!"
        printf "\nSet new path below or manually edit ${HOME}/.geoschem/config.\n"
    fi
else
    printf "${thinline}Define path to ExtData."
    printf "\nThis will be stored in ${HOME}/.geoschem/config for future automatic use.${thinline}"
    mkdir -p ${HOME}/.geoschem
fi

#-----------------------------------------------------------------
# One-time configuration of data root path in ~/.geoschem/config
#-----------------------------------------------------------------
if [[ -z "${GC_DATA_ROOT}" ]]; then
    printf "${thinline}Enter path for ExtData:${thinline}"
    valid_path=0
    while [ "$valid_path" -eq 0 ]; do
	read -e extdata
	if [[ ${extdata} = "q" ]]; then
	    printf "\nExiting.\n"
	    exit 1
	elif [[ ! -d ${extdata} ]]; then
            printf "\nERROR: ${extdata} does not exist. Enter a new path or hit q to quit.\n"
	else
	    valid_path=1
	    echo "export GC_DATA_ROOT=${extdata}" >> ${HOME}/.geoschem/config
            source ${HOME}/.geoschem/config
	fi
    done
fi

RDI_VARS+="RDI_DATA_ROOT=$GC_DATA_ROOT\n"

#-----------------------------------------------------------------
# Ask user to select simulation type
#-----------------------------------------------------------------
printf "${thinline}Choose simulation type:${thinline}"
printf "   1. Full chemistry\n"
printf "   2. Aerosols only\n"
printf "   3. CH4\n"
printf "   4. CO2\n"
printf "   5. Hg\n"
printf "   6. POPs\n"
printf "   7. Tagged CH4\n"
printf "   8. Tagged CO\n"
printf "   9. Tagged O3\n"
printf "  10. TransportTracers\n"
printf "  11. Trace metals\n"

valid_sim=0
while [ "${valid_sim}" -eq 0 ]; do
    read sim_num
    valid_sim=1
    if [[ ${sim_num} = "1" ]]; then
	sim_name=fullchem
    elif [[ ${sim_num} = "2" ]]; then
	sim_name=aerosol
    elif [[ ${sim_num} = "3" ]]; then
	sim_name=CH4
    elif [[ ${sim_num} = "4" ]]; then
	sim_name=CO2
    elif [[ ${sim_num} = "5" ]]; then
	sim_name=Hg
    elif [[ ${sim_num} = "6" ]]; then
	sim_name=POPs
    elif [[ ${sim_num} = "7" ]]; then
	sim_name=tagCH4
    elif [[ ${sim_num} = "8" ]]; then
	sim_name=tagCO
    elif [[ ${sim_num} = "9" ]]; then
	sim_name=tagO3
    elif [[ ${sim_num} = "10" ]]; then
	sim_name=TransportTracers
    elif [[ ${sim_num} = "11" ]]; then
	sim_name=metals
    else
        valid_sim=0
	printf "Invalid simulation option. Try again.\n"
    fi
done

RDI_VARS+="RDI_SIM_NAME=$sim_name\n"

#-----------------------------------------------------------------
# Ask user to specify full-chemistry simulation options
#-----------------------------------------------------------------
sim_extra_option=none

# Ask user to specify full chemistry simulation options
if [[ ${sim_name} = "fullchem" ]]; then

    printf "${thinline}Choose additional simulation option:${thinline}"
    printf "  1. Standard\n"
    printf "  2. Benchmark\n"
    printf "  3. Complex SOA\n"
    printf "  4. Marine POA\n"
    printf "  5. Acid uptake on dust\n"
    printf "  6. TOMAS\n"
    printf "  7. APM\n"
    printf "  8. RRTMG\n"
    valid_sim_option=0
    while [ "${valid_sim_option}" -eq 0 ]; do
	read sim_option
	valid_sim_option=1
	if [[ ${sim_option} = "1" ]]; then
	    sim_extra_option=none
	elif [[ ${sim_option} = "2" ]]; then
	    sim_extra_option="benchmark"
	elif [[ ${sim_option} = "3" ]]; then
	    printf "${thinline}Choose complex SOA option:${thinline}"
	    printf "  1. Complex SOA\n"
	    printf "  2. Complex SOA with semivolatile POA\n"
	    valid_soa=0
	    while [ "${valid_soa}" -eq 0 ]; do
		read soa_option
		valid_soa=1
		if [[ ${soa_option} = "1" ]]; then
		    sim_extra_option="complexSOA"
		elif [[ ${soa_option} = "2" ]]; then
		    sim_extra_option="complexSOA_SVPOA"
		else
		    valid_soa=0
		    printf "Invalid complex SOA option.Try again.\n"
		fi
	    done
	elif [[ ${sim_option} = "4" ]]; then
	    sim_extra_option="marinePOA"
	elif [[ ${sim_option} = "5" ]]; then
	    sim_extra_option="aciduptake"
	elif [[ ${sim_option} = "6" ]]; then
	    printf "${thinline}Choose TOMAS option:${thinline}"
	    printf "  1. TOMAS with 15 bins\n"
	    printf "  2. TOMAS with 40 bins\n"
	    valid_tomas=0
	    while [ "${valid_tomas}" -eq 0 ]; do
		read tomas_option
		valid_tomas=1
		if [[ ${tomas_option} = "1" ]]; then
		    sim_extra_option="TOMAS15"
		elif [[ ${tomas_option} = "2" ]]; then
		    sim_extra_option="TOMAS40"
		else
		    valid_tomas=0
		    printf "Invalid TOMAS option. Try again.\n"
		fi
	    done
	elif [[ ${sim_option} = "7" ]]; then
	    sim_extra_option="APM"
	elif [[ ${sim_option} = "8" ]]; then
	    sim_extra_option="RRTMG"
            printf "*** IMPORTANT: You must manually specify -DRRTMG=y when compiling the model. ***\n"
	else
	    valid_sim_option=0
	    printf "Invalid simulation option. Try again.\n"
	fi
    done

# Currently no transport tracer extra options
elif [[ ${sim_name} = "TransportTracers" ]]; then
    sim_extra_option=none

# Ask user to specify POPs simulation options
elif [[ ${sim_name} = "POPs" ]]; then
    printf "${thinline}Choose POPs type:${thinline}"
    printf "  1. BaP\n"
    printf "  2. PHE\n"
    printf "  3. PYR\n"
    valid_pops=0
    while [ "${valid_pops}" -eq 0 ]; do
	read pops_num
	valid_pops=1
	if [[ ${pops_num} = "1" ]]; then
	    sim_extra_option="BaP"
	elif [[ ${pops_num} = "2" ]]; then
	    sim_extra_option="PHE"
	elif [[ ${pops_num} = "3" ]]; then
	    sim_extra_option="PYR"
	else
	    valid_pops=0
	    printf "Invalid POPs type. Try again.\n"
	fi
    done
fi

RDI_VARS+="RDI_SIM_EXTRA_OPTION=$sim_extra_option\n"

# Determine settings based on simulation type
SettingsDir="${gcdir}/run/shared/settings"
if [[ ${sim_extra_option} == "BaP" ]]; then
    RDI_VARS+="$(cat ${SettingsDir}/POPs_BaP.txt)\n"
elif [[ ${sim_extra_option} == "PHE" ]]; then
    RDI_VARS+="$(cat ${SettingsDir}/POPs_PHE.txt)\n"
elif [[ ${sim_extra_option} == "PYR" ]]; then
    RDI_VARS+="$(cat ${SettingsDir}/POPs_PYR.txt)\n"
fi

if [[ ${sim_extra_option} == "benchmark"  ]] || \
   [[ ${sim_extra_option} =~ "complexSOA" ]] || \
   [[ ${sim_extra_option} == "APM"        ]]; then
    RDI_VARS+="RDI_COMPLEX_SOA='T'\n"
    if [[ ${sim_extra_option}="complexSOA_SVPOA" ]]; then
	RDI_VARS+="RDI_SVPOA='T'\n"
    else
	RDI_VARS+="RDI_SVPOA='F'\n"
    fi
else
    RDI_VARS+="RDI_COMPLEX_SOA='F'\n"
    RDI_VARS+="RDI_SVPOA='F'\n"
fi

if [[ ${sim_extra_option} == "aciduptake" ]]; then
    RDI_VARS+="RDI_DUSTALK_EXT='on '\n"
    RDI_VARS+="RDI_ACID_UPTAKE='T'\n"
else
    RDI_VARS+="RDI_DUSTALK_EXT='off'\n"
    RDI_VARS+="RDI_ACID_UPTAKE='F'\n"
fi

if [[ ${sim_extra_option} == "marinePOA" ]]; then
    RDI_VARS+="RDI_MARINE_POA='T'\n"
else
    RDI_VARS+="RDI_MARINE_POA='F'\n"
fi

if [[ ${sim_extra_option} == "RRTMG" ]]; then
    RDI_VARS+="RDI_RRTMG_OPTS='T'\n"
    RDI_VARS+="RDI_USE_RRTMG='true '\n"
else
    RDI_VARS+="RDI_RRTMG_OPTS='F'\n"
    RDI_VARS+="RDI_USE_RRTMG='false'\n"
fi

if [[ ${sim_extra_option} =~ "TOMAS" ]]; then
    RDI_VARS+="RDI_USE_NLPBL='F'\n"
    RDI_VARS+="RDI_USE_ONLINE_O3='F'\n"
else
    RDI_VARS+="RDI_USE_NLPBL='T'\n"
    RDI_VARS+="RDI_USE_ONLINE_O3='T'\n"
fi

#-----------------------------------------------------------------
# Ask user to select meteorology source
#-----------------------------------------------------------------
printf "${thinline}Choose meteorology source:${thinline}"
printf "  1. MERRA-2 (Recommended)\n"
printf "  2. GEOS-FP \n"
printf "  3. GISS ModelE2.1 (GCAP 2.0)\n"

valid_met=0
while [ "${valid_met}" -eq 0 ]; do
    read met_num
    valid_met=1
    if [[ ${met_num} = "1" ]]; then
	met="merra2"
	RDI_VARS+="$(cat ${gcdir}/run/shared/settings/merra2.txt)\n"
	RDI_VARS+="RDI_MET_FIELD_CONFIG='HEMCO_Config.rc.gmao_metfields'\n"
    elif [[ ${met_num} = "2" ]]; then
	met="geosfp"
	RDI_VARS+="$(cat ${gcdir}/run/shared/settings/geosfp.txt)\n"
	RDI_VARS+="RDI_MET_FIELD_CONFIG='HEMCO_Config.rc.gmao_metfields'\n"
    elif [[ ${met_num} = "3" ]]; then
	met="ModelE2.1"
	RDI_VARS+="$(cat ${gcdir}/run/shared/settings/modele2.1.txt)\n"
	RDI_VARS+="RDI_MET_FIELD_CONFIG='HEMCO_Config.rc.gcap2_metfields'\n"
    else
	valid_met=0
	printf "Invalid meteorology option. Try again.\n"
    fi
done

if [[ ${met} = "ModelE2.1" ]]; then
    printf "${thinline}Choose scenario (presently available years in parentheses):${thinline}"
    printf "  1. Historical (1851-1860; 2001-2014)\n"
    printf "  2. Historical nudged to MERRA-2 (2001-2014)\n"
    printf "  3. SSP1-1.9 (2040-2049; 2090-2099)\n"
    printf "  4. SSP1-2.6 (2040-2049; 2090-2099)\n"
    printf "  5. SSP4-3.4 (2040-2049; 2090-2099)\n"
    printf "  6. SSP2-4.5 (2040-2049; 2090-2099)\n"
    printf "  7. SSP4-6.0 (2040-2049; 2090-2099)\n"
    printf "  8. SSP3-7.0 (2040-2049; 2090-2099)\n"
    printf "  9. SSP5-8.5 (2040-2049; 2090-2099)\n"

    valid_scen=0
    while [ "${valid_scen}" -eq 0 ]; do
	read scen_num
	valid_scen=1
	if [[ ${scen_num} = "1" ]]; then
	    scenario="HIST"
            runid="E213f10aF40oQ40"
	    RDI_VARS+="RDI_MET_AVAIL='# 1851-1860; 2001-2014'\n"
	elif [[ ${scen_num} = "2" ]]; then
	    scenario="HIST"
            runid="E213f10aF40oQ40nudge"
	    RDI_VARS+="RDI_MET_AVAIL='# 2001-2014"
	elif [[ ${scen_num} = "3" ]]; then
	    scenario="SSP119"
            runid="E213SSP119aF40oQ40"
	    RDI_VARS+="RDI_MET_AVAIL='# 2040-2049; 2090-2099'\n"
	elif [[ ${scen_num} = "4" ]]; then
	    scenario="SSP119"
            runid="E213SSP119aF40oQ40"
	    RDI_VARS+="RDI_MET_AVAIL='# 2040-2049; 2090-2099'\n"
	elif [[ ${scen_num} = "5" ]]; then
	    scenario="SSP119"
            runid="E213SSP119aF40oQ40"
	    RDI_VARS+="RDI_MET_AVAIL='# 2040-2049; 2090-2099'\n"
	elif [[ ${scen_num} = "6" ]]; then
	    scenario="SSP119"
            runid="E213SSP119aF40oQ40"
	    RDI_VARS+="RDI_MET_AVAIL='# 2040-2049; 2090-2099'\n"
	elif [[ ${scen_num} = "7" ]]; then
	    scenario="SSP119"
            runid="E213SSP119aF40oQ40"
	    RDI_VARS+="RDI_MET_AVAIL='# 2040-2049; 2090-2099'\n"
	elif [[ ${scen_num} = "8" ]]; then
	    scenario="SSP119"
            runid="E213SSP119aF40oQ40"
	    RDI_VARS+="RDI_MET_AVAIL='# 2040-2049; 2090-2099'\n"
	elif [[ ${scen_num} = "9" ]]; then
	    scenario="SSP119"
            runid="E213SSP119aF40oQ40"
	    RDI_VARS+="RDI_MET_AVAIL='# 2040-2049; 2090-2099'\n"
	else
  	    valid_scen=0
	    printf "Invalid GCAP 2.0 scenario. Try again.\n"
	fi
	RDI_VARS+="RDI_GCAP2_SCENARIO='$scenario'\n"
	RDI_VARS+="RDI_GCAP2_RUNID='$runid'\n"
    done

    if [[ "${sim_name}" == "fullchem" ]] || [[ "${sim_name}" == "aerosol" ]]; then
	printf "${thinline}Choose a fixed year for volcanic emissions (1978-2020)\n or -1 for year of simulation (assuming year exists):${thinline}"
	valid_volc=0
	while [ "${valid_volc}" -eq 0 ]; do
	    read volc_year
	    valid_volc=1
	    echo $volc_year
	    if [[ $volc_year -ge 1978 ]] && [[ $volc_year -le 2020 ]]; then
		RDI_VARS+="RDI_VOLC_YEAR='$volc_year'\n"
            elif [[ $volc_year -eq -1 ]]; then
		RDI_VARS+="RDI_VOLC_YEAR='$YYYY'\n"
	    else
  		valid_volc=0
		printf "Invalid volcano year. Try again.\n"
            fi
	done
    fi

else
    RDI_VARS+="RDI_GCAP2_SCENARIO='not_used'\n"
    RDI_VARS+="RDI_GCAP2_RUNID='not_used'\n"
    RDI_VARS+="RDI_VOLC_YEAR='\$YYYY'\n"
    RDI_VARS+="RDI_MET_AVAIL='# 1980-2021'\n"
fi

#-----------------------------------------------------------------
# Ask user to select horizontal resolution
#-----------------------------------------------------------------
printf "${thinline}Choose horizontal resolution:${thinline}"
if [[ ${met} = "ModelE2.1" ]] || [[ ${met} = "ModelE2.2" ]]; then
    printf "  1. 4.0  x 5.0 *\n"
    printf "  2. 2.0  x 2.5\n"
    printf "  3. 0.5  x 0.625 *\n"
    printf "  4. 0.25 x 0.3125 *${thinline}"
    printf "  \n* Will be interpolated online via FlexGrid from native 2.0 x 2.5 resolution\n"
else
    printf "  1. 4.0  x 5.0\n"
    printf "  2. 2.0  x 2.5\n"
    printf "  3. 0.5  x 0.625\n"
    if [[ ${met} = "geosfp" ]]; then
	printf "  4. 0.25 x 0.3125\n"
    fi
fi

valid_res=0
while [ "${valid_res}" -eq 0 ]; do
    read res_num
    valid_res=1
    if [[ ${res_num} = "1" ]]; then
	grid_res='4x5'
	RDI_VARS+="$(cat ${gcdir}/run/shared/settings/4x5.txt)\n"
    elif [[ ${res_num} = "2" ]]; then
	grid_res='2x25'
	RDI_VARS+="$(cat ${gcdir}/run/shared/settings/2x25.txt)\n"
    elif [[ ${res_num} = "3" ]]; then
	grid_res='05x0625'
	RDI_VARS+="$(cat ${gcdir}/run/shared/settings/05x0625.txt)\n"
    elif [[ ${res_num} = "4" ]]; then
	grid_res='025x03125'
	RDI_VARS+="$(cat ${gcdir}/run/shared/settings/025x03125.txt)\n"
    else
	valid_res=0
	printf "Invalid horizontal resolution option. Try again.\n"
    fi
done

if [[ ${grid_res} = "05x0625" ]] || [[ ${grid_res} = "025x03125" ]]; then
    printf "${thinline}Choose horizontal grid domain:${thinline}"
    printf "  1. Global\n"
    printf "  2. Asia\n"
    printf "  3. Europe\n"
    printf "  4. North America\n"
    printf "  5. Custom\n"

    valid_domain=0
    while [ "${valid_domain}" -eq 0 ]; do
	read domain_num
	valid_domain=1
	if [[ ${domain_num} = "1" ]]; then
	    RDI_VARS+="$(cat ${gcdir}/run/shared/settings/global_grid.txt)\n"
	else
	    RDI_VARS+="$(cat ${gcdir}/run/shared/settings/nested_grid.txt)\n"
	    if [[ ${domain_num} = "2" ]]; then
		RDI_VARS+="RDI_GRID_DOMAIN_NAME='AS'\n"
	        if [[ ${grid_res} = "05x0625" ]]; then
	            RDI_VARS+="RDI_GRID_LON_RANGE=' 60.0 150.0'\n"
		    RDI_VARS+="RDI_GRID_LAT_RANGE='-11.0  55.0'\n"
		elif [[ ${grid_res} = "025x03125" ]]; then
	            RDI_VARS+="RDI_GRID_LON_RANGE=' 70.0 140.0'\n"
		    RDI_VARS+="RDI_GRID_LAT_RANGE=' 15.0  55.0'\n"
		fi
	    elif [[ ${domain_num} = "3" ]]; then
		RDI_VARS+="RDI_GRID_DOMAIN_NAME='EU'\n"
	        if [[ ${grid_res} = "05x0625" ]]; then
	            RDI_VARS+="RDI_GRID_LON_RANGE='-30.0 50.0'\n"
		    RDI_VARS+="RDI_GRID_LAT_RANGE=' 30.0 70.0'\n"
		elif [[ ${grid_res} = "025x03125" ]]; then
	            RDI_VARS+="RDI_GRID_LON_RANGE='-15.0  40.0'\n"
		    RDI_VARS+="RDI_GRID_LAT_RANGE=' 32.75 61.25'\n"
		fi
	    elif [[ ${domain_num} = "4" ]]; then
		RDI_VARS+="RDI_GRID_DOMAIN_NAME='NA'\n"
	        if [[ ${grid_res} = "05x0625" ]]; then
	            RDI_VARS+="RDI_GRID_LON_RANGE='-140.0 -40.0'\n"
		    RDI_VARS+="RDI_GRID_LAT_RANGE='  10.0  70.0'\n"
		elif [[ ${grid_res} = "025x03125" ]]; then
	            RDI_VARS+="RDI_GRID_LON_RANGE='-130.0  -60.0'\n"
		    RDI_VARS+="RDI_GRID_LAT_RANGE='   9.75  60.0'\n"
		fi
	    elif [[ ${domain_num} = "5" ]]; then
		RDI_VARS+="RDI_GRID_DOMAIN_NAME='custom'\n"
	        RDI_VARS+="RDI_GRID_LON_RANGE='MinLon MaxLon'\n"
	        RDI_VARS+="RDI_GRID_LAT_RANGE='MinLat MaxLat'\n"
	        printf "\n  -- You will need to manually set longitude and latitude"
		printf "\n     bounds in the Grid Menu of input.geos.\n"
	    else
  		valid_domain=0
		printf "Invalid horizontal grid domain option. Try again.\n"
	    fi
        fi
    done
else
    RDI_VARS+="$(cat ${gcdir}/run/shared/settings/global_grid.txt)\n"
    if [[ ${met} = "ModelE2.1" ]] || [[ ${met} = "ModelE2.2" ]]; then
        if [[ "$grid_res" == "4x5" ]]; then
	    RDI_VARS+="RDI_GRID_HALF_POLAR='T'\n"
	else
	    RDI_VARS+="RDI_GRID_HALF_POLAR='F'\n"
	fi
    else
	RDI_VARS+="RDI_GRID_HALF_POLAR='T'\n"
    fi
fi

# Set timesteps according to grid resolution
if [[ ${grid_res} = "05x0625" ]] || [[ ${grid_res} = "025x03125" ]]; then
    RDI_VARS+="RDI_TRANSPORT_TS='300'\n"
    RDI_VARS+="RDI_CHEMISTRY_TS='600'\n"
else
    if [[ ${sim_extra_option} =~ "TOMAS" ]]; then
	RDI_VARS+="RDI_TRANSPORT_TS='1800'\n"
	RDI_VARS+="RDI_CHEMISTRY_TS='3600'\n"
    else
	RDI_VARS+="RDI_TRANSPORT_TS='600'\n"
	RDI_VARS+="RDI_CHEMISTRY_TS='1200'\n"
    fi
fi

#-----------------------------------------------------------------
# Is International Date Line an edge or midpoint?
#-----------------------------------------------------------------

if [[ ${met} = "ModelE2.1" ]] || [[ ${met} = "ModelE2.2" ]] ; then
    if [[ "$grid_res" == "2x25" ]]; then
	# Native GISS fine resolution
	RDI_VARS+="RDI_CENTER_LON_180='F'\n"
    else
        # FlexGrid re-gridded resolutions
	RDI_VARS+="RDI_CENTER_LON_180='T'\n"
    fi
else
    # All GMAO products
    RDI_VARS+="RDI_CENTER_LON_180='T'\n"
fi

#----------------------------------------------------------------
# Horizontal resolution-dependent settings
#-----------------------------------------------------------------

if [[ ${met} = "ModelE2.1" ]]; then
    if [[ "$runid" == "E213f10aF40oQ40nudge" ]]; then
        if [[ "$grid_res" ==  "4x5" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='0.00474046'\n"
	    RDI_VARS+="RDI_GISS_RES='F40'\n"
        elif [[ "$grid_res" == "2x25" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='0.00243979'\n"
	    RDI_VARS+="RDI_GISS_RES='F40'\n"
        elif [[ "$grid_res" == "05x0625" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='0.00276896'\n"
	    RDI_VARS+="RDI_GISS_RES='F40'\n"
        elif [[ "$grid_res" == "025x03125" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='0.00254319'\n"
	    RDI_VARS+="RDI_GISS_RES='F40'\n"
  	fi
    else
        if [[ "$grid_res" ==  "4x5" ]]; then
            RDI_VARS+="RDI_DUSTDEAD_TF='0.03564873'\n"
	    RDI_VARS+="RDI_GISS_RES='F40'\n"
        elif [[ "$grid_res" == "2x25" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='0.01050036'\n"
	    RDI_VARS+="RDI_GISS_RES='F40'\n"
        elif [[ "$grid_res" == "05x0625" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='0.01340854'\n"
	    RDI_VARS+="RDI_GISS_RES='F40'\n"
        elif [[ "$grid_res" == "025x03125" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='0.01066495'\n"
	    RDI_VARS+="RDI_GISS_RES='F40'\n"
	fi
    fi
else
    RDI_VARS+="RDI_GISS_RES='not_used'\n"
    if [[ "x${sim_name}" == "xfullchem" || "x${sim_name}" == "xaerosol" ]]; then
	if [[ "x${met}" == "geosfp" && "x${grid_res}" == "x4x5" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='8.3286e-4'\n"
	fi
	if [[ "x${met}" == "xgeosfp" && "x${grid_res}" == "x2x25" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='5.0416e-4'\n"
	fi
	if [[ "x${met}" == "xmerra2" && "x${grid_res}" == "x4x5" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='7.8533e-4'\n"
	fi
	if [[ "x${met}" == "xmerra2" && "x${grid_res}" == "x2x25" ]]; then
	    RDI_VARS+="RDI_DUSTDEAD_TF='4.7586e-4'\n"
	fi
    else
	RDI_VARS+="RDI_DUSTDEAD_TF='-999.0e0'\n"
    fi
fi

#-----------------------------------------------------------------
# Ask user to select vertical resolution
#-----------------------------------------------------------------
printf "${thinline}Choose number of levels:${thinline}"

if [[ ${met} = "geosfp" ]] || [[ ${met} = "merra2" ]]; then
    printf "  1. 72 (native)\n"
    printf "  2. 47 (reduced)\n"

    valid_lev=0
    while [ "${valid_lev}" -eq 0 ]; do
        read lev_num
        valid_lev=1
        if [[ ${lev_num} = "1" ]]; then
            RDI_VARS+="RDI_GRID_NLEV='72'\n"
        elif [[ ${lev_num} = "2" ]]; then
	    RDI_VARS+="RDI_GRID_NLEV='47'\n"
        else
            valid_lev=0
            printf "Invalid vertical resolution option. Try again.\n"
        fi
    done
fi

if [[ ${met} = "ModelE2.1" ]]; then
    printf "  1. 40 (native)\n"
    valid_lev=0
    while [ "${valid_lev}" -eq 0 ]; do
        read lev_num
        valid_lev=1
        if [[ ${lev_num} = "1" ]]; then
            RDI_VARS+="RDI_GRID_NLEV='40'\n"
        else
            valid_lev=0
            printf "Invalid vertical resolution option. Try again.\n"
        fi
    done
fi

if [[ ${met} = "ModelE2.2" ]]; then
    printf "  1. 102 (native)\n"
    printf "  2. 74 (reduced)\n"
    valid_lev=0
    while [ "${valid_lev}" -eq 0 ]; do
        read lev_num
        valid_lev=1
        if [[ ${lev_num} = "1" ]]; then
            RDI_VARS+="RDI_GRID_NLEV='102'\n"
        elif [[ ${lev_num} = "2" ]]; then
            RDI_VARS+="RDI_GRID_NLEV='74'\n"
        else
            valid_lev=0
            printf "Invalid vertical resolution option. Try again.\n"
        fi
    done
fi

#-----------------------------------------------------------------
# Ask user to define path where directory will be created
#-----------------------------------------------------------------
printf "${thinline}Enter path where the run directory will be created:${thinline}"
valid_path=0
while [ "$valid_path" -eq 0 ]; do
    read -e rundir_path

    # Test for quitting
    if [[ "x${rundir_path}" == "xq" ]]; then
	printf "\nExiting.\n"
	exit 1
    fi

    # Replace ~ with the user's home directory
    # NOTE: This is a safe algorithm.
    if [[ "${rundir_path}" =~ '~' ]]; then
	rundir_path="${rundir_path/#\~/$HOME}"
	echo "Expanding to: ${rundir_path}"
    fi

    # If this is just a new directory within an existing one,
    # give the user the option to proceed
    if [[ ! -d ${rundir_path} ]]; then
        if [[ -d $(dirname ${rundir_path} ) ]]; then
            printf "\nWarning: ${rundir_path} does not exist,\nbut the parent directory does.\nWould you like to make this directory? (y/n/q)\n"
            read mk_rundir
            if [[ "x${mk_rundir}" == "xy" ]]; then
                mkdir $rundir_path
	    elif [[ "x${mk_rundir}" == "xq" ]]; then
		printf "\nExiting.\n"
		exit 1
            fi
        fi
    fi

    # Ask user to supply a new path again
    if [[ ! -d ${rundir_path} ]]; then
        printf "\nERROR: ${rundir_path} does not exist. Enter a new path or hit q to quit.\n"
    else
	valid_path=1
    fi
done

#-----------------------------------------------------------------
# Ask user to define run directory name if not passed as argument
#-----------------------------------------------------------------
if [ -z "$1" ]; then
    printf "${thinline}Enter run directory name, or press return to use default:\n\n"
    printf "NOTE: This will be a subfolder of the path you entered above.${thinline}"
    read -e rundir_name
    if [[ -z "${rundir_name}" ]]; then
	if [[ "${sim_extra_option}" = "none" ]]; then
	    rundir_name=gc_${met}_${sim_name}
	else
	    rundir_name=gc_${met}_${sim_name}_${sim_extra_option}
	fi
	printf "  -- Using default directory name ${rundir_name}\n"
    fi
else
    rundir_name=$1
fi

#-----------------------------------------------------------------
# Ask user for a new run directory name if specified one exists
#-----------------------------------------------------------------
rundir=${rundir_path}/${rundir_name}
valid_rundir=0
while [ "${valid_rundir}" -eq 0 ]; do
    if [[ -d ${rundir} ]]; then
	printf "\nWARNING: ${rundir} already exists.\n"
        printf "Enter a different run directory name, or q to quit:\n"
	read -e new_rundir
	if [[ ${new_rundir} = "q" ]]; then
	    printf "Exiting.\n"
	    exit 1
	else
	    rundir=${rundir_path}/${new_rundir}
	fi
    else
        valid_rundir=1
    fi
done

#-----------------------------------------------------------------
# Create run directory
#-----------------------------------------------------------------
mkdir -p ${rundir}

# Copy run directory files and subdirectories
cp ${gcdir}/run/shared/cleanRunDir.sh       ${rundir}
cp ${gcdir}/run/shared/download_data.py     ${rundir}
cp ${gcdir}/run/shared/download_data.yml    ${rundir}
cp ./getRunInfo                             ${rundir}
cp ./archiveRun.sh                          ${rundir}
cp ./README                                 ${rundir}
cp ./gitignore                              ${rundir}/.gitignore

if [[ "x${sim_name}" == "xfullchem" || "x${sim_name}" == "xCH4" ]]; then
    cp -r ${gcdir}/run/shared/metrics.py  ${rundir}
    chmod 744 ${rundir}/metrics.py
fi

# Set permissions
chmod 744 ${rundir}/cleanRunDir.sh
chmod 744 ${rundir}/archiveRun.sh

# Copy species database; append APM or TOMAS species if needed
# Also copy APM input files to the run directory
cp -r ${gcdir}/run/shared/species_database.yml   ${rundir}
if [[ ${sim_extra_option} =~ "TOMAS" ]]; then
    cat ${gcdir}/run/shared/species_database_tomas.yml >> ${rundir}/species_database.yml
elif [[ ${sim_extra_option} =~ "APM" ]]; then
    cat ${gcdir}/run/shared/species_database_apm.yml >> ${rundir}/species_database.yml
    cp ${gcdir}/run/shared/apm_tmp.dat ${rundir}/apm_tmp.dat
    cp ${gcdir}/run/shared/input.apm   ${rundir}/input.apm
fi

# If benchmark simulation, put run script in directory
if [[ ${sim_extra_option} == "benchmark" ]]; then
    cp ./runScriptSamples/geoschem.benchmark.run ${rundir}
    chmod 744 ${rundir}/geoschem.benchmark.run
fi

# Create symbolic link to code directory
ln -s ${wrapperdir} ${rundir}/CodeDir
ln -s ${wrapperdir}/run/GCHP/runScriptSamples ${rundir}/runScriptSamples

# Create build directory
mkdir ${rundir}/build
printf "To build GEOS-Chem type:\n   cmake ../CodeDir\n   cmake . -DRUNDIR=..\n   make -j\n   make install\n" >> ${rundir}/build/README

#--------------------------------------------------------------------
# Navigate to run directory and set up input files
#--------------------------------------------------------------------
cd ${rundir}

# Special handling for start/end date based on simulation so that
# start year/month/day matches default initial restart file.
if [[ "x${sim_name}" == "xHg"     ||
      "x${sim_name}" == "xCH4"    ||
      "x${sim_name}" == "xtagCH4" ||
      "x${sim_name}" == "xTransportTracers" ]]; then
    startdate='20190101'
    enddate='20190201'
elif [[ "x${sim_name}" == "xmetals" ]]; then
    startdate='20110101'
    enddate='20110201'
else
    startdate='20190701'
    enddate='20190801'
fi
if [[ ${met} = "ModelE2.1" ]] || [[ ${met} = "ModelE2.2" ]]; then
    if [[ "x$scenario" == "HIST" ]]; then
	startdate='20050701'
	enddate='20050801'
    else
	startdate='20900701'
	enddate='20900801'
    fi
fi
RDI_VARS+="RDI_SIM_START_DATE=$startdate\n"
RDI_VARS+="RDI_SIM_END_DATE=$enddate\n"
RDI_VARS+="RDI_SIM_START_TIME='000000'\n"
RDI_VARS+="RDI_SIM_END_TIME='000000'\n"

# Use monthly diagnostics by default
RDI_VARS+="RDI_HIST_TIME_AVG_DUR='00000100 000000'\n"
RDI_VARS+="RDI_HIST_TIME_AVG_FREQ='00000100 000000'\n"
RDI_VARS+="RDI_HIST_INST_DUR='00000100 000000'\n"
RDI_VARS+="RDI_HIST_INST_FREQ='00000100 000000'\n"
RDI_VARS+="RDI_HIST_MONTHLY_DIAG='1'\n"

# Turn on GEOS-Chem timers for benchmark simulations
if [[ "${sim_extra_option}" == "benchmark" ]]; then
    RDI_VARS+="RDI_USE_GCCLASSIC_TIMERS='T'\n"
else
    RDI_VARS+="RDI_USE_GCCLASSIC_TIMERS='F'\n"
fi

# Assign appropriate file paths and settings in HEMCO_Config.rc
if [[ ${met} = "ModelE2.1" ]]; then
    RDI_VARS+="RDI_DUSTDEAD_EXT='on '\n"
    RDI_VARS+="RDI_SEASALT_EXT='on '\n"
    RDI_VARS+="RDI_SOILNOX_EXT='on '\n"
    RDI_VARS+="RDI_OFFLINE_DUST='false'\n"
    RDI_VARS+="RDI_OFFLINE_BIOVOC='false'\n"
    RDI_VARS+="RDI_OFFLINE_SEASALT='false'\n"
    RDI_VARS+="RDI_OFFLINE_SOILNOX='false'\n"
    RDI_VARS+="$(cat ${gcdir}/run/shared/settings/gcap2_hemco.txt)\n"
else
    if [[ "${sim_extra_option}" == "benchmark" ]]; then
	RDI_VARS+="RDI_DUSTDEAD_EXT='on '\n"
	RDI_VARS+="RDI_SEASALT_EXT='on '\n"
	RDI_VARS+="RDI_SOILNOX_EXT='on '\n"
	RDI_VARS+="RDI_OFFLINE_DUST='false'\n"
	RDI_VARS+="RDI_OFFLINE_BIOVOC='false'\n"
	RDI_VARS+="RDI_OFFLINE_SEASALT='false'\n"
	RDI_VARS+="RDI_OFFLINE_SOILNOX='false'\n"
    else
	if [[ "${sim_extra_option}" == "marinePOA" ]]; then
	    RDI_VARS+="RDI_SEASALT_EXT='on '\n"
	    RDI_VARS+="RDI_OFFLINE_SEASALT='false'\n"
	else
	    RDI_VARS+="RDI_SEASALT_EXT='off'\n"
	    if [[ ${sim_extra_option} =~ "TOMAS" ]]; then
		RDI_VARS+="RDI_TOMAS_SEASALT='on '\n"
		RDI_VARS+="RDI_OFFLINE_SEASALT='false'\n"
	    else
		RDI_VARS+="RDI_TOMAS_SEASALT='off'\n"
		RDI_VARS+="RDI_OFFLINE_SEASALT='true '\n"
	    fi
	fi
	if [[ ${sim_extra_option} =~ "TOMAS" ]]; then
	    RDI_VARS+="RDI_TOMAS_DUSTDEAD='on '\n"
	    RDI_VARS+="RDI_OFFLINE_DUST='false'\n"
	else
	    RDI_VARS+="RDI_TOMAS_DUSTDEAD='off'\n"
	    RDI_VARS+="RDI_OFFLINE_DUST='true '\n" 
	fi
	RDI_VARS+="RDI_DUSTDEAD_EXT='off'\n"
	RDI_VARS+="RDI_SOILNOX_EXT='off'\n"
	RDI_VARS+="RDI_OFFLINE_BIOVOC='true '\n"
	RDI_VARS+="RDI_OFFLINE_SOILNOX='true '\n"
    fi
    RDI_VARS+="$(cat ${gcdir}/run/shared/settings/gmao_hemco.txt)\n"
fi

#--------------------------------------------------------------------
# Replace settings in config files with RDI variables
#--------------------------------------------------------------------

# Save RDI variables to file
echo -e "$RDI_VARS" > rdi_vars.txt
sort -o rdi_vars.txt rdi_vars.txt

# Call init_rd.sh
${srcrundir}/init_rd.sh rdi_vars.txt

#--------------------------------------------------------------------
# Print run direcory setup info to screen
#--------------------------------------------------------------------
printf "\n  See rdi_vars.txt for run directory settings.\n\n"

printf "\n  -- This run directory has been set up for $startdate - $enddate."
printf "\n     You may modify these settings in input.geos.\n"

printf "\n  -- The default frequency and duration of diagnostics is set to monthly."
printf "\n     You may modify these settings in HISTORY.rc and HEMCO_Config.rc.\n"

if [[ "x${nested_sim}" == "xT" ]]; then    
    printf "\n  -- Nested-grid simulations use global high-reoslution met fields"
    printf "\n     by default. To improve run time, you may choose to use cropped"
    printf "\n     met fields by modifying the file paths and names in HEMCO_Config.rc"
    printf "\n     to include the region string (e.g. 'AS', 'EU', 'NA').\n"
fi

#--------------------------------------------------------------------
# Copy sample restart file to run directory
#--------------------------------------------------------------------

if [[ ${met} = "merra2" ]] || [[ ${met} = "geosfp" ]]; then

    # Root path for restarts
    # Check the Linux Kernel version to see if we are on the AWS cloud.
    # If we are, define the command to copy the restart file from s3://gcgrid
    is_aws=$(uname -r | grep aws)
    if [[ "x${is_aws}" != "x" ]]; then
	rst_root="s3://gcgrid/GEOSCHEM_RESTARTS"
	s3_cp="aws s3 cp --request-payer=requester"
    else
	rst_root="${GC_DATA_ROOT}/GEOSCHEM_RESTARTS"
    fi

    if [[ "x${sim_name}" == "xfullchem" || "x${sim_name}" == "xaerosol" ]]; then

        # NOTE: We need to read the fullchem and TOMAS restart files from
	# the v2021-09/ folder.  These contain extra species (e.g HMS),
	# for chemistry updates that were added in 13.3.0.  This is necessary
	# to avoid GEOS-Chem Classic simulations from halting if these
	# species are not found in the restart file (time cycle flag "EFYO").
	#   -- Bob Yantosca (22 Sep 2021)
	#
	# Aerosol-only simulations can use the fullchem restart since all of the
	# aerosol species are included.
	if [[ "x${sim_extra_option}" == "xTOMAS15" ]]; then
	    sample_rst=${rst_root}/v2021-09/GEOSChem.Restart.TOMAS15.${startdate}_0000z.nc4
	elif [[ "x${sim_extra_option}" == "xTOMAS40" ]]; then
	    sample_rst=${rst_root}/v2021-09/GEOSChem.Restart.TOMAS40.${startdate}_0000z.nc4
	else
	    sample_rst=${rst_root}/v2021-09/GEOSChem.Restart.fullchem.${startdate}_0000z.nc4
	fi

    elif [[ "x${sim_name}" == "xTransportTracers" ]]; then

	# For TransportTracers, use restart from latest benchmark
	sample_rst=${rst_root}/GC_13.0.0/GEOSChem.Restart.TransportTracers.${startdate}_0000z.nc4

    elif [[ "x${sim_name}" == "xPOPs" ]]; then

	# For POPs, the extra option is in the restart file name
	sample_rst=${rst_root}/v2020-02/GEOSChem.Restart.${sim_name}_${sim_extra_option}.${startdate}_0000z.nc4

    elif [[ "x${sim_name}" == "xmetals" ]]; then

	# For metals, use the extra option is in the restart file name
	sample_rst=${rst_root}/v2021-06/GEOSChem.Restart.${sim_name}.${startdate}_0000z.nc4

    else

	# For other specialty simulations, use previoiusly saved restarts
	sample_rst=${rst_root}/v2020-02/GEOSChem.Restart.${sim_name}.${startdate}_0000z.nc4

    fi

elif [[ ${met} = "ModelE2.1" ]]; then

    # Root path for restarts
    # Check the Linux Kernel version to see if we are on the AWS cloud.
    # If we are, define the command to copy the restart file from s3://gcgrid
    is_aws=$(uname -r | grep aws)
    if [[ "x${is_aws}" != "x" ]]; then
	rst_root="s3://gcgrid/GCAP2_RESTARTS"
	s3_cp="aws s3 cp --request-payer=requester"
    else
	rst_root="${GC_DATA_ROOT}/GCAP2_RESTARTS"
    fi

    if [[ "x${sim_name}" == "xfullchem" ]]; then

        # For TOMAS simulations, use restarts provided by the TOMAS team
        # For other fullchem simulations, use restart the latest 1-yr benchmark
        if [[ "x${sim_extra_option}" == "xTOMAS15" ]]; then
    	    sample_rst=${rst_root}/v2020-02/${RDI_GRID_NLEV}L/initial_GCAP2_rst.4x5_TOMAS15.nc4
        elif [[ "x${sim_extra_option}" == "xTOMAS40" ]]; then
    	    sample_rst=${rst_root}/v2020-02/${RDI_GRID_NLEV}L/initial_GCAP2_rst.4x5_TOMAS40.nc4
        else
    	    sample_rst=${rst_root}/GC_13.0.0/${RDI_GRID_NLEV}L/GCAP2.Restart.fullchem.20190701_0000z.nc4
        fi

    elif [[ ${sim_name} = "TransportTracers" ]]; then

        # For TransportTracers, use restart from latest 1-year benchmark
        sample_rst=${rst_root}/GC_13.0.0/${RDI_GRID_NLEV}L/GEOSChem.Restart.TransportTracers.20190101_0000z.nc4

    else

        # For other specialty simulations, use previously saved restarts
        sample_rst=${rst_root}/v2018-11/${RDI_GRID_NLEV}L/initial_GCAP2_rst.${grid_res}_${sim_name}.nc4

    fi

fi

# Copy the restart file to the run directory (for AWS or on a local server)
if [[ "x${is_aws}" != "x" ]]; then
    ${s3_cp} ${sample_rst} ${rundir}/GEOSChem.Restart.${startdate}_0000z.nc4 2>/dev/null
elif [[ -f ${sample_rst} ]]; then
    cp ${sample_rst} ${rundir}/GEOSChem.Restart.${startdate}_0000z.nc4
else
    printf "\n  -- No sample restart provided for this simulation."
    printf "\n     You will need to provide an initial restart file or disable"
    printf "\n     GC_RESTARTS in HEMCO_Config.rc to initialize your simulation"
    printf "\n     with default background species concentrations.\n"
fi

# Sample restarts for several simulations do not contain all species. For those
# simulations, print a warning and change the time cycle option in HEMCO config
# so that we do not force an error if not found (i.e. EFYO --> EY)
if [[ "x${sim_extra_option}" == "xaciduptake"        ||
      "x${sim_extra_option}" == "xmarinePOA"         ||
      "x${sim_extra_option}" == "xcomplexSOA_SVPOA"  ||
      "x${sim_extra_option}" == "xAPM"               ||
      "x${sim_name}"         == "xPOPs"              ||
      "x${sim_name}"         == "xtagCH4"            ||
      "x${sim_name}"         == "xtagO3"             ]]; then
    old="SpeciesRst_?ALL?    \$YYYY/\$MM/\$DD/\$HH EFYO"
    new="SpeciesRst_?ALL?    \$YYYY/\$MM/\$DD/\$HH EY  "
    sed_ie "s|${old}|${new}|" HEMCO_Config.rc

    printf "\n  -- The sample restart provided for this simulation may not"
    printf "\n     contain all species defined in this simulation. Missing"
    printf "\n     species will be assigned default background concentrations."
    printf "\n     Check your GEOS-Chem log file for details. As always, it"
    printf "\n     is recommended that you spin up your simulation to ensure"
    printf "\n     proper initial conditions.\n"
fi

# Call function to setup configuration files with settings common between
# GEOS-Chem Classic and GCHP. This script mainly now adds species to input.geos
# and modifies diagnostic output based on simulation type.
if [[ "x${sim_name}" = "xfullchem" ]]; then
    set_common_settings ${sim_extra_option}
fi

#--------------------------------------------------------------------
# Navigate back to source code directory
#--------------------------------------------------------------------
cd ${srcrundir}

#----------------------------------------------------------------------
# Archive repository version in run directory file rundir.version
#----------------------------------------------------------------------
version_log=${rundir}/rundir.version
echo "This run directory was created with ${srcrundir}/createRunDir.sh." > ${version_log}
echo " " >> ${version_log}
echo "GEOS-Chem repository version information:" >> ${version_log}
cd ${gcdir}
remote_url=$(git config --get remote.origin.url)
code_branch=$(git rev-parse --abbrev-ref HEAD)
last_commit=$(git log -n 1 --pretty=format:"%s")
commit_date=$(git log -n 1 --pretty=format:"%cd")
commit_user=$(git log -n 1 --pretty=format:"%cn")
commit_hash=$(git log -n 1 --pretty=format:"%h")
cd ${srcrundir}
printf "\n  Remote URL: ${remote_url}" >> ${version_log}
printf "\n  Branch: ${code_branch}"    >> ${version_log}
printf "\n  Commit: ${last_commit}"    >> ${version_log}
printf "\n  Date: ${commit_date}"      >> ${version_log}
printf "\n  User: ${commit_user}"      >> ${version_log}
printf "\n  Hash: ${commit_hash}"      >> ${version_log}

#-----------------------------------------------------------------
# Ask user whether to track run directory changes with git
#-----------------------------------------------------------------
printf "${thinline}Do you want to track run directory changes with git? (y/n)${thinline}"
valid_response=0
while [ "$valid_response" -eq 0 ]; do
    read enable_git
    if [[ ${enable_git} = "y" ]]; then
	cd ${rundir}
	printf "\n\nChanges to the following run directory files are tracked by git:\n\n" >> ${version_log}
	printf "\n"
	git init
	git add *.rc *.sh *.yml *.run *.py input.geos getRunInfo
	git add runScriptSamples/* README .gitignore
	printf " " >> ${version_log}
	git commit -m "Initial run directory" >> ${version_log}
	cd ${srcrundir}
	valid_response=1
    elif [[ ${enable_git} = "n" ]]; then
	valid_response=1
    else
	printf "Input not recognized. Try again.\n"
    fi
done

#-----------------------------------------------------------------
# Done!
#-----------------------------------------------------------------
printf "\nCreated ${rundir}\n"

exit 0
