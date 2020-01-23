# icc2_workshop_collaterals
This repository has a list of collaterals needed for ICC2 workshop. It has a modified version of raven_soc which was taped-out by Efabless Corp. Pvt. Ltd. VSD has not checked functionality for these collaterals, so please do not expect a functionality bug fix. These are used purely for PNR workshops and trainings

In case you want to use it for internal training purposes, you might want to check with at kunalpghosh@gmail.com and I will be able to guide you on the usage

Some important notes about this design
1) It doesn't have analog blocks like ADC, DAC, band-gap, on-chip pll, due to non-availability of open-source IP's for these blocks

2) Dummy interconnect technology file (ITF) was used to generate TLU+ files using ICC2 grdgenxo utility of STAR-RC

3) Memory views were generated using open-source memory compiler OpenRAM for open-source nangate 45nm freePDK

4) All scripts in "standAlone" directory are ICC2 reference scripts. It cannot be used with any other PNR tool

5) Due to non-availability of 45nm open-source PADS, we have created dummy pads (lib/lef). THIS IS "STRICTLY" NOT ALLOWED FOR REAL CHIP TAPEOUTS. Please contact your foundry for "pad" information and don't create dummy one's

If you have any questions, please feel free to email at kunalpghosh@gmail.com
