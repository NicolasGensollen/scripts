#!/bin/bash

set -eu -o pipefail # fail on error and report it, debug all lines

sudo -n true
test $? -eq 0 || exit 1 "you should have sudo privilege to run this script"

case $(uname | tr '[:upper:]' '[:lower:]') in
  linux*)
    export OS_NAME=linux
    ;;
  darwin*)
    export OS_NAME=osx
    ;;
  msys*)
    export OS_NAME=windows
    ;;
  *)
    export OS_NAME=notset
    ;;
esac

echo "Platform detected : $OS_NAME"

install_dcm2niix () {
	echo "=== dcm2niix ==="
	if ! command -v dcm2niix &> /dev/null
	then
		echo "-> dcm2niix could not be found"
		echo "-> Installing dcm2niix"
		echo "-> Download sources..."
		if [ -d "dcm2niix" ]
		then
			echo "-> Skip download as dcm2niix folder already exists"
		else
			git clone https://github.com/rordenlab/dcm2niix.git
		fi
		cd dcm2niix
		mkdir build && cd build
		echo "-> Building from sources..."
		cmake ..
		echo "-> Installing..."
		make install
		cd ..
		cd ..
	else
		echo "-> dcm2niix already installed"
	fi
}

install_itk () {
	echo "=== ITK ==="
	echo "-> Installing ITK"
	echo "-> Download sources..."
	if [ -d "ITK" ]
	then
		echo "-> Skip download as ITK folder already exists"
	else
		git clone https://github.com/InsightSoftwareConsortium/ITK.git
	fi
	mkdir ITK-build && cd ITK-build
	echo "-> Building from sources..."
	cmake -DITK_BUILD_DEFAULT_MODULES:BOOL=OFF
	      -DBUILD_EXAMPLES:BOOL=OFF
              -DModule_ITKReview:BOOL=ON
              ../ITK
	make
	echo "-> Installing..."
	make install
	cd ..
}

install_petpvc () {
	echo "=== PETPVC ==="
	if ! command -v petpvc &> /dev/null
	then
		echo "-> petpvc could not be found"
		echo "-> Installing petpvc"
		echo "-> Download sources..."
		if [ -d "dcm2niix" ]
		then
			echo "-> Skip download as PETPVC folder already exists"
		else
			git clone https://github.com/UCL/PETPVC.git
		fi
		mkdir PETPVC-build && cd PETPVC-build
		echo "-> Building from sources..."
		cmake ../PETPVC
		make
		make test
		echo "-> Installing..."
		make install
		cd ..
	else
		echo "-> petpvc already installed"
	fi
}

install_convert3d () {
	echo "=== Convert3D ==="
	if ! command -v c3d &> /dev/null
	then
		echo "-> c3d could not be found"
		echo "-> Installing Convert3D"
		echo "-> Download sources..."
		if [ -d "c3d" ]
		then
			echo "-> Skip download as c3d folder already exists"
		else
			git clone https://git.code.sf.net/p/c3d/git c3d
		fi
		mkdir c3d-build && cd c3d-build
		echo "-> Building from sources..."
		cmake ../c3d
		make
		echo "-> Installing..."
		make install
		cd ..
	else
		echo "-> Convert3D already installed"
	fi
}

install_mrtrix3 () {
	echo "=== MRtrix3 ==="
	if ! command -v mrconvert &> /dev/null
	then
		echo "-> mrconvert could not be found"
		echo "-> Installing MRtrix3"
		if $OS_NAME == osx
		then
			install_mrtrix3_macos
		elif $OS_NAME == linux
		then
			install_mrtrix3_linux
		fi
	else
		echo "-> MRtrix3 already installed"

	fi
}

install_mrtrix3_macos () {
	sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/MRtrix3/macos-installer/master/install)"
}

install_mrtrix3_linux () {
	conda install -c mrtrix3 mrtrix3
}

install_ants () {
	echo "=== ANTs ==="
	if ! command -v antsRegistration &> /dev/null
	then
		echo "-> antsRegistration could not be found"
		echo "-> Installing ANTS"
		if [ -d "ANTs" ]
		then
			echo "-> Skip download as ANTs folder already exists"
		else
			git clone https://github.com/ANTsX/ANTs.git
		fi
		mkdir ants-build
		workingDir=${PWD}/ants-build
		cd ants-build
		mkdir build install
		cd build
		cmake \
    			-DCMAKE_INSTALL_PREFIX=${workingDir}/install \
    			../ANTs 2>&1 | tee cmake.log
		make -j 4 2>&1 | tee build.log
		cd ANTS-build
		make install 2>&1 | tee install.log
		export ANTSPATH=/opt/ANTs/bin/
		export PATH=${ANTSPATH}:$PATH
		cd ..
		cd ..
		cd ..
	else
		echo "-> ANTS already installed"
	fi
}

install_fsl () {
	echo "=== FSL ==="
	if ! command -v fsl &> /dev/null
	then
		echo "-> fsl could not be found"
		echo "-> Installing FSL"
	else
		echo "-> FSL already installed"
	fi
}

install_freesurfer_macos () {
	wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.2.0/freesurfer-darwin-macOS-7.2.0.tar.gz
	sudo tar -C /Applications -zxvpf freesurfer-darwin-macOS-7.2.0.tar.gz
	export FREESURFER_HOME=/Applications/freesurfer
}

install_freesurfer_ubuntu () {
	wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.2.0/freesurfer-linux-ubuntu18_amd64-7.2.0.tar.gz
	tar -zxpf freesurfer-linux-ubuntu18_amd64-7.2.0.tar.gz
	export FREESURFER_HOME=$HOME/freesurfer
}

install_freesurfer () {
	echo "=== FreeSurfer ==="
	if ! command -v freeview &> /dev/null
	then
		echo "-> freeview could not be found"
		echo "-> Installing FreeSurfer"	
		if $OS_NAME == osx
		then
			install_freesurfer_macos
		elif $OS_NAME == linux
		then
			install_freesurfer_ubuntu
		fi
		export SUBJECTS_DIR=$FREESURFER_HOME/subjects
		#export FUNCTIONALS_DIR=$FREESURFER_HOME/sessions
		source $FREESURFER_HOME/SetUpFreeSurfer.sh
		which freeview
	else
		echo "-> FreeSurfer already installed"
	fi
}

install_matlab_runtime_linux () {
	mkdir matlab_runtime && cd matlab_runtime
	#wget https://ssd.mathworks.com/supportfiles/downloads/R2022a/Release/2/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2022a_Update_2_glnxa64.zip
	wget https://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/MCR/glnxa64/MCRInstaller.bin
	#unzip MATLAB_Runtime_R2022a_Update_2_glnxa64.zip
	chmod 755 MCRInstaller.bin
	./MCRInstaller.bin -P bean421.installLocation="MCR" -silent
	cd ..
}

install_spm_12_linux () {
	mkdir spm12 && cd spm12
	wget https://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/spm12_r7771.zip
	unzip spm12_r7771.zip
	./run_spm12.sh /usr/local/MATLAB/MATLAB_Compiler_Runtime/v713/
}

install_spm () {
	echo "=== SPM ==="
	install_matlab_runtime_linux
	install_spm12_linux
}

install_dcm2niix
install_itk
install_petpvc
install_convert3d
install_mrtrix3
install_ants
install_fsl
install_freesurfer
install_spm