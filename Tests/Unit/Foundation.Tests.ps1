Import-Module "$PSScriptRoot/../../OpenShift.PowerShell.psd1"
Describe 'Phase 1 foundation' {
    InModuleScope OpenShift.PowerShell {
        BeforeEach {
            $script:Connections = @{}; $script:Secrets = @{}; $script:DefaultConnection = $null
            Mock New-OSHttpClient { [pscustomobject]@{} | Add-Member ScriptMethod Dispose {} -PassThru }
            Mock Send-OSHttp { [pscustomobject]@{ StatusCode=200; Content='{"gitVersion":"v1.33.0"}'; RetryAfter=0 } }
            Mock Start-Sleep {}
            $script:TestToken = ConvertTo-SecureString 'test-only-never-a-real-token' -AsPlainText -Force
        }
        It 'exports only implemented commands' {
            $manifest = Import-PowerShellDataFile "$PSScriptRoot/../../OpenShift.PowerShell.psd1"
            foreach ($name in $manifest.FunctionsToExport) { Get-Command $name -Module OpenShift.PowerShell | Should -Not -BeNullOrEmpty }
        }
        It 'connects and exposes only metadata' {
            $c = Connect-OpenShift -Server https://cluster.example:6443 -Token $script:TestToken
            $c.Mode | Should -Be ReadOnly
            ($c | ConvertTo-Json -Depth 10) | Should -Not -Match 'test-only|"Client"|"Secret"|"Token"\s*:'
            (Get-OpenShiftCredential).Authentication | Should -Be Token
            (Get-OpenShiftConnection).Name | Should -Be default
            (Get-OpenShiftClusterInfo).Version.gitVersion | Should -Be v1.33.0
            Test-OpenShiftConnection | Should -BeTrue
        }
        It 'rejects insecure or credential-bearing endpoints' -TestCases @(
            @{Url='http://cluster.example'}, @{Url='https://u:p@cluster.example'}, @{Url='https://cluster.example/path'}, @{Url='https://cluster.example/?token=x'}
        ) { param($Url) { Connect-OpenShift -Server $Url -Token $script:TestToken } | Should -Throw }
        It 'fails closed without registering failed authentication' {
            Mock Send-OSHttp { [pscustomobject]@{StatusCode=401;Content='secret echoed by server';RetryAfter=0} }
            { Connect-OpenShift -Server https://cluster.example -Token $script:TestToken } | Should -Throw '*401*'
            $script:Connections.Count | Should -Be 0; $script:Secrets.Count | Should -Be 0
        }
        It 'manages multiple independent sessions and local contexts' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken -Name one
            $null = Connect-OpenShift -Server https://two.example -Token $script:TestToken -Name two
            (Set-OpenShiftConnection one).Server | Should -Be https://one.example
            (Set-OpenShiftContext -Connection one -Namespace production).Namespace | Should -Be production
            @(Get-OpenShiftContext).Count | Should -Be 2
            Disconnect-OpenShift one
            @(Get-OpenShiftConnection).Count | Should -Be 1
            { Resolve-OSConnection one } | Should -Throw
        }
        It 'does not replace an existing session' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            { Connect-OpenShift -Server https://two.example -Token $script:TestToken } | Should -Throw '*already exists*'
        }
        It 'maps RBAC errors without including server response bodies' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            Mock Send-OSHttp { [pscustomobject]@{StatusCode=403;Content='TOP_SECRET';RetryAfter=0} }
            { Get-OpenShiftClusterInfo } | Should -Throw '*403*RBAC*'
            Test-OpenShiftConnection | Should -BeFalse
        }
        It 'retries transient reads three times and honors backoff' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            Mock Send-OSHttp { [pscustomobject]@{StatusCode=429;Content='';RetryAfter=3} }
            { Get-OpenShiftClusterInfo } | Should -Throw '*429*'
            Should -Invoke Send-OSHttp -Times 4 -Exactly
            Should -Invoke Start-Sleep -Times 2 -Exactly -ParameterFilter { $Seconds -eq 3 }
        }
        It 'does not retry writes and blocks all writes on read-only sessions' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            $s = Resolve-OSConnection
            { Invoke-OSRequest -Session $s -Method POST -Path /api/v1/namespaces -Body @{} } | Should -Throw '*read-only*'
            $s.Mode = 'Administrative'
            Mock Send-OSHttp { [pscustomobject]@{StatusCode=503;Content='';RetryAfter=0} }
            { Invoke-OSRequest -Session $s -Method POST -Path /api/v1/namespaces -Body @{} } | Should -Throw '*503*'
            Should -Invoke Start-Sleep -Times 0
        }
        It 'rejects external or traversing API paths' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            foreach ($path in @('https://other.example','//other.example','/api/../secret','/api\evil')) {
                { Invoke-OSRequest -Session (Resolve-OSConnection) -Path $path } | Should -Throw
            }
        }
        It 'discovers versions, subresources and scoped resources with cache and refresh' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            Mock Invoke-OSRequest {
                switch ($Path) {
                    '/api' { [pscustomobject]@{versions=@('v1')} }
                    '/apis' { [pscustomobject]@{groups=@([pscustomobject]@{name='kubevirt.io';preferredVersion=@{groupVersion='kubevirt.io/v1'};versions=@(@{version='v1';groupVersion='kubevirt.io/v1'},@{version='v1alpha3';groupVersion='kubevirt.io/v1alpha3'})})} }
                    '/api/v1' { [pscustomobject]@{resources=@(@{name='pods';kind='Pod';namespaced=$true;verbs=@('get','list')})} }
                    default { [pscustomobject]@{resources=@(@{name='virtualmachines';kind='VirtualMachine';namespaced=$true;verbs=@('get','list')},@{name='virtualmachines/status';kind='VirtualMachine';namespaced=$true;verbs=@('get')})} }
                }
            }
            @(Get-OpenShiftAPIResource).Count | Should -Be 3
            @(Get-OpenShiftAPIResource -Group kubevirt.io -AllVersions).Count | Should -Be 4
            $null = Get-OpenShiftAPIResource
            Should -Invoke Invoke-OSRequest -Times 1 -Exactly -ParameterFilter {$Path -eq '/apis'}
            $null = Get-OpenShiftAPIResource -Refresh
            Should -Invoke Invoke-OSRequest -Times 2 -Exactly -ParameterFilter {$Path -eq '/apis'}
        }
        It 'follows continuation tokens and URL-encodes selectors' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            Mock Get-OpenShiftAPIResource { [pscustomobject]@{Name='pods';Namespaced=$true;BasePath='/api/v1';Verbs=@('get','list')} }
            Mock Invoke-OSRequest {
                if ($Path -match 'continue=') { [pscustomobject]@{items=@(@{metadata=@{name='web-2'}});metadata=@{}} }
                else { [pscustomobject]@{items=@(@{metadata=@{name='web-1'}});metadata=@{continue='a+b/='}} }
            }
            $items = @(Get-OpenShiftResource pods -Namespace production -Name 'web-*' -LabelSelector 'app=web,role in (a,b)')
            $items.Count | Should -Be 2
            Should -Invoke Invoke-OSRequest -Times 1 -ParameterFilter {$Path -match 'continue=a%2Bb%2F%3D' -and $Path -match 'labelSelector=app%3Dweb'}
        }
        It 'detects repeated pagination tokens' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            Mock Get-OpenShiftAPIResource { [pscustomobject]@{Name='pods';Namespaced=$true;BasePath='/api/v1';Verbs=@('get','list')} }
            Mock Invoke-OSRequest { [pscustomobject]@{items=@();metadata=@{continue='repeat'}} }
            { Get-OpenShiftResource pods } | Should -Throw '*repeated*'
        }
        It 'refuses ambiguous resources' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            Mock Get-OpenShiftAPIResource { @([pscustomobject]@{Name='events'},[pscustomobject]@{Name='events'}) }
            { Get-OpenShiftResource events } | Should -Throw '*ambiguous*'
        }
        It 'redacts secret data and nested inline initialization' {
            $obj = '{"kind":"Secret","data":{"password":"sensitive"},"metadata":{"name":"example"},"spec":{"userData":"private","env":[{"name":"KEY","value":"private"}]}}' | ConvertFrom-Json
            $safe = Protect-OSResource $obj
            ($safe | ConvertTo-Json -Depth 20) | Should -Not -Match 'sensitive|private'
            $safe.metadata.name | Should -Be example
        }
        It 'captures sanitized audit events only' {
            $audit = Join-Path $TestDrive audit.jsonl
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken -AuditPath $audit
            $text = Get-Content $audit -Raw
            $text | Should -Match 'GET'; $text | Should -Not -Match 'test-only|Authorization|one.example'
        }
        It 'redacts OAuth token names and route TLS keys' {
            $oauth = '{"kind":"OAuthAccessToken","metadata":{"name":"secret-identifier"},"userName":"admin"}' | ConvertFrom-Json
            (Protect-OSResource $oauth | ConvertTo-Json -Depth 10) | Should -Not -Match 'secret-identifier|admin'
            $route = '{"kind":"Route","spec":{"tls":{"key":"private-pem"}}}' | ConvertFrom-Json
            (Protect-OSResource $route | ConvertTo-Json -Depth 10) | Should -Not -Match private-pem
        }
        It 'suppresses malformed response contents' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            Mock Send-OSHttp { [pscustomobject]@{StatusCode=200;Content='{PRIVATE_INVALID_DATA';RetryAfter=0} }
            { Get-OpenShiftClusterInfo } | Should -Throw '*malformed*'
        }
        It 'reads kubeconfig contexts and tokens through a safe JSON boundary' {
            $file = Join-Path $TestDrive contexts; Set-Content $file 'fixture'
            Mock Invoke-OpenShiftCLI { [pscustomobject]@{StdOut='{"current-context":"lab","contexts":[{"name":"lab","context":{"cluster":"c","user":"u","namespace":"work"}}],"clusters":[{"name":"c","cluster":{"server":"https://one.example"}}],"users":[{"name":"u","user":{"token":"fixture"}}]}'} }
            (Read-OSKubeConfig $file '').Context | Should -Be lab
            (Get-OpenShiftContext -KubeConfig $file).Namespace | Should -Be work
            Should -Invoke Invoke-OpenShiftCLI -Times 1 -ParameterFilter { '--raw' -in $Arguments }
            Mock Invoke-OpenShiftCLI { [pscustomobject]@{StdOut='{PRIVATE_INVALID_CONFIG'} }
            { Read-OSKubeConfig $file lab } | Should -Throw '*invalid kubeconfig JSON*'
        }
        It 'can disconnect all sessions through a pipeline without invalidating enumeration' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken -Name one
            $null = Connect-OpenShift -Server https://two.example -Token $script:TestToken -Name two
            Get-OpenShiftConnection | ForEach-Object { Disconnect-OpenShift -Connection $_.Name }
            @(Get-OpenShiftConnection).Count | Should -Be 0
        }
        It 'honors WhatIf on encrypted session persistence' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            if ($IsWindows) { Save-OpenShiftSession -Path (Join-Path $TestDrive session.json) -WhatIf; Test-Path (Join-Path $TestDrive session.json) | Should -BeFalse }
            else { { Save-OpenShiftSession -Path (Join-Path $TestDrive session.json) } | Should -Throw '*Windows*' }
        }
        It 'round-trips DPAPI sessions without plaintext and refuses overwrite' -Skip:(-not $IsWindows) {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            $path = Join-Path $TestDrive saved.json
            Save-OpenShiftSession -Path $path
            (Get-Content $path -Raw) | Should -Not -Match 'test-only'
            { Save-OpenShiftSession -Path $path } | Should -Throw '*overwrite*'
            Disconnect-OpenShift
            (Import-OpenShiftSession -Path $path).Mode | Should -Be ReadOnly
        }
        It 'imports explicit token kubeconfig without changing current context' {
            $file = Join-Path $TestDrive config; Set-Content $file 'mock'
            Mock Read-OSKubeConfig { [pscustomobject]@{Context='lab';ContextData=[pscustomobject]@{namespace='work'};Cluster=[pscustomobject]@{server='https://one.example'};User=[pscustomobject]@{token='fixture'}} }
            $c = Connect-OpenShift -KubeConfig $file -Context lab
            $c.Namespace | Should -Be work; $c.Context | Should -Be lab
        }
        It 'refuses kubeconfig executable credential plugins' {
            $file = Join-Path $TestDrive config; Set-Content $file 'mock'
            Mock Read-OSKubeConfig { [pscustomobject]@{Context='lab';ContextData=@{};Cluster=@{};User=[pscustomobject]@{exec=@{command='danger'}}} }
            { Connect-OpenShift -KubeConfig $file } | Should -Throw '*Exec*'
        }
        It 'returns CLI version as an object' {
            Mock Invoke-OpenShiftCLI { [pscustomobject]@{StdOut='{"clientVersion":{"gitVersion":"v4.20.0"}}'} }
            (Get-OpenShiftCLIVersion).clientVersion.gitVersion | Should -Be v4.20.0
        }
        It 'blocks arbitrary CLI use from read-only sessions' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken
            { Invoke-OpenShiftCommand -Arguments @('delete','pod','test') -Confirm:$false } | Should -Throw '*Administrative*'
        }
        It 'honors WhatIf and blocks CLI endpoint override' {
            $null = Connect-OpenShift -Server https://one.example -Token $script:TestToken -Mode Administrative
            $s = Resolve-OSConnection; $s.KubeConfig='fixture'; $s.Context='lab'
            Mock Read-OSKubeConfig { [pscustomobject]@{Cluster=[pscustomobject]@{server='https://one.example'};User=[pscustomobject]@{token='fixture'}} }
            Mock Invoke-OpenShiftCLI {}
            Invoke-OpenShiftCommand -Arguments @('get','pods') -WhatIf
            Should -Invoke Invoke-OpenShiftCLI -Times 0
            foreach ($args in @(@('get','pods','--server=https://other.example'),@('get','pods','-shttps://other.example'),@('login'))) {
                { Invoke-OpenShiftCommand -Arguments $args -Confirm:$false } | Should -Throw
            }
        }
    }
}
