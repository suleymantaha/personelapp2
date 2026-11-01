$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$cache = Join-Path $env:USERPROFILE '.gradle/caches/modules-2/files-2.1'
function Cached-Jar($module, $version) {
    $jar = Get-ChildItem (Join-Path $cache "$module/$version") -Recurse -Filter '*.jar' |
        Select-Object -First 1 -ExpandProperty FullName
    if (!$jar) { throw "Required cached dependency missing: $module/$version" }
    return $jar
}
$compiler = Cached-Jar 'org.jetbrains.kotlin/kotlin-compiler-embeddable' '1.9.10'
$stdlib = Cached-Jar 'org.jetbrains.kotlin/kotlin-stdlib' '1.9.10'
$reflect = Cached-Jar 'org.jetbrains.kotlin/kotlin-reflect' '1.9.20'
$trove = Cached-Jar 'org.jetbrains.intellij.deps/trove4j' '1.0.20200330'
$annotations = Cached-Jar 'org.jetbrains/annotations' '13.0'
$compilerCp = @($compiler, $stdlib, $reflect, $trove, $annotations) -join ';'
$testOut = Join-Path ([System.IO.Path]::GetTempPath()) ('nizam-f05-tests-' + [guid]::NewGuid())
New-Item -ItemType Directory $testOut | Out-Null
$package = 'kotlin/com/example/personelapp2'
$source = Join-Path $repoRoot "android/app/src/main/$package/BoundedBackupReader.kt"
$test = Join-Path $PSScriptRoot "$package/BoundedBackupReaderTest.kt"
Write-Output "UTC: $([DateTime]::UtcNow.ToString('o'))"
Get-FileHash -Algorithm SHA256 $source, $test | Format-Table -AutoSize
& java -cp $compilerCp org.jetbrains.kotlin.cli.jvm.K2JVMCompiler -no-stdlib -no-reflect `
    -classpath "$stdlib;$annotations" -jvm-target 17 -d "$testOut/tests.jar" $source $test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& java -Xmx512m -cp "$testOut/tests.jar;$stdlib" com.example.personelapp2.BoundedBackupReaderTest
exit $LASTEXITCODE
