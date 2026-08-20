# ===================================================================================
#  +-----------------------------------------------------------------------------+
#  |  __      __ ____   _____   _______  ______  __   __                         |
#  |  \ \    / // __ \ |  __ \ |__   __||  ____| \ \ / /                         |
#  |   \ \  / /| |  | || |__) |   | |   | |__     \ V /   APEX ANTI-CHEAT        |
#  |    \ \/ / | |  | ||  _  /    | |   |  __|     > <    FORENSIC SUITE         |
#  |     \  /  | |__| || | \ \    | |   | |____   / . \   (VORTEX-AC)            |
#  |      \/    \____/ |_|  \_\   |_|   |______| /_/ \_\  Coded By BayrdY        |
#  +-----------------------------------------------------------------------------+
#                ADVANCED ANTI-CHEAT & FORENSIC SUITE (VORTEX-AC)
#            [ SYSTEM ARCHITECTURE & CORE ENGINE : CODED BY BAYRDY ]
#             [ SECURITY RESEARCH & SIGNATURES : BAYRDY LABS 2026 ]
# ===================================================================================


[CmdletBinding()]
param(
    [string]$TargetFolder = "",
    [switch]$FullScan,
    [switch]$NoHtmlReport,
    [string]$DiscordWebhook = ""
)

# ----------------- Enforce Administrator Mode -----------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    if ($MyInvocation.MyCommand.Path) {
        try {
            $argList = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
            if ($TargetFolder) { $argList += " -TargetFolder `"$TargetFolder`"" }
            if ($FullScan) { $argList += " -FullScan" }
            if ($NoHtmlReport) { $argList += " -NoHtmlReport" }
            if ($DiscordWebhook) { $argList += " -DiscordWebhook `"$DiscordWebhook`"" }
            
            $p = Start-Process powershell.exe -ArgumentList $argList -Verb RunAs -PassThru -ErrorAction Stop
            exit
        } catch {
            Write-Host "`n [!] CRITICAL ERROR: Administrator privileges are strictly required." -ForegroundColor Red
            Write-Host " [!] Please right click and select 'Run as Administrator'." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            exit 1
        }
    } else {
        Write-Host "`n [!] CRITICAL ERROR: Administrator privileges are strictly required." -ForegroundColor Red
        Write-Host " [!] Lutfen PowerShell veya CMD'yi 'Yonetici Olarak Calistir' (Run as Administrator) ile acip tekrar yapistirin." -ForegroundColor Yellow
        Write-Host " [!] Coded By BayrdY" -ForegroundColor Cyan
        exit 1
    }
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue

# ----------------- UTF-8 & Console Initialization -----------------
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
try { chcp 65001 | Out-Null } catch { }

# ----------------- Load System.IO.Compression Assemblies -----------------
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

# ----------------- High-Performance C# Core Engine -----------------
$cSharpCode = @"
// ==============================================================================
// VORTEX CORE ENGINE :: HIGH PERFORMANCE NATIVE FORENSICS
// [ AUTHORED & ARCHITECTED BY BAYRDY // SEC-DEV: BAYRDY-VORTEX-PRO ]
// ==============================================================================
using System;
using System.IO;
using System.IO.Compression;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Security.Cryptography;

namespace VortexCoreEngine {
    // [Win32-Native-Memory-Interface :: Implemented by BayrdY]
    public static class Win32 {
        public const uint PROCESS_QUERY_INFORMATION = 0x0400;
        public const uint PROCESS_VM_READ = 0x0010;
        public const uint MEM_COMMIT = 0x1000;
        public const uint PAGE_READONLY = 0x02;
        public const uint PAGE_READWRITE = 0x04;
        public const uint PAGE_EXECUTE_READ = 0x20;
        public const uint PAGE_EXECUTE_READWRITE = 0x40;
        public const uint PAGE_GUARD = 0x100;
        public const uint PAGE_NOACCESS = 0x01;
        public const uint TH32CS_SNAPMODULE = 0x00000008;
        public const uint TH32CS_SNAPMODULE32 = 0x00000010;

        [StructLayout(LayoutKind.Sequential)]
        public struct MEMORY_BASIC_INFORMATION {
            public IntPtr BaseAddress;
            public IntPtr AllocationBase;
            public uint AllocationProtect;
            public IntPtr RegionSize;
            public uint State;
            public uint Protect;
            public uint Type;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        public struct MODULEENTRY32 {
            public uint dwSize;
            public uint th32ModuleID;
            public uint th32ProcessID;
            public uint GlblcntUsage;
            public uint ProccntUsage;
            public IntPtr modBaseAddr;
            public uint modBaseSize;
            public IntPtr hModule;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public string szModule;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string szExePath;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int VirtualQueryEx(IntPtr hProcess, IntPtr lpAddress, out MEMORY_BASIC_INFORMATION lpBuffer, uint dwLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, [Out] byte[] lpBuffer, int dwSize, out IntPtr lpNumberOfBytesRead);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr CreateToolhelp32Snapshot(uint dwFlags, uint th32ProcessID);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool Module32First(IntPtr hSnapshot, ref MODULEENTRY32 lpme);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool Module32Next(IntPtr hSnapshot, ref MODULEENTRY32 lpme);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr GetStdHandle(int nStdHandle);

        [DllImport("kernel32.dll")]
        public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

        [DllImport("kernel32.dll")]
        public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

        public static void DisableQuickEdit() {
            try {
                IntPtr handle = GetStdHandle(-10);
                uint mode;
                if (GetConsoleMode(handle, out mode)) {
                    mode &= ~0x0040u;
                    mode |= 0x0080u;
                    SetConsoleMode(handle, mode);
                }
            } catch { }
        }
    }

    public class MemoryFinding {
        public string Pattern;
        public string Address;
        public string Evidence;
    }

    public class JarScanSummary {
        public string JarPath;
        public string JarName;
        public string Sha1;
        public long FileSize;
        public string ClaimedModId;
        public List<string> MatchedMacros = new List<string>();
        public List<string> MatchedObfuscators = new List<string>();
        public bool HasTokenStealer = false;
        public bool HasDiscordWebhook = false;
        public bool HasRuntimeExec = false;
        public int SingleLetterCount = 0;
        public int JapaneseCount = 0;
        public int NumericCount = 0;
        public int TotalClasses = 0;
        public bool IsSpoofed = false;
    }

    // [FastScanner-Bytecode-And-RAM-Engine :: Engineered by BayrdY]
    public static class FastScanner {
        public static string ComputeSHA1(string filePath) {
            try {
                using (var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite, 65536))
                using (var sha1 = SHA1.Create()) {
                    byte[] hash = sha1.ComputeHash(stream);
                    var sb = new StringBuilder(hash.Length * 2);
                    foreach (byte b in hash) sb.Append(b.ToString("x2"));
                    return sb.ToString();
                }
            } catch { return string.Empty; }
        }

        public static string ComputeSHA256(string filePath) {
            try {
                using (var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite, 65536))
                using (var sha256 = SHA256.Create()) {
                    byte[] hash = sha256.ComputeHash(stream);
                    var sb = new StringBuilder(hash.Length * 2);
                    foreach (byte b in hash) sb.Append(b.ToString("x2"));
                    return sb.ToString();
                }
            } catch { return string.Empty; }
        }

        public static string Rot13(string input) {
            if (string.IsNullOrEmpty(input)) return string.Empty;
            char[] arr = input.ToCharArray();
            for (int i = 0; i < arr.Length; i++) {
                char c = arr[i];
                if (c >= 'a' && c <= 'z') arr[i] = (char)('a' + (c - 'a' + 13) % 26);
                else if (c >= 'A' && c <= 'Z') arr[i] = (char)('A' + (c - 'A' + 13) % 26);
            }
            return new string(arr);
        }

        public static string NormalizeFullwidth(string input) {
            if (string.IsNullOrEmpty(input)) return string.Empty;
            var sb = new StringBuilder(input.Length);
            foreach (char c in input) {
                if (c >= 0xFF01 && c <= 0xFF5E) sb.Append((char)(c - 0xFEE0));
                else if (c == 0x3000) sb.Append(' ');
                else sb.Append(c);
            }
            return sb.ToString();
        }

        // [MemoryInspectionRoutine :: Authored by BayrdY]
        public static List<MemoryFinding> ScanProcessRam(int pid, string[] signatures) {
            var results = new List<MemoryFinding>();
            var matched = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            IntPtr hProcess = Win32.OpenProcess(Win32.PROCESS_QUERY_INFORMATION | Win32.PROCESS_VM_READ, false, pid);
            if (hProcess == IntPtr.Zero) return results;

            try {
                long currentAddress = 0x10000;
                long maxAddress = 0x7FFFFFFEFFFF;
                byte[] buffer = new byte[65536];
                long totalScanned = 0;
                long maxScanLimit = 80 * 1024 * 1024;

                while (currentAddress < maxAddress && totalScanned < maxScanLimit) {
                    Win32.MEMORY_BASIC_INFORMATION memInfo = new Win32.MEMORY_BASIC_INFORMATION();
                    int query = Win32.VirtualQueryEx(hProcess, new IntPtr(currentAddress), out memInfo, (uint)Marshal.SizeOf(typeof(Win32.MEMORY_BASIC_INFORMATION)));
                    if (query == 0) break;

                    long baseAddr = memInfo.BaseAddress.ToInt64();
                    long rSize = memInfo.RegionSize.ToInt64();

                    if (rSize <= 0 || baseAddr < 0) break;

                    bool isCommitted = (memInfo.State == Win32.MEM_COMMIT);
                    bool isWritable = (memInfo.Protect & (Win32.PAGE_READWRITE | Win32.PAGE_EXECUTE_READWRITE)) != 0;
                    bool isGuarded = (memInfo.Protect & (Win32.PAGE_GUARD | Win32.PAGE_NOACCESS)) != 0;

                    if (isCommitted && isWritable && !isGuarded && rSize < 10 * 1024 * 1024) {
                        long offset = 0;
                        while (offset < rSize && totalScanned < maxScanLimit) {
                            int toRead = (int)Math.Min((long)buffer.Length, rSize - offset);
                            if (toRead <= 0) break;

                            IntPtr bytesRead;
                            if (Win32.ReadProcessMemory(hProcess, new IntPtr(baseAddr + offset), buffer, toRead, out bytesRead)) {
                                int read = (int)bytesRead.ToInt64();
                                if (read > 0) {
                                    totalScanned += read;
                                    string text = Encoding.ASCII.GetString(buffer, 0, read);
                                    foreach (var sig in signatures) {
                                        if (!matched.Contains(sig) && text.IndexOf(sig, StringComparison.OrdinalIgnoreCase) >= 0) {
                                            matched.Add(sig);
                                            results.Add(new MemoryFinding {
                                                Pattern = sig,
                                                Address = string.Format("0x{0:X8}", baseAddr + offset),
                                                Evidence = string.Format("Resident RAM Signature at 0x{0:X8} matching '{1}'", baseAddr + offset, sig)
                                            });
                                        }
                                    }
                                }
                            }
                            offset += toRead;
                        }
                    }

                    long nextAddr = memInfo.BaseAddress.ToInt64() + rSize;
                    if (nextAddr > 0x0000002000000000 && nextAddr < 0x00007FF000000000) {
                        currentAddress = 0x00007FF000000000;
                    } else if (nextAddr <= currentAddress) {
                        currentAddress += 0x10000;
                    } else {
                        currentAddress = nextAddr;
                    }
                }
            } catch { }
            finally {
                Win32.CloseHandle(hProcess);
            }
            return results;
        }

        public static List<string> GetLoadedModules(int pid) {
            var modules = new List<string>();
            IntPtr snap = Win32.CreateToolhelp32Snapshot(Win32.TH32CS_SNAPMODULE | Win32.TH32CS_SNAPMODULE32, (uint)pid);
            if (snap == IntPtr.Zero || snap.ToInt64() == -1) return modules;

            try {
                var entry = new Win32.MODULEENTRY32();
                entry.dwSize = (uint)Marshal.SizeOf(typeof(Win32.MODULEENTRY32));
                if (Win32.Module32First(snap, ref entry)) {
                    do {
                        if (!string.IsNullOrEmpty(entry.szExePath)) modules.Add(entry.szExePath);
                    } while (Win32.Module32Next(snap, ref entry));
                }
            } catch { }
            finally {
                Win32.CloseHandle(snap);
            }
            return modules;
        }

