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
                    
                    # We have to check if the package is already in the repo.
                    # If it is, we have to check if the release is equal.
                    # If it is, we have to skip it.
                    # If the release is different, if it's higher, we skip it.
                    # If it's lower, we replace it.
                    # We do this by using the grep command.
                    # If the package is not in the repo, grep will return nothing.
                    # We are looking for a line formatted like this:
                    # package_name package_version package_release
                    # So we are looking for a line starting with package_name package_version.

                    if [ "$(grep -E "^$name $version" /var/evobld/$repo/DIST)" != "" ]; then
                        if [ "$(grep -E "^$name $version $release" /var/evobld/$repo/DIST)" != "" ]; then
                            # The package is in the repo and the release is equal.
                            # We have to skip it.
                            echo "Package $name already in repos, skipping it."
                            continue
                        else
                            # The package is in the repo but the release is different.
                            # We have to check if the release is higher or lower.
                            # We do this by getting the release from the repo.
                            repo_release=$(grep -E "^$name $version" /var/evobld/$repo/DIST | awk '{print $3}' | xargs)
                            if [ "$repo_release" -gt "$release" ]; then
                                # The release is higher, we have to skip it.
                                echo "Package $name is more up-to-date on $repo than local, skipping it."
                                continue
                            fi
                        fi
                    fi

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
