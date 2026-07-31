Set-StrictMode -Version Latest

Describe 'Invoke-IntuneGraphRequest' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'calls Invoke-MgGraphRequest without body for GET' {
            Mock -CommandName Invoke-MgGraphRequest -MockWith { @{ ok = $true } }

            $result = Invoke-IntuneGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/test'
            $result.ok | Should -BeTrue
            Assert-MockCalled -CommandName Invoke-MgGraphRequest -Times 1 -Exactly
        }

        It 'serializes body for POST requests' {
            $script:capturedBody = $null
            Mock -CommandName Invoke-MgGraphRequest -MockWith {
                param($Method, $Uri, $Body, $ContentType)
                $script:capturedBody = $Body
                @{ ok = $true }
            }

            $result = Invoke-IntuneGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/test' -Body @{ a = 1; b = 'x' }
            $result.ok | Should -BeTrue
            $script:capturedBody | Should -Match '"a"\s*:\s*1'
            $script:capturedBody | Should -Match '"b"\s*:\s*"x"'
        }

        It 'throws wrapped message when Graph call fails' {
            Mock -CommandName Invoke-MgGraphRequest -MockWith { throw 'boom' }

            { Invoke-IntuneGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/test' -Body @{ a = 1 } } | Should -Throw 'Graph request failed*'
        }
    }
}
