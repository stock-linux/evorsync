#!/bin/bash

source /etc/evorsync.conf

while read line; do
    # If line is not empty and begins with "REPO", we copy the repo.
    if [ "$line" != "" ] && [ "$(echo $line | cut -d ' ' -f 1)" = "REPO" ]; then
        repo=$(echo $line | cut -d ' ' -f 2)
        repo_path=$(echo $line | cut -d ' ' -f 3)
        
        if [ "$HOST" = "" ]; then
            echo "FTP Host: "
            read HOST < /dev/tty
        fi
        
        if [ "$BASEDIR" = "" ]; then
            echo "FTP Packages Directory: "
            read BASEDIR < /dev/tty
        fi
        
        if [ "$USER" = "" ]; then
            echo "FTP Username: "
            read USER < /dev/tty
        fi
        
        if [ "$PASSWORD" = "" ]; then
            echo "FTP Password: "
            read -s PASSWORD < /dev/tty
        fi
        
        if [[ $repo_path == http* ]]; then
            if [ -d /var/evobld/$repo ]; then
                echo "Syncing --- $repo ---"
                wget -O /var/evobld/$repo/DIST $repo_path/INDEX -q
                while read -r line; do
                    name=$(echo $line | awk '{print $1}' | xargs)
                    version=$(echo $line | awk '{print $2}' | xargs)
                    release=$(echo $line | awk '{print $3}' | xargs)
                    
                    while read -r line; do
                        trimmed_line =  $(echo $line | xargs)
                        if [ "$trimmed_line" = "$name $version $release" ]; then
                            echo "Package $name already in repos, skipping it."
                            continue 2
                        fi
                        pkg_name=$(echo $trimmed_line | awk '{print $1}' | xargs)
                        pkg_version=$(echo $trimmed_line | awk '{print $2}' | xargs)
                        pkg_release=$(echo $trimmed_line | awk '{print $3}' | xargs)

                        if [ "$pkg_name" = "$name" ] && [ "$pkg_version" = "$version" ] && [ "$pkg_release" -gt "$release"]; then
                            echo "Package $name is more up-to-date on $repo than local, skipping it."
                            continue 2
                        fi
                    done  < /var/evobld/$repo/DIST
                    echo "Processing $name"
                            
                    sed -i "/$name/d" /var/evobld/$repo/DIST
                    echo "$name $version $release" >> /var/evobld/$repo/DIST
                    
                    FILE="/var/evobld/$repo/$name-$version.evx"
                    FILENAME="$name-$version.evx"
                    
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
