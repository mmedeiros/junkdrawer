#!/bin/sh 

# Installs daemontools-encore software from source on CentOS systems

# app specific commands 
md5="/usr/bin/md5sum"
wget="/usr/bin/wget"
untar="/bin/tar -xvzf"
sed="/bin/sed"
cat="/bin/cat"
make="/usr/bin/make"
wc="/usr/bin/wc"

# system paths 
progdir="/usr/sbin/"
workdir="/root/tmp"
servicedir="/service"
patch="/srv/salt/daemontools/daemontools_patch"

# program info 
package="daemontools-encore"
version="1.10"
tarball="${package}-${version}.tar.gz"
site="untroubled.org"
downpath="http://${site}/${package}/${tarball}"
#downpath="http://untroubled.org/daemontools-encore/daemontools-encore-1.10.tar.gz"
tools=(supervise svscan svc fghack multilog svscanboot) 
goodmd5="a9b22e9eff5c690cd1c37e780d30cd78"
dependencies=(patch mailx gcc md5sum wget tar sed cat make wc)

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

# Resolve dependencies 
install_dependencies () {
  echo -e "${COL_CYAN}Checking dependencies${COL_RESET}"
  for prog in "${dependencies[@]}"
  do 
    command -v $prog || yum -y install $prog
  done
  echo ""
}

# Check for the existence of the tools 
check_tools () { 
  echo -e "${COL_CYAN}Checking if the software is installed${COL_RESET}"
  local count=${#tools[@]}
  local i=0; 
  for tool in "${tools[@]}"
  do
     if [ -e "$progdir/$tool"  ]; then
       i=$(( $i+1 ))
     else 
       echo "${COL_RED}Error: $tool does not exist ${COL_RESET}" 
     fi 
  done
  if [ $i -eq $count ]; then 
    echo -e "${COL_GREEN}SUCCESS: All $count packages are installed ${COL_RESET}"
  else 
    echo -e "${COL_RED}packages are missing $count expected, $i found${COL_RESET}"
    check_tarball
  fi
}

check_tarball () { 
  # does the file exist?
  echo -e "${COL_CYAN}Checking tarball status...${COL_RESET}"
  if [ -f $workdir/$tarball ]; then  
    echo -e "${COL_GREEN}Installer tarball exists${COL_RESET}"
    check_md5 $goodmd5 "$workdir/$tarball"
  else
    # if not, does the dir exist? 
    if [ ! -d "$workdir"  ]; then
      mkdir $workdir 
    fi
    download
  fi 
}

check_md5 () {
  local hash=$1
  local file=$2 
    # make sure the checksum matches
    checkmd5=`$md5 $file | awk '{print $1}'`
    echo -e "${COL_CYAN}Checking the installer md5 sum...${COL_RESET}" 
    if [[ $checkmd5 -eq $goodmd5 ]]; then 
      echo -e "${COL_GREEN}md5 OK! - File $file downloaded successfully${COL_RESET}"
      install_package
    else
      echo -e "${COL_RED}md5 BAD! trying again${COL_RESET}"
      download 
    fi  
}

download () {
  echo -e "${COL_CYAN}Downloading the installer...${COL_RESET}"
  if [ -f $workdir/$tarball ]; then 
    rm $workdir/$tarball
  fi 
  $wget $downpath -P $workdir
  check_md5 $goodmd5 "$workdir/$tarball"
}

install_package () { 
  cd $workdir
  echo -e "${COL_CYAN}Expanding the tarball...${COL_RESET}"
  $untar $tarball
  cd ${workdir}/${package}-${version}
  echo "updating configs..."
  if [[ -f ${patch} ]]; then 
    echo -e "${COL_GREEN}applying patch...${COL_RESET}"
    patch < ${patch} 
  else 
    echo -e "${COL_RED}Error: Patch file ${patch} not found!${COL_RESET}"
  fi
  #cp conf-man conf-man.bak
  #$cat conf-man.bak | $sed "s/\/usr\/local\/man/\/usr\/share\/man/g" > conf-man 
  #cp conf-bin conf-bin.bak
  #$cat conf-bin.bak | $sed "s/\/usr\/local\/bin/\/usr\/sbin/g" > conf-bin
  echo "making the program..."
  $make 
  echo "installing the program..."
  $make install
  check_tools
}

check_dir () {
  echo ""
  echo -e "${COL_CYAN}Checking service directory...${COL_RESET}"
  if [ ! -d "$servicedir"  ]; then
    mkdir $servicedir
  fi
  local servicecount=$(ls $servicedir | grep -v nohup | $wc -l )
  if [ $servicecount -eq 0 ]; then 
    echo -e "${COL_RED}supervise is installed, but no services are using it${COL_RESET}"
    echo -e "${COL_RED}check your configuration directory $servicedir ${COL_RESET}"
  else 
    echo -e "${COL_GREEN}supervise used by $servicecount services...${COL_RESET}"
  fi
}

install_dependencies 
check_tools 
check_dir 


#daemontools-encore does not have an rpm package for installation. Salt does not have a facility for installing from source. 

#However, salt allows for the execution of arbitrary code, so I will write installer code. It will do the following: 

#1) software check 
#check the existence of daemontools-encore tools (check_tools) 
#- if missing: 
#   - pull tarball (download) 
#   - modify config file (install_package) 
#   - make file (install_package)
#   - install (install_package)
#   - check again (check_tools invocation in install) 
 
#2) check the existence of the /service directory (check_dir)
#  - if missing, create (check_dir)  
#  - if empty, present warning (check_dir)
