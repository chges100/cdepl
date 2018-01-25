#!/bin/bash

__CLUSTER_CLEANUP_ON_ERROR="1"
__CLUSTER_CLEANUP_ON_SIGINT="1"

##
# Initialize the cluster
#
# This is the first function you should call before continuing with any
# resource allocation or deployment tasks.
# This sets up the environment and loads the specified cluster module.
#
# $1: Name of the cluster module to load
# $2: Name of the user to log into the cluster
# ...: Further optional arguments that are passed on as parameters to the
#      loaded cluster module
##
cdepl_cluster_init()
{
	local cluster_name=$1
	local cluster_user=$2

	local available=0

	# Check if scripts for cluster are available
	for f in ${CDEPL_SCRIPT_DIR}/cluster/*; do
		if [ "$f" = "$cluster_name" ]; then
			available=1
		fi
	done

	if [ ! available ]; then
		util_error_and_exit "[cluster] Could not find cluster script for $cluster_name"
	fi

	util_log_debug "[cluster] Cluster selected on init: $cluster_name"
	util_log_debug "[cluster] Cluster user: $cluster_user"

	# Include
	source ${CDEPL_SCRIPT_DIR}/cluster/${cluster_name}

	__cdepl_cluster_check_cluster_api $cluster_name

	# Call "constructor"
	_cdepl_cluster_on_init "$cluster_user" "${@:3}"
}

##
# Enable/disable calling of the cleanup callback on any error (default enabled)
#
# $1: Enable (1) or disable (0)
##
cdepl_cluster_cleanup_on_error()
{
	local cleanup=$1

	__CLUSTER_CLEANUP_ON_ERROR="$cleanup"
}

##
# Enable/disable calling of the cleanup callback on SIGINT
#
# $1: Enable (1) or disable (0)
##
cdepl_cluster_cleanup_on_sigint()
{
	local cleanup=$1

	__CLUSTER_CLEANUP_ON_SIGINT="$cleanup"
}

##
# Load an application module of an app you want to deploy and initialize
# the environment
#
# $1: Name of the application module to load
##
cdepl_cluster_app_load()
{
	local cluster_app=$1

	local available=0

	# Check if scripts for cluster are available
	for f in ${CDEPL_SCRIPT_DIR}/app/*; do
		if [ "$f" = "$cluster_app" ]; then
			available=1
		fi
	done

	if [ ! available ]; then
		util_error_and_exit "[cluster] Could not find application script for $cluster_app"
	fi

	util_log_debug "[cluster] Application loaded: $cluster_app"

	# Include
	source ${CDEPL_SCRIPT_DIR}/app/${cluster_app}
}

__cdepl_cluster_check_cluster_api()
{
	local cluster_type=$1

	__cdepl_cluster_assert_function cdepl_cluster_node_alloc $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_get_alloc_node_count $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_walltime $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_node_excl $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_node_cpu_limit_single_socket $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_node_cpus $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_node_mem $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_node_network $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_resolve_hostname_to_ip $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_resolve_node_to_ip $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_node_resolve_node_to_hostname $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_node_cmd $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_gather_log_files $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_file_system_cmd $cluster_type
	__cdepl_cluster_assert_function cdepl_cluster_allows_sudo $cluster_type

	__cdepl_cluster_assert_function _cdepl_cluster_on_init $cluster_type
	__cdepl_cluster_assert_function _cdepl_cluster_on_node_setup_finish $cluster_type
	__cdepl_cluster_assert_function _cdepl_cluster_before_deploy $cluster_type
	__cdepl_cluster_assert_function _cdepl_cluster_after_deploy $cluster_type
	__cdepl_cluster_assert_function _cdepl_cluster_before_cleanup $cluster_type
	__cdepl_cluster_assert_function _cdepl_cluster_after_cleanup $cluster_type
}

__cdepl_cluster_assert_function()
{
	local func=$1
	local cluster_type=$2

	local type="$(type -t $func)"

	if [ ! "$type" ]; then
		util_log_error_and_exit "[cluster] Missing function $func in cluster type $cluster_type"
	fi

	if [ "$type" != "function" ]; then
		util_log_error_and_exit "[cluster] $func is not a function ($type) in cluster type $cluster_type"
	fi
}