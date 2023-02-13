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
                    
                    comm -12 <(sort /var/evobld/$repo/INDEX) <(sort /var/evobld/$repo/DIST) | while read commonline ; do
                        trimmed_line=$(echo $commonline | xargs)
                        if [ ! "$trimmed_line" = "$name $version $release" ]; then
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
                        else
                            echo "Package $name is already in the repos, skipping it."
                        fi
                    done
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
