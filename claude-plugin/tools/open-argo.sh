#!/bin/zsh
# Open an explicitly selected Argo CD application; no environment or naming defaults.
set -euo pipefail
base_url=${ARGOCD_URL:-}
namespace=${ARGOCD_NAMESPACE:-}
application=''
while (( $# )); do
  case "$1" in
    --url|--namespace|--application)
      (( $# >= 2 )) && [[ -n "$2" ]] || { print -u2 'Missing option value.'; exit 2; }
      case "$1" in
        --url) base_url=$2 ;;
        --namespace) namespace=$2 ;;
        --application) application=$2 ;;
      esac
      shift 2 ;;
    -h|--help)
      print 'Usage: open-argo --url <management-root> --namespace <namespace> --application <exact-name>'
      print 'ARGOCD_URL and ARGOCD_NAMESPACE can supply connection defaults.'
      exit 0 ;;
    *) print -u2 -- "Unknown option: $1"; exit 2 ;;
  esac
done
[[ -n "$base_url" && -n "$namespace" && -n "$application" ]] || {
  print -u2 'Argo CD URL, namespace and exact application name are required.'; exit 2
}
url=$(python3 - "$base_url" "$namespace" "$application" <<'PY'
import sys
from urllib.parse import urlsplit,quote
base,namespace,application=sys.argv[1:]
u=urlsplit(base)
if u.scheme not in ('http','https') or not u.hostname or u.username or u.password or u.query or u.fragment:
    sys.exit('Invalid Argo CD base URL.')
if any(x in ('.','..') for x in (namespace,application)):
    sys.exit('Invalid application path component.')
print(base.rstrip('/')+'/applications/'+quote(namespace,safe='')+'/'+quote(application,safe=''))
PY
)
print -r -- "$url"
if command -v open >/dev/null; then open "$url"
elif command -v xdg-open >/dev/null; then xdg-open "$url"
else print -u2 'No browser opener available; open the displayed URL manually.'; exit 1
fi