        public static List<JarScanSummary> ScanAllJarsParallel(
            string[] jarPaths,
            string[] macroPatterns,
            string[] tokenPatterns,
            string[] obfSigs,
            string[] legitIds)
        {
            var results = new ConcurrentBag<JarScanSummary>();
            var legitSet = new HashSet<string>(legitIds, StringComparer.OrdinalIgnoreCase);

            var options = new ParallelOptions {
                MaxDegreeOfParallelism = Environment.ProcessorCount
            };

            Parallel.ForEach(jarPaths, options, jarPath => {
                if (string.IsNullOrEmpty(jarPath) || !File.Exists(jarPath)) return;

                var fi = new FileInfo(jarPath);
                var summary = new JarScanSummary {
                    JarPath = jarPath,
                    JarName = fi.Name,
                    FileSize = fi.Length,
                    Sha1 = ComputeSHA1(jarPath)
                };

                string pathLower = jarPath.ToLowerInvariant();
                bool isDevToolOrWrapper = pathLower.Contains("gradle-wrapper.jar") || 
                                          pathLower.Contains(".gradle") || 
                                          pathLower.Contains("fabric-loader") ||
                                          pathLower.Contains("spark-paper") ||
                                          pathLower.Contains("loom-cache");

                try {
                    using (var fs = new FileStream(jarPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite, 65536))
                    using (var archive = new ZipArchive(fs, ZipArchiveMode.Read, false)) {
                        
                        // 1. Read fabric.mod.json / mcmod.info in memory
                        foreach (var entry in archive.Entries) {
                            if (entry.FullName.Equals("fabric.mod.json", StringComparison.OrdinalIgnoreCase) ||
                                entry.FullName.Equals("mcmod.info", StringComparison.OrdinalIgnoreCase)) {
                                try {
                                    using (var reader = new StreamReader(entry.Open(), Encoding.UTF8)) {
                                        string jsonText = reader.ReadToEnd();
                                        var m = Regex.Match(jsonText, @"""id""\s*:\s*""([^""]+)""", RegexOptions.IgnoreCase);
                                        if (m.Success) {
                                            summary.ClaimedModId = m.Groups[1].Value.ToLowerInvariant();
                                        }
                                    }
                                } catch { }
                                break;
                            }
                        }

                        // 2. Stream .class files constant pools
                        var matchedMacrosLocal = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                        var matchedObfLocal = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

                        foreach (var entry in archive.Entries) {
                            if (!entry.FullName.EndsWith(".class", StringComparison.OrdinalIgnoreCase)) continue;
                            if (entry.Length > 2 * 1024 * 1024) continue;

                            try {
                                using (var cs = entry.Open())
                                using (var ms = new MemoryStream((int)Math.Min(entry.Length, 65536))) {
                                    cs.CopyTo(ms);
                                    byte[] data = ms.ToArray();
                                    if (data.Length < 10 || data[0] != 0xCA || data[1] != 0xFE || data[2] != 0xBA || data[3] != 0xBE) continue;

                                    int pos = 8;
                                    if (pos + 2 > data.Length) continue;
                                    int cpCount = (data[pos] << 8) | data[pos + 1];
                                    pos += 2;
                                    if (cpCount < 1) continue;

                                    string[] cp = new string[cpCount];
                                    ushort[] cpClass = new ushort[cpCount];

                                    for (int i = 1; i < cpCount && pos < data.Length; i++) {
                                        byte tag = data[pos++];
                                        switch (tag) {
                                            case 1: // Utf8
                                                if (pos + 2 > data.Length) break;
                                                int len = (data[pos] << 8) | data[pos + 1];
                                                pos += 2;
                                                if (pos + len > data.Length) break;
                                                string s = Encoding.UTF8.GetString(data, pos, len);
                                                cp[i] = s;
                                                pos += len;
                                                break;
                                            case 3: case 4: case 9: case 10: case 11: case 12: case 17: case 18:
                                                pos += 4;
                                                break;
                                            case 7: case 8: case 16: case 19: case 20:
                                                if (pos + 2 <= data.Length) {
                                                    if (tag == 7) cpClass[i] = (ushort)((data[pos] << 8) | data[pos + 1]);
                                                    pos += 2;
                                                }
                                                break;
                                            case 15:
                                                pos += 3;
                                                break;
                                            case 5: case 6:
                                                pos += 8;
                                                i++;
                                                break;
                                            default:
                                                pos = data.Length;
                                                break;
                                        }
                                    }

                                    for (int i = 1; i < cpCount; i++) {
                                        string val = cp[i];
                                        if (string.IsNullOrEmpty(val)) continue;

                                        // Class names
                                        if (cpClass[i] != 0 && cpClass[i] < cpCount && !string.IsNullOrEmpty(cp[cpClass[i]])) {
                                            string cls = cp[cpClass[i]];
                                            summary.TotalClasses++;
                                            string simpleName = cls.Substring(cls.LastIndexOf('/') + 1);
                                            if (simpleName.Length == 1 && char.IsLetter(simpleName[0])) summary.SingleLetterCount++;
                                            if (Regex.IsMatch(simpleName, @"^\d+$")) summary.NumericCount++;
                                            if (Regex.IsMatch(simpleName, @"[\u3040-\u309F\u30A0-\u30FF]")) summary.JapaneseCount++;
                                        }

                                        // Constant String Checks
                                        if (val.Length > 2) {
                                            string normVal = val;
                                            if (Regex.IsMatch(val, @"[\uFF01-\uFF5E]{2,}")) {
                                                normVal = NormalizeFullwidth(val);
                                            }

                                            // Macro Patterns
                                            foreach (var p in macroPatterns) {
                                                if (!matchedMacrosLocal.Contains(p) && normVal.IndexOf(p, StringComparison.OrdinalIgnoreCase) >= 0) {
                                                    matchedMacrosLocal.Add(p);
                                                }
                                            }

                                            // Token Stealers / Webhooks
                                            if (normVal.IndexOf("discord.com/api/webhooks", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                normVal.IndexOf("discordapp.com/api/webhooks", StringComparison.OrdinalIgnoreCase) >= 0) {
                                                summary.HasTokenStealer = true;
                                                summary.HasDiscordWebhook = true;
                                            }

                                            // Obfuscator Signatures
                                            foreach (var obf in obfSigs) {
                                                if (!matchedObfLocal.Contains(obf) && normVal.IndexOf(obf, StringComparison.OrdinalIgnoreCase) >= 0) {
                                                    matchedObfLocal.Add(obf);
                                                }
                                            }

                                            if (!isDevToolOrWrapper && (
                                                normVal.IndexOf("Runtime.getRuntime().exec", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                normVal.IndexOf("ProcessBuilder", StringComparison.OrdinalIgnoreCase) >= 0)) {
                                                summary.HasRuntimeExec = true;
                                            }
                                        }
                                    }
                                }
                            } catch { }
                        }

                        summary.MatchedMacros.AddRange(matchedMacrosLocal);
                        summary.MatchedObfuscators.AddRange(matchedObfLocal);

                        // Trojan Spoof Check
                        if (!string.IsNullOrEmpty(summary.ClaimedModId) && legitSet.Contains(summary.ClaimedModId)) {
                            if (summary.MatchedMacros.Count > 0 || summary.HasRuntimeExec || summary.HasTokenStealer) {
                                summary.IsSpoofed = true;
                            }
                        }
                    }
                } catch { }

                results.Add(summary);
            });

            return new List<JarScanSummary>(results);
        }
    }
}
"@

Add-Type -TypeDefinition $cSharpCode -ReferencedAssemblies System.IO.Compression, System.IO.Compression.FileSystem

# Disable console quick-edit mode so accidental mouse clicks never freeze/pause the scan
[VortexCoreEngine.Win32]::DisableQuickEdit()

# ----------------- Universal Crisp ASCII Banner -----------------
$Banner = @"
 +-----------------------------------------------------------------------------+
 |  __      __ ____   _____   _______  ______  __   __                         |
 |  \ \    / // __ \ |  __ \ |__   __||  ____| \ \ / /                         |
 |   \ \  / /| |  | || |__) |   | |   | |__     \ V /   APEX ANTI-CHEAT        |
 |    \ \/ / | |  | ||  _  /    | |   |  __|     > <    FORENSIC SUITE         |
 |     \  /  | |__| || | \ \    | |   | |____   / . \   (VORTEX-AC)            |
 |      \/    \____/ |_|  \_\   |_|   |______| /_/ \_\  Coded By BayrdY        |
 +-----------------------------------------------------------------------------+
"@

Write-Host $Banner -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor DarkCyan
Write-Host "  [+] Developer:       Coded By BayrdY" -ForegroundColor Yellow
Write-Host "  [+] Engine:          Multi-Core Parallel Bytecode & Win32 RAM Scanner" -ForegroundColor White
Write-Host "  [+] Privilege Level: ADMINISTRATOR (Full Deep Forensic Access)" -ForegroundColor Green
Write-Host "  [+] System Target:   $([Environment]::UserName) @ $([Environment]::MachineName)" -ForegroundColor DarkGray
Write-Host "================================================================================" -ForegroundColor DarkCyan

# ----------------- Global State & Signatures -----------------
$findings = [System.Collections.Generic.List[PSCustomObject]]::new()
$scannedModsInventory = [System.Collections.Generic.List[PSCustomObject]]::new()
$swTotal = [System.Diagnostics.Stopwatch]::StartNew()

function Add-Finding {
    param(
        [string]$Title,
        [string]$Description,
        [string]$Severity,
        [string]$Category,
        [string]$TargetPath,
        [string]$Evidence
    )
    $findings.Add([PSCustomObject]@{
        Title       = $Title
        Description = $Description
        Severity    = $Severity
        Category    = $Category
        TargetPath  = $TargetPath
        Evidence    = $Evidence
        Timestamp   = ([DateTime]::Now).ToString("yyyy-MM-dd HH:mm:ss")
    })
}

function Show-Progress {
    param([string]$Phase, [string]$Item)
    Write-Host "`r  [>] $Phase : $Item" -NoNewline -ForegroundColor DarkYellow
}

# ----------------- Cheat Signatures Database -----------------
# [VORTEX_KNOWN_THREATS_DB // CURATED_BY_BAYRDY]
$cheatClientsSet = @(
    "Vape", "VapeLite", "VapeV4", "Rise", "Rise6", "Drip", "DripLite", "Novoline", "Astolfo", "LiquidBounce", "Meteor", "Wurst", "BleachHack", "Ares", "Future", "Rusherhack", "Boze", "Prestige", "Catlean", "Asteria", "Onetap", "Neverlose", "GrimDisabler", "PolarDisabler", "MatrixDisabler", "AutoCrystal", "CW_CRYSTAL", "AnchorMacro", "AutoTotem", "SilentAim", "HitboxExpand", "ReachHack", "FastPlace", "AntiKnockback", "VelocityMacro", "SprintReset"
)

# [LIVE_RAM_PATTERNS_DB // RESEARCH_BY_BAYRDY]
$liveRamSignatures = @(
    "AutoCrystal", "CW_CRYSTAL", "cw crystal", "AnchorMacro", "DoubleAnchor", "SafeAnchor",
    "AutoTotem", "HoverTotem", "LegitTotem", "InventoryTotem", "AutoDoubleHand",
    "ShieldDisabler", "ShieldBreaker", "SilentAim", "HitboxExpand", "ReachHack",
    "GrimVelocity", "GrimDisabler", "AntiKnockback", "VapeLite", "vape.gg",
    "meteordevelopment", "dqrkis.xyz", "prestigeclient.vip", "novaclient",
    "WalksyCrystalOptimizer", "AutoMace", "StunSlam", "FastPlace", "ItemExploit",
    "net.ccbluex.liquidbounce", "dev.krypton", "AsteriaClient", "CatleanClient"
)

# [BYTECODE_HEURISTICS_MAP // CONSTRUCTED_BY_BAYRDY]
$macroBytecodePatterns = @(
    "AutoCrystal", "CW_CRYSTAL", "AnchorMacro", "AutoTotem", "AutoMace",
    "FastPlace", "SilentAim", "HitboxExpand", "ReachHack", "GrimVelocity",
    "GrimDisabler", "AntiKnockback", "VapeLite", "dev/krypton", "prestigeclient"
)

$tokenStealerPatterns = @(
    "discord.com/api/webhooks", "discordapp.com/api/webhooks"
)

$obfuscatorSignatures = @(
    "dev/skidfuscator", "radon/runtime", "paramorphism", "bozar", "branchlock", "binscure",
    "com/zelix", "com/stringer", "jnic/JNICLoader", "ScutiObfuscator", "superblaubeere27", "allatori"
)

$legitModIds = @(
    "fabric-api", "fabric", "minecraft", "sodium", "iris", "lithium", "ferritecore",
    "indium", "modmenu", "cloth-config", "optifine", "jei", "rei", "emi", "appleskin",
    "zoomify", "entityculling", "immediatelyfast", "dynamiclights", "litematica", "voicechat"
)

$trustedJvmDllPaths = @(
    "\system32\", "\syswow64\", "\winsxs\", "\windows\",
    "\program files\", "\program files (x86)\",
    "\java\", "\jdk", "\jre", "\adoptium", "\zulu", "\temurin", "\corretto",
    "\oracle\", "\microsoft\", "microsoft.net", "\assembly\",
    "\.minecraft\", "\.lunarclient\", "\.badlion\", "\.tlauncher\",
    "\.feedthebeast\", "\.technic\", "\.curseforge\", "\.gradle\",
    "\modrinthapp\", "\prismlauncher\", "\atlauncher\", "\gdlauncher\", "\feather\",
    "\libopus4j", "\librnnoise4j", "\libspeex4j", "\liblame4j", "\sable_rapier",
    "\drivers\", "\nvcontainer\", "\appdata\local\microsoft\"
)

# ====================================================================
# >>> [PHASE 1 : LIVE RUNTIME & JVM MEMORY FORENSICS // ARCHITECT: BayrdY] <<<
# ====================================================================
Write-Host "`n[PHASE 1/5] Scanning Active Processes & JVM Runtime..." -ForegroundColor Cyan

$javaProcesses = Get-Process -Name "javaw", "java" -ErrorAction SilentlyContinue
if ($javaProcesses) {
    foreach ($proc in $javaProcesses) {
        $pName = $proc.ProcessName
        $procId = $proc.Id
        $uptime = (Get-Date) - $proc.StartTime
        $uptimeStr = "{0}h {1}m {2}s" -f $uptime.Hours, $uptime.Minutes, $uptime.Seconds
        
        Write-Host "  [+] Live JVM Found: $pName (PID $procId)" -ForegroundColor Green
        Write-Host "      Uptime: $uptimeStr | Start: $($proc.StartTime)" -ForegroundColor DarkGray

        # JVM Flags
        try {
            $wmi = Get-CimInstance Win32_Process -Filter "ProcessId = $procId" -ErrorAction SilentlyContinue
            $cmdLine = $wmi.CommandLine
            if ($cmdLine -match "(-javaagent:|-Xbootclasspath:|-agentlib:jdwp)") {
                Add-Finding -Title "Suspicious JVM Launch Arguments Detected" `
                            -Description "JVM was started with suspicious instrumentation or debugging flags." `
                            -Severity "High" -Category "Process" `
                            -TargetPath "$pName (PID $procId)" `
                            -Evidence $cmdLine
            }
        } catch { }
        
        # Native Loaded Modules
        Show-Progress -Phase "Memory" -Item "Scanning loaded native modules in PID $procId"
        $loadedModules = [VortexCoreEngine.FastScanner]::GetLoadedModules($procId)
        foreach ($mod in $loadedModules) {
            $modLower = $mod.ToLowerInvariant()
            $isTrusted = $false
            foreach ($tp in $trustedJvmDllPaths) {
                if ($modLower.Contains($tp)) { $isTrusted = $true; break }
            }
            if (-not $isTrusted) {
                $isSuspicious = $modLower -match "inject|cheat|loader|minhook|kiero|imgui|jna|jinput|vape|rise|doomsday|hook"
                $sev = if ($isSuspicious) { "Critical" } else { "Medium" }
                Add-Finding -Title "Untrusted / Injected DLL Loaded in Java" `
                            -Description "Native module loaded into JVM address space from untrusted directory." `
                            -Severity $sev -Category "Memory" `
                            -TargetPath "$pName (PID $procId)" `
                            -Evidence "Module Path: $mod"
                if ($modLower -match "(?i)(\\temp\\|\\appdata\\|\\downloads\\|\\desktop\\)(.*)(d3d|dxgi|opengl|hook|overlay|render)(.*)\.dll$") {
                    Add-Finding -Title "Suspicious DirectX / OpenGL Graphics Hook Injected" `
                                -Description "An unverified graphics/render hook module was injected into Minecraft JVM from a user directory." `
                                -Severity "Critical" -Category "Memory" `
                                -TargetPath "$pName (PID $procId)" `
                                -Evidence ("Injected Render Hook Module: " + $mod)
                }
            }
        }
        
        # RAM Scan
        Show-Progress -Phase "Memory" -Item "Scanning committed RAM pages for active cheat signatures"
        $ramFindings = [VortexCoreEngine.FastScanner]::ScanProcessRam($procId, $liveRamSignatures)
        foreach ($rf in $ramFindings) {
            Add-Finding -Title ("Active RAM Cheat Signature: " + $rf.Pattern) `
                        -Description "Live unencrypted cheat pattern detected resident in javaw.exe RAM space." `
                        -Severity "Critical" -Category "Memory" `
                        -TargetPath "$pName (PID $procId)" `
                        -Evidence $rf.Evidence
        }
    }
} else {
    Write-Host "  [-] No active Java/Minecraft process running. (Skipping live RAM scan)" -ForegroundColor DarkGray
}

# ====================================================================
# >>> [PHASE 2 : MULTI-CORE JAR BYTECODE HEURISTICS // DESIGNED BY BayrdY] <<<
# ====================================================================
Write-Host "`n[PHASE 2/5] Parallel Deep Scanning Launcher Mods & Bytecode..." -ForegroundColor Cyan

$directoriesToScan = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

if ($TargetFolder -and (Test-Path $TargetFolder)) {
    [void]$directoriesToScan.Add((Resolve-Path $TargetFolder).Path)
} else {
    $userProf = $env:USERPROFILE
    $appData  = $env:APPDATA
    $locs = @(
        "$appData\.minecraft",
        "$appData\ModrinthApp",
        "$appData\PrismLauncher",
        "$appData\.curseforge",
        "$appData\.badlion",
        "$appData\.feather",
        "$appData\.tlauncher",
        "$appData\.technic",
        "$userProf\.lunarclient",
        "$userProf\Desktop",
        "$userProf\Downloads"
    )
    foreach ($l in $locs) {
        if (Test-Path $l) { [void]$directoriesToScan.Add($l) }
    }
}

$allJarFiles = [System.Collections.Generic.List[string]]::new()
foreach ($dir in $directoriesToScan) {
    try {
        if (Test-Path $dir) {
            $files = [System.IO.Directory]::GetFiles($dir, "*.jar", [System.IO.SearchOption]::AllDirectories)
            foreach ($f in $files) {
                $fLower = $f.ToLowerInvariant()
                if ($fLower.Contains("\libraries\") -and ($fLower -match "(netty|guava|commons-|log4j|asm-|fastutil|gson|lwjgl|icu4j|authlib|trove|scala|jline)")) {
                    continue
                }
                $allJarFiles.Add($f)
            }
        }
    } catch { }
}

$totalJars = $allJarFiles.Count
Write-Host "  [+] Found $totalJars JAR file(s) across $($directoriesToScan.Count) directory source(s)" -ForegroundColor Green

if ($totalJars -gt 0) {
    Show-Progress -Phase "Bytecode" -Item "Multi-threaded parallel scan running across all CPU cores..."
    $swJars = [System.Diagnostics.Stopwatch]::StartNew()
    $jarResults = [VortexCoreEngine.FastScanner]::ScanAllJarsParallel(
        $allJarFiles.ToArray(),
        $macroBytecodePatterns,
        $tokenStealerPatterns,
        $obfuscatorSignatures,
        $legitModIds
    )
    $swJars.Stop()
    Write-Host "`r  [+] Scanned $totalJars JAR file(s) in $([math]::Round($swJars.ElapsedMilliseconds / 1000, 2))s using multi-core parallelism!" -ForegroundColor Green

    foreach ($jr in $jarResults) {
        # Check ADS Zone.Identifier
        $downloadUrl = $null
        try {
            $ads = Get-Content -Raw -Stream Zone.Identifier $jr.JarPath -ErrorAction SilentlyContinue
            if ($ads -match "HostUrl=(.+)") { $downloadUrl = $matches[1].Trim() }
        } catch { }

        $hasThreat = ($jr.MatchedMacros.Count -gt 0 -or $jr.MatchedObfuscators.Count -gt 0 -or $jr.HasTokenStealer -or $jr.HasRuntimeExec -or $jr.IsSpoofed)
        $modStatus = if ($hasThreat) { "SUSPICIOUS" } else { "CLEAN" }

        $scannedModsInventory.Add([PSCustomObject]@{
            FileName    = $jr.JarName
            FullPath    = $jr.JarPath
            Sha1        = $jr.Sha1
            Size        = $jr.FileSize
            Status      = $modStatus
            ClaimedId   = if ($jr.ClaimedModId) { $jr.ClaimedModId } else { "N/A" }
            DownloadUrl = if ($downloadUrl) { $downloadUrl } else { "Local / Launcher" }
        })

        if ($downloadUrl -and ($downloadUrl -match "discord|anonfiles|mediafire|mega\.nz|workupload|transfer\.sh|cdn\.discordapp")) {
            Add-Finding -Title "Suspicious Mod Download Source (Zone.Identifier ADS)" `
                        -Description "Mod was downloaded directly from an untrusted file-sharing or Discord CDN host." `
                        -Severity "Medium" -Category "Bytecode" `
                        -TargetPath $jr.JarPath `
                        -Evidence ("Download URL: " + $downloadUrl)
        }

        if ($jr.MatchedMacros.Count -gt 0) {
            $mList = ($jr.MatchedMacros) -join ", "
            Add-Finding -Title ("Cheat / Macro Signatures Detected in Mod: " + $mList) `
                        -Description "Mod contains compiled Java bytecode signatures matching known PvP macros and cheat routines." `
                        -Severity "Critical" -Category "Bytecode" `
                        -TargetPath $jr.JarPath `
                        -Evidence ("Matched Patterns: " + $mList)
        }

        if ($jr.HasTokenStealer) {
            Add-Finding -Title "Malicious Token Stealer / Webhook Exfiltration Detected" `
                        -Description "Mod contains embedded Discord webhook or browser token exfiltration endpoints." `
                        -Severity "Critical" -Category "Bytecode" `
                        -TargetPath $jr.JarPath `
                        -Evidence "Discord webhook / Token Grabber URL found in bytecode constant pool."
        }

        if ($jr.HasRuntimeExec) {
            Add-Finding -Title "Suspicious Native OS Command Execution in Bytecode" `
                        -Description "Mod executes arbitrary operating system commands inside bytecode." `
                        -Severity "High" -Category "Bytecode" `
                        -TargetPath $jr.JarPath `
                        -Evidence "Runtime.getRuntime().exec() / ProcessBuilder call detected."
        }

        if ($jr.MatchedObfuscators.Count -gt 0) {
            $obfList = ($jr.MatchedObfuscators) -join ", "
            Add-Finding -Title ("Commercial / Cheat Java Obfuscator Signature: " + $obfList) `
                        -Description "Mod was protected using obfuscators commonly used by commercial cheat developers." `
                        -Severity "High" -Category "Obfuscation" `
                        -TargetPath $jr.JarPath `
                        -Evidence ("Obfuscators: " + $obfList)
        }

        if ($jr.IsSpoofed) {
            Add-Finding -Title ("Trojan Mod Identity Spoofing: " + $jr.ClaimedModId) `
                        -Description "Mod pretends to be legitimate but contains hidden malicious/cheat code." `
                        -Severity "Critical" -Category "Bytecode" `
                        -TargetPath $jr.JarPath `
                        -Evidence ("Claimed Mod ID: " + $jr.ClaimedModId)
        }
    }
}

# ====================================================================
# >>> [PHASE 3 : WINDOWS EXECUTION ARTIFACTS & CACHES // FORENSIC LOGIC: BayrdY] <<<
# ====================================================================
Write-Host "`n[PHASE 3/5] Scanning Windows Execution Forensics & Caches..." -ForegroundColor Cyan

$knownLegitPaths = @(
    "\system32\", "\syswow64\", "\windows\", "\program files\", "\program files (x86)\",
    "\riot games\", "\steamapps\", "\epic games\", "\ubisoft\", "\ea games\",
    "\discord\", "\spotify\", "\google\chrome\", "\mozilla firefox\", "\bravesoftware\",
    "\microsoft\", "\nvidia\", "\amd\", "\intel\", "\overwolf\", "\curseforge\"
)

# 1. Prefetch Scanning
$prefetchDir = "C:\Windows\Prefetch"
if (Test-Path $prefetchDir) {
    Show-Progress -Phase "Forensics" -Item "Scanning Windows Prefetch directory"
    try {
        $pfFiles = [System.IO.Directory]::GetFiles($prefetchDir, "*.pf")
        foreach ($pfPath in $pfFiles) {
            $pfName = [System.IO.Path]::GetFileName($pfPath).ToUpperInvariant()
            foreach ($cn in $cheatClientsSet) {
                $cnUpper = $cn.ToUpperInvariant()
                if ($cnUpper.Length -ge 4 -and $pfName.StartsWith($cnUpper + "-")) {
                    Add-Finding -Title ("Prefetch Execution Trace: " + $pfName) `
                                -Description "Windows Prefetch recorded execution of known cheat executable." `
                                -Severity "High" -Category "Forensics" `
                                -TargetPath $pfPath `
                                -Evidence ("Prefetch Entry: " + $pfName)
                    break
                }
            }
        }
    } catch { }
}

# 2. BAM / DAM Registry Execution
Show-Progress -Phase "Forensics" -Item "Scanning BAM (Background Activity Moderator) Registry"
try {
    $bamPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
    if (Test-Path $bamPath) {
        $sids = Get-ChildItem -Path $bamPath -ErrorAction SilentlyContinue
        foreach ($sid in $sids) {
            $vals = (Get-ItemProperty -Path $sid.PSPath -ErrorAction SilentlyContinue).PSObject.Properties
            foreach ($prop in $vals) {
                $exePath = $prop.Name
                $exeLower = $exePath.ToLowerInvariant()
                $isLegitVendor = $false
                foreach ($lp in $knownLegitPaths) { if ($exeLower.Contains($lp)) { $isLegitVendor = $true; break } }
                if ($isLegitVendor) { continue }
                
                $exeNameOnly = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
                foreach ($cn in $cheatClientsSet) {
                    if ($cn.Length -ge 3 -and ($exeNameOnly -eq $cn -or $exePath -match "(?i)[\\/]$([regex]::Escape($cn))(\.exe)?$")) {
                        Add-Finding -Title ("BAM Execution Record: " + $cn) `
                                    -Description "Background Activity Moderator recorded execution of cheat executable." `
                                    -Severity "High" -Category "Forensics" `
                                    -TargetPath $exePath `
                                    -Evidence ("Registry SID: " + $sid.PSChildName)
                        break
                    }
                }
            }
        }
    }
} catch { }

# 3. UserAssist ROT13 Registry Execution
Show-Progress -Phase "Forensics" -Item "Decoding UserAssist ROT13 execution history"
try {
    $uaRoot = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
    if (Test-Path $uaRoot) {
        $guids = Get-ChildItem -Path $uaRoot -ErrorAction SilentlyContinue
        foreach ($g in $guids) {
            $countKey = Join-Path $g.PSPath "Count"
            if (Test-Path $countKey) {
                $props = (Get-ItemProperty -Path $countKey -ErrorAction SilentlyContinue).PSObject.Properties
                foreach ($p in $props) {
                    $decoded = [VortexCoreEngine.FastScanner]::Rot13($p.Name)
                    $decLower = $decoded.ToLowerInvariant()
                    $isLegitVendor = $false
                    foreach ($lp in $knownLegitPaths) { if ($decLower.Contains($lp)) { $isLegitVendor = $true; break } }
                    if ($isLegitVendor) { continue }

                    $decNameOnly = [System.IO.Path]::GetFileNameWithoutExtension($decoded)
                    foreach ($cn in $cheatClientsSet) {
                        if ($cn.Length -ge 3 -and ($decNameOnly -eq $cn -or $decoded -match "(?i)[\\/]$([regex]::Escape($cn))(\.exe|\.jar)?$")) {
                            Add-Finding -Title ("UserAssist GUI Execution Record: " + $cn) `
                                        -Description "UserAssist recorded GUI launch of cheat executable." `
                                        -Severity "High" -Category "Forensics" `
                                        -TargetPath $decoded `
                                        -Evidence ("ROT13 Decoded: " + $decoded)
                            break
                        }
                    }
                }
            }
        }
    }
} catch { }

# 4. ShimCache & MUICache
Show-Progress -Phase "Forensics" -Item "Checking MUICache & Recent Application Records"
try {
    $muiPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    if (Test-Path $muiPath) {
        $props = (Get-ItemProperty -Path $muiPath -ErrorAction SilentlyContinue).PSObject.Properties
        foreach ($p in $props) {
            $path = $p.Name
            $pathLower = $path.ToLowerInvariant()
            $isLegitVendor = $false
            foreach ($lp in $knownLegitPaths) { if ($pathLower.Contains($lp)) { $isLegitVendor = $true; break } }
            if ($isLegitVendor) { continue }

            $pNameOnly = [System.IO.Path]::GetFileNameWithoutExtension($path.Replace(".FriendlyAppName", "").Replace(".ApplicationCompany", ""))
            foreach ($cn in $cheatClientsSet) {
                if ($cn.Length -ge 3 -and ($pNameOnly -eq $cn -or $path -match "(?i)[\\/]$([regex]::Escape($cn))(\.exe|\.jar)?(\.FriendlyAppName|\.ApplicationCompany)?$")) {
                    Add-Finding -Title ("MUICache Execution Trace: " + $cn) `
                                -Description "Application execution record found in MUICache." `
                                -Severity "Medium" -Category "Forensics" `
                                -TargetPath $path `
                                -Evidence ("MUICache Entry: " + $path)
                    break
                }
            }
        }
    }
} catch { }

# 5. ComDlg32 OpenSavePidlMRU & LastVisited (File Picker Traces)
Show-Progress -Phase "Forensics" -Item "Scanning Open/Save File Dialog Picker History"
try {
    $comDlg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU"
    if (Test-Path $comDlg) {
        $subKeys = Get-ChildItem -Path $comDlg -ErrorAction SilentlyContinue
        foreach ($sk in $subKeys) {
            $ext = $sk.PSChildName
            $props = (Get-ItemProperty -Path $sk.PSPath -ErrorAction SilentlyContinue).PSObject.Properties
            foreach ($p in $props) {
                if ($p.Name -match "^\d+$" -and $p.Value -is [byte[]]) {
                    $rawBytes = [byte[]]$p.Value
                    $strDec = [System.Text.Encoding]::Unicode.GetString($rawBytes)
                    $clean = [regex]::Replace($strDec, "[^\x20-\x7E]", "")
                    foreach ($cn in $cheatClientsSet) {
                        if ($cn.Length -ge 4 -and $clean -match "(?i)$([regex]::Escape($cn))") {
                            Add-Finding -Title ("Cheat File Selected in Windows Open/Save Dialog: " + $cn) `
                                        -Description "User selected a cheat binary in a Windows file picker dialog (ComDlg32 MRU)." `
                                        -Severity "High" -Category "Forensics" `
                                        -TargetPath ("OpenSavePidlMRU\" + $ext) `
                                        -Evidence ("ComDlg32 MRU Record: " + $clean)
                            break
                        }
                    }
                }
            }
        }
    }
} catch { }

# 6. WinRAR, 7-Zip & Bandizip Archive History Forensics
Show-Progress -Phase "Forensics" -Item "Scanning WinRAR & 7-Zip Archive History (ArcHistory)"
try {
    # WinRAR
    $winrarKey = "HKCU:\Software\WinRAR\ArcHistory"
    if (Test-Path $winrarKey) {
        $props = (Get-ItemProperty -Path $winrarKey -ErrorAction SilentlyContinue).PSObject.Properties
        foreach ($p in $props) {
            $val = "$($p.Value)"
            foreach ($cn in $cheatClientsSet) {
                if ($cn.Length -ge 3 -and $val -match "(?i)[\\/]?$([regex]::Escape($cn)).*\.(zip|rar|7z|tar|gz|jar)$") {
                    Add-Finding -Title ("Opened Cheat Archive in WinRAR / 7-Zip History: " + $cn) `
                                -Description "Windows registry recorded opening of a cheat archive package." `
                                -Severity "High" -Category "Forensics" `
                                -TargetPath $val `
                                -Evidence ("WinRAR ArcHistory: " + $val)
                    break
                }
            }
        }
    }
    # 7-Zip
    $sevenZipKey = "HKCU:\Software\7-Zip\FM"
    if (Test-Path $sevenZipKey) {
        $szProps = (Get-ItemProperty -Path $sevenZipKey -ErrorAction SilentlyContinue).PSObject.Properties
        foreach ($p in $szProps) {
            $val = "$($p.Value)"
            foreach ($cn in $cheatClientsSet) {
                if ($cn.Length -ge 3 -and $val -match "(?i)$([regex]::Escape($cn))") {
                    Add-Finding -Title ("Opened Cheat Archive in WinRAR / 7-Zip History: " + $cn) `
                                -Description "Windows registry recorded opening of a cheat archive package." `
                                -Severity "High" -Category "Forensics" `
                                -TargetPath $val `
                                -Evidence ("7-Zip History: " + $val)
                    break
                }
            }
        }
    }
} catch { }

# 7. Everything / Voidtools Search History Forensics
Show-Progress -Phase "Forensics" -Item "Inspecting Everything (Voidtools) Search & Run History"
try {
    $everyPaths = @(
        "$env:APPDATA\Everything\Everything.ini",
        "$env:APPDATA\Everything\Everything64.ini",
        "$env:LOCALAPPDATA\Everything\Everything.ini"
    )
    foreach ($ep in $everyPaths) {
        if (Test-Path $ep) {
            $lines = Get-Content $ep -Tail 300 -ErrorAction SilentlyContinue
            foreach ($l in $lines) {
                if ($l -match "^(search_history|run_history_entry_search|history_entry)=" -or $l -match "(?i)vape|krypton|drip|reach|autoclicker|cleaner|bypass|wurst|disabler|usn|prefetch|eventlog|selfdestruct") {
                    foreach ($cn in $cheatClientsSet) {
                        if ($cn.Length -ge 4 -and $l -match "(?i)$([regex]::Escape($cn))") {
                            Add-Finding -Title ("Cheat Keyword Search in Everything History: " + $cn) `
                                        -Description "User searched for cheat binaries or forensic cleaner tools in Voidtools Everything." `
                                        -Severity "High" -Category "Cleaner" `
                                        -TargetPath $ep `
                                        -Evidence ("Everything Log Line: " + $l)
                            break
                        }
                    }
                }
            }
        }
    }
} catch { }

# ====================================================================
# >>> [PHASE 4 : NTFS JOURNAL & STORAGE TRACES // WRITTEN BY BayrdY] <<<
# ====================================================================
Write-Host "`n[PHASE 4/5] Scanning USN Journal Deletions & Recycle Bin..." -ForegroundColor Cyan

# 1. Recycle Bin
Show-Progress -Phase "Forensics" -Item "Checking Recycle Bin for purged cheats"
try {
    $rb = Get-ChildItem -Path 'C:\$Recycle.Bin' -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($item in $rb) {
        $iName = $item.Name
        foreach ($cn in $cheatClientsSet) {
            if ($cn.Length -ge 4 -and $iName -match "(?i)$([regex]::Escape($cn))") {
                Add-Finding -Title ("Deleted Cheat in Recycle Bin: " + $cn) `
                            -Description "Deleted cheat executable or archive found resting in Recycle Bin." `
                            -Severity "High" -Category "Forensics" `
                            -TargetPath $item.FullName `
                            -Evidence ("Recycle Bin file: " + $item.Name + " | Size: " + $item.Length)
                break
            }
        }
    }
} catch { }

# 2. USN Journal
Show-Progress -Phase "Forensics" -Item "Querying NTFS Change Journal for deleted cheat binaries"
try {
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }
    foreach ($d in $drives) {
        $driveLetter = $d.Name + ":"
        $usnOutput = fsutil usn readjournal $driveLetter csv 2>$null | Select-Object -First 1000
        if ($usnOutput) {
            foreach ($line in $usnOutput) {
                foreach ($cn in $cheatClientsSet) {
                    if ($cn.Length -ge 4 -and $line -match "(?i)[\\/]$([regex]::Escape($cn))\.(exe|jar|dll|bat)") {
                        Add-Finding -Title ("USN Journal Deleted File Record: " + $cn) `
                                    -Description "NTFS USN Journal recorded recent deletion of cheat binary." `
                                    -Severity "High" -Category "Forensics" `
                                    -TargetPath ($driveLetter + " " + $cn) `
                                    -Evidence ("Journal Record: " + $line)
                        break
                    }
                }
            }
        }
    }
} catch { }

# ====================================================================
# >>> [PHASE 5 : ANTI-CLEANER, ROOTKIT & NETWORK AUDIT // SECURITY DEV: BayrdY] <<<
# ====================================================================
Write-Host "`n[PHASE 5/5] Scanning for Cleaners, Self-Destructs & Tampering..." -ForegroundColor Cyan

# 1. PowerShell History Cleaner Commands
Show-Progress -Phase "Cleaners" -Item "Inspecting PowerShell ConsoleHost_history.txt"
try {
    $psHistoryPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    if (Test-Path $psHistoryPath) {
        $lines = Get-Content $psHistoryPath -Tail 200 -ErrorAction SilentlyContinue
        foreach ($l in $lines) {
            if ($l -match "(?i)wevtutil|deletejournal|usn|clear-eventlog|vanish|selfdestruct|cleaner|fsutil\s+usn\s+delete") {
                Add-Finding -Title "Anti-Forensic Cleaner Command in PowerShell History" `
                            -Description "PowerShell history contains evidence of log clearing or forensic journal purging." `
                            -Severity "High" -Category "Cleaner" `
                            -TargetPath $psHistoryPath `
                            -Evidence ("Executed Command: " + $l)
            }
        }
    }
} catch { }

# 2. PcaSvc Service State
Show-Progress -Phase "Cleaners" -Item "Checking Program Compatibility Assistant (PcaSvc) Service"
try {
    $pca = Get-Service -Name "PcaSvc" -ErrorAction SilentlyContinue
    if ($pca -and $pca.Status -eq "Stopped") {
        Add-Finding -Title "PcaSvc Service Disabled / Stopped" `
                    -Description "Program Compatibility Assistant is stopped. Often disabled by cheat cleaners to avoid execution logging." `
                    -Severity "Medium" -Category "Cleaner" `
                    -TargetPath "Service: PcaSvc" `
                    -Evidence "PcaSvc service status is Stopped."
    }
} catch { }

# 3. %TEMP% Ghost Batches & JNA / JInput Leftovers
Show-Progress -Phase "Cleaners" -Item "Scanning %TEMP% for leftover cleaner scripts and JNA hooks"
try {
    $tempDir = [System.IO.Path]::GetTempPath()
    $tempFiles = [System.IO.Directory]::GetFiles($tempDir, "*.bat")
    foreach ($tf in $tempFiles) {
        $content = Get-Content $tf -Raw -ErrorAction SilentlyContinue
        if ($content -match "(?i)del\s+\%0|shutdown|choice\s+\/t|timeout|ping\s+127\.0\.0\.1") {
            Add-Finding -Title "Self-Destruct Cleaner Batch Script in %TEMP%" `
                        -Description "A self-deleting batch script commonly dropped by cheat self-destruct routines was discovered." `
                        -Severity "High" -Category "Cleaner" `
                        -TargetPath $tf `
                        -Evidence ("Cleaner script: " + [System.IO.Path]::GetFileName($tf))
        }
    }
} catch { }

# 4. Windows Event Logs Tampering (Events 1102, 104, 7045)
try {
    $evt1102 = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=1102} -MaxEvents 5 -ErrorAction SilentlyContinue
    if ($evt1102) {
        foreach ($e in $evt1102) {
            Add-Finding -Title "Security Audit Log Cleared (Event 1102)" `
                        -Description "The Windows Security Event Log was manually purged." `
                        -Severity "Critical" -Category "Cleaner" `
                        -TargetPath "Windows Security Event Log" `
                        -Evidence ("Cleared at: " + $e.TimeCreated)
        }
    }
    $evt7045 = Get-WinEvent -FilterHashtable @{LogName='System'; Id=7045} -MaxEvents 20 -ErrorAction SilentlyContinue
    if ($evt7045) {
        foreach ($e in $evt7045) {
            $msg = $e.FormatDescription()
            if ($msg -match "(?i)gdrv|mhyprot|kdu|vboxdrv|procexp|capcom") {
                Add-Finding -Title "Vulnerable / Bypass Kernel Driver Installed (Event 7045)" `
                            -Description "A vulnerable kernel driver known for Anti-Cheat bypasses was registered as a service." `
                            -Severity "Critical" -Category "Cleaner" `
                            -TargetPath "System Service Control Manager" `
                            -Evidence ("Installed at: " + $e.TimeCreated + " | " + $msg)
            }
        }
    }
} catch { }

