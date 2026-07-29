Set-StrictMode -Version Latest

Describe 'New-FileDetectionRule' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'creates exists rule' {
            $rule = New-FileDetectionRule -Path 'C:\Program Files\Notepad++' -FileOrFolderName 'notepad++.exe' -Exists

            $rule.'@odata.type' | Should -Be '#microsoft.graph.win32LobAppFileSystemDetection'
            $rule.detectionType | Should -Be 'exists'
            $rule.path | Should -Be 'C:\Program Files\Notepad++'
            $rule.fileOrFolderName | Should -Be 'notepad++.exe'
            $rule.ContainsKey('operator') | Should -BeFalse
            $rule.ContainsKey('detectionValue') | Should -BeFalse
        }

        It 'creates doesNotExist rule' {
            $rule = New-FileDetectionRule -Path 'C:\Program Files\Notepad++' -FileOrFolderName 'notepad++.exe' -DoesNotExist

            $rule.detectionType | Should -Be 'doesNotExist'
        }

        It 'creates version rule' {
            $rule = New-FileDetectionRule -Path 'C:\Program Files\Notepad++' -FileOrFolderName 'notepad++.exe' -Version -Operator greaterThanOrEqual -VersionValue '8.9.7.0'

            $rule.detectionType | Should -Be 'version'
            $rule.operator | Should -Be 'greaterThanOrEqual'
            $rule.detectionValue | Should -Be '8.9.7.0'
        }

        It 'creates sizeInMB rule' {
            $rule = New-FileDetectionRule -Path 'C:\Program Files\Contoso' -FileOrFolderName 'agent.dll' -SizeInMB -Operator greaterThan -SizeValueInMB 10

            $rule.detectionType | Should -Be 'sizeInMB'
            $rule.operator | Should -Be 'greaterThan'
            $rule.detectionValue | Should -Be '10'
        }

        It 'creates modifiedDate rule with UTC ISO8601 detection value' {
            $date = [datetime]'2025-01-01T10:00:00+02:00'
            $rule = New-FileDetectionRule -Path 'C:\Program Files\Contoso' -FileOrFolderName 'agent.dll' -ModifiedDate -Operator greaterThan -DateTimeValue $date

            $rule.detectionType | Should -Be 'modifiedDate'
            $rule.operator | Should -Be 'greaterThan'
            ([datetime]::Parse($rule.detectionValue)).ToUniversalTime() | Should -Be $date.ToUniversalTime()
        }

        It 'creates createdDate rule' {
            $rule = New-FileDetectionRule -Path 'C:\Program Files\Contoso' -FileOrFolderName 'agent.dll' -CreatedDate -Operator lessThan -DateTimeValue ([datetime]'2024-12-31T00:00:00Z')

            $rule.detectionType | Should -Be 'createdDate'
            $rule.operator | Should -Be 'lessThan'
        }

        It 'throws when version mode has invalid operator' {
            { New-FileDetectionRule -Path 'C:\Program Files\Notepad++' -FileOrFolderName 'notepad++.exe' -Version -Operator badOperator -VersionValue '1.0.0.0' } | Should -Throw
        }

        It 'throws when operator is empty for version mode' {
            { New-FileDetectionRule -Path 'C:\Program Files\Notepad++' -FileOrFolderName 'notepad++.exe' -Version -Operator '' -VersionValue '1.0.0.0' } | Should -Throw
        }

        It 'throws when path is empty' {
            { New-FileDetectionRule -Path '' -FileOrFolderName 'notepad++.exe' -Exists } | Should -Throw
        }
    }
}
