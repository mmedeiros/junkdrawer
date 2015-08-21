#!/bin/bash

define_valid_envs(){
  valid_envs=("prod inf stg qa uat demo")
}

build_vars() {
  if [[ -z "$region" ]]; then
    region="us-east-1"
  fi
  if [[ -z "$domain" ]]; then
    domain="example.com"
  fi
  tf_dir=$(pwd)
  workdir="${tf_dir}/${region}/${stack}"
  outfile="terraform.plan"
  varfile="variables.tf"
  tf_varfile="terraform.tfvars"
  tfstatedir="${workdir}/.terraform"
  if [ $verbose -eq 1 ]; then
    saywhat "region     = $region"
    saywhat "domain     = $domain"
    saywhat "tf_dir     = $tf_dir"
    saywhat "workdir    = $workdir"
    saywhat "outfile    = $outfile"
    saywhat "varfile    = $varfile"
    saywhat "tf_varfile = $tf_varfile"
    saywhat "tfstatedir = $tfstatedir"
  fi
}

check_workdir_exists() {
  saywhat "Checking for the existence of dir: $workdir ..."
  if [ ! -d "$workdir" ]; then
    barf "$workdir does not exist, exiting..."
  fi
}

create_sym_link() {
  cd "$workdir"
  unlink $varfile
  saywhat "Creating sym link..."
  saywhat "ln -s ${tf_dir}/common/${varfile} $varfile"
  ln -s "$tf_dir"/common/"$varfile" "$varfile"
}

tf_remote_config() {
  # $path here is not a system path, but a
  # virtual path used by terraform
  path=${region}/${stack}
  if [ "$env" != "inf" ]; then
    path=${region}/${env}/${stack}
  fi
  if [ $verbose -eq 1 ]; then
    saywhat "about to run the following command"
    echo "terraform remote config -backend=consul \
    -backend-config=\"address=consul.${domain}\" \
    -backend-config=\"path=${path}\" \
    -backend-config=\"scheme=https\""
  fi
  terraform remote config -backend=consul \
    -backend-config="address=consul.${domain}" \
    -backend-config="path=${path}" \
    -backend-config="scheme=https"
}

tf_remote_push() {
  saywhat "$banner Pushing terraform state to repo"
  terraform remote push
}

tf_get() {
  if [ $verbose -eq 1 ]; then
    saywhat "cd to $workdir"
  fi
  cd "$workdir"
  saywhat "Pulling down terraform modules"
  delete_tfstate_cache
  saywhat "Running Terraform get"
  terraform get .
  if [ $? -ne 0 ]; then
    saywhat "Could not retrieve terraform modules"
  fi
}

tf_remote_pull() {
  saywhat "Pulling remote state"
  terraform remote pull
}

tf_build_plan() {
  check_tfvars
  saywhat "Building plan"
  terraform plan -out=$outfile -module-depth=1 \
    -detailed-exitcode \
    -var environment="$env"\
    -var-file="$tf_dir"/"$tf_varfile" .
  if [ $? -eq 2 ]; then
    run_the_plan
  elif [ $? -eq 1 ]; then
    barf "Build plan failed."
  else
    saywhat "The plan was run, no infrastructure changes to be applied"
    exit 0
  fi
}

check_tfvars() {
  saywhat "Checking for tfvars file"
  if [ ! -e "$tf_dir"/"$tf_varfile" ]; then
    echo "${tf_varfile} does not exist!"
    echo "please create a tfvars file containing aws creds at"
    echo "${tf_dir}/${tf_varfile}"
    return 1
  fi
}

run_the_plan() {
  while true; do
    read -p "$0: Do you want to run the above plan? [Y/N]" yn
    case $yn in
      [Yy]* )
        tf_remote_pull
        terraform apply ${outfile}
        tf_remote_push
        return 0
        ;;
      [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done
}

check_args(){
  verbose=0
  while (( "$#" ));
  do
    key="$1"
    case $key in
      -h|--help|help|halp)
        saywhat "Happy to help!"
        usage
        exit 0;
        ;;
      -v|--verbose)
        verbose=1;
        saywhat "verbose mode enabled!"
        ;;
      -d|--destroy|--kill)
        destroy=1;
        ;;
      -D|--domain)
        domain=$2
        shift
        ;;
      -e|--environment|--env)
        env=$2
        shift
        ;;
      -r|--region)
        region=$2
        shift
        ;;
      -s|--stack)
        stack=$2
        shift
        ;;
      */*)
    esac
    shift
  done

  if [[ -z "$env" ]]; then
    env=inf
  fi

  validate_env
}

usage(){
  echo "usage $0 --environment [ENV] --stack [STACKNAME]"
  echo "sample usage:"
  echo "  $0 --env dev --stack dev-security-groups"
  echo "sample usage (to destroy):"
  echo "  $0 --destroy --env dev --stack dev-security-groups"
}

delete_tfstate_cache() {
  echo -e "$banner Deleting tfstate cache"
  saywhat "rm -rf \"$tfstatedir\"/*"
  rm -rf "$tfstatedir"/*
}

saywhat() {
  printf "$banner $*\n"
  logger "$0: $*"
}

destroy_the_stack(){
  check_tfvars
  saywhat "Preparing to destroy stack: $stack in environment: $env"
  cd "$workdir"
  todestroy="terraform destroy -var-file $tf_dir/$tf_varfile -var environment=$env . "
  saywhat "running: $todestroy"
  $todestroy
}

make_banner() {
  # Colorize output
  cyan='\033[0;36m'
  NC='\033[0m' # No Color
  banner="${cyan}$0:${NC}"
}

barf() {
  saywhat "$*"; exit 111;
}

validate_env() {
  for environ in "${valid_envs[@]}";
  do
    if [[ "$environ" =~ "$env" ]]; then
      match=1;
    fi
  done
  if [[ ! "$match" -eq 1 ]]; then
    barf "invalid env: $env"
  fi
}

run_the_program() {
  define_valid_envs
  check_args "$@"
  make_banner
  build_vars
  check_workdir_exists
  create_sym_link
  tf_get
  tf_remote_config
  tf_remote_pull
  if [[ "$destroy" -eq 1 ]]; then
    destroy_the_stack
  else
    tf_build_plan
  fi
}

run_the_program "$@"
