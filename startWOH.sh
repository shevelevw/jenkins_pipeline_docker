#!/bin/bash
exec &> >(tee -a "/var/log/container.log")
export ENVWAN=`curl -s ifconfig.me`
export ENVHOSTNAME=$HOSTNAME
export GOOGLE_APPLICATION_CREDENTIALS=/etc/visumenu/gcs-key.json 

#Generate substitutes to generate configs
printenv|grep '^ENV'|awk 'BEGIN{FS="="}{print("s/${" $1 "}/" $2 "/")}' > /home/replace.sed

#Generate configs from templates
find /etc -type f -name '*.tmpl' |\
while read i; do
        sed -f /home/replace.sed $i > "${i::-5}"
done

# dig +short $ENVDNSNAME |\
# while read ip; do 
#   /usr/bin/gcloud dns --project=visumenu-1312 record-sets transaction start --zone=aybell
#   /usr/bin/gcloud dns record-sets transaction remove --zone=aybell --name "$ENVDNSNAME." --ttl 300 --type A "$ip"
#   /usr/bin/gcloud dns --project=visumenu-1312 record-sets transaction execute --zone=aybell
# done

# /usr/bin/gcloud dns --project=visumenu-1312 record-sets transaction start --zone=aybell
# /usr/bin/gcloud dns --project=visumenu-1312 record-sets transaction add $ENVWAN --name=$ENVDNSNAME. --ttl=300 --type=A --zone=aybell
# /usr/bin/gcloud dns --project=visumenu-1312 record-sets transaction execute --zone=aybell

# Wait while DNS will be populated with correct IP
# while [[ ! "`ping -c 1 $ENVDNSNAME`" || "`dig +short $ENVDNSNAME`" != "$ENVWAN" ]]; do 
#   sleep 5; 
#   echo "Whait while DNS will be populated with correct data"
# done

# certbot certonly --non-interactive --agree-tos --standalone -d $ENVDNSNAME -m admin@aybell.com
a2ensite crawlerapi.conf
a2dissite 000-default.conf

#Create uploads dir based on conf.json
jq '.crawler.uploads' /etc/visumenu/conf.json | xargs mkdir -p 
jq '.crawler.uploads' /etc/visumenu/conf.json | xargs chmod 777 -R 

# Creat need folders vm.config['crawler']['uploads'] ....
# Add DNS names to hosts file
/bin/echo "127.0.0.1 crawler.aybell.com crawler" >> /etc/hosts

#service supervisor stop
/usr/bin/supervisord