# 5. Windows Defender Antivirus Exclusions Audit
Show-Progress -Phase "Security" -Item "Auditing Windows Defender Folder & Process Exclusions"
try {
    $mpPref = Get-MpPreference -ErrorAction SilentlyContinue
    if ($mpPref) {
        $exPaths = @($mpPref.ExclusionPath) | Where-Object { $_ }
        $exExts  = @($mpPref.ExclusionExtension) | Where-Object { $_ }
        $exProcs = @($mpPref.ExclusionProcess) | Where-Object { $_ }
        
        foreach ($ep in $exPaths) {
            if ($ep -match "(?i)(\\temp|\\appdata|\\downloads|\\desktop|\\users|\\drivers|\.exe|\.dll|\.jar)") {
                Add-Finding -Title "Suspicious Windows Defender Path Exclusion" `
                            -Description "A critical user/system folder is excluded from Windows Defender real-time scanning." `
                            -Severity "High" -Category "Security" `
                            -TargetPath $ep `
                            -Evidence ("Defender ExclusionPath: " + $ep)
            }
        }
        foreach ($ee in $exExts) {
            if ($ee -match "(?i)(exe|dll|jar|bat|vbs|ps1|sys)") {
                Add-Finding -Title "Malicious Windows Defender Extension Exclusion" `
                            -Description "Executable or script extensions are excluded from antivirus scanning." `
                            -Severity "High" -Category "Security" `
                            -TargetPath ("*." + $ee) `
                            -Evidence ("Defender ExclusionExtension: *." + $ee)
            }
        }
        foreach ($epr in $exProcs) {
            Add-Finding -Title "Windows Defender Process Exclusion" `
                        -Description "A process binary is excluded from Windows Defender monitoring." `
                        -Severity "Medium" -Category "Security" `
                        -TargetPath $epr `
                        -Evidence ("Defender ExclusionProcess: " + $epr)
        }
    }
} catch { }

