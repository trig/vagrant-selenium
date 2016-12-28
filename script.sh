#!/bin/sh
#=========================================================

#=========================================================
echo "Install the packages..."
#=========================================================
sudo apt-get -y install fluxbox xorg unzip vim rungetty firefox

if ! which java > /dev/null 2>&1; then
	#=========================================================
	echo "Install Java 8..."
	#=========================================================
	sudo apt-get install -y python-software-properties debconf-utils
	sudo add-apt-repository -y ppa:webupd8team/java
	sudo apt-get update
	echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
	sudo apt-get install -y oracle-java8-installer > /dev/null && echo 'OK'
fi

if ! grep "vagrant tty1" /etc/init/tty1.conf > /dev/null 2>&1; then
	#=========================================================
	echo "Set autologin for the Vagrant user..."
	#=========================================================
	sudo sed -i '$ d' /etc/init/tty1.conf
	sudo echo "exec /sbin/rungetty --autologin vagrant tty1" >> /etc/init/tty1.conf
fi

if ! grep "startx" .profile > /dev/null 2>&1; then
	#=========================================================
	echo -n "Start X on login..."
	#=========================================================
	PROFILE_STRING=$(cat <<EOF
if [ ! -e "/tmp/.X0-lock" ] ; then
    startx
fi
EOF
)
	echo "${PROFILE_STRING}" >> .profile
	echo "ok"
fi

if [ ! -f /etc/apt/sources.list.d/google-chrome.list ];then
	#=========================================================
	echo "Download the latest Chrome..."
	#=========================================================
	wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
	sudo dpkg -i google-chrome-stable_current_amd64.deb
	sudo rm google-chrome-stable_current_amd64.deb
	sudo apt-get install -y -f
else
	#=========================================================
	echo "Updating Chrome..."
	#=========================================================
	sudo apt-get upgrade -y google-chrome-stable > /dev/null 2>&1 && echo "OK"
fi

#=========================================================
echo "Download latest selenium server..."
#=========================================================
sudo rm selenium-server-standalone.jar > /dev/null 2>&1
wget -q "https://goo.gl/Lyo36k" -O selenium-server-standalone.jar
chown vagrant:vagrant selenium-server-standalone.jar

#=========================================================
echo "Download latest chrome driver..."
#=========================================================
sudo rm chromedriver > /dev/null 2>&1
CHROMEDRIVER_VERSION=$(curl -s "http://chromedriver.storage.googleapis.com/LATEST_RELEASE")
wget -q "http://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip"
unzip chromedriver_linux64.zip
sudo rm chromedriver_linux64.zip
chown vagrant:vagrant chromedriver

#=========================================================
echo "Download geckodriver-v0.11.1 driver..."
#=========================================================
sudo rm geckodriver > /dev/null 2>&1
wget -q https://github.com/mozilla/geckodriver/releases/download/v0.11.1/geckodriver-v0.11.1-linux64.tar.gz
tar -xvf geckodriver-v0.11.1-linux64.tar.gz
sudo rm geckodriver-v0.11.1-linux64.tar.gz
chown vagrant:vagrant geckodriver


if [ ! -f /etc/X11/Xsession.d/9999-common_start ]; then
	#=========================================================
	echo -n "Install tmux scripts..."
	#=========================================================
	TMUX_SCRIPT=$(cat <<EOF
#!/bin/sh
tmux start-server

tmux new-session -d -s selenium
tmux send-keys -t selenium:0 './chromedriver' C-m

tmux new-session -d -s chrome-driver
tmux send-keys -t chrome-driver:0 'java -jar selenium-server-standalone.jar' C-m

tmux new-session -d -s geckodriver
tmux send-keys -t geckodriver:0 './geckodriver' C-m
EOF
)
	echo "${TMUX_SCRIPT}"
	echo "${TMUX_SCRIPT}" > tmux.sh
	chmod +x tmux.sh
	chown vagrant:vagrant tmux.sh
	echo "ok"


	#=========================================================
	echo -n "Install startup scripts..."
	#=========================================================
	STARTUP_SCRIPT=$(cat <<EOF
#!/bin/sh
~/tmux.sh &
xterm &
EOF
)
	echo "${STARTUP_SCRIPT}" > /etc/X11/Xsession.d/9999-common_start
	chmod +x /etc/X11/Xsession.d/9999-common_start
	echo "ok"
fi

if ! grep "192.168.33.1 host" /etc/hosts > /dev/null 2>&1; then
	#=========================================================
	echo -n "Add host alias..."
	#=========================================================

	echo "192.168.33.1 host" >> /etc/hosts
	echo "ok"
fi


#=========================================================
echo "Reboot the VM"
#=========================================================
sudo reboot
