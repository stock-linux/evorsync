#!/bin/bash

while read line; do
    # If line is not empty and begins with "REPO", we copy the repo.
    if [ "$line" != "" ] && [ "$(echo $line | cut -d ' ' -f 1)" = "REPO" ]; then
        repo=$(echo $line | cut -d ' ' -f 2)
        repo_path=$(echo $line | cut -d ' ' -f 3)
        echo $repo_path
        if [[ $repo_path == http* ]]; then
            if [ -d /var/evobld/$repo ]; then
                echo "$repo exists"
                wget -O /var/evobld/$repo/DIST $repo_path/INDEX
                while read -r line; do
                    name=$(echo $line | grep -oE '^[^ ]+')
                    version=$(echo $line | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
                    release=$(echo $line | grep -oE '[0-9]+$')
 
                    sed -i "/$name/d" /var/evobld/$repo/DIST
                    echo "$name $version $release" >> /var/evobld/$repo/DIST

                    #!/bin/bash
                    FILE="/var/evobld/$repo/$name-$version.evx"
                    FILENAME="$name-$version.evx"

                    echo "FTP Host: "
                    read HOST < /dev/tty
                    echo "FTP Packages Directory: "
                    read BASEDIR < /dev/tty
                    echo "FTP Username: "
                    read USER < /dev/tty
                    echo "FTP Password: "
                    read -s PASSWORD < /dev/tty

                    ftp -n $HOST <<END_SCRIPT
user $USER $PASSWORD
cd $BASEDIR/$repo
put $FILE $FILENAME
quit
END_SCRIPT
                done < /var/evobld/$repo/INDEX
                FILE="/var/evobld/$repo/DIST"
                FILENAME="INDEX"
                ftp -n $HOST <<END_SCRIPT
user $USER $PASSWORD
cd $BASEDIR/$repo
put $FILE $FILENAME
quit
END_SCRIPT
            fi
        fi
    fi
done < /etc/evox.conf