# 6. DNS Cache & Network Forensics
Show-Progress -Phase "Network" -Item "Scanning DNS Client Resolver Cache for Cheat Auth Endpoints"
try {
    $dnsRecords = Get-DnsClientCache -ErrorAction SilentlyContinue
    if ($dnsRecords) {
        $cheatDomains = @(
            "vape.gg", "drip.gg", "riseclient.com", "intent.store", "liquidbounce.net",
            "tenacity.dev", "novaclient", "astolfo.lgbt", "prestigeclient", "dqrkis.xyz",
            "slinky.gg", "opal.vip", "augustus.lol", "kura.rip", "skilledclient",
            "boze.dev", "futureclient", "rusherhack", "aristois.net", "meteorclient"
        )
        $seenDns = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($rec in $dnsRecords) {
            $entry = $rec.Entry
            if (-not $entry -or -not $seenDns.Add($entry)) { continue }
            foreach ($cd in $cheatDomains) {
                if ($entry -match "(?i)$([regex]::Escape($cd))") {
                    Add-Finding -Title ("Cheat / Ghost Client Domain in DNS Cache: " + $cd) `
                                -Description "Computer resolved DNS query for a known cheat authentication server or website." `
                                -Severity "Critical" -Category "Network" `
                                -TargetPath $entry `
                                -Evidence ("DNS Cache Query: " + $entry + " | Status: " + $rec.Status)
                    break
                }
            }
        }
    }
} catch { }

