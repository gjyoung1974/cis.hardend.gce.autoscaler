#!/bin/bash -xe

BUILDER_DIR="/tmp/builder"

. $BUILDER_DIR/CONFIG


run_command () {
    echo "Running script [$1]"
    chmod +x $1
    (cd $BUILDER_DIR/setup-scripts; BUILDER_DIR=$BUILDER_DIR $1 )
    if [ $? -ne "0" ]; then
        echo "Exiting. Failed to execute [$1]"
        exit 1
    fi
}

setup_beanstalk_base() {
    echo "Creating base directories for platform."
    mkdir -p $BEANSTALK_DIR/deploy/appsource/
    mkdir -p /var/app/staging
    mkdir -p /var/app/current
    mkdir -p /var/log/nginx/healthd/
    mkdir -p /var/log/tomcat/

    echo "Setting permissions in /opt/elasticbeanstalk"
    find /opt/elasticbeanstalk -type d -exec chmod 755 {} \; -print
    chown -R root:root /opt/elasticbeanstalk/

    echo "Setting permissions for shell scripts"
    find /opt/elasticbeanstalk/ -name "*.sh" -exec chmod 755 {} \; -print
}

set_permissions() {
    echo "Setting permissions for /tmp"
    chmod 1777 /tmp
    chown root:root /tmp
}


wait_for_cloudinit() {
    echo "Waiting for cloud init to finish bootstrapping.."
    until [ -f /var/lib/cloud/instance/boot-finished ]; do
        echo "Still bootstrapping.. sleeping. "
        sleep 3;
    done
}

prepare_platform_base() {
    # TODO: split EB image creation
    #setup_beanstalk_base
    set_permissions
}

sync_platform_uploads() {
    ##### COPY THE everything in platform-uploads to / ####
    echo "Setting up platform hooks"
    rsync -ar $BUILDER_DIR/platform-uploads/ /
}

run_setup_scripts() {
    for entry in $( ls $BUILDER_DIR/setup-scripts/*.sh | sort ) ; do
        run_command $entry
    done
}

run_ansible_provisioning_plays(){
    pushd $BUILDER_DIR
    echo `pwd`
    echo `ansible --version`
    echo "Starting hardening and base ansible roles implementation"
    ansible-playbook playbook.yml \
    -e partitioning=False \
    --skip-tags=\"section1.2.1,section1.3,section3.2.4,section3.2.8,section4.1,section4.3.1,section4.1.12.2,section5.2\"
    popd
}

cleanup() {
    echo "Done all customization of packer instance. Cleaning up"
    apt-get clean && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    rm -rf $BUILDER_DIR
}

echo "Running packer builder script"
#wait_for_cloudinit # port this to GCP
#prepare_platform_base
#sync_platform_uploads
run_setup_scripts
# get galaxy roles
# run_ansible_provisioning_plays
#cleanup
# set_permissions