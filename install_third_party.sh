#!/bin/bash

set -eu -o pipefail # fail on error and report it, debug all lines

sudo -n true
test $? -eq 0 || exit 1 "you should have sudo privilege to run this script"

if [ -f /etc/os-release ]; then
	# freedesktop.org and systemd
	. /etc/os-release
	OS=$NAME
 	VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
	# linuxbase.org
	OS=$(lsb_release -si)
 	VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
	# For some versions of Debian/Ubuntu without lsb_release command
	. /etc/lsb-release
	OS=$DISTRIB_ID
	VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
	# Older Debian/Ubuntu/etc.
 	OS=Debian
 	VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
	# Older SuSE/etc.
 	...
elif [ -f /etc/redhat-release ]; then
	# Older Red Hat, CentOS, etc.
 	...
else
	# Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
	OS=$(uname -s)
	VER=$(uname -r)
fi

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

echo "Platform detected : $OS_NAME, $OS, $VER"

install_cmake_linux () {
    if [ -d "cmake-3.23.2-linux-x86_64" ]
    then
        echo "Skip download"
    else
        wget https://github.com/Kitware/CMake/releases/download/v3.23.2/cmake-3.23.2-linux-x86_64.tar.gz
        tar -xvzf cmake-3.23.2-linux-x86_64.tar.gz
    fi
    cd cmake-3.23.2-linux-x86_64
    ./bootstrap
    make
    make install
}

install_cmake_macos () {
    echo "Not Implemented"
}

install_cmake () {
    echo "=== CMake ==="
    if ! command -v cmake &> /dev/null
    then
        echo "-> cmake could not be found"
        echo "-> Installing cmake"
		if [ $OS_NAME == osx ];
		then
            install_cmake_macos
        elif [ $OS_NAME == linux ];
        then
            sudo apt-get -y install cmake
            #install_cmake_linux
        fi

    else
        echo "-> cmake already installed"
    fi
}

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
        if [ ! -d "build" ]
        then
		    mkdir build
        fi
        cd build
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
    if [ ! -d "ITK-build" ]
    then
	    mkdir ITK-build
    fi
    cd ITK-build
	echo "-> Building from sources..."
	cmake -DITK_BUILD_DEFAULT_MODULES:BOOL=OFF -DBUILD_EXAMPLES:BOOL=OFF -DModule_ITKReview:BOOL=ON ../ITK
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
		if [ -d "PETPVC" ]
		then
			echo "-> Skip download as PETPVC folder already exists"
		else
			git clone https://github.com/UCL/PETPVC.git
		fi
        if [ ! -d "PETPVC-build" ]
        then
            mkdir PETPVC-build
        fi
        cd PETPVC-build
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
        if [ ! -d "c3d-build" ]
        then
            mkdir c3d-build
        fi
        cd c3d-build
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
		if [ $OS_NAME == osx ]
		then
			install_mrtrix3_macos
		elif [ $OS_NAME == linux ]
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

install_conda_linux () {
	wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh -O $HOME/miniconda.sh
	bash $HOME/miniconda.sh -b -u -p $HOME/miniconda
	export PATH=$HOME/miniconda/bin:$PATH
	conda init bash
}

install_mrtrix3_linux () {
	if ! command -v conda &> /dev/null
	then
		install_conda_linux
	fi
	conda install -y -c mrtrix3 mrtrix3
}

install_ants () {
	echo "=== ANTs ==="
	if ! command -v antsRegistration &> /dev/null
	then
		echo "-> antsRegistration could not be found"
		apt-get install zlib1g-dev
		echo "-> Installing ANTS"
		if [ -d "ANTs" ]
		then
			echo "-> Skip download as ANTs folder already exists"
		else
			git clone https://github.com/ANTsX/ANTs.git
		fi
        if [ ! -d "ants-build" ]
        then
		    mkdir ants-build
        fi
		workingDir=${PWD}/ants-build
		cd ants-build
		#mkdir build install
		if [ ! -d "install" ]
		then
			mkdir install
		fi
		#cd build
		cmake \
    			-DCMAKE_INSTALL_PREFIX=${workingDir}/install \
    			../ANTs 2>&1 | tee cmake.log
		make -j 4 2>&1 | tee build.log
		cd ANTS-build
		make install 2>&1 | tee install.log
		export ANTSPATH=/opt/ANTs/bin/
		export PATH=${ANTSPATH}:$PATH
		#cd ..
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
		if [ $OS_NAME == osx ]
		then
			install_freesurfer_macos
		elif [ $OS_NAME == linux ]
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
	#wget https://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/MCR/glnxa64/MCRInstaller.bin
	wget https://ssd.mathworks.com/supportfiles/downloads/R2021a/Release/6/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2021a_Update_6_glnxa64.zip
	apt install unzip
	unzip MATLAB_Runtime_R2021a_Update_6_glnxa64.zip
	cd matlab
	./install -mode silent -agreeToLicense yes
	#unzip MATLAB_Runtime_R2022a_Update_2_glnxa64.zip
	#chmod 755 MCRInstaller.bin
	#./MCRInstaller.bin -P bean421.installLocation="MCR" -silent
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

#install_cmake
#install_dcm2niix
#install_itk
#install_petpvc
#install_convert3d
#install_mrtrix3
#install_ants
#install_fsl
#install_freesurfer
#install_spm