# 7. USB & External Device Forensics (USBSTOR)
Show-Progress -Phase "Forensics" -Item "Checking USB Storage History for Ghost Flash Cheats"
try {
    $usbPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
    if (Test-Path $usbPath) {
        $devices = Get-ChildItem -Path $usbPath -ErrorAction SilentlyContinue
        foreach ($dev in $devices) {
            $subInstances = Get-ChildItem -Path $dev.PSPath -ErrorAction SilentlyContinue
            foreach ($inst in $subInstances) {
                $props = Get-ItemProperty -Path $inst.PSPath -ErrorAction SilentlyContinue
                $friendlyName = $props.FriendlyName
                if (-not $friendlyName) { $friendlyName = $dev.PSChildName }
                # Check for suspicious cheat-named drives or log external drive presence
                if ($friendlyName -match "(?i)(cheat|vape|ghost|bypass|inject|loader)") {
                    Add-Finding -Title ("Suspicious USB Storage Device Connected: " + $friendlyName) `
                                -Description "An external USB storage drive matching cheat keywords was mounted on this system." `
                                -Severity "High" -Category "Forensics" `
                                -TargetPath ("USBSTOR\" + $dev.PSChildName) `
                                -Evidence ("FriendlyName: " + $friendlyName)
                }
            }
        }
    }
} catch { }

# 8. Kernel Security, TestSigning & BYOVD Status
Show-Progress -Phase "Security" -Item "Verifying Kernel TestSigning & Driver Signature Enforcement"
try {
    $bcd = bcdedit.exe /enum '{current}' 2>$null
    if ($bcd -match "(?i)testsigning\s+yes") {
        Add-Finding -Title "Windows TestSigning Mode Active (Kernel Driver Bypass)" `
                    -Description "Windows is running in TestSigning mode allowing unsigned kernel-mode drivers to load." `
                    -Severity "Critical" -Category "Kernel" `
                    -TargetPath "SYSTEM\CurrentControlSet\Control" `
                    -Evidence "bcdedit TestSigning = Yes (Driver Signature Enforcement bypassed)"
    }
    if ($bcd -match "(?i)nointegritychecks\s+yes") {
        Add-Finding -Title "Driver Integrity Checks Disabled (NoIntegrityChecks)" `
                    -Description "Windows kernel integrity checks have been explicitly disabled." `
                    -Severity "Critical" -Category "Kernel" `
                    -TargetPath "bcdedit {current}" `
                    -Evidence "bcdedit nointegritychecks = Yes"
    }
    if ($bcd -match "(?i)debug\s+yes") {
        Add-Finding -Title "Kernel Debugging Enabled" `
                    -Description "Windows Kernel Debugger is active, which can be leveraged for cheat memory manipulation." `
                    -Severity "High" -Category "Kernel" `
                    -TargetPath "bcdedit {current}" `
                    -Evidence "bcdedit debug = Yes"
    }
} catch { }

# 9. RegEdit Search & Anti-Forensic Cleanup Trace
Show-Progress -Phase "Cleaners" -Item "Inspecting RegEdit Navigation & Keyword Searches"
try {
    $regApplet = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit"
    if (Test-Path $regApplet) {
        $rProps = Get-ItemProperty -Path $regApplet -ErrorAction SilentlyContinue
        $lastKey = $rProps.LastKey
        $searchKeys = @("vape", "reach", "autoclicker", "bypass", "krypton", "drip", "ghost", "client", "cheat", "wurst", "inject")
        foreach ($sk in $searchKeys) {
            if ($lastKey -match "(?i)$sk") {
                Add-Finding -Title "Suspicious RegEdit Navigation / Cleanup Trace" `
                            -Description "Windows Registry Editor LastKey points to a cheat search or key deletion attempt." `
                            -Severity "High" -Category "Cleaner" `
                            -TargetPath "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" `
                            -Evidence ("RegEdit LastKey: " + $lastKey)
                break
            }
        }
    }
} catch { }

# 10. Hardware Macro & LUA Scripts Forensics (Logitech, Razer, Bloody, Corsair)
Show-Progress -Phase "Forensics" -Item "Scanning Logitech G HUB, Razer, Bloody & Corsair Macro Profiles"
try {
    $macroDirs = @(
        "$env:LOCALAPPDATA\LGHUB\scripts",
        "$env:LOCALAPPDATA\Razer\Synapse3\Macros",
        "$env:APPDATA\Razer\Synapse\Accounts",
        "$env:APPDATA\Corsair\CUE5\actions",
        "$env:APPDATA\Corsair\CUE\actions",
        "C:\Program Files (x86)\Bloody7\Bloody7\Data\Res",
        "C:\Program Files\Bloody7\Bloody7\Data\Res"
    )
    foreach ($md in $macroDirs) {
        if (Test-Path $md) {
            $mFiles = Get-ChildItem -Path $md -Recurse -File -Include "*.lua", "*.xml", "*.amc", "*.mgn", "*.bld" -ErrorAction SilentlyContinue
            foreach ($mf in $mFiles) {
                $mContent = Get-Content $mf.FullName -Raw -ErrorAction SilentlyContinue
                if ($mContent -match "(?i)(PressMouseButton|OutputLogMessage|Sleep|IsMouseButtonPressed|jitter|autoclick|recoil|cps|fastplace|right_click_burst)") {
                    Add-Finding -Title ("Hardware Macro / LUA AutoClicker Script Detected: " + $mf.Name) `
                                -Description "A gaming mouse/keyboard macro script designed for automated CPS or recoil compensation was found." `
                                -Severity "High" -Category "Forensics" `
                                -TargetPath $mf.FullName `
                                -Evidence ("Hardware Profile: " + $mf.FullName + " (Size: " + $mf.Length + " bytes)")
                }
            }
        }
    }
} catch { }

# 11. Windows Clipboard (Pano) Forensics
Show-Progress -Phase "Forensics" -Item "Auditing Active Windows Clipboard Content"
try {
    $clipText = ""
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        if ([System.Windows.Forms.Clipboard]::ContainsText()) {
            $clipText = [System.Windows.Forms.Clipboard]::GetText()
        }
    } catch {
        $clipText = Get-Clipboard -Raw -ErrorAction SilentlyContinue
    }
    
    if ($clipText -and $clipText.Length -lt 2000) {
        if ($clipText -match "(?i)(discord\.com/api/webhooks/|discordapp\.com/api/webhooks/|vape\.gg|riseclient|drip\.gg|intent\.store|deletejournal|wevtutil|clear-eventlog|selfdestruct|bypass|krypton)") {
            $cleanClip = $clipText.Replace("`r", " ").Replace("`n", " ")
            if ($cleanClip.Length -gt 120) { $cleanClip = $cleanClip.Substring(0, 120) + "..." }
            Add-Finding -Title "Suspicious Cheat Payload / Webhook in Clipboard" `
                        -Description "Windows clipboard contained active cheat commands, authorization tokens, or webhook endpoints." `
                        -Severity "High" -Category "Forensics" `
                        -TargetPath "Windows System Clipboard" `
                        -Evidence ("Clipboard Content: " + $cleanClip)
        }
    }
} catch { }

# 12. Browser Download History Forensics (Chrome, Edge, Brave, Opera, Firefox)
Show-Progress -Phase "Network" -Item "Scanning Web Browser Download Records for Cheat Clients"
try {
    $browserHistoryPaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\History",
        "$env:APPDATA\Opera Software\Opera Stable\History",
        "$env:APPDATA\Opera Software\Opera GX Stable\History"
    )
    foreach ($bhp in $browserHistoryPaths) {
        if (Test-Path $bhp) {
            try {
                $fs = [System.IO.File]::Open($bhp, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                $sr = [System.IO.StreamReader]::new($fs, [System.Text.Encoding]::ASCII)
                $bContent = $sr.ReadToEnd()
                $sr.Close()
                $fs.Close()
                
                foreach ($cn in $cheatClientsSet) {
                    if ($cn.Length -ge 4 -and $bContent -match "(?i)(https?://[^\x00-\x20""'<>]*$([regex]::Escape($cn))[^\x00-\x20""'<>]*)") {
                        $matchedUrl = $Matches[1]
                        if ($matchedUrl.Length -gt 140) { $matchedUrl = $matchedUrl.Substring(0, 140) + "..." }
                        Add-Finding -Title ("Cheat Download Trace in Web Browser History: " + $cn) `
                                    -Description "Browser history contains recorded download of known cheat client or injector." `
                                    -Severity "High" -Category "Network" `
                                    -TargetPath $bhp `
                                    -Evidence ("Browser Download URL: " + $matchedUrl)
                        break
                    }
                }
            } catch { }
        }
    }
} catch { }

Write-Host "`r$(' ' * 90)`r" -NoNewline
$swTotal.Stop()
$elapsedSec = [math]::Round($swTotal.ElapsedMilliseconds / 1000, 2)

# ====================================================================
# PRESENTATION & TERMINAL SUMMARY REPORT
# ====================================================================
$critCount = @($findings | Where-Object { $_.Severity -eq "Critical" }).Count
$highCount = @($findings | Where-Object { $_.Severity -eq "High" }).Count
$medCount  = @($findings | Where-Object { $_.Severity -eq "Medium" }).Count
$totalThreats = $findings.Count

# Threat Score Calculation (0-100)
$score = ($critCount * 30) + ($highCount * 15) + ($medCount * 5)
if ($score -gt 100) { $score = 100 }

$verdictText = "CLEAN & SECURE"
$verdictColor = "Green"
if ($critCount -gt 0) { $verdictText = "CRITICAL CHEAT THREATS DETECTED"; $verdictColor = "Red" }
elseif ($highCount -gt 0) { $verdictText = "HIGH RISK SUSPECT DETECTED"; $verdictColor = "Yellow" }
elseif ($medCount -gt 0) { $verdictText = "POTENTIAL SUSPICIOUS ANOMALIES"; $verdictColor = "DarkYellow" }

Write-Host "`n"
Write-Host "==============================================================================" -ForegroundColor DarkCyan
Write-Host "          VORTEX-AC SCAN RESULTS & VERDICT - Coded By BayrdY" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor DarkCyan
Write-Host "  VERDICT:       " -NoNewline -ForegroundColor Gray
Write-Host " $verdictText " -BackgroundColor $verdictColor -ForegroundColor Black
Write-Host "  THREAT SCORE:  " -NoNewline -ForegroundColor Gray
$scoreColor = if ($score -ge 50) { "Red" } elseif ($score -gt 0) { "Yellow" } else { "Green" }
Write-Host "$score / 100" -ForegroundColor $scoreColor
Write-Host "  SCAN TIME:     $elapsedSec seconds" -ForegroundColor Gray
Write-Host "  SCANNED FILES: $totalJars JAR archives analyzed" -ForegroundColor White
Write-Host "  FINDINGS:      " -NoNewline -ForegroundColor Gray
Write-Host "$critCount Critical" -ForegroundColor Red -NoNewline
Write-Host " | " -ForegroundColor DarkGray -NoNewline
Write-Host "$highCount High" -ForegroundColor Yellow -NoNewline
Write-Host " | " -ForegroundColor DarkGray -NoNewline
Write-Host "$medCount Medium" -ForegroundColor DarkYellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkGray

if ($findings.Count -gt 0) {
    Write-Host "`n  [!] DETAILED DETECTIONS ($($findings.Count)):" -ForegroundColor Yellow
    foreach ($f in $findings) {
        $bColor = switch ($f.Severity) { "Critical" { "Red" } "High" { "Yellow" } default { "DarkYellow" } }
        Write-Host "  +--[" -NoNewline -ForegroundColor $bColor
        Write-Host "$($f.Severity.ToUpperInvariant())" -ForegroundColor White -NoNewline
        Write-Host "] " -NoNewline -ForegroundColor $bColor
        Write-Host "$($f.Title)" -ForegroundColor White
        Write-Host "  | Category: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($f.Category)" -ForegroundColor Cyan
        Write-Host "  | Target:   " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($f.TargetPath)" -ForegroundColor DarkCyan
        Write-Host "  | Evidence: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($f.Evidence)" -ForegroundColor Gray
        Write-Host "  +---------------------------------------------------------------------------" -ForegroundColor DarkGray
    }
} else {
    Write-Host "`n  [+] No active cheats, injected modules, or forensic wipe traces found." -ForegroundColor Green
}

