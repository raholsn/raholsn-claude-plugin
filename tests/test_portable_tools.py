"""Exercise target selection without contacting providers or opening a browser."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[1] / 'claude-plugin' / 'tools'


class PortableTools(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'])
        for key in ('ARGOCD_URL', 'ARGOCD_NAMESPACE'):
            self.env.pop(key, None)
        self.env['OPEN_LOG'] = str(self.root / 'opened')
        self.stub('open', '#!/bin/sh\nprintf "%s" "$1" > "$OPEN_LOG"\n')
        self.stub('gh', '''#!/usr/bin/env python3
import json,os,sys
args=sys.argv[1:]
with open(os.environ['GH_LOG'],'a') as f: f.write(json.dumps(args)+'\\n')
repo=args[args.index('--repo')+1]
if repo=='other/failure': sys.exit(1)
if args[:2]==['run','list']:
    print(json.dumps([{'databaseId':123,'url':'https://example.com/run','status':'completed','conclusion':'success'}]))
elif args[:2]==['run','view']:
    print(json.dumps({'url':'https://example.com/run','jobs':[
        {'name':'Ship test','status':'completed','conclusion':'success','completedAt':'2026-01-01T00:00:00Z'},
        {'name':'Unrelated job','status':'completed','conclusion':'failure'}]}))
else: sys.exit(91)
''')
        self.env['GH_LOG'] = str(self.root / 'gh-calls')
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        subprocess.run(['git', '-C', str(self.root), 'symbolic-ref', 'HEAD', 'refs/heads/feature/a&b'], check=True)

    def stub(self, name, source):
        p = self.bin / name
        p.write_text(source)
        p.chmod(0o755)

    def run_tool(self, name, *args):
        return subprocess.run(['zsh', str(TOOLS / (name + '.sh')), *args], cwd=self.root,
                              env=self.env, text=True, capture_output=True)

    def remote(self, url):
        subprocess.run(['git', '-C', str(self.root), 'config', 'remote.origin.url', url], check=True)

    def test_github_owner_from_https_and_ssh(self):
        for url in ('https://github.com/new-client/service.git', 'git@github.com:new-client/service.git'):
            with self.subTest(url=url):
                self.remote(url)
                result = self.run_tool('show-pullrequests')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual((self.root / 'opened').read_text(),
                                 'https://github.com/new-client/service/compare/feature%2Fa%26b?expand=1')

    def test_azure_project_from_remote(self):
        for url in ('https://user@dev.azure.com/new-client/My%20Project/_git/service',
                    'git@ssh.dev.azure.com:v3/new-client/My%20Project/service'):
            with self.subTest(url=url):
                self.remote(url)
                result = self.run_tool('show-pullrequests')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual((self.root / 'opened').read_text(),
                                 'https://dev.azure.com/new-client/My%20Project/_git/service/pullrequests?_a=mine')

    def test_legacy_azure(self):
        self.remote('https://new-client.visualstudio.com/Project/_git/service')
        result = self.run_tool('show-pullrequests')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('new-client.visualstudio.com/Project/_git/service/pullrequests', result.stdout)

    def test_unsupported_remote_does_not_open(self):
        self.remote('https://github.com.untrusted.example/new-client/service')
        self.assertNotEqual(self.run_tool('show-pullrequests').returncode, 0)
        self.assertFalse((self.root / 'opened').exists())

    def test_argo_requires_target(self):
        self.assertNotEqual(self.run_tool('open-argo', '--application', 'service').returncode, 0)
        self.assertFalse((self.root / 'opened').exists())

    def test_argo_explicit_target_and_encoding(self):
        result = self.run_tool('open-argo', '--url', 'https://argo.example.com/prefix/',
                               '--namespace', 'delivery', '--application', 'service?a=b')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / 'opened').read_text(),
                         'https://argo.example.com/prefix/applications/delivery/service%3Fa%3Db')

    def test_argo_environment_defaults_and_flag_precedence(self):
        self.env.update(ARGOCD_URL='https://default.example.com', ARGOCD_NAMESPACE='delivery')
        result = self.run_tool('open-argo', '--url', 'https://selected.example.com', '--application', 'api')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / 'opened').read_text(),
                         'https://selected.example.com/applications/delivery/api')

    def test_deploy_explicit_owner_workflow_and_job(self):
        result = self.run_tool('get-deploy-status', 'new-client/service', 'release.yml', 'Ship test', '3')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Ship test', result.stdout)
        self.assertNotIn('Unrelated job', result.stdout)
        calls = [json.loads(line) for line in (self.root / 'gh-calls').read_text().splitlines()]
        self.assertEqual(calls[0], ['run','list','--repo','new-client/service','--workflow','release.yml',
                                    '--limit','3','--json','databaseId,url,status,conclusion'])

    def test_deploy_partial_failure(self):
        result = self.run_tool('get-deploy-status', 'other/failure,new-client/service', 'release.yml', 'Ship')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Could not read runs for other/failure', result.stderr)
        self.assertIn('Ship test', result.stdout)

    def test_deploy_invalid_inputs_never_call_gh(self):
        for args in [('service','release.yml','Ship'), ('owner/repo','release.yml','Ship','0'),
                     ('owner/repo','release.yml','Ship','101'), ('owner/repo',)]:
            with self.subTest(args=args):
                self.assertNotEqual(self.run_tool('get-deploy-status', *args).returncode, 0)
        self.assertFalse((self.root / 'gh-calls').exists())


if __name__ == '__main__':
    unittest.main()
