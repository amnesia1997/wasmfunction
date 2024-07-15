#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

SCRIPT_ROOT=$(dirname ${BASH_SOURCE})/..

# Generates types_swagger_doc_generated file for the given group version.
# $1: Name of the group version
# $2: Path to the directory where types.go for that group version exists. This
# is the directory where the file will be generated.
kube::swagger::gen_types_swagger_doc() {
  local group_version=$1
  local gv_dir=$2
  local TMPFILE="${TMPDIR:-/tmp}/zz_generated.swagger_doc_generated.$(date +%s).go"

  echo "Generating swagger type docs for ${group_version} at ${gv_dir}"

  # sed 's/YEAR/2017/' hack/boilerplate.txt > "$TMPFILE"
  echo "package ${group_version##*/}" >> "$TMPFILE"
  cat >> "$TMPFILE" <<EOF
// This file contains a collection of methods that can be used from go-restful to
// generate Swagger API documentation for its models. Please read this PR for more
// information on the implementation: https://github.com/emicklei/go-restful/pull/215
//
// TODOs are ignored from the parser (e.g. TODO(andronat):... || TODO:...) if and only if
// they are on one line! For multiple line or blocks that you want to ignore use ---.
// Any context after a --- is ignored.
//
// Those methods can be generated by using hack/update-swagger-docs.sh
// AUTO-GENERATED FUNCTIONS START HERE
EOF

  go run tools/genswaggertypedocs/swagger_type_docs.go -s \
    ${gv_dir}/types*.go \
    -f - \
    >>  "$TMPFILE"

  echo "// AUTO-GENERATED FUNCTIONS END HERE" >> "$TMPFILE"

  gofmt -w -s "$TMPFILE"
  mv "$TMPFILE" ""${gv_dir}"/zz_generated.swagger_doc_generated.go"
}

util::group-version-to-pkg-path() {
    local group_version="$1"
    echo "pkg/apis/${group_version}"
}

for gv in ${API_GROUP_VERSIONS}; do
  rm -f "${SCRIPT_ROOT}/${gv}/zz_generated.swagger_doc_generated.go"
  util::group-version-to-pkg-path "${gv}"
  kube::swagger::gen_types_swagger_doc "${gv}" "$(util::group-version-to-pkg-path "${gv}")"
done