# ====================================================================
# NEXT-GEN CYBERPUNK INTERACTIVE HTML WEB REPORT (AUTO-TRANSLATE & CLEAN)
# ====================================================================
if (-not $NoHtmlReport) {
    $timestampStr = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $reportDir = if (Test-Path "$env:USERPROFILE\Desktop") { "$env:USERPROFILE\Desktop" } else { (Get-Location).Path }
    $reportPath = Join-Path $reportDir "VortexReport_$timestampStr.html"
    
    $jsonFindings = ConvertTo-Json -InputObject @($findings) -Depth 5 -Compress
    if (-not $jsonFindings -or $jsonFindings -eq "null") { $jsonFindings = "[]" }

    $jsonMods = ConvertTo-Json -InputObject @($scannedModsInventory) -Depth 5 -Compress
    if (-not $jsonMods -or $jsonMods -eq "null") { $jsonMods = "[]" }

    $gaugeColor = if ($score -ge 50) { "#FF0055" } elseif ($score -gt 0) { "#FFB800" } else { "#00FFA3" }
    $gaugeOffset = [math]::Round(314 - (314 * ($score / 100)))

    $htmlTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>VORTEX-AC Forensic Intelligence Report - __USER__ | Coded By BayrdY</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;800&family=Outfit:wght@400;600;700;800;900&display=swap" rel="stylesheet">
  <!-- [VORTEX APEX INTERACTIVE DASHBOARD] :: UI/UX CODED BY BAYRDY -->
  <style>
    /* Cyberpunk UI Engine - Crafted by BayrdY */
    :root {
      --bg-dark: #07090E;
      --card-bg: rgba(14, 20, 32, 0.85);
      --card-border: rgba(0, 240, 255, 0.15);
      --neon-cyan: #00F0FF;
      --neon-crimson: #FF0055;
      --neon-amber: #FFB800;
      --neon-green: #00FFA3;
      --text-main: #F0F4F8;
      --text-muted: #8E9BAE;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: "Outfit", -apple-system, BlinkMacSystemFont, sans-serif; }
    code, pre, .mono { font-family: "JetBrains Mono", monospace !important; }
    body { background: radial-gradient(circle at top right, #0F172A 0%, #07090E 100%); color: var(--text-main); min-height: 100vh; padding: 30px 20px; }
    .container { max-width: 1250px; margin: 0 auto; }
    .header-card { background: linear-gradient(135deg, rgba(16, 24, 40, 0.95), rgba(8, 12, 22, 0.95)); border: 1px solid var(--card-border); border-radius: 18px; padding: 25px 35px; margin-bottom: 25px; box-shadow: 0 10px 35px rgba(0,0,0,0.6), 0 0 30px rgba(0, 240, 255, 0.05); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 20px; }
    .brand h1 { font-size: 26px; font-weight: 900; letter-spacing: 1.5px; background: linear-gradient(90deg, #00F0FF, #00FFA3); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .brand p { color: var(--text-muted); font-size: 13px; margin-top: 5px; }
    .header-actions { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }
    .action-btn { padding: 9px 16px; border-radius: 10px; font-weight: 700; font-size: 13px; cursor: pointer; border: 1px solid var(--card-border); background: rgba(16, 22, 36, 0.8); color: var(--text-main); transition: all 0.2s ease; display: flex; align-items: center; gap: 8px; }
    .action-btn:hover { background: var(--neon-cyan); color: #000; border-color: var(--neon-cyan); transform: translateY(-2px); }
    .dash-grid { display: grid; grid-template-columns: 280px 1fr; gap: 20px; margin-bottom: 25px; }
    @media(max-width: 850px) { .dash-grid { grid-template-columns: 1fr; } }
    .gauge-card { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 16px; padding: 25px; text-align: center; display: flex; flex-direction: column; justify-content: center; align-items: center; backdrop-filter: blur(10px); }
    .gauge-svg { width: 140px; height: 140px; transform: rotate(-90deg); }
    .gauge-bg { fill: none; stroke: rgba(255,255,255,0.06); stroke-width: 10; }
    .gauge-fill { fill: none; stroke: __GAUGE_COLOR__; stroke-width: 10; stroke-dasharray: 314; stroke-dashoffset: __GAUGE_OFFSET__; stroke-linecap: round; transition: stroke-dashoffset 1s ease; }
    .gauge-center { position: absolute; font-size: 28px; font-weight: 900; color: #FFF; }
    .verdict-tag { margin-top: 15px; padding: 6px 14px; border-radius: 20px; font-size: 12px; font-weight: 800; letter-spacing: 1px; text-transform: uppercase; background: __GAUGE_COLOR__22; color: __GAUGE_COLOR__; border: 1px solid __GAUGE_COLOR__55; }
    .stats-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; }
    .stat-box { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 14px; padding: 20px; backdrop-filter: blur(10px); display: flex; flex-direction: column; justify-content: space-between; }
    .stat-label { font-size: 12px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px; }
    .stat-val { font-size: 26px; font-weight: 900; margin-top: 8px; color: #FFF; }
    .tabs-nav { display: flex; gap: 10px; margin-bottom: 20px; border-bottom: 1px solid var(--card-border); padding-bottom: 12px; overflow-x: auto; }
    .tab-btn { padding: 10px 20px; background: transparent; border: none; color: var(--text-muted); font-size: 14px; font-weight: 700; cursor: pointer; border-radius: 10px; transition: all 0.2s ease; white-space: nowrap; }
    .tab-btn.active { background: rgba(0, 240, 255, 0.15); color: var(--neon-cyan); border: 1px solid var(--neon-cyan); }
    .filter-section { background: rgba(14, 20, 32, 0.6); border: 1px solid var(--card-border); border-radius: 14px; padding: 18px; margin-bottom: 20px; display: flex; flex-direction: column; gap: 12px; }
    .search-row { display: flex; gap: 12px; flex-wrap: wrap; }
    .search-input { flex: 1; min-width: 250px; padding: 12px 18px; background: rgba(8, 12, 20, 0.9); border: 1px solid var(--card-border); border-radius: 10px; color: #FFF; outline: none; font-size: 14px; }
    .search-input:focus { border-color: var(--neon-cyan); box-shadow: 0 0 15px rgba(0, 240, 255, 0.2); }
    .filter-group { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
    .group-label { font-size: 12px; font-weight: 800; color: var(--text-muted); text-transform: uppercase; margin-right: 5px; }
    .filter-btn { padding: 7px 14px; background: rgba(14, 20, 32, 0.7); border: 1px solid var(--card-border); color: var(--text-muted); border-radius: 8px; cursor: pointer; font-weight: 700; font-size: 12px; transition: all 0.2s ease; }
    .filter-btn.active, .filter-btn:hover { background: var(--neon-cyan); color: #000; border-color: var(--neon-cyan); }
    .cards-list { display: flex; flex-direction: column; gap: 15px; }
    .f-card { background: var(--card-bg); border-left: 4px solid var(--neon-cyan); border-top: 1px solid var(--card-border); border-right: 1px solid var(--card-border); border-bottom: 1px solid var(--card-border); border-radius: 14px; padding: 22px; transition: transform 0.2s ease; }
    .f-card.Critical { border-left-color: var(--neon-crimson); }
    .f-card.High { border-left-color: var(--neon-amber); }
    .f-card.Medium { border-left-color: var(--neon-cyan); }
    .f-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; gap: 15px; }
    .f-title { font-size: 17px; font-weight: 800; color: #FFF; }
    .badge { padding: 4px 10px; border-radius: 6px; font-size: 11px; font-weight: 800; text-transform: uppercase; }
    .badge.Critical { background: rgba(255, 0, 85, 0.2); color: var(--neon-crimson); }
    .badge.High { background: rgba(255, 184, 0, 0.2); color: var(--neon-amber); }
    .badge.Medium { background: rgba(0, 240, 255, 0.2); color: var(--neon-cyan); }
    .f-desc { color: var(--text-muted); font-size: 14px; margin-bottom: 12px; line-height: 1.5; }
    .f-evidence { background: rgba(0,0,0,0.6); border: 1px solid rgba(255,255,255,0.06); padding: 12px 15px; border-radius: 10px; font-size: 13px; color: #A0C0E0; display: flex; justify-content: space-between; align-items: center; gap: 10px; }
    .copy-btn { padding: 5px 12px; background: rgba(255,255,255,0.1); border: none; border-radius: 6px; color: #FFF; font-size: 11px; cursor: pointer; font-weight: 700; white-space: nowrap; }
    .copy-btn:hover { background: var(--neon-cyan); color: #000; }
    .f-footer { margin-top: 12px; font-size: 12px; color: var(--text-muted); display: flex; gap: 20px; flex-wrap: wrap; }
    .mods-table { width: 100%; border-collapse: collapse; background: var(--card-bg); border-radius: 14px; overflow: hidden; border: 1px solid var(--card-border); }
    .mods-table th { background: rgba(16, 24, 40, 0.9); padding: 14px 16px; text-align: left; font-size: 12px; font-weight: 800; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px; border-bottom: 1px solid var(--card-border); }
    .mods-table td { padding: 12px 16px; font-size: 13px; border-bottom: 1px solid rgba(255,255,255,0.04); color: var(--text-main); }
    .mods-table tr:hover td { background: rgba(0, 240, 255, 0.04); }
    .tag-clean { color: var(--neon-green); font-weight: 700; background: rgba(0,255,163,0.1); padding: 3px 8px; border-radius: 5px; }
    .tag-susp { color: var(--neon-crimson); font-weight: 700; background: rgba(255,0,85,0.1); padding: 3px 8px; border-radius: 5px; }
    .tab-pane { display: none; }
    .tab-pane.active { display: block; }
    
    /* Google Translate Styling */
    .goog-te-banner-frame.skiptranslate { display: none !important; }
    body { top: 0px !important; }
    .goog-te-gadget-simple { background: rgba(16, 22, 36, 0.8) !important; border: 1px solid var(--card-border) !important; padding: 6px 12px !important; border-radius: 8px !important; color: #FFF !important; }
    .goog-te-gadget-simple span { color: #FFF !important; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header-card">
      <div class="brand">
        <h1 id="ui_title">VORTEX APEX FORENSIC INTELLIGENCE SUITE</h1>
        <p><span id="ui_user_lbl">Target User:</span> <b>__USER__</b> | <span id="ui_host_lbl">Host:</span> <b>__HOST__</b> | <span id="ui_date_lbl">Scanned:</span> __TIMESTAMP__ | <b style="color: var(--neon-cyan);">Coded By BayrdY</b></p>
      </div>
      <div class="header-actions">
        <button class="action-btn" onclick="copyReportJson()"><span style="font-weight:900;">&#128190;</span> <span id="ui_btn_export">Export JSON</span></button>
        <button class="action-btn" onclick="window.print()"><span style="font-weight:900;">&#128424;</span> <span id="ui_btn_print">Print / PDF</span></button>
      </div>
    </div>
    <div class="dash-grid">
      <div class="gauge-card">
        <div style="position: relative; display: flex; justify-content: center; align-items: center;">
          <svg class="gauge-svg" viewBox="0 0 120 120">
            <circle class="gauge-bg" cx="60" cy="60" r="50"/>
            <circle class="gauge-fill" cx="60" cy="60" r="50"/>
          </svg>
          <div class="gauge-center">__SCORE__<span style="font-size: 14px; color: var(--text-muted);">/100</span></div>
        </div>
        <div class="verdict-tag" id="verdictBadge">__VERDICT__</div>
      </div>
      <div class="stats-cards">
        <div class="stat-box">
          <div class="stat-label" id="ui_stat_crit">Critical Threats</div>
          <div class="stat-val" style="color: var(--neon-crimson);">__CRIT__</div>
        </div>
        <div class="stat-box">
          <div class="stat-label" id="ui_stat_high">High Risk</div>
          <div class="stat-val" style="color: var(--neon-amber);">__HIGH__</div>
        </div>
        <div class="stat-box">
          <div class="stat-label" id="ui_stat_mods">Scanned JAR Mods</div>
          <div class="stat-val">__TOTAL_JARS__</div>
        </div>
        <div class="stat-box">
          <div class="stat-label" id="ui_stat_speed">Scan Speed</div>
          <div class="stat-val" style="color: var(--neon-green); font-size: 20px;">__ELAPSED__s</div>
        </div>
      </div>
    </div>
    <div class="tabs-nav">
      <button class="tab-btn active" onclick="switchTab('tab-findings', this)" id="tabBtnFindings">&#9888; <span id="ui_tab_findings">Detections & Anomalies</span> (__FINDINGS_COUNT__)</button>
      <button class="tab-btn" onclick="switchTab('tab-mods', this)" id="tabBtnMods">&#128230; <span id="ui_tab_mods">Mod Inventory</span> (__TOTAL_JARS__)</button>
    </div>
    
    <!-- FINDINGS TAB -->
    <div id="tab-findings" class="tab-pane active">
      <div class="filter-section">
        <div class="search-row">
          <input type="text" id="searchInput" class="search-input" placeholder="Search detections, signatures, memory regions, paths..." onkeyup="filterFindings()">
        </div>
        <div class="filter-group">
          <span class="group-label" id="ui_lbl_sev">Severity:</span>
          <button class="filter-btn active" onclick="setSeverityFilter('all', this)" id="ui_btn_all_sev">All (__FINDINGS_COUNT__)</button>
          <button class="filter-btn" onclick="setSeverityFilter('Critical', this)"><span id="ui_btn_crit">Critical</span> (__CRIT__)</button>
          <button class="filter-btn" onclick="setSeverityFilter('High', this)"><span id="ui_btn_high">High</span> (__HIGH__)</button>
          <button class="filter-btn" onclick="setSeverityFilter('Medium', this)"><span id="ui_btn_med">Medium</span> (__MED__)</button>
        </div>
        <div class="filter-group">
          <span class="group-label" id="ui_lbl_cat">Category:</span>
          <button class="filter-btn active" onclick="setCategoryFilter('all', this)" id="ui_btn_all_cat">All Categories</button>
          <button class="filter-btn" onclick="setCategoryFilter('Bytecode', this)">Bytecode</button>
          <button class="filter-btn" onclick="setCategoryFilter('Memory', this)" id="ui_btn_mem">Memory / RAM</button>
          <button class="filter-btn" onclick="setCategoryFilter('Forensics', this)">Forensics</button>
          <button class="filter-btn" onclick="setCategoryFilter('Cleaner', this)" id="ui_btn_clean">Cleaners & Anti-Forensics</button>
          <button class="filter-btn" onclick="setCategoryFilter('Security', this)" id="ui_btn_sec">Security & Kernel</button>
          <button class="filter-btn" onclick="setCategoryFilter('Network', this)" id="ui_btn_net">Network & DNS</button>
          <button class="filter-btn" onclick="setCategoryFilter('Obfuscation', this)">Obfuscation</button>
        </div>
      </div>
      <div class="cards-list" id="findingsList"></div>
    </div>
    
    <!-- MODS INVENTORY TAB -->
    <div id="tab-mods" class="tab-pane">
      <div class="filter-section">
        <div class="search-row">
          <input type="text" id="modSearchInput" class="search-input" placeholder="Filter by JAR name, SHA-1 hash, or Mod ID..." onkeyup="filterMods()">
        </div>
        <div class="filter-group">
          <span class="group-label" id="ui_lbl_status">Status:</span>
          <button class="filter-btn active" onclick="setModStatusFilter('all', this)" id="ui_btn_all_mods">All Mods (__TOTAL_JARS__)</button>
          <button class="filter-btn" onclick="setModStatusFilter('SUSPICIOUS', this)" id="ui_btn_susp_only">&#9888; Suspicious Only</button>
          <button class="filter-btn" onclick="setModStatusFilter('CLEAN', this)" id="ui_btn_clean_only">&#10004; Clean Only</button>
        </div>
      </div>
      <table class="mods-table">
        <thead>
          <tr>
            <th id="ui_th_file">File Name</th>
            <th id="ui_th_hash">SHA-1 Hash</th>
            <th id="ui_th_size">Size</th>
            <th id="ui_th_id">Mod ID</th>
            <th id="ui_th_status">Status</th>
          </tr>
        </thead>
        <tbody id="modsTableBody"></tbody>
      </table>
    </div>
    <div style="margin-top: 30px; padding: 18px 0; border-top: 1px solid var(--card-border); text-align: center; color: var(--text-muted); font-size: 12px; letter-spacing: 0.5px;">
      <span style="color: var(--neon-cyan); font-weight: 700;">VORTEX APEX (VORTEX-AC)</span> &bull; ADVANCED FORENSIC INTELLIGENCE SUITE &bull; <span style="color: #FFF; font-weight: 700;">Coded By BayrdY</span>
    </div>
  </div>



  <script>
    // [Vortex-Client-Translator-Engine] :: Authored & Built by BayrdY
    const findingsData = __JSON_FINDINGS__;
    const modsData = __JSON_MODS__;
    let currentSeverity = "all";
    let currentCategory = "all";
    let currentModStatus = "all";

    // Auto-detect browser language and translate UI + Detections
    const userLang = (navigator.language || navigator.userLanguage || "en").toLowerCase();
    const isTurkish = userLang.startsWith("tr");

        const trDictionary = {
      "Suspicious Native OS Command Execution in Bytecode": "Bytecode \u0130\u00E7inde \u015E\u00FCpheli \u0130\u015Fletim Sistemi Komutu \u00C7al\u0131\u015Ft\u0131rma",
      "Mod executes arbitrary operating system commands inside bytecode.": "Mod, Java bytecode i\u00E7erisinde i\u015Fletim sistemi komutlar\u0131 (ProcessBuilder / Runtime.exec) \u00E7al\u0131\u015Ft\u0131r\u0131yor.",
      "Runtime.getRuntime().exec() / ProcessBuilder call detected.": "Runtime.getRuntime().exec() veya ProcessBuilder \u00E7a\u011Fr\u0131s\u0131 tespit edildi.",
      "Cheat / Macro Signatures Detected in Mod": "Mod \u0130\u00E7inde Hile / Makro \u0130mzalar\u0131 Tespit Edildi",
      "Mod contains compiled Java bytecode signatures matching known PvP macros and cheat routines.": "Mod, bilinen PvP makrolar\u0131 ve hile rutinleriyle e\u015Fle\u015Fen derlenmi\u015F bytecode i\u00E7eriyor.",
      "Malicious Token Stealer / Webhook Exfiltration Detected": "Zararl\u0131 Token \u00C7al\u0131c\u0131 / Webhook S\u0131z\u0131nt\u0131s\u0131 Tespit Edildi",
      "Mod contains embedded Discord webhook or browser token exfiltration endpoints.": "Mod, g\u00F6m\u00FCl\u00FC Discord webhook veya taray\u0131c\u0131 token s\u0131zd\u0131rma u\u00E7 noktalar\u0131 i\u00E7eriyor.",
      "Commercial / Cheat Java Obfuscator Signature": "Ticari / Hile Java Karart\u0131c\u0131 (Obfuscator) \u0130mzas\u0131",
      "Mod was protected using obfuscators commonly used by commercial cheat developers.": "Mod, ticari hile geli\u015Ftiricileri taraf\u0131ndan kullan\u0131lan karart\u0131c\u0131larla korunmu\u015F.",
      "Trojan Mod Identity Spoofing": "Truva At\u0131 Mod Kimlik Sahtekarl\u0131\u011F\u0131",
      "Mod pretends to be legitimate but contains hidden malicious/cheat code.": "Mod me\u015Fru gibi davran\u0131yor ancak gizli zararl\u0131 veya hile kodu bar\u0131nd\u0131r\u0131yor.",
      "Suspicious Mod Download Source (Zone.Identifier ADS)": "\u015E\u00FCpheli Mod \u0130ndirme Kayna\u011F\u0131 (Zone.Identifier ADS)",
      "Mod was downloaded directly from an untrusted file-sharing or Discord CDN host.": "Mod, do\u011Frudan g\u00FCvenilmeyen dosya payla\u015F\u0131m sitesinden veya Discord CDN'den indirilmi\u015F.",
      "Active RAM Cheat Signature": "Canl\u0131 RAM Hile \u0130mzas\u0131",
      "Live unencrypted cheat pattern detected resident in javaw.exe RAM space.": "javaw.exe RAM belle\u011Finde \u015Fifrelenmemi\u015F canl\u0131 hile deseni tespit edildi.",
      "Untrusted / Injected DLL Loaded in Java": "Java'ya Y\u00FCklenen G\u00FCvenilmeyen / Enjekte Edilmi\u015F DLL",
      "Native module loaded into JVM address space from untrusted directory.": "G\u00FCvenilmeyen dizinden JVM adres alan\u0131na yerel mod\u00FCl y\u00FCklendi.",
      "Prefetch Execution Trace": "Prefetch \u00C7al\u0131\u015Ft\u0131rma \u0130zi",
      "Windows Prefetch recorded execution of known cheat executable.": "Windows Prefetch, bilinen hile dosyas\u0131n\u0131n \u00E7al\u0131\u015Ft\u0131r\u0131ld\u0131\u011F\u0131n\u0131 kaydetti.",
      "BAM Execution Record": "BAM \u00C7al\u0131\u015Ft\u0131rma Kayd\u0131",
      "Background Activity Moderator recorded execution of cheat executable.": "BAM (Arka Plan Aktivite Y\u00F6neticisi), hile \u00E7al\u0131\u015Ft\u0131r\u0131ld\u0131\u011F\u0131n\u0131 kaydetti.",
      "UserAssist GUI Execution Record": "UserAssist Aray\u00FCz \u00C7al\u0131\u015Ft\u0131rma Kayd\u0131",
      "UserAssist recorded GUI launch of cheat executable.": "UserAssist, hilenin grafik aray\u00FCz\u00FCnden ba\u015Flat\u0131ld\u0131\u011F\u0131n\u0131 kaydetti.",
      "MUICache Execution Trace": "MUICache \u00C7al\u0131\u015Ft\u0131rma \u0130zi",
      "Application execution record found in MUICache.": "MUICache i\u00E7inde uygulama \u00E7al\u0131\u015Ft\u0131rma kayd\u0131 bulundu.",
      "Deleted Cheat in Recycle Bin": "Geri D\u00F6n\u00FC\u015F\u00FCm Kutusunda Silinmi\u015F Hile",
      "Deleted cheat executable or archive found resting in Recycle Bin.": "Geri D\u00F6n\u00FC\u015F\u00FCm Kutusunda silinmi\u015F hile dosyas\u0131 veya ar\u015Fivi bulundu.",
      "USN Journal Deleted File Record": "USN G\u00FCnl\u00FC\u011F\u00FC Silinmi\u015F Dosya Kayd\u0131",
      "NTFS USN Journal recorded recent deletion of cheat binary.": "NTFS USN De\u011Fi\u015Fiklik G\u00FCnl\u00FC\u011F\u00FC, hile dosyas\u0131n\u0131n yak\u0131n zamanda silindi\u011Fini kaydetti.",
      "Anti-Forensic Cleaner Command in PowerShell History": "PowerShell Ge\u00E7mi\u015Finde Temizleyici Komut",
      "PowerShell history contains evidence of log clearing or forensic journal purging.": "PowerShell ge\u00E7mi\u015Finde log temizleme veya g\u00FCnl\u00FCk silme komutlar\u0131 bulundu.",
      "Self-Destruct Cleaner Batch Script in %TEMP%": "%TEMP% Klas\u00F6r\u00FCnde Kendini Silen Temizleyici Batch Beti\u011Fi",
      "A self-deleting batch script commonly dropped by cheat self-destruct routines was discovered.": "Hile kendini imha rutinleri taraf\u0131ndan olu\u015Fturulan kendini silen batch beti\u011Fi bulundu.",
      "Security Audit Log Cleared (Event 1102)": "G\u00FCvenlik Denetim G\u00FCnl\u00FC\u011F\u00FC Temizlendi (Event 1102)",
      "The Windows Security Event Log was manually purged.": "Windows G\u00FCvenlik G\u00FCnl\u00FC\u011F\u00FC manuel olarak temizlendi.",
      "Vulnerable / Bypass Kernel Driver Installed (Event 7045)": "Savunmas\u0131z / Bypass \u00C7ekirdek S\u00FCr\u00FCc\u00FCs\u00FC Y\u00FCklendi (Event 7045)",
      "A vulnerable kernel driver known for Anti-Cheat bypasses was registered as a service.": "Anti-Cheat atlatmalar\u0131 i\u00E7in kullan\u0131lan savunmas\u0131z bir \u00E7ekirdek s\u00FCr\u00FCc\u00FCs\u00FC hizmet olarak y\u00FCklendi.",
      "Suspicious Windows Defender Path Exclusion": "Windows Defender \u015E\u00FCpheli Dizin D\u0131\u015Flama Tespiti",
      "A critical user/system folder is excluded from Windows Defender real-time scanning.": "Kritik bir kullan\u0131c\u0131/sistem dizini Windows Defender ger\u00E7ek zamanl\u0131 taramas\u0131ndan hari\u00E7 tutulmu\u015F.",
      "Malicious Windows Defender Extension Exclusion": "Windows Defender Zararl\u0131 Uzant\u0131 D\u0131\u015Flama Tespiti",
      "Executable or script extensions are excluded from antivirus scanning.": "Y\u00FCr\u00FCt\u00FClebilir dosya veya betik uzant\u0131lar\u0131 antivir\u00FCs taramas\u0131ndan hari\u00E7 tutulmu\u015F.",
      "Windows Defender Process Exclusion": "Windows Defender S\u00FCre\u00E7 D\u0131\u015Flama Tespiti",
      "A process binary is excluded from Windows Defender monitoring.": "Bir program s\u00FCreci Windows Defender g\u00F6zetiminden hari\u00E7 tutulmu\u015F.",
      "Cheat / Ghost Client Domain in DNS Cache": "DNS \u00D6nbelle\u011Finde Hile / Ghost Client Alan Ad\u0131",
      "Computer resolved DNS query for a known cheat authentication server or website.": "Bilgisayar, bilinen bir hile do\u011Frulama sunucusu veya web sitesi i\u00E7in DNS sorgusu ger\u00E7ekle\u015Ftirmi\u015F.",
      "Windows TestSigning Mode Active (Kernel Driver Bypass)": "Windows TestSigning Modu Aktif (\u00C7ekirdek S\u00FCr\u00FCc\u00FC Bypass)",
      "Windows is running in TestSigning mode allowing unsigned kernel-mode drivers to load.": "Windows, imzas\u0131z \u00E7ekirdek s\u00FCr\u00FCc\u00FClerinin y\u00FCklenmesine izin veren TestSigning modunda \u00E7al\u0131\u015F\u0131yor.",
      "Driver Integrity Checks Disabled (NoIntegrityChecks)": "S\u00FCr\u00FCc\u00FC B\u00FCt\u00FCnl\u00FCk Denetimleri Devre D\u0131\u015F\u0131",
      "Windows kernel integrity checks have been explicitly disabled.": "Windows \u00E7ekirdek b\u00FCt\u00FCnl\u00FCk denetimleri a\u00E7\u0131k\u00E7a devre d\u0131\u015F\u0131 b\u0131rak\u0131lm\u0131\u015F.",
      "Kernel Debugging Enabled": "\u00C7ekirdek Hata Ay\u0131klama (Kernel Debug) Aktif",
      "Windows Kernel Debugger is active, which can be leveraged for cheat memory manipulation.": "Hile bellek manip\u00FClasyonu i\u00E7in kullan\u0131labilecek Windows Kernel Debugger aktif durumda.",
      "Cheat File Selected in Windows Open/Save Dialog": "Windows Dosya Se\u00E7im Penceresinde Hile Dosyas\u0131 Se\u00E7ilmi\u015F",
      "User selected a cheat binary in a Windows file picker dialog (ComDlg32 MRU).": "Kullan\u0131c\u0131 bir Windows dosya se\u00E7ici penceresinde hile dosyas\u0131 se\u00E7mi\u015F (ComDlg32 MRU).",
      "Suspicious RegEdit Navigation / Cleanup Trace": "\u015E\u00FCpheli RegEdit Gezinme / Temizleme \u0130zi",
      "Windows Registry Editor LastKey points to a cheat search or key deletion attempt.": "Windows Kay\u0131t Defteri D\u00FCzenleyicisi son aranan anahtar\u0131, hile aramas\u0131 veya silme giri\u015Fimine i\u015Faret ediyor.",
      "Suspicious DirectX / OpenGL Graphics Hook Injected": "\u015E\u00FCpheli DirectX / OpenGL Grafik Kancas\u0131 Enjekte Edildi",
      "An unverified graphics/render hook module was injected into Minecraft JVM from a user directory.": "Kullan\u0131c\u0131 dizininden Minecraft JVM'ye do\u011Frulanmam\u0131\u015F bir grafik kanca mod\u00FCl\u00FC enjekte edilmi\u015F.",
      "Opened Cheat Archive in WinRAR / 7-Zip History": "WinRAR / 7-Zip Ge\u00E7mi\u015Finde A\u00E7\u0131lm\u0131\u015F Hile Ar\u015Fivi",
      "Windows registry recorded opening of a cheat archive package.": "Windows kay\u0131t defteri, hile ar\u015Fiv paketinin a\u00E7\u0131ld\u0131\u011F\u0131n\u0131 kaydetti.",
      "Hardware Macro / LUA AutoClicker Script Detected": "Donan\u0131m Makrosu / LUA AutoClicker Beti\u011Fi Tespit Edildi",
      "A gaming mouse/keyboard macro script designed for automated CPS or recoil compensation was found.": "Otomatik t\u0131klama veya makro i\u00E7in geli\u015Ftirilen fare/klavye donan\u0131m beti\u011Fi bulundu.",
      "Suspicious Cheat Payload / Webhook in Clipboard": "Panoda \u015E\u00FCpheli Hile Y\u00FCk\u00FC / Webhook Bulundu",
      "Windows clipboard contained active cheat commands, authorization tokens, or webhook endpoints.": "Windows panosunda hile komutlar\u0131, yetkilendirme anahtar\u0131 veya webhook ba\u011Flant\u0131s\u0131 bulundu.",
      "Cheat Keyword Search in Everything History": "Everything Arama Ge\u00E7mi\u015Finde Hile / Temizleyici Arama \u0130zi",
      "User searched for cheat binaries or forensic cleaner tools in Voidtools Everything.": "Kullan\u0131c\u0131 Everything uygulamas\u0131nda hile veya temizleyici aramalar\u0131 yapm\u0131\u015F.",
      "Cheat Download Trace in Web Browser History": "Web Taray\u0131c\u0131s\u0131 Ge\u00E7mi\u015Finde Hile \u0130ndirme \u0130zi",
      "Browser history contains recorded download of known cheat client or injector.": "Taray\u0131c\u0131 ge\u00E7mi\u015Finde bilinen bir hile istemcisi veya injector indirme kayd\u0131 bulundu."
    };

    function translateText(str) {
      if (!isTurkish || !str) return str;
      for (const [en, tr] of Object.entries(trDictionary)) {
        if (str.indexOf(en) !== -1) {
          str = str.replace(en, tr);
        }
      }
      return str;
    }

    if (isTurkish) {
      document.getElementById("ui_title").innerText = "VORTEX APEX ANTICHEAT H\u0130LE RAPORU";
      document.getElementById("ui_user_lbl").innerText = "Hedef Kullan\u0131c\u0131:";
      document.getElementById("ui_host_lbl").innerText = "Cihaz:";
      document.getElementById("ui_date_lbl").innerText = "Tarih:";
      document.getElementById("ui_btn_export").innerText = "JSON D\u0131\u015Fa Aktar";
      document.getElementById("ui_btn_print").innerText = "Yazd\u0131r / PDF";
      document.getElementById("ui_stat_crit").innerText = "Kritik Tehditler";
      document.getElementById("ui_stat_high").innerText = "Y\u00FCksek Risk";
      document.getElementById("ui_stat_mods").innerText = "Taranan Modlar";
      document.getElementById("ui_stat_speed").innerText = "Tarama H\u0131z\u0131";
      document.getElementById("ui_tab_findings").innerText = "Tespitler & Anomaliler";
      document.getElementById("ui_tab_mods").innerText = "Mod Envanteri";
      document.getElementById("ui_lbl_sev").innerText = "\u00D6nem Derecesi:";
      document.getElementById("ui_btn_all_sev").innerText = "T\u00FCm\u00FC (" + findingsData.length + ")";
      document.getElementById("ui_btn_crit").innerText = "Kritik";
      document.getElementById("ui_btn_high").innerText = "Y\u00FCksek";
      document.getElementById("ui_btn_med").innerText = "Orta";
      document.getElementById("ui_lbl_cat").innerText = "Kategori:";
      document.getElementById("ui_btn_all_cat").innerText = "T\u00FCm Kategoriler";
      document.getElementById("ui_btn_mem").innerText = "RAM / Bellek";
      document.getElementById("ui_btn_clean").innerText = "Cleaners / Temizleyiciler";
      if (document.getElementById("ui_btn_sec")) document.getElementById("ui_btn_sec").innerText = "G\u00FCvenlik & \u00C7ekirdek";
      if (document.getElementById("ui_btn_net")) document.getElementById("ui_btn_net").innerText = "A\u011F & DNS \u00D6nbellek";
      document.getElementById("ui_lbl_status").innerText = "Durum:";
      document.getElementById("ui_btn_all_mods").innerText = "T\u00FCm Modlar (" + modsData.length + ")";
      document.getElementById("ui_btn_susp_only").innerHTML = "&#9888; Yaln\u0131zca \u015E\u00FCpheli / Hile";
      document.getElementById("ui_btn_clean_only").innerHTML = "&#10004; Yaln\u0131zca Temiz";
      document.getElementById("ui_th_file").innerText = "Dosya Ad\u0131";
      document.getElementById("ui_th_hash").innerText = "SHA-1 \u00D6zeti";
      document.getElementById("ui_th_size").innerText = "Boyut";
      document.getElementById("ui_th_id").innerText = "Mod ID";
      document.getElementById("ui_th_status").innerText = "Durum";
      document.getElementById("searchInput").placeholder = "Hile ad\u0131, imza, dosya yolu veya kan\u0131t ara...";
      document.getElementById("modSearchInput").placeholder = "JAR ad\u0131, SHA-1 \u00F6zeti veya Mod ID ile filtrele...";
    }

    function filterFindingsData() {
      const q = document.getElementById("searchInput").value.toLowerCase();
      return findingsData.filter(function(f) {
        const matchSev = currentSeverity === "all" || f.Severity === currentSeverity;
        const matchCat = currentCategory === "all" || f.Category === currentCategory;
        const matchQ = !q || f.Title.toLowerCase().indexOf(q) !== -1 || f.Description.toLowerCase().indexOf(q) !== -1 || f.Evidence.toLowerCase().indexOf(q) !== -1 || f.TargetPath.toLowerCase().indexOf(q) !== -1;
        return matchSev && matchCat && matchQ;
      });
    }

    function renderFindings(items) {
      const container = document.getElementById("findingsList");
      if (!items || items.length === 0) {
        const noTitle = isTurkish ? "Tehdit Bulunamad\u0131" : "No Threats Detected";
        const noDesc = isTurkish ? "Sistem temiz ve me\u015Fru \u00E7al\u0131\u015Fma ortam\u0131 standartlar\u0131yla e\u015Fle\u015Fiyor." : "System is clean and matches legitimate baseline standards.";
        container.innerHTML = '<div class="f-card" style="text-align:center; padding: 40px; color: var(--neon-green);"><h3>' + noTitle + '</h3><p style="color: var(--text-muted); margin-top: 8px;">' + noDesc + '</p></div>';
        return;
      }
      container.innerHTML = items.map(function(f) {
        const title = translateText(f.Title);
        const desc = translateText(f.Description);
        const evLabel = isTurkish ? "KANIT:" : "EVIDENCE:";
        const catLabel = isTurkish ? "Kategori:" : "Category:";
        const tgtLabel = isTurkish ? "Hedef:" : "Target:";
        const timeLabel = isTurkish ? "Zaman:" : "Time:";
        const copyTxt = isTurkish ? "Kopyala" : "Copy";

        return '<div class="f-card ' + f.Severity + '">' +
          '<div class="f-header">' +
            '<div class="f-title">' + title + '</div>' +
            '<span class="badge ' + f.Severity + '">' + f.Severity + '</span>' +
          '</div>' +
          '<div class="f-desc">' + desc + '</div>' +
          '<div class="f-evidence">' +
            '<span class="mono"><b>' + evLabel + '</b> ' + f.Evidence + '</span>' +
            '<button class="copy-btn" onclick="copyText(\'' + encodeURIComponent(f.Evidence) + '\')">' + copyTxt + '</button>' +
          '</div>' +
          '<div class="f-footer">' +
            '<span><b>' + catLabel + '</b> ' + f.Category + '</span>' +
            '<span><b>' + tgtLabel + '</b> ' + f.TargetPath + '</span>' +
            '<span><b>' + timeLabel + '</b> ' + f.Timestamp + '</span>' +
          '</div>' +
        '</div>';
      }).join("");
    }

    function filterModsData() {
      const q = document.getElementById("modSearchInput").value.toLowerCase();
      return modsData.filter(function(m) {
        const matchStatus = currentModStatus === "all" || m.Status === currentModStatus;
        const matchQ = !q || m.FileName.toLowerCase().indexOf(q) !== -1 || m.Sha1.toLowerCase().indexOf(q) !== -1 || m.ClaimedId.toLowerCase().indexOf(q) !== -1;
        return matchStatus && matchQ;
      });
    }

    function renderMods(items) {
      const tbody = document.getElementById("modsTableBody");
      if (!items || items.length === 0) {
        const noMods = isTurkish ? "Filtrelere uygun JAR ar\u015Fivi bulunamad\u0131." : "No JAR archives matched current filters.";
        tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; padding: 25px; color: var(--text-muted);">' + noMods + '</td></tr>';
        return;
      }
      tbody.innerHTML = items.map(function(m) {
        const statusClass = m.Status === "CLEAN" ? "tag-clean" : "tag-susp";
        const statusLabel = isTurkish ? (m.Status === "CLEAN" ? "TEM\u0130Z" : "\u015E\u00DCPHEL\u0130") : m.Status;
        const sizeKB = (m.Size / 1024).toFixed(1) + " KB";
        return '<tr>' +
          '<td><b>' + m.FileName + '</b></td>' +
          '<td class="mono" style="font-size: 11px; color: #A0C0E0;">' + (m.Sha1 || "N/A") + '</td>' +
          '<td>' + sizeKB + '</td>' +
          '<td>' + m.ClaimedId + '</td>' +
          '<td><span class="' + statusClass + '">' + statusLabel + '</span></td>' +
        '</tr>';
      }).join("");
    }

    function filterFindings() {
      renderFindings(filterFindingsData());
    }

    function setSeverityFilter(sev, btn) {
      currentSeverity = sev;
      btn.parentElement.querySelectorAll(".filter-btn").forEach(function(b) { b.classList.remove("active"); });
      btn.classList.add("active");
      filterFindings();
    }

    function setCategoryFilter(cat, btn) {
      currentCategory = cat;
      btn.parentElement.querySelectorAll(".filter-btn").forEach(function(b) { b.classList.remove("active"); });
      btn.classList.add("active");
      filterFindings();
    }

    function filterMods() {
      renderMods(filterModsData());
    }

    function setModStatusFilter(st, btn) {
      currentModStatus = st;
      btn.parentElement.querySelectorAll(".filter-btn").forEach(function(b) { b.classList.remove("active"); });
      btn.classList.add("active");
      filterMods();
    }

    function switchTab(tabId, btn) {
      document.querySelectorAll(".tab-pane").forEach(function(p) { p.classList.remove("active"); });
      document.querySelectorAll(".tab-btn").forEach(function(b) { b.classList.remove("active"); });
      document.getElementById(tabId).classList.add("active");
      btn.classList.add("active");
    }

    function copyText(encoded) {
      navigator.clipboard.writeText(decodeURIComponent(encoded));
      alert(isTurkish ? "Kan\u0131t panoya kopyaland\u0131!" : "Evidence copied to clipboard!");
    }

    function copyReportJson() {
      const blob = new Blob([JSON.stringify({ findings: findingsData, mods: modsData }, null, 2)], { type: "application/json" });
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = "Vortex_Report.json";
      a.click();
    }

    renderFindings(findingsData);
    renderMods(modsData);
  </script>
</body>
</html>
'@

    $renderedHtml = $htmlTemplate.
        Replace('__USER__', $env:USERNAME).
        Replace('__HOST__', $env:COMPUTERNAME).
        Replace('__TIMESTAMP__', (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')).
        Replace('__GAUGE_COLOR__', $gaugeColor).
        Replace('__GAUGE_OFFSET__', "$gaugeOffset").
        Replace('__SCORE__', "$score").
        Replace('__VERDICT__', $verdictText).
        Replace('__CRIT__', "$critCount").
        Replace('__HIGH__', "$highCount").
        Replace('__MED__', "$medCount").
        Replace('__TOTAL_JARS__', "$totalJars").
        Replace('__ELAPSED__', "$elapsedSec").
        Replace('__FINDINGS_COUNT__', "$($findings.Count)").
        Replace('__JSON_FINDINGS__', $jsonFindings).
        Replace('__JSON_MODS__', $jsonMods)

    [System.IO.File]::WriteAllText($reportPath, $renderedHtml, [System.Text.UTF8Encoding]::new($true))
    Write-Host "`n  [+] [HTML REPORT] Saved to: $reportPath" -ForegroundColor Cyan
    try {
        if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
            Start-Process $reportPath
        }
    } catch { }
}

# Optional Discord Webhook Notification
if ($DiscordWebhook) {
    try {
        $embed = @{
            title = "Vortex-AC Scan Report"
            description = "Scan completed for **$([Environment]::UserName)** on **$([Environment]::MachineName)**"
            color = if ($critCount -gt 0) { 16711765 } elseif ($highCount -gt 0) { 16758784 } else { 65443 }
            fields = @(
                @{ name = "Verdict"; value = $verdictText; inline = $true },
                @{ name = "Threat Score"; value = "$score / 100"; inline = $true },
                @{ name = "Total Threats"; value = "$($findings.Count)"; inline = $true }
            )
            footer = @{ text = "Vortex Forensics Engine • Coded By BayrdY" }
        }
        $payload = @{ embeds = @($embed) } | ConvertTo-Json -Depth 5
        Invoke-RestMethod -Uri $DiscordWebhook -Method Post -Body $payload -ContentType "application/json" | Out-Null
        Write-Host "  [+] [DISCORD] Scan summary posted to Discord Webhook." -ForegroundColor Green
    } catch {
        Write-Host "  [!] Failed to post Discord Webhook: $_" -ForegroundColor Yellow
    }
}

Write-Host "`n  [+] Analysis complete! [Coded By BayrdY] - Press Enter to exit..." -ForegroundColor Green
try {
    $null = Read-Host
} catch {
    Start-Sleep -Seconds 10
}
