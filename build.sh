#!/usr/bin/env bash


function get_host {
    local __resultvar=$1
    #local myresult="$(expr substr $(uname -s) 1 5)"
    local myresult_s="$(uname -s)"
    if [ $myresult_s = "Darwin" ]; then
	eval $__resultvar="$myresult_s'"
    else
	local myresult="$(uname -o)"
	eval $__resultvar="'$myresult'"
    fi
}
function run_as_sudo {
    get_host host_result

    if [ $host_result = "GNU/Linux" ]; then
	echo -n "We need sudoer password for this command: "
	echo $@
	sudo $@
    elif [ $host_result = "Darwin" ]; then
	$@
    elif [ $host_result = "MINGW32_NT" ] || [ $host_result = "Cygwin" ]; then
	$@
    fi
}
function linux_build_prerequisite {
    echo  "We need a sudoer password to add you to the docker group."
    sudo usermod -a -G docker $USER
}
function windows_build_prerequisite {
    echo -n ""
}

function mac_build_prerequisite {
    #nat 8000-9000 tcp/udp ports from virtualbox
    if [ ! -f ".nat" ]; then 
	for i in {8000..9000}; do
	    VBoxManage controlvm "boot2docker-vm" natpf1 "tcp-port$i,tcp,,$i,,$i";
	    VBoxManage controlvm "boot2docker-vm" natpf1 "udp-port$i,udp,,$i,,$i";
	    touch .nat
	done
    fi 

    #must run from boot2docker
    if [ -z DOCKER_HOST ]; then
	error_exit "not in boot2docker"
    fi
}
function error_exit {
	echo "$1" 1>&2
	exit 1
}

if [ "$(uname)" == "Darwin" ]; then
    echo -n "Preparing to build Macintosh prerequisites..."    
    mac_build_prerequisite
    echo "done!"
elif [ "$(expr substr $(uname -s) 1 5)" = "GNU/Linux" ]; then
    echo -n "Preparing to build Linux prerequisites..."
    linux_build_prerequisite
    echo "done!"
elif [ "$(expr substr $(uname -s) 1 10)" = "MINGW32_NT" ]; then
    echo -n "Preparing to build Windows prerequisites..."
    windows_build_prerequisite
    echo "done!"
fi

#build only argument otherwise all directories
if [ -z "$1" ]; then
  images=`ls -d */ | sed 's/\///g'`
else 
  images=$1
fi


echo "Starting builds"
for i in $images; do
    run_as_sudo docker build -t "$i" "$i"/.
done
