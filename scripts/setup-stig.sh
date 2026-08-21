#!/usr/bin/env bash

set -euo pipefail

image=""
version=0.1.80
datastream="ssg-rhel9-ds.xml"
profile="xccdf_org.ssgproject.content_profile_stig"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)       image="$2";      shift 2 ;;
    --ssg-version) version="$2";    shift 2 ;;
    --datastream)  datastream="$2"; shift 2 ;;
    --profile)     profile="$2";    shift 2 ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

: "${image:?--image is required}"

sudo apt-get update -qq
sudo apt-get install -y -qq openscap-scanner podman jq

curl -fsSL -o ssg.tar.bz2 \
  "https://github.com/ComplianceAsCode/content/releases/download/v${version}/scap-security-guide-${version}.tar.bz2"
tar -xjf ssg.tar.bz2

podman pull "${image}"
podman create --name scan-target "${image}"
mkdir -p rootfs
podman export scan-target | tar -xC rootfs/
podman rm scan-target


rc=0
sudo oscap-chroot rootfs/ xccdf eval \
  --profile "${profile}" \
  --results stig-results.xml \
  --report stig-report.html \
  # --tailoring-file "images/${IMAGE_NAME}/stig-tailoring.xml" \ add tailoring exists
  "scap-security-guide-${version}/${datastream}" || rc=$?

if [[ ${rc} -eq 1 ]]; then
  echo "oscap evaluation errored" >&2
  exit 1
fi

npx --yes @mitre/saf convert xccdf_results2hdf \
  -i stig-results.xml \
  -o stig-results.hdf.json

npx --yes @microsoft/sarif-multitool convert \
  -t Hdf \
  -o stig-results.raw.sarif \
  stig-results.hdf.json
.
jq '
  .runs[].results |= map(
    select(
      (.properties.status // "failed") | ascii_downcase
      | IN("failed", "error")
    )
  )
' stig-results.raw.sarif > stig-results.sarif
