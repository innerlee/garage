#!/usr/bin/env bash
# This script installs garage on OS X distributions.
#
# NOTICE: To keep consistency across this script, scripts/setup_linux.sh and
# docker/Dockerfile.ci, if there's any changes applied to this file, specially
# regarding the installation of dependencies, apply those same changes to the
# mentioned files.

### START OF CODE GENERATED BY Argbash v2.6.1 one line above ###
die()
{
  local _ret=$2
  test -n "$_ret" || _ret=1
  test "$_PRINT_HELP" = yes && print_help >&2
  echo "$1" >&2
  exit ${_ret}
}

begins_with_short_option()
{
  local first_option all_short_options
  all_short_options='h'
  first_option="${1:0:1}"
  test "$all_short_options" = "${all_short_options/$first_option/}" && \
    return 1 || return 0
}



# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_set_envvar="off"

print_help ()
{
  printf '%s\n' "Installer of garage for OS X."
  printf 'Usage: %s [--(no-)set-envvar] ' "$0"
  printf '[-h|--help] <mjkey-path>\n' "$0"
  printf '\t%s\n' "<mjkey-path>: Path of the MuJoCo key"
  printf '\t%s' "--set-envvar,--no-set-envvar: Set environment variables "
  printf '%s\n' "required by garage in .bash_profile (off by default)"
  printf '\t%s\n' "-h,--help: Prints help"
}

parse_commandline ()
{
  while test $# -gt 0
  do
    _key="$1"
    case "$_key" in
      --no-set-envvar|--set-envvar)
        _arg_set_envvar="on"
        test "${1:0:5}" = "--no-" && _arg_set_envvar="off"
        ;;
      -h|--help)
        print_help
        exit 0
        ;;
      -h*)
        print_help
        exit 0
        ;;
      *)
        _positionals+=("$1")
        ;;
    esac
    shift
  done
}


