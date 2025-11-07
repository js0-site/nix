cout() {
  echo -e "[0;32m$1[0m"
}

cerr() {
  echo -e "[0;31m$1[0m" >&2
  exit 1
}

