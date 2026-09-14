#!/bin/zsh
# Derive the PR page from the selected Git remote, not local folder conventions.
set -euo pipefail
(( $# <= 1 )) || { print -u2 'Usage: show-pullrequests [remote=origin]'; exit 2; }
remote_name=${1:-origin}
remote_url=$(git remote get-url -- "$remote_name")
branch=$(git symbolic-ref --quiet --short HEAD) || { print -u2 'Select a branch first.'; exit 1; }
url=$(python3 - "$remote_url" "$branch" <<'PY'
import re,sys
from urllib.parse import urlsplit,quote,unquote
remote,branch=sys.argv[1:]
if '://' not in remote:
    match=re.fullmatch(r'git@([^:]+):(.+)',remote)
    if not match: sys.exit('Unsupported remote format; use a GitHub or Azure DevOps remote.')
    host,path=match.groups()
else:
    u=urlsplit(remote)
    if u.scheme not in ('https','ssh') or u.password or u.query or u.fragment:
        sys.exit('Unsupported remote URL.')
    host,path=u.hostname,u.path.lstrip('/')
parts=path.removesuffix('.git').strip('/').split('/')
enc=lambda value: quote(unquote(value),safe='')
if any(not p or unquote(p) in ('.','..') for p in parts): sys.exit('Invalid remote path.')
if host=='github.com' and len(parts)==2:
    print('https://github.com/'+'/'.join(map(enc,parts))+'/compare/'+quote(branch,safe='')+'?expand=1')
elif host=='dev.azure.com' and len(parts)==4 and parts[2]=='_git':
    print('https://dev.azure.com/'+'/'.join(map(enc,parts))+'/pullrequests?_a=mine')
elif host=='ssh.dev.azure.com' and len(parts)==4 and parts[0]=='v3':
    org,project,repo=map(enc,parts[1:])
    print(f'https://dev.azure.com/{org}/{project}/_git/{repo}/pullrequests?_a=mine')
elif host and host.endswith('.visualstudio.com') and len(parts)==3 and parts[1]=='_git':
    print('https://'+host+'/'+ '/'.join(map(enc,parts))+'/pullrequests?_a=mine')
else:
    sys.exit('Unsupported remote host or path; supported providers are GitHub.com and Azure DevOps.')
PY
)
print -r -- "$url"
if command -v open >/dev/null; then open "$url"
elif command -v xdg-open >/dev/null; then xdg-open "$url"
else print -u2 'No browser opener available; open the displayed URL manually.'; exit 1
fi
