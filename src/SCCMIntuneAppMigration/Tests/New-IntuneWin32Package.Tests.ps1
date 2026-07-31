Set-StrictMode -Version Latest

Describe 'New-IntuneWin32Package' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'creates package when tool returns success and output file exists' {
            $src = Join-Path $env:TEMP ("src_" + [guid]::NewGuid().ToString())
            $out = Join-Path $env:TEMP ("out_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $src | Out-Null
            New-Item -ItemType Directory -Path $out | Out-Null
            $setupName = 'setup.exe'
            Set-Content -LiteralPath (Join-Path $src $setupName) -Value 'x'

            try {
                $pkgPath = Join-Path $out 'setup.intunewin'
                Set-Content -LiteralPath $pkgPath -Value 'pkg'

                Mock -CommandName Start-Process -MockWith { [pscustomobject]@{ ExitCode = 0 } }
                Mock -CommandName Get-Date -MockWith { [datetime]'2026-01-01T00:00:00Z' }
                Mock -CommandName Get-ChildItem -MockWith {
                    Get-Item -LiteralPath $pkgPath
                } -ParameterFilter { $LiteralPath -eq $out -and $Filter -eq '*.intunewin' }

                $pkg = New-IntuneWin32Package -SourceFolder $src -SetupFileName $setupName -OutputLocation $out
                $pkg.FullName | Should -Be $pkgPath
            }
            finally {
                Remove-Item -LiteralPath $src -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'throws when setup file is missing' {
            $src = Join-Path $env:TEMP ("src_" + [guid]::NewGuid().ToString())
            $out = Join-Path $env:TEMP ("out_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $src | Out-Null
            New-Item -ItemType Directory -Path $out | Out-Null

            try {
                { New-IntuneWin32Package -SourceFolder $src -SetupFileName 'missing.exe' -OutputLocation $out } | Should -Throw '*was not found*'
            }
            finally {
                Remove-Item -LiteralPath $src -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'throws when packaging tool exits with non-zero code' {
            $src = Join-Path $env:TEMP ("src_" + [guid]::NewGuid().ToString())
            $out = Join-Path $env:TEMP ("out_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $src | Out-Null
            New-Item -ItemType Directory -Path $out | Out-Null
            $setupName = 'setup.exe'
            Set-Content -LiteralPath (Join-Path $src $setupName) -Value 'x'

            try {
                Mock -CommandName Start-Process -MockWith { [pscustomobject]@{ ExitCode = 99 } }

                { New-IntuneWin32Package -SourceFolder $src -SetupFileName $setupName -OutputLocation $out } | Should -Throw '*exited with code 99*'
            }
            finally {
                Remove-Item -LiteralPath $src -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