handle_passed_args_count ()
{
  _required_args_string="'mjkey-path'"
  error_msg="$(echo "FATAL ERROR: Not enough positional arguments - we" \
    "require exactly 1 (namely: $_required_args_string), but got only" \
    "${#_positionals[@]}.")"
  test ${#_positionals[@]} -ge 1 || _PRINT_HELP=yes die "${error_msg}" 1
  error_msg="$(echo "FATAL ERROR: There were spurious positional arguments" \
    "--- we expect exactly 1 (namely: $_required_args_string), but got" \
    "${#_positionals[@]} (the last one was: '${_positionals[*]: -1}').")"
  test ${#_positionals[@]} -le 1 || _PRINT_HELP=yes die "${error_msg}" 1
}

assign_positional_args ()
{
  _positional_names=('_arg_mjkey_path' )

  for (( ii = 0; ii < ${#_positionals[@]}; ii++))
  do
    error_msg="$(echo "Error during argument parsing, possibly an Argbash" \
      "bug.")"
    eval "${_positional_names[ii]}=\${_positionals[ii]}" || \
      die "${error_msg}" 1
  done
}

parse_commandline "$@"
handle_passed_args_count
assign_positional_args
### END OF CODE GENERATED BY Argbash (sortof) ### ])

# Utility functions
script_dir_path() {
  SCRIPT_DIR="$(dirname ${0})"
  [[ "${SCRIPT_DIR}" = /* ]] && echo "${SCRIPT_DIR}" || \
    echo "${PWD}/${SCRIPT_DIR#./}"
}

# red text
print_error() {
  echo -e "\033[0;31m${@}\033[0m"
}

# yellow text
print_warning() {
  echo -e "\033[0;33m${@}\033[0m"
}

# List of verified versions of OS X where garage has been installed
VALID_VER=("10.12")
VER="$(sw_vers -productVersion)"

if [[ ! " ${VALID_VER[@]} " =~ " ${VER} " ]]; then
  print_warning "It has not been verified whether garage will install" \
    "correctly under your current OS X version (${VER}). If the installation" \
    "is successful, please update the list of valid versions in this script." \
    "Otherwise, if you are able to fix your compatibility issue, please file" \
    "an issue to (https://github.com/rlworkgroup/garage/issues) and include a"\
    "link to your Pull Request.\n" |
  fold -s
  while [[ "${continue_var}" != "y" ]]; do
    read -p "Continue? (y/n): " continue_var
    if [[ "${continue_var}" = "n" ]]; then
      exit
    fi
  done
fi

# Verify there's a file in the mjkey path
test -f "${_arg_mjkey_path}" || _PRINT_HELP=yes die \
  "The path ${_arg_mjkey_path} of the MuJoCo key is not valid." 1

# Make sure that we're under the garage directory
GARAGE_DIR="$(dirname $(script_dir_path))"
cd "${GARAGE_DIR}"

# File where environment variables are stored
BASH_PROF="${HOME}/.bash_profile"

# Install dependencies
echo "Installing garage dependencies"
echo "You will probably be asked for your sudo password"

# Homebrew is required first to install the other dependencies
hash brew 2>/dev/null || {
  # Install the Xcode Command Line Tools
  xcode-select --install
  # Install Homebrew
  /usr/bin/ruby -e "$(curl -fsSL \
    https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

# For installing garage: bzip2, git, glfw, unzip, wget
# For building glfw: cmake
# Required for OpenAI gym: cmake boost boost-python ffmpeg sdl2 swig wget
# Required for OpenAI baselines: cmake openmpi
brew update
brew install \
  bzip2 \
  git \
  glfw \
  unzip \
  wget \
  cmake \
  boost \
  boost-python \
  ffmpeg \
  sdl2 \
  swig \
  openmpi

# Leave a note in ~/.bashrc for the added environment variables
if [[ "${_arg_set_envvar}" = on ]]; then
  echo -e "\n# Added by the garage installer" >> "${BASH_PROF}"
fi

# Set up MuJoCo
if [[ ! -d "${HOME}"/.mujoco/mjpro150 ]]; then
  mkdir "${HOME}"/.mujoco
  MUJOCO_ZIP="$(mktemp -d)/mujoco.zip"
  wget https://www.roboti.us/download/mjpro150_osx.zip -O "${MUJOCO_ZIP}"
  unzip -u "${MUJOCO_ZIP}" -d "${HOME}"/.mujoco
else
  print_warning "MuJoCo is already installed"
fi
# Configure MuJoCo as a shared library
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${HOME}/.mujoco/mjpro150/bin"
LD_LIB_ENV_VAR="LD_LIBRARY_PATH=\"\$LD_LIBRARY_PATH:${HOME}/.mujoco/mjpro150"
LD_LIB_ENV_VAR="${LD_LIB_ENV_VAR}/bin\""
if [[ "${_arg_set_envvar}" = on ]]; then
  echo "export ${LD_LIB_ENV_VAR}" >> "${BASH_PROF}"
fi

# Set up conda
hash conda 2>/dev/null || {
  CONDA_INSTALLER="$(mktemp -d)/miniconda.sh"
  chmod u+x "${CONDA_INSTALLER}"
  wget https://repo.continuum.io/miniconda/Miniconda2-latest-MacOSX-x86_64.sh \
    -O "${CONDA_INSTALLER}"
  bash "${CONDA_INSTALLER}" -b
  # Add conda to executable programs
  CONDA_PATH="${HOME}/miniconda2/bin/"
  export PATH="$PATH:${CONDA_PATH}"
  PATH_ENV_VAR="PATH=\"\$PATH:${CONDA_PATH}\""
  if [[ "${_arg_set_envvar}" = on ]]; then
    echo "export ${PATH_ENV_VAR}" >> "${BASH_PROF}"
  fi
}
conda update -q -y conda

# Create conda environment
conda env create -f environment.yml
if [[ "${?}" -ne 0 ]]; then
  print_error "Error: conda environment could not be created"
fi

# Extras
source activate garage
# Prevent pip from complaining about available upgrades
pip install --upgrade pip
# Fix Box2D install
# See https://github.com/openai/gym/issues/100
# See https://github.com/pybox2d/pybox2d/issues/82
pip uninstall -y Box2D Box2D-kengz box2d-py
PYBOX2D_DIR="$(mktemp -d)/pybox2d"
git clone https://github.com/pybox2d/pybox2d "${PYBOX2D_DIR}"
cd "${PYBOX2D_DIR}"
python setup.py build
python setup.py install
python setup.py develop
cd "${GARAGE_DIR}"
# We need a MuJoCo key to import mujoco_py
cp ${_arg_mjkey_path} "${HOME}"/.mujoco/mjkey.txt
brew reinstall gcc@7 --without-multilib
python -c 'import mujoco_py'
# Set up pre-commit in local repo
pre-commit install -t pre-commit
pre-commit install -t pre-push
pre-commit install -t commit-msg
source deactivate

# Add garage to python modules
export PYTHONPATH="$PYTHONPATH:${GARAGE_DIR}"
PYTHON_ENV_VAR="PYTHONPATH=\"\$PYTHONPATH:${GARAGE_DIR}\""
if [[ "${_arg_set_envvar}" = on ]]; then
  echo "export ${PYTHON_ENV_VAR}" >> "${BASH_PROF}"
else
  echo -e "\nRemember to export the following environment variables before" \
    "running garage:"
  echo "${LD_LIB_ENV_VAR}"
  echo "${PATH_ENV_VAR}"
  echo "${PYTHON_ENV_VAR}"
  echo "You may wish to edit your .bash_profile to prepend the exports of" \
    "these environment variables."
fi

echo -e "\nGarage is installed! To make the changes take effect, work under" \
  "a new terminal. Also, make sure to run \`source activate garage\`" \
  "whenever you open a new terminal and want to run programs under garage." \
  | fold -s
