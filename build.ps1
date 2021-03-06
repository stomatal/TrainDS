$build = 'build'
$sources = 'src', 'src\terrain', 'src\menu', 'src\engine'
$includes = 'src', ($env:CWFolder_NITRO + '\ARM_EABI_Support\msl\MSL_C\MSL_Common\Include')
$arch = '-proc arm946e -little -interworking'
$cflags = '-d SDK_ARM9 -g -fp soft -O2 -r -enum int -inline smart, bottomup ' + $arch;
$cxxflags = $cflags + ' -Cpp_exceptions off'
$ldflags = '-m _start -g -map closure, unused ' + $arch
$libdirs = $env:NITROSDK_ROOT, $env:NITROSYSTEM_ROOT, ($env:CWFolder_NITRO + '\ARM_EABI_Support\msl\MSL_C\MSL_ARM'), ($env:CWFolder_NITRO + '\ARM_EABI_Support\msl\MSL_Extras\MSL_ARM'), ($env:CWFolder_NITRO + '\ARM_EABI_Support\Mathlib'), ($env:CWFolder_NITRO + '\ARM_EABI_Support\Runtime\Runtime_ARM\Runtime_NITRO'), ($env:CWFolder_NITRO + '\ARM_EABI_Support\msl\MSL_C++\MSL_ARM\')
#'isdmainparm'
$libs = 'rtc', 'spi', 'stubscw', 'stubsisd', 'card', 'cp', 'ext', 'fs', 'fx', 'gx', 'mi', 'os', 'prc', 'pxi', 'snd', 'MSL_C_NITRO_Ai_LE.a', 'MSL_Extras_NITRO_Ai_LE.a', 'NITRO_Runtime_Ai_LE.a', 'MSL_CPP_NITRO_Ai_LE.a', 'wm', 'wbt', 'mb', 'syscall', 'dgt', 'ctrdg', 'math', 'cht', 'FP_fastI_v5t_LE.a', 'std', 'env', 'nnsfnd', 'nnsg3d', 'nnsgfd', 'nnsg2d', 'nnssnd'
if($Args.length -eq 0 -or $Args[0] -eq 'build')
{
    if(!(test-path $build))
    {
        new-item -name $build -type directory
    }
    $cfiles = ''
    $cppfiles = ''
    $sfiles = ''
    foreach($path in $sources)
    {
        $indir = get-item -path ($path + '\\*.c')
        if($indir.length -gt 0)
        {
            foreach($path2 in $indir)
            {
                $cfiles += '"' + $path2 + '" '
            }
        }
        $indir = get-item -path ($path + '\\*.cpp')
        if($indir.length -gt 0)
        {
            foreach($path2 in $indir)
            {
                $cppfiles += '"' + $path2 + '" '
            }
        }
        $indir = get-item -path ($path + '\\*.s')
        if($indir.length -gt 0)
        {
            foreach($path2 in $indir)
            {
                $sfiles += '"' + $path2 + '" '
            }
        }
    }
    $include_string = ''
    foreach($path in $includes)
    {
        $include_string += '"-I' + $path + '" ';
    }
    foreach($path in $libdirs)
    {
        if(test-path ($path + '\include'))
        {
            $include_string += '"-I' + $path + '\include" ';
        }
    }
    if($cfiles)
    {
        Start-Process 'mwccarm' ('-nowraplines -nostdinc -msgstyle parseable -gccinc -c ' + $cflags + ' ' + $include_string + ' -o ' + $build + ' ' + $cfiles) -NoNewWindow -Wait
    }
    if($cppfiles)
    {
        Start-Process 'mwccarm' ('-nowraplines -nostdinc -msgstyle parseable -gccinc -c ' + $cxxflags + ' ' + $include_string + ' -o ' + $build + ' ' + $cppfiles) -NoNewWindow -Wait
    }
    Start-Process ($env:NITROSDK_ROOT + '\tools\bin\makelcf.exe') ('Nitro.lcf.lsf "' + $env:NITROSDK_ROOT + '\include\nitro\specfiles\ARM9-TS.lcf.template" ' + $build + '\Nitro.lcf') -NoNewWindow -Wait
    $libdirs_string = ''
    foreach($path in $libdirs)
    {
        if(test-path ($path + '\lib\ARM9-TS\Release'))
        {
            $libdirs_string += '-l "' + $path + '\lib\ARM9-TS\Release" ';
            if(test-path ($path + '\lib\ARM9-TS\etc'))
            {
                $libdirs_string += '-l "' + $path + '\lib\ARM9-TS\etc" ';
            }
        }
        else
        {
            $libdirs_string += '-l "' + $path + '\lib" ';
        }
    }
    $lib_string = ''
    foreach($lib in $libs)
    {
        $lib_string += '"-l' + $lib + '" ';
    }
    $ofiles = ''
    $ofiles += '"' + $env:NITROSDK_ROOT + '\lib\ARM9-TS\Release\crt0.o" '
    $indir = get-item -path ($build + '\\*.o')
    foreach($path2 in $indir)
    {
        $ofiles += '"' + $path2 + '" '
    }
    $name = [System.IO.Path]::GetFileName((get-location))
    Start-Process 'mwldarm' ($ldflags + ' -nowraplines -nostdlib -o ' + $build + '\main.elf ' + $libdirs_string + ' ' + $lib_string + ' ' + $ofiles + ' ' + $build + '\Nitro.lcf') -NoNewWindow -Wait
    start-process ($env:NITROSDK_ROOT + '\tools\bin\makerom.exe') ('-DMAKEROM_ROMROOT=./files -DMAKEROM_ROMFILES=./data -DMAKEROM_ROMSPEED=UNDEFINED -DPROC=ARM9 -DPLATFORM=TS -DCODEGEN= -DBUILD=Rom -DMAKEROM_ARM9=./' + $build + '/main.elf -DMAKEROM_ARM7="' + $env:NITROSDK_ROOT + '/components/mongoose/ARM7-TS/Rom/mongoose_sub.nef" "' + $env:NITROSDK_ROOT + '/include/nitro/specfiles/ROM-TS.rsf" ' + $name + '.nds') -NoNewWindow -Wait 
}
elseif($Args[0] -eq 'clean')
{
    if(test-path $build)
    {
        remove-item -path $build -force -recurse
    }
    $name = [System.IO.Path]::GetFileName((get-location))
    if(test-path ($name + '.nds'))
    {
        remove-item -path ($name + '.nds') -force -recurse
    }
    if(test-path ($name + '.nlf'))
    {
        remove-item -path ($name + '.nlf') -force -recurse
    }
}
else
{
    write-host 'unknown command'
}