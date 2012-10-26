#/bin/bash

check_root_privileges()
{
    ID="id -u"
    MYUID=`$ID 2> /dev/null`
    if [ ! -z "$MYUID" ]; then
        if [ $MYUID != 0 ]; then
            echo "You are not root or a sudoer. Try '$ sudo util/setup.sh' instead";
            exit 1
        fi
    else
        echo "Could not detect UID";
        exit 1
    fi
}
# exits if the UID is not 0 [root]
check_root_privileges

IFS=';'
# setup npms array
declare -a npms=("coffee-script;-g" "coffeelint;-g" "mocha;-g" "uglify-js;-g" "jquery;" "backbone;" "jsdom;")
# setup gems array
declare -a gems=(compass sass markdown)

get_npm()
{
	if [ `npm ls | grep -c -e "$1"` > 0 ]
	then
		echo "\n\n> UPDATING NPM: $1"
		npm update $1
	else
		echo "\n\n> INSTALLING NPM: $1"
		npm install $2 $1
	fi	
}
for npm in "${npms[@]}"
do
	read -ra cmd <<< "$npm"
	get_npm "${cmd[0]}" "${cmd[1]}"
done

get_gem()
{
	if [ `gem list | grep -e "$1"` > 0 ]
	then
		echo "\n\n> UPDATING GEM: $1"
		gem update $1
	else
		echo "\n\n> INSTALLING GEM: $1"
		gem install $1
	fi	
}
for gem in "${gems[@]}"
do
	get_gem "$gem"
done