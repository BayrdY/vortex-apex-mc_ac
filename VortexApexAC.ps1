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

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ----------------- Enforce Administrator Mode -----------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "`n [*] Yonetici (Administrator) izni gerekiyor, yetki yukseltiliyor..." -ForegroundColor Cyan
    try {
        if ($MyInvocation.MyCommand.Path) {
            $argList = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
            if ($TargetFolder) { $argList += " -TargetFolder `"$TargetFolder`"" }
            if ($FullScan) { $argList += " -FullScan" }
            if ($NoHtmlReport) { $argList += " -NoHtmlReport" }
            if ($DiscordWebhook) { $argList += " -DiscordWebhook `"$DiscordWebhook`"" }
            
            Start-Process powershell.exe -ArgumentList $argList -Verb RunAs -ErrorAction Stop
            return
        } else {
            # In-memory execution (irm | iex)
            $remoteCmd = "irm https://raw.githubusercontent.com/BayrdY/vortex-apex-mc_ac/main/VortexApexAC.ps1 | iex"
            Start-Process powershell.exe -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -Command `"$remoteCmd`"" -Verb RunAs -ErrorAction Stop
            return
        }
    } catch {
        Write-Host "`n [!] KRITIK HATA: Yonetici (Administrator) yetkileri zorunludur." -ForegroundColor Red
        Write-Host " [!] Windows UAC izni verilmedi veya yetki yukseltme basarisiz oldu." -ForegroundColor Yellow
        Write-Host " [!] Lutfen PowerShell veya CMD'yi 'Yonetici Olarak Calistir' ile acin." -ForegroundColor Yellow
        Write-Host " [!] Coded By BayrdY" -ForegroundColor Cyan
        Write-Host "`n Kapatmak icin Enter tusuna basin..." -ForegroundColor Gray
        $null = Read-Host
        return
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
        public static class FastCheatMatcher {
        private static HashSet<string> _exactNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        private static List<string> _compoundPatterns = new List<string>();

        public static void Initialize(string[] signatures) {
            _exactNames.Clear();
            _compoundPatterns.Clear();

            foreach (var s in signatures) {
                if (string.IsNullOrEmpty(s) || s.Length < 3) continue;
                string clean = s.Trim();
                _exactNames.Add(clean);
                if (clean.Contains(" ") || clean.Contains("-") || clean.Contains("_")) {
                    _compoundPatterns.Add(clean);
                }
            }
        }

        public static string FindMatch(string text) {
            if (string.IsNullOrEmpty(text)) return null;

            // Direct whole-string match
            if (_exactNames.Contains(text)) return text;

            // Tokenized word boundaries match
            char[] delimiters = new char[] { ' ', '\t', '\r', '\n', '\\', '/', '-', '_', '.', ':', ',', '|', '(', ')', '[', ']' };
            string[] tokens = text.Split(delimiters, StringSplitOptions.RemoveEmptyEntries);

            foreach (var token in tokens) {
                if (token.Length >= 4 && _exactNames.Contains(token)) {
                    return token;
                }
            }

            // Two-word combination token check (e.g. "Wurst Client", "Rise 6.0")
            for (int i = 0; i < tokens.Length - 1; i++) {
                string twoWords = tokens[i] + " " + tokens[i + 1];
                if (_exactNames.Contains(twoWords)) return twoWords;
                string joined = tokens[i] + tokens[i + 1];
                if (_exactNames.Contains(joined)) return joined;
            }

            // Substring check for compound patterns only
            string lower = text.ToLowerInvariant();
            foreach (var cp in _compoundPatterns) {
                if (cp.Length >= 5 && lower.Contains(cp.ToLowerInvariant())) {
                    return cp;
                }
            }

            return null;
        }
    }

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
                                          pathLower.Contains("loom-cache") ||
                                          pathLower.Contains("\\.minecraft\\versions\\") ||
                                          pathLower.Contains("/.minecraft/versions/") ||
                                          pathLower.Contains("\\.minecraft\\libraries\\") ||
                                          pathLower.Contains("/.minecraft/libraries/") ||
                                          pathLower.Contains("modrinthapp\\meta\\libraries") ||
                                          pathLower.Contains("optifine") ||
                                          pathLower.Contains("tl_skin") ||
                                          pathLower.Contains("\\plugins\\") ||
                                          pathLower.Contains("/plugins/") ||
                                          pathLower.Contains("grimac") ||
                                          pathLower.Contains("luckperms") ||
                                          pathLower.Contains("discordsrv") ||
                                          pathLower.Contains("essentials");

                bool isServerPlugin = pathLower.Contains("\\plugins\\") || 
                                      pathLower.Contains("/plugins/") ||
                                      pathLower.Contains("grimac") ||
                                      pathLower.Contains("discordsrv") ||
                                      pathLower.Contains("luckperms") ||
                                      pathLower.Contains("essentials") ||
                                      pathLower.Contains("worldedit") ||
                                      pathLower.Contains("farmcontrol") ||
                                      pathLower.Contains("gsit");

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
                                            if (!isServerPlugin) {
                                                foreach (var p in macroPatterns) {
                                                    if (!matchedMacrosLocal.Contains(p) && normVal.IndexOf(p, StringComparison.OrdinalIgnoreCase) >= 0) {
                                                        matchedMacrosLocal.Add(p);
                                                    }
                                                }
                                            }

                                            // Token Stealers / Webhooks
                                            if (!isServerPlugin && !isDevToolOrWrapper && (
                                                normVal.IndexOf("discord.com/api/webhooks", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                normVal.IndexOf("discordapp.com/api/webhooks", StringComparison.OrdinalIgnoreCase) >= 0)) {
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
                                                normVal.IndexOf("cmd.exe /c", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                normVal.IndexOf("powershell -ep", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                normVal.IndexOf("vssadmin delete", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                normVal.IndexOf("wevtutil cl", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                normVal.IndexOf("certutil -urlcache", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                normVal.IndexOf("rundll32.exe", StringComparison.OrdinalIgnoreCase) >= 0)) {
                                                summary.HasRuntimeExec = true;
                                            }
                                        }
                                    }
                                }
                            } catch { }
                        }

                        if (!isServerPlugin) {
                            summary.MatchedMacros.AddRange(matchedMacrosLocal);
                        }
                        summary.MatchedObfuscators.AddRange(matchedObfLocal);

                        // Trojan Spoof Check
                        if (!string.IsNullOrEmpty(summary.ClaimedModId) && legitSet.Contains(summary.ClaimedModId)) {
                            if (summary.MatchedMacros.Count > 0 || summary.HasTokenStealer) {
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
    "0x3 Client", "0x3Client", "0xClient", "1.8.9 Ghost", "1337 Client", "1337Client",
    "1337Loader", "1Tap Client", "1TapClient", "1TapLoader", "200IQ Client", "200IQClient",
    "200IQLoader", "24/7 Client", "24/7Client", "24/7Loader", "2B2T Utility", "303Hack",
    "3arthh4ck Newbase", "3earthh4ck (Phobos Clean)", "420 Client", "420Client", "420Loader", "7G-Client",
    "888 Client", "888Client", "888Loader", "8Ball Client", "8BallClient", "8BallLoader",
    "999 Client", "999Client", "999Loader", "AbHack", "Abyssal", "Ace Client",
    "AceClient", "AceLoader", "Acid Client", "AcidClient", "AcidLoader", "Action Client",
    "ActionClient", "ActionLoader", "Afterglow", "Aia Client", "AiaClient", "AiaLoader",
    "Airflow Client", "AirflowClient", "AirflowLoader", "Akrien", "Akrien Premium", "Alchemist",
    "Alis Client", "AlisClient", "AlisLoader", "Alopex", "Alpha Client", "AlphaClient",
    "AlphaLoader", "Amber Client", "Amber Ghost", "AmberClient", "AmberLoader", "Ambien Client",
    "AmbienClient", "AmbienLoader", "Amethyst", "Amon Client", "AmonClient", "AmonLoader",
    "Anarchist", "Anarchy Client", "AnarchyClient", "AnarchyLoader", "Anathema", "Angel Client",
    "AngelClient", "AngelLoader", "Anims Client", "AnimsClient", "AnimsLoader", "Annihilation Client",
    "AnnihilationClient", "AnnihilationLoader", "Anonymous Client", "AnonymousClient", "AnonymousLoader", "Antares",
    "Anticheat Bypass Client", "Anticheat BypassClient", "Anticheat BypassLoader", "AntiGrief Client", "AntiGriefClient", "AntiGriefLoader",
    "AntiKik", "Apex Client", "Apex Ghost", "ApexClient", "ApexLoader", "Apollo Client",
    "ApolloClient", "ApolloLoader", "Aqua Client", "AquaClient", "AquaLoader", "Aqueous",
    "Arcane Client", "ArcaneClient", "ArcaneLoader", "Ares Client", "Ares Utility", "AresClient",
    "AresLoader", "Aristois", "Aristois Fabric", "Arkhack", "Artemis", "Asgard Client",
    "AsgardClient", "AsgardLoader", "Astolfo", "Astolfo Leak", "Astral Client", "AstralClient",
    "AstralLoader", "Astro Client", "AstroClient", "AstroLoader", "Athena Client", "AthenaClient",
    "AthenaLoader", "Atlas Client", "AtlasClient", "AtlasLoader", "Atomic Client", "AtomicClient",
    "AtomicLoader", "Aura Client", "AuraClient", "AuraLoader", "Aurora Client", "AuroraClient",
    "AuroraLoader", "Automatic Client", "AutomaticClient", "AutomaticLoader", "Autumn Client", "AutumnClient",
    "AutumnLoader", "Avanguard", "Avatar Client", "AvatarClient", "AvatarLoader", "Avenue Client",
    "AvenueClient", "AvenueLoader", "Awaken", "Axe Client", "AxeClient", "AxeLoader",
    "Axolotl Client", "AxolotlClient", "AxolotlLoader", "Azoer Client", "AzoerClient", "AzoerLoader",
    "Babajee Client", "BabajeeClient", "BabajeeLoader", "Banana+ (Meteor Addon)", "Bape Client", "BapeClient",
    "BapeLoader", "Baritone Client", "BaritoneClient", "BaseFinder Client", "BaseFinderClient", "BaseFinderLoader",
    "Basic Client", "BasicClient", "BasicLoader", "Bedwars Master", "Bee Client", "BeeClient",
    "BeeLoader", "Beep Client", "BeepClient", "BeepLoader", "Bell Client", "BellClient",
    "BellLoader", "Beta Client", "BetaClient", "BetaLoader", "BetterMinecraft Hack", "Bizarre Client",
    "BizarreClient", "BizarreLoader", "Blackout Client", "BlackoutClient", "BlackoutLoader", "Blade Client",
    "BladeClient", "BladeLoader", "Blast Client", "BlastClient", "BlastLoader", "BleachHack",
    "BleachHack Modern", "Bleed Client", "BleedClient", "BleedLoader", "Blick Client", "BlickClient",
    "BlickLoader", "Blind Client", "BlindClient", "BlindLoader", "Blitz Client", "BlitzClient",
    "BlitzLoader", "Blood Client", "BloodClient", "BloodLoader", "Bloom Client", "BloomClient",
    "BloomLoader", "Blue Client", "BlueClient", "BlueLoader", "Blur Client", "BlurClient",
    "BlurLoader", "Bolt Client", "BoltClient", "BoltLoader", "Bounce Client", "BounceClient",
    "BounceLoader", "Bound Client", "BoundClient", "BoundLoader", "BPF Client", "BPFClient",
    "BPFLoader", "Breeze Client", "Breeze Ghost", "BreezeClient", "BreezeLoader", "Bubble Client",
    "BubbleClient", "BubbleLoader", "Butter Client", "ButterClient", "Butterfly Ghost", "ButterLoader",
    "Byfron Client", "ByfronClient", "ByfronLoader", "Bypass Client", "BypassClient", "BypassLoader",
    "Byte Client", "ByteClient", "ByteLoader", "Cactus Client", "CactusClient", "CactusLoader",
    "Candy Client", "CandyClient", "CandyLoader", "Carbon Client", "Carbonate", "CarbonClient",
    "CarbonLoader", "Cardinal Client", "CardinalClient", "CardinalLoader", "Catalyst", "CatFeed",
    "Celestial", "Celestial Free", "Celestial Premium", "Centauri", "Centipede", "Ceres Client",
    "CeresClient", "CeresLoader", "Chain Client", "ChainClient", "ChainLoader", "Chaos Client",
    "ChaosClient", "ChaosHack", "ChaosLoader", "Cheetah Client", "CheetahClient", "CheetahLoader",
    "Cherry Client", "CherryClient", "CherryLoader", "Chill Client", "ChillClient", "ChillLoader",
    "Chocapic Client", "ChocapicClient", "ChocapicLoader", "ChromeLoader", "Chrysalis", "Cinnamon",
    "Cipher Client", "CipherClient", "CipherLoader", "Circuit Client", "CircuitClient", "Clean Client",
    "CleanClient", "CleanLoader", "Clear Client", "ClearClient", "ClearLoader", "Clicker Client",
    "ClickerClient", "ClickerLoader", "Climax Client", "ClimaxClient", "ClimaxLoader", "Clowns Client",
    "ClownsClient", "ClownsLoader", "Cobra Client", "CobraClient", "CobraLoader", "Coffee Client",
    "Coffee Ghost", "CoffeeClient", "CoffeeLoader", "Cold Client", "ColdClient", "ColdLoader",
    "Collision Client", "CollisionClient", "CollisionLoader", "Comet 1.20", "Comet Client", "Comet Fabric",
    "CometClient", "CometLoader", "Complex Client", "ComplexClient", "ComplexLoader", "Conceal Client",
    "ConcealClient", "ConcealLoader", "Concrete Client", "ConcreteClient", "ConcreteLoader", "Continuum Client",
    "ContinuumClient", "ContinuumLoader", "Control Client", "ControlClient", "ControlLoader", "Copper Client",
    "CopperClient", "CopperLoader", "Corgi Client", "CorgiClient", "CorgiLoader", "Cortex Client",
    "CortexClient", "CortexLoader", "Cosmic Client Hack", "Covenant", "CraftHack", "Crash Client",
    "CrashClient", "CrashLoader", "Creation Client", "CreationClient", "CreationLoader", "Crest Client",
    "CrestClient", "CrestLoader", "Critical Client", "CriticalClient", "CriticalLoader", "Cronus",
    "Crown Client", "CrownClient", "CrownLoader", "Crypt Ghost Client", "Crypt GhostClient", "Crypt GhostLoader",
    "Crystal Client Hack", "Cuber Client", "CuberClient", "CuberLoader", "Cyan Client", "CyanClient",
    "CyanLoader", "Cyber Client", "CyberClient", "CyberLoader", "Cyclone Client", "CycloneClient",
    "CycloneLoader", "Daemon Client", "DaemonClient", "DaemonLoader", "Daily Client", "DailyClient",
    "DailyLoader", "Dango Client", "DangoClient", "DangoLoader", "Dark Client", "Dark Light",
    "DarkClient", "DarkLoader", "DarkMatter", "Darkness Client", "DarknessClient", "DarknessLoader",
    "DarkRise", "Dash Client", "DashClient", "DashLoader", "Dawn Client", "DawnClient",
    "DawnLoader", "DeadCode", "DeadCode FunTime", "DeadCode Recode", "Death Client", "DeathClient",
    "DeathLoader", "Decay Client", "DecayClient", "DecayLoader", "Deep Client", "DeepClient",
    "DeepLoader", "Default Client", "DefaultClient", "DefaultLoader", "Defiance Client", "DefianceClient",
    "DefianceLoader", "Delta Client", "DeltaClient", "DeltaLoader", "Deluge Client", "DelugeClient",
    "DelugeLoader", "Demon Client", "DemonClient", "DemonLoader", "Derp Client", "DerpClient",
    "DerpLoader", "Descent Client", "DescentClient", "DescentLoader", "Desync Client", "DesyncClient",
    "DesyncLoader", "DevClient", "Diamond Client", "DiamondClient", "DiamondLoader", "Dimension Client",
    "DimensionClient", "DimensionLoader", "Dingle Client", "DingleClient", "DingleLoader", "Dionis Client",
    "DionisClient", "DionisLoader", "Discord Client Hack", "Divine Client", "DivineClient", "DivineLoader",
    "Division Client", "DivisionClient", "DivisionLoader", "Doge Client", "DogeClient", "DogeLoader",
    "Dolphin Client", "DolphinClient", "DolphinLoader", "Donut BaseFinder", "Donut Dupe Client", "Donut DupeClient",
    "Donut DupeLoader", "Donut SMP Utility", "Doomsday", "Dope Client", "DopeClient", "DopeLoader",
    "Drip Client", "Drip Lite", "Drip Lite Leak", "Drip Private", "DripClient", "DripLoader",
    "Drive Client", "DriveClient", "DriveLoader", "Drop Client", "DropClient", "DropLoader",
    "Duck Client", "DuckClient", "DuckLoader", "Dusk Client", "DuskClient", "DuskLoader",
    "Dust Client", "DustClient", "DustLoader", "Dynamic Client", "DynamicClient", "DynamicLoader",
    "Dynasty Client", "DynastyClient", "DynastyLoader", "Eagle Client", "EagleClient", "EagleLoader",
    "Earth Client", "EarthClient", "Earthhack", "EarthLoader", "Easy Client", "EasyClient",
    "EasyLoader", "Eclipse Client", "EclipseClient", "EclipseLoader", "Eco Client", "EcoClient",
    "EcoLoader", "Eden Client", "EdenClient", "EdenLoader", "Edge Client", "EdgeClient",
    "EdgeLoader", "EGO Client", "EGOClient", "EGOLoader", "Elder Client", "ElderClient",
    "ElderLoader", "Element Client", "ElementClient", "ElementLoader", "Elite Client", "EliteClient",
    "EliteLoader", "Elysium Client", "ElysiumClient", "ElysiumLoader", "Ember Client", "EmberClient",
    "EmberLoader", "Emerald Client", "EmeraldClient", "EmeraldLoader", "Emotion Client", "EmotionClient",
    "EmotionLoader", "Empire Client", "EmpireClient", "EmpireLoader", "Enchant Client", "EnchantClient",
    "EnchantLoader", "Ender Client", "EnderClient", "EnderLoader", "Endex Client", "EndexClient",
    "EndexLoader", "Energy Client", "EnergyClient", "EnergyLoader", "Entropy Client", "Entropy Ghost",
    "EntropyClient", "EntropyLoader", "Envy Client", "EnvyClient", "EnvyLoader", "Eos Client",
    "EosClient", "EosLoader", "Epoch Client", "EpochClient", "EpochLoader", "Epsilon Client",
    "EpsilonClient", "EpsilonLoader", "Equal Client", "EqualClient", "EqualLoader", "Erebus Client",
    "ErebusClient", "ErebusLoader", "Erupt", "Escape Client", "EscapeClient", "EscapeLoader",
    "Essential Hack", "Esthetique", "Ether Ghost", "Ethereal Client", "EtherealClient", "EtherealLoader",
    "Ethics Client", "EthicsClient", "EthicsLoader", "Euphoria Client", "EuphoriaClient", "EuphoriaLoader",
    "Evictus Client", "EvictusClient", "EvictusLoader", "Evolution Client", "EvolutionClient", "EvolutionLoader",
    "Excellent", "Excellent Recode", "Exodus Client", "ExodusClient", "Exoteria Client", "ExoteriaClient",
    "ExoteriaLoader", "Exoware", "Expensive 2.0", "Expensive FunTime", "Expensive Recode", "Exploit Client",
    "ExploitClient", "ExploitLoader", "Express Client", "ExpressClient", "ExpressLoader", "Extasis",
    "Extension Client", "ExtensionClient", "Falcon Client", "FalconClient", "FalconLoader", "Fall Client",
    "FallClient", "FallLoader", "False Client", "FalseClient", "FalseLoader", "Fame Client",
    "FameClient", "FameLoader", "Family Client", "FamilyClient", "FamilyLoader", "Fast Client",
    "FastClient", "FastLoader", "Fatal Client", "FatalClient", "FatalLoader", "Fault Client",
    "FaultClient", "FaultLoader", "FDPClient", "FDPClient Recode", "Fear Client", "FearClient",
    "FearLoader", "Feather Client Hack", "Fedor Client", "FedorClient", "FedorLoader", "Feint Client",
    "FeintClient", "FeintLoader", "Felix Client", "FelixClient", "FelixLoader", "Fern Client",
    "FernClient", "FernLoader", "Field Client", "FieldClient", "FieldLoader", "Fiend Client",
    "FiendClient", "FiendLoader", "Final Client", "FinalClient", "FinalLoader", "Fine Client",
    "FineClient", "FineLoader", "Fire Client", "FireClient", "FireLoader", "Fish Client",
    "FishClient", "FishLoader", "Flame Client", "FlameClient", "FlameLoader", "Flare Client",
    "FlareClient", "FlareLoader", "Flash Client", "FlashClient", "FlashLoader", "Flat Client",
    "FlatClient", "FlatLoader", "Flex Client", "FlexClient", "FlexLoader", "Flick Client",
    "FlickClient", "FlickLoader", "Flight Client", "FlightClient", "FlightLoader", "Florence Client",
    "FlorenceClient", "FlorenceLoader", "Flow Client", "FlowClient", "FlowLoader", "Flux B13",
    "Flux Client", "FluxClient", "FluxLoader", "Fly Client", "FlyClient", "FlyLoader",
    "Focus Client", "FocusClient", "FocusLoader", "Force Client", "ForceClient", "ForceLoader",
    "ForgeHax", "Formula Client", "FormulaClient", "FormulaLoader", "Fox Client", "FoxClient",
    "FoxLoader", "Fragment Client", "FragmentClient", "FragmentLoader", "Frank Client", "FrankClient",
    "FrankLoader", "Freak Client", "FreakClient", "FreakLoader", "Free Client", "FreeClient",
    "FreeLoader", "Freeze Client", "FreezeClient", "FreezeLoader", "Frost Client", "Frostbite Client",
    "FrostbiteClient", "FrostbiteLoader", "FrostClient", "FrostLoader", "Frozen Client", "FrozenClient",
    "FrozenLoader", "Fuel Client", "FuelClient", "FuelLoader", "FunTime Bypass", "FunTime Client",
    "FunTime Skid", "FunTimeClient", "FunTimeLoader", "Fusion Client", "FusionClient", "FusionLoader",
    "Future 2.0", "Future Client", "Future Leak", "FutureClient", "FutureLoader", "Galaxy Client",
    "GalaxyClient", "GalaxyLoader", "Gamma Client", "GammaClient", "GammaLoader", "Gemini Client",
    "GeminiClient", "GeminiLoader", "Genesis Client", "GenesisClient", "GenesisLoader", "Ghost Client Mod 1.8.9",
    "GhostClient", "Ghostly Client", "GhostlyClient", "GhostlyLoader", "GhostWare", "Giga Client",
    "GigaClient", "GigaLoader", "Glint Client", "GlintClient", "GlintLoader", "Global Client",
    "GlobalClient", "GlobalLoader", "Gloomy Client", "GloomyClient", "GloomyLoader", "Glow Client",
    "GlowClient", "GlowLoader", "Glowstone Client", "GlowstoneClient", "GlowstoneLoader", "God Client",
    "GodClient", "GodLoader", "Gold Client", "GoldClient", "Golden Client", "GoldenClient",
    "GoldenLoader", "GoldLoader", "Goofy Client", "GoofyClient", "GoofyLoader", "Grace Client",
    "GraceClient", "GraceLoader", "Gram Client", "GramClient", "GramLoader", "Grand Client",
    "GrandClient", "GrandLoader", "Gravity Client", "GravityClient", "GravityLoader", "Green Client",
    "GreenClient", "GreenLoader", "Grid Client", "GridClient", "GridLoader", "Grim Client",
    "GrimClient", "GrimLoader", "Grizzly Client", "GrizzlyClient", "GrizzlyLoader", "Group Client",
    "GroupClient", "GroupLoader", "Guardian Client", "GuardianClient", "GuardianLoader", "Guild Client",
    "GuildClient", "GuildLoader", "Gungnir Client", "GungnirClient", "GungnirLoader", "Hades Client",
    "HadesClient", "HadesLoader", "Hake Client", "HakeClient", "HakeLoader", "Halo Client",
    "HaloClient", "HaloLoader", "Harbor Client", "HarborClient", "HarborLoader", "Harmony Client",
    "HarmonyClient", "HarmonyLoader", "Hate Client", "HateClient", "HateLoader", "Havoc Client",
    "HavocClient", "HavocLoader", "Hawk Client", "HawkClient", "HawkLoader", "Hazard Client",
    "HazardClient", "HazardLoader", "Hazel Client", "HazelClient", "HazelLoader", "Headless Client",
    "HeadlessClient", "HeadlessLoader", "Heaven Client", "HeavenClient", "HeavenLoader", "Heavy Client",
    "HeavyClient", "HeavyLoader", "Hectik Client", "HectikClient", "HectikLoader", "Helios Client",
    "HeliosClient", "HeliosLoader", "Helix Client", "HelixClient", "HelixLoader", "Hellcat Client",
    "HellcatClient", "HellcatLoader", "Hello Client", "HelloClient", "HelloLoader", "Hermes Client",
    "HermesClient", "HermesLoader", "Hero Client", "HeroClient", "HeroLoader", "Hex Client",
    "Hexagon Client", "HexagonClient", "HexagonLoader", "HexClient", "HexLoader", "High Client",
    "HighClient", "HighLoader", "Horizon Client", "HorizonClient", "HorizonLoader", "Hot Client",
    "HotClient", "HotLoader", "Houdini Client", "HoudiniClient", "HoudiniLoader", "Hurricane Client",
    "HurricaneClient", "HurricaneLoader", "Huzuni", "Huzuni VIP", "Hydra Client", "HydraClient",
    "HydraLoader", "Hyper Client", "HyperClient", "Hyperion Client", "HyperionClient", "HyperionLoader",
    "HyperLoader", "Hypixel Bypass Client", "Hypixel BypassClient", "Hypixel BypassLoader", "Hysteria Client", "HysteriaClient",
    "HysteriaLoader", "Ice Client", "Iceberg Client", "IcebergClient", "IcebergLoader", "IceClient",
    "IceLoader", "Icon Client", "IconClient", "IconLoader", "Ideal Client", "IdealClient",
    "IdealLoader", "Impact 4.9", "Impact Client", "Impact Fabric", "ImpactClient", "ImpactLoader",
    "Impulse Client", "ImpulseClient", "ImpulseLoader", "Incognito Client", "IncognitoClient", "IncognitoLoader",
    "Indigo Client", "IndigoClient", "IndigoLoader", "Inertia Client", "Inertia Ghost", "InertiaClient",
    "InertiaLoader", "Infinity Client", "InfinityClient", "InfinityLoader", "Inflation Client", "InflationClient",
    "InflationLoader", "Infra Client", "InfraClient", "InfraLoader", "Injection Client", "InjectionClient",
    "InjectionLoader", "Inos Client", "InosClient", "InosLoader", "Insane Client", "InsaneClient",
    "InsaneLoader", "Insecuria", "Insight Client", "InsightClient", "InsightLoader", "Instant Client",
    "InstantClient", "InstantLoader", "Intent Client", "IntentClient", "IntentLoader", "Interdiction",
    "Internal Client", "InternalClient", "InternalLoader", "Intersect Client", "IntersectClient", "IntersectLoader",
    "Interstellar Client", "InterstellarClient", "InterstellarLoader", "Invictus", "Ion Client", "IonClient",
    "IonLoader", "Iris Client", "IrisClient", "IrisLoader", "Iron Client", "IronClient",
    "IronLoader", "Ishtar Client", "IshtarClient", "IshtarLoader", "Jade Client", "JadeClient",
    "JadeLoader", "Jello Client", "Jello for Sigma", "JelloClient", "JelloLoader", "Jelly Client",
    "JellyClient", "JellyLoader", "Jet Client", "JetClient", "JetLoader", "Jex Client",
    "JexClient", "JexLoader", "Jigsaw Client", "Jigsaw Reloaded", "JigsawClient", "JigsawLoader",
    "Jinx Client", "JinxClient", "JinxLoader", "Joker Client", "JokerClient", "JokerLoader",
    "Joy Client", "JoyClient", "JoyLoader", "Juice Client", "Juice Ghost Client", "Juice GhostClient",
    "Juice GhostLoader", "JuiceClient", "JuiceLoader", "Julia Client", "JuliaClient", "JuliaLoader",
    "July Client", "JulyClient", "JulyLoader", "Jumbo Client", "JumboClient", "JumboLoader",
    "Jump Client", "JumpClient", "JumpLoader", "Jupiter Client", "JupiterClient", "JupiterLoader",
    "Justice Client", "JusticeClient", "JusticeLoader", "Juxta Client", "JuxtaClient", "JuxtaLoader",
    "Kaaba Client", "KaabaClient", "KaabaLoader", "Kaboom Client", "KaboomClient", "KaboomLoader",
    "Kagura Client", "KaguraClient", "KaguraLoader", "Kairi Client", "KairiClient", "KairiLoader",
    "Kami Blue", "Kami Client", "KAMI Client 1.12.2", "KamiClient", "KamiLoader", "Kangaroo Client",
    "KangarooClient", "KangarooLoader", "Karma Client", "KarmaClient", "KarmaLoader", "Katana Client",
    "KatanaClient", "KatanaLoader", "KDK Client", "KDKClient", "KDKLoader", "Keep Client",
    "KeepClient", "KeepLoader", "Kepler Client", "KeplerClient", "KeplerLoader", "Kilo Client",
    "Kilo Ghost", "KiloClient", "KiloLoader", "Kinetic Client", "KineticClient", "Kingdom Client",
    "KingdomClient", "KingdomLoader", "Kingpin Client", "KingpinClient", "KingpinLoader", "Kirka Client",
    "KirkaClient", "KirkaLoader", "Kiwi Client", "KiwiClient", "KiwiLoader", "Koid Clicker",
    "Konas", "Konas Leak", "Kronos Client", "KronosClient", "KronosLoader", "KuraHack",
    "KuraHack 1.12.2", "Kyro Client", "KyroClient", "KyroLoader", "LabyMod Hack Addons", "Lambda Client",
    "LambdaClient", "LambdaLoader", "Lance Client", "LanceClient", "LanceLoader", "Lapiz Client",
    "LapizClient", "LapizLoader", "Lava Client", "LavaClient", "LavaLoader", "Layer Client",
    "LayerClient", "LayerLoader", "Lazy Client", "LazyClient", "LazyLoader", "Leader Client",
    "LeaderClient", "LeaderLoader", "Leak Client", "LeakClient", "LeakLoader", "Legacy Client",
    "LegacyClient", "LegacyLoader", "Legend Client", "LegendClient", "LegendLoader", "Lemon Client",
    "LemonClient", "LemonLoader", "Leo Client", "LeoClient", "LeoLoader", "Lethal Client",
    "LethalClient", "LethalLoader", "Level Client", "LevelClient", "LevelLoader", "Levitate Client",
    "LevitateClient", "LevitateLoader", "Liberty Client", "LibertyClient", "LibertyLoader", "Life Client",
    "LifeClient", "LifeLoader", "Light Client", "LightClient", "LightLoader", "Lightning Client",
    "LightningClient", "LightningLoader", "Lillium Client", "LilliumClient", "LilliumLoader", "Lime Client",
    "LimeClient", "LimeLoader", "Limit Client", "LimitClient", "LimitLoader", "Line Client",
    "LineClient", "LineLoader", "Link Client", "LinkClient", "LinkLoader", "Lion Client",
    "LionClient", "LionLoader", "LiquidBounce", "LiquidBounce Next", "LiquidBounce Reborn", "LiquidBounce+",
    "LiquidBypass", "LiquidCloud", "Lithium Client", "LithiumClient", "LithiumLoader", "Logic Client",
    "LogicClient", "LogicLoader", "Lotus Client", "LotusClient", "LotusLoader", "Lucid Client",
    "LucidClient", "LucidLoader", "Lucifer Client", "LuciferClient", "LuciferLoader", "Lucky Client",
    "LuckyClient", "LuckyLoader", "Luigihack", "Lumina Client", "LuminaClient", "LuminaLoader",
    "Lunar Client Hack Mod", "Lunar Injector", "Lux Client", "LuxClient", "LuxLoader", "Lynx Client",
    "LynxClient", "LynxLoader", "Macro Client", "MacroClient", "MacroLoader", "Magic Client",
    "MagicClient", "MagicLoader", "Magnet Client", "MagnetClient", "MagnetLoader", "Majestic Client",
    "MajesticClient", "MajesticLoader", "Manga Client", "MangaClient", "MangaLoader", "Manifold Client",
    "ManifoldClient", "ManifoldLoader", "Mantis Client", "MantisClient", "MantisLoader", "Maple Client",
    "MapleClient", "MapleLoader", "Marble Client", "MarbleClient", "MarbleLoader", "Margin Client",
    "MarginClient", "MarginLoader", "Marine Client", "MarineClient", "MarineLoader", "MarkX Client",
    "MarkXClient", "MarkXLoader", "Mars Client", "MarsClient", "MarsLoader", "Marvel Client",
    "MarvelClient", "MarvelLoader", "Master Client", "MasterClient", "MasterLoader", "MatchD Client",
    "MatchDClient", "MatchDLoader", "Mathax Client", "MathaxClient", "MathaxLoader", "Matrix Bypass Client",
    "Matrix BypassClient", "Matrix BypassLoader", "Matrix Client", "MatrixClient", "MatrixLoader", "Matter Client",
    "MatterClient", "MatterLoader", "Maverick Client", "MaverickClient", "MaverickLoader", "Max Client",
    "MaxClient", "MaxLoader", "Mayhem Client", "MayhemClient", "MayhemLoader", "Medusa Client",
    "MedusaClient", "MedusaLoader", "Mega Client", "MegaClient", "MegaLoader", "Melt Client",
    "MeltClient", "MeltLoader", "Mercury Client", "MercuryClient", "MercuryLoader", "Merge Client",
    "MergeClient", "MergeLoader", "Merit Client", "MeritClient", "MeritLoader", "Mesh Client",
    "MeshClient", "MeshLoader", "Meta Client", "MetaClient", "MetaLoader", "Meteor Client",
    "Meteor Plus", "Meteor Reject", "Meteor TrouserStreak", "MeteorClient", "MeteorLoader", "Method Client",
    "MethodClient", "MethodLoader", "Micro Client", "MicroClient", "MicroLoader", "Midnight Client",
    "MidnightClient", "MidnightLoader", "Minced Client", "Minced FunTime", "MincedClient", "MincedLoader",
    "Mind Client", "MindClient", "MindLoader", "Mine Client", "MineClient", "MineCollapse",
    "MineLoader", "Mint Client", "MintClient", "MintLoader", "Miracle Client", "MiracleClient",
    "MiracleLoader", "Mirror Client", "MirrorClient", "MirrorLoader", "Misplace Client", "MisplaceClient",
    "MisplaceLoader", "Mist Client", "MistClient", "MistLoader", "Mix Client", "MixClient",
    "MixLoader", "Mob Client", "MobClient", "MobLoader", "Modest Client", "ModestClient",
    "ModestLoader", "Momentum Client", "MomentumClient", "MomentumLoader", "Monolith Client", "MonolithClient",
    "MonolithLoader", "Moon 3.0", "Moon Client", "MoonClient", "MoonLight Client", "MoonLightClient",
    "MoonLightLoader", "MoonLoader", "Morph Client", "MorphClient", "MorphLoader", "Motion Client",
    "MotionClient", "MotionLoader", "Moving Client", "MovingClient", "MovingLoader", "Mox Client",
    "MoxClient", "MoxLoader", "MRA Client", "MRAClient", "MRALoader", "Mugen Client",
    "MugenClient", "MugenLoader", "Muscle Client", "MuscleClient", "MuscleLoader", "Mushroom Client",
    "MushroomClient", "MushroomLoader", "Mystery Client", "MysteryClient", "MysteryLoader", "Nano Client",
    "NanoClient", "NanoLoader", "Native Client", "NativeClient", "NativeLoader", "Natura Client",
    "NaturaClient", "NaturaLoader", "Nebula Client", "NebulaClient", "NebulaLoader", "Nectar Client",
    "NectarClient", "NectarLoader", "Nelson Client", "NelsonClient", "NelsonLoader", "Nemesis Client",
    "NemesisClient", "NemesisLoader", "Neoforge Hack", "Neon Client", "NeonClient", "NeonLoader",
    "Neptune Client", "NeptuneClient", "NeptuneLoader", "Nerve Client", "NerveClient", "NerveLoader",
    "Neverland Client", "NeverlandClient", "NeverlandLoader", "Neverlose MC", "New Client", "NewClient",
    "NewLoader", "Nexus Client", "NexusClient", "NexusLoader", "Night Client", "NightClient",
    "NightLoader", "NightX Client", "NightXClient", "NightXLoader", "Nimble Client", "NimbleClient",
    "NimbleLoader", "Nimbus Client", "NimbusClient", "NimbusLoader", "Ninja Client", "NinjaClient",
    "NinjaLoader", "Nitro Client", "NitroClient", "NitroLoader", "Nix Client", "NixClient",
    "NixLoader", "Noble Client", "NobleClient", "NobleLoader", "Nodus Client", "NodusClient",
    "NodusLoader", "Nomad Client", "NomadClient", "NomadLoader", "Nostalgia Client", "NostalgiaClient",
    "NostalgiaLoader", "Nova Client", "NovaClient", "NovaLoader", "Novoline", "Novoline Guilded",
    "Novoline Intent", "Null Client", "NullClient", "NullLoader", "Nursultan Client", "Nursultan FunTime",
    "Nursultan Leak", "NursultanClient", "NursultanLoader", "Nyx Client", "NyxClient", "NyxLoader",
    "Oasis Client", "OasisClient", "OasisLoader", "Oblivion Client", "OblivionClient", "OblivionLoader",
    "Ocean Client", "OceanClient", "OceanLoader", "OctoClient", "Octohack", "Odyssey Client",
    "OdysseyClient", "OdysseyLoader", "Omega Client", "OmegaClient", "OmegaLoader", "Omen Client",
    "OmenClient", "OmenLoader", "Omni Client", "OmniClient", "OmniLoader", "Onyx Client",
    "OnyxClient", "OnyxLoader", "Opal Client", "OpalClient", "OpalLoader", "OpenAura",
    "OpenHurtCam", "Operations Client", "OperationsClient", "OperationsLoader", "Opium Client", "OpiumClient",
    "OpiumLoader", "OptiClient", "Option Client", "OptionClient", "OptionLoader", "Oracle Client",
    "OracleClient", "OracleLoader", "Orbit Client", "OrbitClient", "OrbitLoader", "Orca Client",
    "OrcaClient", "OrcaLoader", "Order Client", "OrderClient", "OrderLoader", "OreFinder Client",
    "OreFinderClient", "OreFinderLoader", "Orion Client", "OrionClient", "OrionLoader", "Osiris Client",
    "OsirisClient", "OsirisLoader", "Outlaw Client", "OutlawClient", "OutlawLoader", "Overcast Client",
    "OvercastClient", "OvercastLoader", "Overflow Client", "OverflowClient", "OverflowLoader", "Overhead Client",
    "OverheadClient", "OverheadLoader", "Owl Client", "OwlClient", "OwlLoader", "Oxygen Client",
    "OxygenClient", "OxygenLoader", "Ozone Client", "OzoneClient", "OzoneLoader", "Pacman Client",
    "PacmanClient", "PacmanLoader", "Page Client", "PageClient", "PageLoader", "Pale Client",
    "PaleClient", "PaleLoader", "Panda Client", "PandaClient", "PandaLoader", "Panic Client",
    "PanicClient", "PanicLoader", "Panther Client", "PantherClient", "PantherLoader", "Paper Client",
    "PaperClient", "PaperLoader", "Paradox Client", "ParadoxClient", "ParadoxLoader", "Paragon Client",
    "ParagonClient", "ParagonLoader", "Parallel Client", "ParallelClient", "ParallelLoader", "Particle Client",
    "ParticleClient", "ParticleLoader", "Pass Client", "PassClient", "PassLoader", "Past Client",
    "PastClient", "PastLoader", "Patriot Client", "PatriotClient", "PatriotLoader", "Pebble Client",
    "PebbleClient", "PebbleLoader", "Penetrate Client", "PenetrateClient", "PenetrateLoader", "Phantom Client",
    "PhantomClient", "PhantomLoader", "Phobos 1.5.4 Clean", "Phobos 1.9.0", "Phobos Client", "PhobosClient",
    "PhobosLoader", "Phoenix Client", "PhoenixClient", "PhoenixLoader", "Photon Client", "PhotonClient",
    "PhotonLoader", "Physics Client", "PhysicsClient", "PhysicsLoader", "Pika Client", "PikaClient",
    "PikaLoader", "Pilot Client", "PilotClient", "PilotLoader", "Pink Client", "PinkClient",
    "PinkLoader", "Pixel Client", "PixelClient", "PixelLoader", "Plague Client", "PlagueClient",
    "PlagueLoader", "Planet Client", "PlanetClient", "PlanetLoader", "Plasma Client", "PlasmaClient",
    "PlasmaLoader", "Plastic Client", "PlasticClient", "PlasticLoader", "Platinum Client", "PlatinumClient",
    "PlatinumLoader", "Pluto Client", "PlutoClient", "PlutoLoader", "Polar Client", "PolarClient",
    "Polaris Client", "PolarisClient", "PolarisLoader", "PolarLoader", "Polyphemus", "Popbob Client",
    "PopbobClient", "PopbobLoader", "Pulse Client", "PulseClient", "PulseLoader", "Purpur Client Hack",
    "Pylo Client", "PyloClient", "PyloLoader", "Python Client", "PythonClient", "PythonLoader",
    "QAF Client", "QAFClient", "QAFLoader", "Quad Client", "QuadClient", "QuadLoader",
    "Quantum Client", "QuantumClient", "QuantumLoader", "Quark Client", "QuarkClient", "QuarkLoader",
    "Quartz Client", "QuartzClient", "QuartzLoader", "Quasar Client", "QuasarClient", "QuasarLoader",
    "Queen Client", "QueenClient", "QueenLoader", "Quest Client", "QuestClient", "QuestLoader",
    "Quick Client", "QuickClient", "QuickLoader", "Quiet Client", "QuietClient", "QuietLoader",
    "Quill Client", "QuillClient", "QuillLoader", "Quiver Client", "QuiverClient", "QuiverLoader",
    "Quote Client", "QuoteClient", "QuoteLoader", "Radium Client", "RadiumClient", "RadiumLoader",
    "Rage Client", "RageClient", "RageLoader", "Rain Client", "Rainbow Client", "RainbowClient",
    "RainbowLoader", "RainClient", "RainLoader", "Rally Client", "RallyClient", "RallyLoader",
    "Rampage Client", "RampageClient", "RampageLoader", "Range Client", "RangeClient", "RangeLoader",
    "Rapid Client", "RapidClient", "RapidLoader", "Rare Client", "RareClient", "RareLoader",
    "Rave Client", "RaveClient", "RaveLoader", "Raven B+", "Raven B3", "Raven BS",
    "Raven Client", "Raven N3XT", "Raven WE", "RavenClient", "RavenLoader", "Ray Client",
    "RayClient", "RayLoader", "Razor Client", "RazorClient", "RazorLoader", "Reach Client",
    "ReachClient", "ReachLoader", "Reaction Client", "ReactionClient", "ReactionLoader", "Realm Client",
    "RealmClient", "RealmLoader", "Reaper Client", "ReaperClient", "ReaperLoader", "Rebirth Client",
    "RebirthClient", "RebirthLoader", "Reborn Client", "RebornClient", "RebornLoader", "Rebuilt Client",
    "RebuiltClient", "RebuiltLoader", "Red Client", "RedClient", "Redline Client", "RedlineClient",
    "RedlineLoader", "RedLoader", "Reflect Client", "ReflectClient", "ReflectLoader", "Reflex Client",
    "ReflexClient", "ReflexLoader", "Reign Client", "ReignClient", "ReignLoader", "Relative Client",
    "RelativeClient", "RelativeLoader", "Relentless", "Relief Client", "ReliefClient", "ReliefLoader",
    "Remake Client", "RemakeClient", "RemakeLoader", "Render Client", "RenderClient", "RenderLoader",
    "Replay Client Hack", "Resilience Client", "ResilienceClient", "Resistance Client", "ResistanceClient", "Resolute Client",
    "ResoluteClient", "ResoluteLoader", "Rest Client", "RestClient", "RestLoader", "Retro Client",
    "RetroClient", "RetroLoader", "Reversed Client", "ReversedClient", "ReversedLoader", "Revolution Client",
    "RevolutionClient", "Rich Client", "Rich Premium", "Rich Premium Leak", "RichClient", "RichLoader",
    "Rise 5.0", "Rise 6.0", "Rise Client", "RiseClient", "RiseLoader", "Rito Client",
    "RitoClient", "RitoLoader", "Rival Client", "RivalClient", "RivalLoader", "River Client",
    "RiverClient", "RiverLoader", "Robust Client", "RobustClient", "RobustLoader", "Rocket Client",
    "RocketClient", "RocketLoader", "Rogue Client", "RogueClient", "RogueLoader", "Root Client",
    "RootClient", "RootLoader", "Royal Client", "RoyalClient", "RoyalLoader", "Ruby Client",
    "RubyClient", "RubyLoader", "Rune Client", "RuneClient", "RuneLoader", "RusherHack",
    "RusherHack Modern", "Rust Client", "RustClient", "RustLoader", "Ruthless Client", "RuthlessClient",
    "RuthlessLoader", "Sabbath Client", "SabbathClient", "SabbathLoader", "Saber Client", "SaberClient",
    "SaberLoader", "Safe Client", "SafeClient", "SafeLoader", "SAGE Client", "SAGEClient",
    "SAGELoader", "SalHack", "SalHack Modern", "Salt Client", "SaltClient", "SaltLoader",
    "Salvation Client", "SalvationClient", "SalvationLoader", "Sapphire Client", "SapphireClient", "SapphireLoader",
    "Saturn Client", "SaturnClient", "SaturnLoader", "Savage Client", "SavageClient", "SavageLoader",
    "Scaffold Client", "ScaffoldClient", "ScaffoldLoader", "Scale Client", "ScaleClient", "ScaleLoader",
    "Scathe Client", "ScatheClient", "ScatheLoader", "Scene Client", "SceneClient", "SceneLoader",
    "Scent Client", "ScentClient", "ScentLoader", "Scythe Client", "Scythe Ghost", "ScytheClient",
    "ScytheLoader", "Secret Client", "SecretClient", "SecretLoader", "SeedFinder Client", "SeedFinderClient",
    "SeedFinderLoader", "Selection Client", "SelectionClient", "SelectionLoader", "Sensation Client", "SensationClient",
    "SensationLoader", "Sense Client", "SenseClient", "SenseLoader", "Sentinel Client", "SentinelClient",
    "SentinelLoader", "Sequel Client", "SequelClient", "SequelLoader", "Serenity Client", "SerenityClient",
    "Serpent Client", "SerpentClient", "SerpentLoader", "Shadow Client", "ShadowClient", "ShadowLoader",
    "Shard Client", "ShardClient", "ShardLoader", "Shark Client", "SharkClient", "SharkLoader",
    "Shift Client", "ShiftClient", "ShiftLoader", "Shine Client", "ShineClient", "ShineLoader",
    "Shock Client", "ShockClient", "ShockLoader", "Shred Client", "ShredClient", "ShredLoader",
    "Sick Client", "SickClient", "SickLoader", "Sierra Client", "SierraClient", "SierraLoader",
    "Sigma 4.0", "Sigma 5.0 (Jello)", "Sigma Client", "SigmaClient", "SigmaLoader", "Silk Client",
    "SilkClient", "SilkLoader", "Silver Client", "SilverClient", "SilverLoader", "Simple Client",
    "SimpleClient", "SimpleLoader", "Sine Client", "SineClient", "SineLoader", "Siphon Client",
    "SiphonClient", "SiphonLoader", "Siren Client", "SirenClient", "SirenLoader", "Sirius Client",
    "SiriusClient", "SiriusLoader", "Skeleton Client", "SkeletonClient", "SkeletonLoader", "Skill Client",
    "SkillClient", "SkillLoader", "Sky Client", "Skyblock Addons Hack", "SkyClient", "SkyLoader",
    "Skywars Master", "Slayer Client", "SlayerClient", "SlayerLoader", "Sleek Client", "SleekClient",
    "SleekLoader", "Slick Client", "SlickClient", "SlickLoader", "Slide Client", "SlideClient",
    "SlideLoader", "Slime Client", "SlimeClient", "SlimeLoader", "Slip Client", "SlipClient",
    "SlipLoader", "Smart Client", "SmartClient", "SmartLoader", "Smoke Client", "SmokeClient",
    "SmokeLoader", "Smooth Client", "SmoothClient", "SmoothLoader", "Snake Client", "SnakeClient",
    "SnakeLoader", "Snow Client", "SnowClient", "SnowLoader", "Soar Client Hack", "Solar Client",
    "SolarClient", "SolarLoader", "Solid Client", "SolidClient", "SolidLoader", "Solo Client",
    "SoloClient", "SoloLoader", "Solution Client", "SolutionClient", "SolutionLoader", "Spark Client",
    "SparkClient", "SparkLoader", "Spartan Bypass", "Spectrum Client", "SpectrumClient", "SpectrumLoader",
    "Speed Client", "SpeedClient", "SpeedLoader", "Spice Client", "SpiceClient", "SpiceLoader",
    "Spider Client", "SpiderClient", "SpiderLoader", "SpookyTime Bypass", "SpookyTime Client", "SpookyTimeClient",
    "SpookyTimeLoader", "Spring Client", "SpringClient", "SpringLoader", "Sprint Client", "SprintClient",
    "SprintLoader", "Spy Client", "SpyClient", "SpyLoader", "Square Client", "SquareClient",
    "SquareLoader", "Squid Client", "SquidClient", "SquidLoader", "Stack Client", "StackClient",
    "StackLoader", "Star Client", "StarClient", "Starfall Client", "StarfallClient", "StarfallLoader",
    "Starlight Client", "StarlightClient", "StarlightLoader", "StarLoader", "Stealth Client", "StealthClient",
    "StealthLoader", "Steel Client", "SteelClient", "SteelLoader", "Stellar Client", "StellarClient",
    "StellarLoader", "Step Client", "StepClient", "StepLoader", "Storm Client", "StormClient",
    "StormLoader", "Strike Client", "StrikeClient", "StrikeLoader", "Structure Client", "StructureClient",
    "StructureLoader", "Subzero Client", "SubzeroClient", "SubzeroLoader", "Sugar Client", "SugarClient",
    "SugarLoader", "Sumo Ghost Client", "Sumo GhostClient", "Sumo GhostLoader", "Sun Client", "SunClient",
    "SunLoader", "Sunset Client", "SunsetClient", "SunsetLoader", "Super Client", "SuperClient",
    "Superior Client", "SuperiorClient", "SuperiorLoader", "SuperLoader", "Supreme Client", "SupremeClient",
    "SupremeLoader", "Surf Client", "SurfClient", "SurfLoader", "Surge Client", "SurgeClient",
    "SurgeLoader", "Survival Utility", "Swamp Client", "SwampClient", "SwampLoader", "Swift Client",
    "SwiftClient", "SwiftLoader", "Synergy Client", "SynergyClient", "SynergyLoader", "System Client",
    "SystemClient", "SystemLoader", "Tactical Client", "TacticalClient", "TacticalLoader", "Target Client",
    "TargetClient", "TargetLoader", "Task Client", "TaskClient", "TaskLoader", "Team Client",
    "TeamClient", "TeamLoader", "Tempest Client", "TempestClient", "TempestLoader", "Tenacity 5.0",
    "Tenacity Client", "TenacityClient", "TenacityLoader", "Tendency Client", "TendencyClient", "TendencyLoader",
    "Terminus Client", "TerminusClient", "TerminusLoader", "Terra Client", "TerraClient", "TerraLoader",
    "Tesseract Client", "TesseractClient", "TesseractLoader", "Texture Client", "TextureClient", "TextureLoader",
    "Thorium Client", "ThoriumClient", "ThoriumLoader", "Thunder Client", "ThunderClient", "ThunderHack",
    "ThunderHack Recode", "ThunderLoader", "Tide Client", "TideClient", "TideLoader", "Tiger Client",
    "TigerClient", "TigerLoader", "Timber Client", "TimberClient", "TimberLoader", "Time Client",
    "TimeClient", "TimeLoader", "Titan Client", "TitanClient", "Titanium Client", "TitaniumClient",
    "TitaniumLoader", "TitanLoader", "Token Client", "TokenClient", "TokenLoader", "Topaz Client",
    "TopazClient", "TopazLoader", "Tornado Client", "TornadoClient", "TornadoLoader", "Toxic Client",
    "ToxicClient", "ToxicLoader", "Trace Client", "TraceClient", "TraceLoader", "Track Client",
    "TrackClient", "TrackLoader", "Traction Client", "TractionClient", "TractionLoader", "Traffic Client",
    "TrafficClient", "TrafficLoader", "Trail Client", "TrailClient", "TrailLoader", "Trajectory Client",
    "TrajectoryClient", "TrajectoryLoader", "Transcend Client", "TranscendClient", "TranscendLoader", "Trench Client",
    "TrenchClient", "TrenchLoader", "Trick Client", "TrickClient", "TrickLoader", "Trident Client",
    "TridentClient", "TridentLoader", "Trigger Client", "TriggerClient", "TriggerLoader", "Trinity Client",
    "TrinityClient", "TrinityLoader", "Triple Client", "TripleClient", "TripleLoader", "Trojan Client",
    "TrojanClient", "TrojanLoader", "Tropic Client", "TropicClient", "TropicLoader", "TrouserStreak",
    "Tsunami Client", "TsunamiClient", "TsunamiLoader", "Twilight Client", "TwilightClient", "TwilightLoader",
    "Twin Client", "TwinClient", "TwinLoader", "Typhoon Client", "TyphoonClient", "TyphoonLoader",
    "Ultimate Client", "UltimateClient", "UltimateLoader", "Ultra Client", "UltraClient", "UltraLoader",
    "Umbral Client", "UmbralClient", "UmbralLoader", "Unarmed Client", "UnarmedClient", "UnarmedLoader",
    "Unbeaten Client", "UnbeatenClient", "UnbeatenLoader", "Uncanny Client", "UncannyClient", "UncannyLoader",
    "Underground Client", "UndergroundClient", "UndergroundLoader", "Unicorn Client", "UnicornClient", "UnicornLoader",
    "Unification Client", "UnificationClient", "UnificationLoader", "Unique Client", "UniqueClient", "Unit Client",
    "UnitClient", "UnitLoader", "Unity Client", "UnityClient", "UnityLoader", "Universal Client",
    "UniversalClient", "UniversalLoader", "Unknown Client", "UnknownClient", "UnknownLoader", "Unleashed Client",
    "UnleashedClient", "UnleashedLoader", "Unlegitised", "Unnamed Client", "UnnamedClient", "UnnamedLoader",
    "Unseen Client", "UnseenClient", "UnseenLoader", "Unstoppable Client", "UnstoppableClient", "UnstoppableLoader",
    "Up Client", "UpClient", "UpLoader", "Uranium Client", "UraniumClient", "UraniumLoader",
    "Urban Client", "UrbanClient", "UrbanLoader", "Utility Client", "UtilityClient", "UtilityLoader",
    "Utopia Client", "UtopiaClient", "UtopiaLoader", "Valkyrie Client", "ValkyrieClient", "ValkyrieLoader",
    "Value Client", "ValueClient", "ValueLoader", "Vamp Client", "VampClient", "Vampire Client",
    "VampireClient", "VampireLoader", "VampLoader", "Vanta Client", "VantaClient", "VantaLoader",
    "Vape Client", "Vape Lite", "Vape v2", "Vape v3", "Vape v4", "VapeClient",
    "VapeLoader", "Vapor Client", "VaporClient", "VaporLoader", "Vaporware", "Vector Client",
    "Vector Donut SMP", "VectorClient", "VectorLoader", "Velocity Client", "VelocityClient", "VelocityLoader",
    "Venom Client", "VenomClient", "VenomLoader", "Vent Client", "VentClient", "VentLoader",
    "Venue Client", "VenueClient", "VenueLoader", "Venus Client", "VenusClient", "VenusLoader",
    "Verbal Client", "VerbalClient", "VerbalLoader", "Vergence Client", "VergenceClient", "VergenceLoader",
    "Verlet Client", "VerletClient", "VerletLoader", "Verse Client", "VerseClient", "VerseLoader",
    "Vesper Client", "VesperClient", "VesperLoader", "Veto Client", "VetoClient", "VetoLoader",
    "Vex Client", "VexClient", "VexLoader", "Viamcp Client", "ViamcpClient", "ViamcpLoader",
    "Vibe Client", "VibeClient", "VibeLoader", "Vice Client", "ViceClient", "ViceLoader",
    "Vigor Client", "VigorClient", "VigorLoader", "Viking Client", "VikingClient", "VikingLoader",
    "Viper Client", "ViperClient", "ViperLoader", "Viridian", "Virtual Client", "VirtualClient",
    "Virtuality Client", "VirtualityClient", "VirtualityLoader", "VirtualLoader", "Visage Client", "VisageClient",
    "VisageLoader", "Vision Client", "VisionClient", "VisionLoader", "Visual Client", "VisualClient",
    "VisualLoader", "Vital Client", "VitalClient", "Vitality Client", "VitalityClient", "VitalityLoader",
    "VitalLoader", "Void Client", "VoidClient", "VoidLoader", "Volcan Client", "VolcanClient",
    "VolcanLoader", "Voltage Client", "VoltageClient", "VoltageLoader", "Volume Client", "VolumeClient",
    "VolumeLoader", "Voodoo Client", "VoodooClient", "VoodooLoader", "Vortex Client", "VortexClient",
    "VortexLoader", "Vulcan Bypass Client", "Vulcan BypassClient", "Vulcan BypassLoader", "Vulpix Client", "VulpixClient",
    "VulpixLoader", "Walk Client", "WalkClient", "WalkLoader", "Wall Client", "WallClient",
    "WallLoader", "Wave Client", "WaveClient", "WaveLoader", "Way Client", "WayClient",
    "WayLoader", "Web Client", "WebClient", "WebLoader", "Weighted Client", "WeightedClient",
    "WeightedLoader", "Wet Client", "WetClient", "WetLoader", "Whisper Client", "WhisperClient",
    "WhisperLoader", "White Client", "WhiteClient", "WhiteLoader", "Whiteout Client", "Whiteout Screenshare",
    "WhiteoutClient", "WhiteoutLoader", "Wicked Client", "WickedClient", "WickedLoader", "Wild Client",
    "Wild FunTime", "WildClient", "WildLoader", "Win Client", "WinClient", "Wind Client",
    "WindClient", "WindLoader", "WinLoader", "Winter Client", "WinterClient", "WinterLoader",
    "Wisdom Client", "WisdomClient", "WisdomLoader", "Wish Client", "WishClient", "WishLoader",
    "Witch Client", "WitchClient", "WitchLoader", "Wizard Client", "WizardClient", "WizardLoader",
    "Wolf Client", "WolfClient", "WolfLoader", "Wonder Client", "WonderClient", "WonderLoader",
    "Wood Client", "WoodClient", "WoodLoader", "World Client", "WorldClient", "WorldLoader",
    "Wrath Client", "WrathClient", "WrathLoader", "Wurst Client", "Wurst Fabric", "Wurst+2",
    "Wurst+3", "WurstClient", "WurstLoader", "Wyvern Client", "WyvernClient", "WyvernLoader",
    "X-Ray Mod", "X-Ray Ultimate Hack", "Xanax Client", "XanaxClient", "XanaxLoader", "Xeons Client",
    "XeonsClient", "XeonsLoader", "Xerox Client", "XeroxClient", "XeroxLoader", "Xeta Client",
    "XetaClient", "XetaLoader", "Xeu Client", "XeuClient", "XeuLoader", "Xmas Client",
    "XmasClient", "XmasLoader", "Xor Client", "XorClient", "XorLoader", "Xray Client",
    "Xray Utility", "XrayClient", "XrayLoader", "Xrez Client", "XrezClient", "XrezLoader",
    "Xtreme Client", "XtremeClient", "XtremeLoader", "Yacht Client", "YachtClient", "YachtLoader",
    "Yaro Client", "YaroClient", "YaroLoader", "Yello Client", "YelloClient", "YelloLoader",
    "Yellow Client", "YellowClient", "YellowLoader", "Yeti Client", "YetiClient", "YetiLoader",
    "Yield Client", "YieldClient", "YieldLoader", "Yin Client", "YinClient", "YinLoader",
    "Yoink Client", "YoinkClient", "YoinkLoader", "Yoshi Client", "YoshiClient", "YoshiLoader",
    "Young Client", "YoungClient", "YoungLoader", "Youth Client", "YouthClient", "YouthLoader",
    "Ypres Client", "YpresClient", "YpresLoader", "Yuki Client", "YukiClient", "YukiLoader",
    "Yuko Client", "YukoClient", "YukoLoader", "Zap Client", "ZapClient", "ZapLoader",
    "Zar Client", "ZarClient", "ZarLoader", "Zeal Client", "ZealClient", "ZealLoader",
    "Zenith Client", "ZenithClient", "ZenithLoader", "Zephyr Client", "ZephyrClient", "ZephyrLoader",
    "Zero Client", "ZeroClient", "Zeroday Client", "Zeroday Reborn", "ZerodayClient", "ZerodayLoader",
    "ZeroLoader", "Zeus Client", "ZeusClient", "ZeusLoader", "ZigZag Client", "ZigZagClient",
    "ZigZagLoader", "Zion Client", "ZionClient", "ZionLoader", "Zip Client", "ZipClient",
    "ZipLoader", "Zodiac Client", "ZodiacClient", "ZodiacLoader", "Zone Client", "ZoneClient",
    "ZoneLoader", "Zulu Client", "ZuluClient", "ZuluLoader", "Zyna Client", "ZynaClient",
    "ZynaLoader"
)


# [LIVE_RAM_PATTERNS_DB // RESEARCH_BY_BAYRDY]
$liveRamSignatures = @(
    "nursultan", "celestial", "expensive", "wildclient", "akrien", "minced", "deltaclient", "exloader",
    "AutoCrystal", "CW_CRYSTAL", "cw crystal", "AnchorMacro", "DoubleAnchor", "SafeAnchor",
    "AutoTotem", "HoverTotem", "LegitTotem", "InventoryTotem", "AutoDoubleHand",
    "ShieldDisabler", "ShieldBreaker", "SilentAim", "HitboxExpand", "ReachHack",
    "GrimVelocity", "GrimDisabler", "VapeLite", "vape.gg", "drip.gg", "slinky.gg",
    "meteordevelopment", "dqrkis.xyz", "prestigeclient.vip", "novaclient",
    "WalksyCrystalOptimizer", "AutoMace", "StunSlam", "FastPlace", "ItemExploit",
    "net.ccbluex.liquidbounce", "dev.krypton", "AsteriaClient", "CatleanClient"
)

# [BYTECODE_HEURISTICS_MAP // CONSTRUCTED_BY_BAYRDY]
$macroBytecodePatterns = @(
    "AutoCrystal", "CW_CRYSTAL", "cw crystal", "AnchorMacro", "DoubleAnchor", "SafeAnchor",
    "AutoTotem", "HoverTotem", "LegitTotem", "InventoryTotem", "AutoDoubleHand",
    "ShieldDisabler", "ShieldBreaker", "SilentAim", "HitboxExpand",
    "GrimVelocity", "GrimDisabler", "PolarDisabler", "MatrixDisabler", "AntiKnockbackModifier",
    "VapeLite", "vape.gg", "drip.gg", "slinky.gg", "meteordevelopment", "wurstclient", "liquidbounce",
    "dev/krypton", "prestigeclient", "nursultan.fun", "nursultanclient", "ru/nursultan",
    "celestial.fun", "celestialclient", "ru/celestial", "expensive.fun", "expensiveclient",
    "ru/expensive", "akrien.fun", "akrienclient", "mincedclient", "deltaclient", "fdpclient"
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

# Initialize Native High-Performance Cheat Matcher
[VortexCoreEngine.FastCheatMatcher]::Initialize($cheatClientsSet)

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
# ====================================================================
# >>> [PHASE 1 : LIVE RUNTIME & PROCESSES FORENSICS // ARCHITECT: BayrdY] <<<
# ====================================================================
Write-Host "`n[PHASE 1/5] Scanning Active Processes, Loaders & JVM Runtime..." -ForegroundColor Cyan

# 1. Active Windows Background Processes & Cheat Injectors
Show-Progress -Phase "Processes" -Item "Scanning active background processes and injectors"
try {
    $allProcesses = Get-Process -ErrorAction SilentlyContinue
    foreach ($proc in $allProcesses) {
        try {
            $pName = $proc.ProcessName
            $pTitle = $proc.MainWindowTitle
            $pPath = $null
            try { $pPath = $proc.MainModule.FileName } catch { }
            $pDesc = $null
            try { $pDesc = $proc.MainModule.FileVersionInfo.FileDescription } catch { }
            $pProd = $null
            try { $pProd = $proc.MainModule.FileVersionInfo.ProductName } catch { }

            $searchString = "$pName $pTitle $pPath $pDesc $pProd"
            $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($searchString)
            if ($matched) {
                Add-Finding -Title "Active Cheat Process / Injector Running: $pName" `
                            -Description "A running background process matched a known cheat injector or standalone client." `
                            -Severity "Critical" -Category "Memory" `
                            -TargetPath (if ($pPath) { $pPath } else { "$pName (PID $($proc.Id))" }) `
                            -Evidence "Process: $pName (PID $($proc.Id)) | Title: $pTitle | Path: $pPath | Product: $pProd | Matched: $matched"
            }
        } catch { }
    }
} catch { }

# 2. Live JVM Memory & Hook Scan
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
                $isSuspicious = $modLower -match "inject|cheat|loader|minhook|kiero|imgui|jna|jinput|vape|rise|doomsday|nursultan|celestial|expensive|wild|akrien|hook"
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
# >>> [PHASE 2 : EXECUTABLES, CLIENT DIRECTORIES & JAR BYTECODE // BayrdY] <<<
# ====================================================================
Write-Host "`n[PHASE 2/5] Deep Scanning Standalone Clients, Executables & JAR Mods..." -ForegroundColor Cyan

# 1. Known Cheat Client Folders & Profiles Scan
Show-Progress -Phase "Clients" -Item "Scanning standalone cheat client directories"
$cheatFolderNames = @(
    ".nursultan", ".celestial", ".expensive", ".wild", ".akrien", ".minced", ".delta",
    "ExLoader", ".vape", "DripLite", ".liquidbounce", ".meteor", ".futureclient",
    ".rusherhack", ".boze", ".aristois", ".impact", ".doomsday", ".kura"
)
foreach ($cf in $cheatFolderNames) {
    $cfPath = Join-Path $env:APPDATA $cf
    if (Test-Path $cfPath) {
        Add-Finding -Title ("Standalone Cheat Client Directory Found: " + $cf) `
                    -Description "A known standalone cheat client configuration or data directory exists on the system." `
                    -Severity "Critical" -Category "Forensics" `
                    -TargetPath $cfPath `
                    -Evidence ("Directory Path: " + $cfPath)
    }
}

# 2. Minecraft Versions Directory Scan (.minecraft\versions)
$mcVersionsDir = Join-Path $env:APPDATA ".minecraft\versions"
if (Test-Path $mcVersionsDir) {
    Show-Progress -Phase "Clients" -Item "Scanning .minecraft\versions for cheat clients"
    try {
        $vFolders = [System.IO.Directory]::GetDirectories($mcVersionsDir)
        foreach ($vf in $vFolders) {
            $vfName = [System.IO.Path]::GetFileName($vf)
            $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($vfName)
            if ($matched) {
                Add-Finding -Title ("Cheat Client Profile in Versions: " + $vfName) `
                            -Description "Minecraft versions directory contains a known cheat client profile." `
                            -Severity "Critical" -Category "Bytecode" `
                            -TargetPath $vf `
                            -Evidence ("Version Profile: " + $vf + " | Matched: " + $matched)
            }
        }
    } catch { }
}

# 3. Executable Cheat Binaries (.exe, .dll, .bat, .zip, .rar) Scan on Desktop, Downloads, Temp
Show-Progress -Phase "Executables" -Item "Scanning Desktop, Downloads and Temp for cheat binaries"
$searchExeDirs = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Downloads",
    "$env:LOCALAPPDATA\Temp",
    "C:\Users\Public"
)
foreach ($ed in $searchExeDirs) {
    if (Test-Path $ed) {
        try {
            $binFiles = [System.IO.Directory]::GetFiles($ed, "*.*", [System.IO.SearchOption]::TopDirectoryOnly)
            foreach ($bf in $binFiles) {
                $ext = [System.IO.Path]::GetExtension($bf).ToLowerInvariant()
                if ($ext -notin @(".exe", ".dll", ".bat", ".cmd", ".vbs", ".zip", ".rar", ".7z")) { continue }
                
                $bfName = [System.IO.Path]::GetFileNameWithoutExtension($bf)
                $matchedCheat = [VortexCoreEngine.FastCheatMatcher]::FindMatch($bfName)
                
                # Check PE File Metadata for disguised EXEs
                $peDesc = $null
                $peProd = $null
                $peOrig = $null
                $peComp = $null
                if ($ext -in @(".exe", ".dll")) {
                    try {
                        $fvi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($bf)
                        $peDesc = $fvi.FileDescription
                        $peProd = $fvi.ProductName
                        $peOrig = $fvi.OriginalFilename
                        $peComp = $fvi.CompanyName
                        $metaStr = "$peDesc $peProd $peOrig $peComp"
                        
                        $isVerifiedVendor = $false
                        if ($peComp -match "(?i)Riot Games|Valve|Discord|Epic Games|Electronic Arts|Ubisoft|Microsoft|Google|NVIDIA|Logitech|Razer|SteelSeries|Corsair|Spotify|Mozilla|Oracle|Adobe|Blizzard|Overwolf") {
                            $isVerifiedVendor = $true
                        }

                        if (-not $isVerifiedVendor -and -not $matchedCheat) {
                            $matchedMeta = [VortexCoreEngine.FastCheatMatcher]::FindMatch($metaStr)
                            if ($matchedMeta) {
                                $matchedCheat = "$matchedMeta (Disguised as $([System.IO.Path]::GetFileName($bf)))"
                            }
                        }
                    } catch { }
                }

                if ($matchedCheat) {
                    Add-Finding -Title ("Cheat Executable / Archive Found: " + [System.IO.Path]::GetFileName($bf)) `
                                -Description "An executable, library, or archive matching a known cheat client was discovered." `
                                -Severity "Critical" -Category "Forensics" `
                                -TargetPath $bf `
                                -Evidence ("File: $bf | Detected: $matchedCheat | Product: $peProd | Desc: $peDesc")
                }
            }
        } catch { }
    }
}

# 4. Multi-Core Parallel JAR Bytecode Scanner
$jarTargets = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

if ($TargetFolder -and (Test-Path $TargetFolder)) {
    try {
        $customJars = [System.IO.Directory]::GetFiles($TargetFolder, "*.jar", [System.IO.SearchOption]::AllDirectories)
        foreach ($cj in $customJars) { [void]$jarTargets.Add($cj) }
    } catch { }
} else {
    $standardJarDirs = @(
        (Join-Path $env:APPDATA ".minecraft\mods"),
        (Join-Path $env:APPDATA ".minecraft\versions"),
        (Join-Path $env:USERPROFILE "Desktop"),
        (Join-Path $env:USERPROFILE "Downloads")
    )
    foreach ($jd in $standardJarDirs) {
        if (Test-Path $jd) {
            try {
                $opts = if ($jd -match "\.minecraft") { [System.IO.SearchOption]::AllDirectories } else { [System.IO.SearchOption]::AllDirectories }
                $foundJars = [System.IO.Directory]::GetFiles($jd, "*.jar", $opts)
                foreach ($fj in $foundJars) { [void]$jarTargets.Add($fj) }
            } catch { }
        }
    }
}

$jarList = [string[]]@($jarTargets)
if ($jarList.Length -gt 0) {
    Write-Host "  [+] Found $($jarList.Length) JAR file(s) across standard directories" -ForegroundColor Green
    Show-Progress -Phase "Bytecode" -Item "Multi-threaded parallel scan running across all CPU cores..."
    
    $swBytecode = [System.Diagnostics.Stopwatch]::StartNew()
    $jarSummaries = [VortexCoreEngine.FastScanner]::ScanAllJarsParallel(
        $jarList,
        $macroBytecodePatterns,
        $tokenStealerPatterns,
        $obfuscatorSignatures,
        $legitModIds
    )
    $swBytecode.Stop()
    $bcElapsedSec = [math]::Round($swBytecode.ElapsedMilliseconds / 1000, 2)
    Write-Host "`r  [+] Scanned $($jarList.Length) JAR file(s) in $($bcElapsedSec)s using multi-core parallelism!" -ForegroundColor Green

    foreach ($jr in $jarSummaries) {
        $modStatus = if ($jr.MatchedMacros.Count -gt 0 -or $jr.HasTokenStealer -or $jr.IsSpoofed) { "SUSPICIOUS" } else { "CLEAN" }
        $scannedModsInventory.Add([PSCustomObject]@{
            FileName     = [System.IO.Path]::GetFileName($jr.JarPath)
            FullPath     = $jr.JarPath
            SHA1         = $jr.SHA1
            ClaimedId    = $jr.ClaimedModId
            SizeKB       = [math]::Round($jr.FileSizeBytes / 1024, 1)
            Status       = $modStatus
            Macros       = ($jr.MatchedMacros -join ", ")
            Obfuscators  = ($jr.MatchedObfuscators -join ", ")
        })

        if ($jr.MatchedMacros.Count -gt 0) {
            $macroList = ($jr.MatchedMacros) -join ", "
            Add-Finding -Title ("Cheat / Macro Signatures Detected in Mod: " + $macroList) `
                        -Description "Mod contains compiled Java bytecode signatures matching known PvP macros and cheat routines." `
                        -Severity "Critical" -Category "Bytecode" `
                        -TargetPath $jr.JarPath `
                        -Evidence ("Matched Patterns: " + $macroList)
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
            $pfNameOnly = [System.IO.Path]::GetFileNameWithoutExtension($pfPath)
            if ($pfNameOnly.Contains("-")) { $pfNameOnly = $pfNameOnly.Substring(0, $pfNameOnly.LastIndexOf("-")) }
            $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($pfNameOnly)
            if ($matched) {
                Add-Finding -Title ("Prefetch Execution Trace: " + $matched) `
                            -Description "Windows Prefetch recorded execution of known cheat executable." `
                            -Severity "High" -Category "Forensics" `
                            -TargetPath $pfPath `
                            -Evidence ("Prefetch Entry: " + [System.IO.Path]::GetFileName($pfPath))
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
                $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($exeNameOnly)
                if ($matched) {
                    Add-Finding -Title ("BAM Execution Record: " + $matched) `
                                -Description "Background Activity Moderator recorded execution of cheat executable." `
                                -Severity "High" -Category "Forensics" `
                                -TargetPath $exePath `
                                -Evidence ("Registry SID: " + $sid.PSChildName + " | Executable: " + $exePath)
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
                    $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($decNameOnly)
                    if ($matched) {
                        Add-Finding -Title ("UserAssist GUI Execution Record: " + $matched) `
                                    -Description "UserAssist recorded GUI launch of cheat executable." `
                                    -Severity "High" -Category "Forensics" `
                                    -TargetPath $decoded `
                                    -Evidence ("ROT13 Decoded: " + $decoded)
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
            $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($pNameOnly)
            if ($matched) {
                Add-Finding -Title ("MUICache Execution Trace: " + $matched) `
                            -Description "Application execution record found in MUICache." `
                            -Severity "Medium" -Category "Forensics" `
                            -TargetPath $path `
                            -Evidence ("MUICache Entry: " + $path)
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
                    $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($clean)
                    if ($matched) {
                        Add-Finding -Title ("Cheat File Selected in Windows Open/Save Dialog: " + $matched) `
                                    -Description "User selected a cheat binary in a Windows file picker dialog (ComDlg32 MRU)." `
                                    -Severity "High" -Category "Forensics" `
                                    -TargetPath ("OpenSavePidlMRU\" + $ext) `
                                    -Evidence ("ComDlg32 MRU Record: " + $clean)
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
            $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($val)
            if ($matched) {
                Add-Finding -Title ("Opened Cheat Archive in WinRAR / 7-Zip History: " + $matched) `
                            -Description "Windows registry recorded opening of a cheat archive package." `
                            -Severity "High" -Category "Forensics" `
                            -TargetPath $val `
                            -Evidence ("WinRAR ArcHistory: " + $val)
            }
        }
    }
    # 7-Zip
    $sevenZipKey = "HKCU:\Software\7-Zip\FM"
    if (Test-Path $sevenZipKey) {
        $szProps = (Get-ItemProperty -Path $sevenZipKey -ErrorAction SilentlyContinue).PSObject.Properties
        foreach ($p in $szProps) {
            $val = "$($p.Value)"
            $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($val)
            if ($matched) {
                Add-Finding -Title ("Opened Cheat Archive in WinRAR / 7-Zip History: " + $matched) `
                            -Description "Windows registry recorded opening of a cheat archive package." `
                            -Severity "High" -Category "Forensics" `
                            -TargetPath $val `
                            -Evidence ("7-Zip History: " + $val)
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
                    $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($l)
                    if ($matched) {
                        Add-Finding -Title ("Cheat Keyword Search in Everything History: " + $matched) `
                                    -Description "User searched for cheat binaries or forensic cleaner tools in Voidtools Everything." `
                                    -Severity "High" -Category "Cleaner" `
                                    -TargetPath $ep `
                                    -Evidence ("Everything Log Line: " + $l)
                    }
                }
            }
        }
    }
} catch { }

# ====================================================================
# >>> [PHASE 4 : STORAGE TRACES & RECENT DELETIONS // ULTRA-FAST ENGINE: BayrdY] <<<
# ====================================================================
Write-Host "`n[PHASE 4/5] Scanning Recent Deletions & Storage Traces..." -ForegroundColor Cyan

# 1. High-Speed Recycle Bin Forensics (Top-Level & Recent Purges)
Show-Progress -Phase "Forensics" -Item "Checking Recycle Bin for purged cheat artifacts"
try {
    if (Test-Path 'C:\$Recycle.Bin') {
        $subDirs = [System.IO.Directory]::GetDirectories('C:\$Recycle.Bin')
        foreach ($sd in $subDirs) {
            try {
                $files = [System.IO.Directory]::GetFiles($sd, "*", [System.IO.SearchOption]::TopDirectoryOnly)
                foreach ($itemPath in $files) {
                    $iName = [System.IO.Path]::GetFileName($itemPath)
                    if ($iName -match "^\$I") {
                        try {
                            $bytes = [System.IO.File]::ReadAllBytes($itemPath)
                            if ($bytes.Length -gt 28) {
                                $origName = [System.Text.Encoding]::Unicode.GetString($bytes, 28, $bytes.Length - 28).TrimEnd("`0")
                                $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($origName)
                                if ($matched) {
                                    Add-Finding -Title ("Deleted Cheat in Recycle Bin: " + $matched) `
                                                -Description "Deleted cheat executable or archive found resting in Recycle Bin." `
                                                -Severity "High" -Category "Forensics" `
                                                -TargetPath $origName `
                                                -Evidence ("Recycle Bin Metadata: " + $origName + " (in " + $iName + ")")
                                }
                            }
                        } catch { }
                    } else {
                        $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($iName)
                        if ($matched) {
                            Add-Finding -Title ("Deleted Cheat in Recycle Bin: " + $matched) `
                                        -Description "Deleted cheat executable or archive found resting in Recycle Bin." `
                                        -Severity "High" -Category "Forensics" `
                                        -TargetPath $itemPath `
                                        -Evidence ("Recycle Bin file: " + $iName)
                        }
                    }
                }
            } catch { }
        }
    }
} catch { }

# 2. Windows Shell RecentDocs & Explorer Shell Forensics (Sub-Millisecond Registry & LNK)
Show-Progress -Phase "Forensics" -Item "Auditing Windows RecentDocs & JumpList storage traces"
try {
    # RecentDocs MRU Registry
    $recentDocsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    if (Test-Path $recentDocsKey) {
        $subExts = Get-ChildItem -Path $recentDocsKey -ErrorAction SilentlyContinue
        foreach ($se in $subExts) {
            $props = (Get-ItemProperty -Path $se.PSPath -ErrorAction SilentlyContinue).PSObject.Properties
            foreach ($p in $props) {
                if ($p.Value -is [byte[]]) {
                    $rawBytes = [byte[]]$p.Value
                    $strDec = [System.Text.Encoding]::Unicode.GetString($rawBytes)
                    $clean = [regex]::Replace($strDec, "[^\x20-\x7E]", "")
                    $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($clean)
                    if ($matched) {
                        Add-Finding -Title ("RecentDocs Executed / Deleted Cheat Record: " + $matched) `
                                    -Description "Windows RecentDocs recorded execution or deletion of cheat binary." `
                                    -Severity "High" -Category "Forensics" `
                                    -TargetPath ("RecentDocs\" + $se.PSChildName) `
                                    -Evidence ("MRU Record: " + $clean)
                    }
                }
            }
        }
    }
    
    # Recent LNK Shortcuts
    $recentPath = "$env:APPDATA\Microsoft\Windows\Recent"
    if (Test-Path $recentPath) {
        $recentFiles = [System.IO.Directory]::GetFiles($recentPath, "*.lnk", [System.IO.SearchOption]::TopDirectoryOnly)
        foreach ($rf in $recentFiles) {
            $rName = [System.IO.Path]::GetFileNameWithoutExtension($rf)
            $matched = [VortexCoreEngine.FastCheatMatcher]::FindMatch($rName)
            if ($matched) {
                Add-Finding -Title ("Recent File History Trace: " + $matched) `
                            -Description "Windows Recent shortcuts recorded interaction with a cheat binary." `
                            -Severity "High" -Category "Forensics" `
                            -TargetPath $rf `
                            -Evidence ("Recent Shortcut: " + $rName)
            }
        }
    }
} catch { }
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
                
                $cheatDomainsAndUrls = @(
                    "vape.gg", "drip.gg", "slinky.gg", "nursultan.fun", "celestial.fun", "expensive.fun",
                    "akrien.fun", "minced.fun", "exloader.net", "liquidbounce.net", "wurstclient.net",
                    "meteorclient.com", "intent.store", "neverlose.cc", "onetap.su", "aristois.net",
                    "futureclient.net", "rusherhack.org", "boze.dev", "bleachhack", "prestigeclient.vip",
                    "novaclient", "fdpclient", "sigma5.jar", "vape_v4", "vapelite", "nursultan_crack",
                    "celestial_premium", "expensive_loader", "grimdisabler", "polardisabler"
                )
                foreach ($cd in $cheatDomainsAndUrls) {
                    if ($bContent -match "(?i)(https?://[^\x00-\x20""'<>]*$([regex]::Escape($cd))[^\x00-\x20""'<>]*)") {
                        $matchedUrl = $Matches[1]
                        if ($matchedUrl.Length -gt 140) { $matchedUrl = $matchedUrl.Substring(0, 140) + "..." }
                        Add-Finding -Title ("Cheat Download Trace in Web Browser History: " + $cd) `
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
# NEXT-GEN CYBERPUNK INTERACTIVE HTML WEB REPORT (SMART SUMMARY & DETAILED SCORING)
# ====================================================================
if (-not $NoHtmlReport) {
    $timestampStr = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $reportDir = if (Test-Path "$env:USERPROFILE\Desktop") { "$env:USERPROFILE\Desktop" } else { (Get-Location).Path }
    $reportPath = Join-Path $reportDir "VortexReport_$timestampStr.html"
    
    $jsonFindings = ConvertTo-Json -InputObject @($findings) -Depth 5 -Compress
    if (-not $jsonFindings -or $jsonFindings -eq "null") { $jsonFindings = "[]" }

    $jsonMods = ConvertTo-Json -InputObject @($scannedModsInventory) -Depth 5 -Compress
    if (-not $jsonMods -or $jsonMods -eq "null") { $jsonMods = "[]" }

    $gaugeColor = if ($score -ge 50) { "#FF0055" } elseif ($score -gt 15) { "#FFB800" } else { "#00FFA3" }
    $gaugeOffset = [math]::Round(314 - (314 * ($score / 100)))

    $htmlTemplate = @'
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>VORTEX-AC Forensic Intelligence Report - __USER__ | Coded By BayrdY</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;800&family=Outfit:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-dark: #0B0F19;
      --card-bg: #131B2E;
      --card-bg-subtle: #0E1524;
      --card-border: #1E293B;
      --card-border-hover: #334155;
      --accent-blue: #38BDF8;
      --accent-red: #EF4444;
      --accent-amber: #F59E0B;
      --accent-green: #10B981;
      --text-main: #F8FAFC;
      --text-muted: #94A3B8;
      --text-dim: #64748B;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: "Outfit", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    code, pre, .mono { font-family: "JetBrains Mono", monospace !important; }
    body { background: #0B0F19; color: var(--text-main); min-height: 100vh; padding: 25px 20px; }
    .container { max-width: 1250px; margin: 0 auto; }
    
    /* Header Bar */
    .header-card { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 14px; padding: 22px 28px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px; }
    .brand h1 { font-size: 22px; font-weight: 800; color: #FFF; letter-spacing: 0.5px; }
    .brand p { color: var(--text-muted); font-size: 13px; margin-top: 5px; }
    .header-actions { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }
    .action-btn { padding: 8px 14px; border-radius: 8px; font-weight: 600; font-size: 13px; cursor: pointer; border: 1px solid var(--card-border); background: #1E293B; color: var(--text-main); transition: all 0.15s ease; display: flex; align-items: center; gap: 6px; }
    .action-btn:hover { background: #334155; border-color: #475569; }
    .lang-btn { background: #1E293B; color: var(--accent-blue); border-color: #0284C7; }
    .lang-btn:hover { background: #0284C7; color: #FFF; }

    /* Top Grid */
    .dash-grid { display: grid; grid-template-columns: 280px 1fr; gap: 18px; margin-bottom: 20px; }
    @media(max-width: 880px) { .dash-grid { grid-template-columns: 1fr; } }
    .gauge-card { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 14px; padding: 22px; text-align: center; display: flex; flex-direction: column; justify-content: center; align-items: center; }
    .gauge-svg { width: 130px; height: 130px; transform: rotate(-90deg); }
    .gauge-bg { fill: none; stroke: rgba(255,255,255,0.06); stroke-width: 9; }
    .gauge-fill { fill: none; stroke: __GAUGE_COLOR__; stroke-width: 9; stroke-dasharray: 314; stroke-dashoffset: __GAUGE_OFFSET__; stroke-linecap: round; transition: stroke-dashoffset 0.8s ease; }
    .gauge-center { position: absolute; font-size: 28px; font-weight: 800; color: #FFF; }
    .verdict-tag { margin-top: 14px; padding: 5px 14px; border-radius: 20px; font-size: 12px; font-weight: 700; letter-spacing: 0.5px; text-transform: uppercase; background: rgba(255,255,255,0.05); color: __GAUGE_COLOR__; border: 1px solid __GAUGE_COLOR__55; }
    
    .stats-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 14px; }
    .stat-box { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 14px; padding: 18px; display: flex; flex-direction: column; justify-content: space-between; }
    .stat-label { font-size: 11.5px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; }
    .stat-val { font-size: 26px; font-weight: 800; margin-top: 6px; color: #FFF; }

    /* Smart Executive Summary & Verdict Box */
    .ai-summary-card { background: var(--card-bg); border: 1px solid #0284C7; border-radius: 14px; padding: 22px 26px; margin-bottom: 20px; }
    .ai-header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; margin-bottom: 14px; border-bottom: 1px solid var(--card-border); padding-bottom: 12px; }
    .ai-title { font-size: 16px; font-weight: 700; display: flex; align-items: center; gap: 8px; color: #FFF; }
    .ai-badge { padding: 4px 12px; border-radius: 16px; font-size: 11.5px; font-weight: 700; letter-spacing: 0.5px; text-transform: uppercase; }
    .ai-badge.clean { background: rgba(16, 185, 129, 0.15); color: var(--accent-green); border: 1px solid var(--accent-green); }
    .ai-badge.susp { background: rgba(245, 158, 11, 0.15); color: var(--accent-amber); border: 1px solid var(--accent-amber); }
    .ai-badge.danger { background: rgba(239, 68, 68, 0.15); color: var(--accent-red); border: 1px solid var(--accent-red); }
    .ai-desc { font-size: 14px; line-height: 1.6; color: #CBD5E1; margin-bottom: 16px; }
    .ai-highlights-title { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-muted); margin-bottom: 8px; }
    .ai-bullets { list-style: none; display: flex; flex-direction: column; gap: 6px; margin-bottom: 16px; }
    .ai-bullets li { font-size: 13px; line-height: 1.5; padding: 7px 12px; background: var(--card-bg-subtle); border-left: 3px solid var(--accent-blue); border-radius: 4px; color: #E2E8F0; }
    .ai-bullets li.crit { border-left-color: var(--accent-red); }
    .ai-bullets li.warn { border-left-color: var(--accent-amber); }
    .ai-bullets li.ok { border-left-color: var(--accent-green); }
    .ai-recommendation-box { background: rgba(56, 189, 248, 0.08); border: 1px solid rgba(56, 189, 248, 0.25); border-radius: 10px; padding: 12px 16px; display: flex; align-items: center; gap: 10px; font-size: 13.5px; font-weight: 600; color: #FFF; }
    .ai-recommendation-box.danger { background: rgba(239, 68, 68, 0.08); border-color: rgba(239, 68, 68, 0.3); }
    .ai-recommendation-box.warn { background: rgba(245, 158, 11, 0.08); border-color: rgba(245, 158, 11, 0.3); }
    .ai-recommendation-box.clean { background: rgba(16, 185, 129, 0.08); border-color: rgba(16, 185, 129, 0.3); }

    /* Threat Score Breakdown Section */
    .score-breakdown-card { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 14px; padding: 20px 24px; margin-bottom: 20px; }
    .score-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; flex-wrap: wrap; gap: 10px; }
    .score-title { font-size: 15px; font-weight: 700; color: #FFF; display: flex; align-items: center; gap: 8px; }
    
    /* Scale Progress Bar */
    .scale-bar-wrapper { margin-bottom: 16px; }
    .scale-bar-track { display: flex; height: 10px; border-radius: 6px; overflow: hidden; background: rgba(255,255,255,0.06); margin-bottom: 6px; }
    .scale-seg { height: 100%; }
    .scale-seg.clean { width: 15%; background: var(--accent-green); }
    .scale-seg.low { width: 30%; background: var(--accent-amber); }
    .scale-seg.high { width: 30%; background: #F97316; }
    .scale-seg.crit { width: 25%; background: var(--accent-red); }
    .scale-labels { display: flex; justify-content: space-between; font-size: 10.5px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; }
    .scale-cursor-info { text-align: center; margin-top: 6px; font-size: 12px; font-weight: 700; color: var(--accent-blue); }

    /* Score Composition Grid */
    .calc-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 10px; margin-top: 12px; }
    .calc-box { background: var(--card-bg-subtle); border: 1px solid var(--card-border); border-radius: 10px; padding: 12px 14px; display: flex; justify-content: space-between; align-items: center; }
    .calc-box-left { display: flex; flex-direction: column; gap: 2px; }
    .calc-name { font-size: 11.5px; font-weight: 700; color: var(--text-muted); }
    .calc-formula { font-size: 10.5px; color: var(--text-dim); }
    .calc-points { font-size: 16px; font-weight: 800; color: #FFF; }

    /* Tabs Nav */
    .tabs-nav { display: flex; gap: 8px; margin-bottom: 18px; border-bottom: 1px solid var(--card-border); padding-bottom: 10px; overflow-x: auto; }
    .tab-btn { padding: 9px 18px; background: transparent; border: 1px solid transparent; color: var(--text-muted); font-size: 13.5px; font-weight: 600; cursor: pointer; border-radius: 8px; transition: all 0.15s ease; white-space: nowrap; }
    .tab-btn.active { background: #1E293B; color: var(--accent-blue); border-color: var(--card-border); }
    
    /* Filters */
    .filter-section { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 14px; padding: 16px; margin-bottom: 18px; display: flex; flex-direction: column; gap: 10px; }
    .search-row { display: flex; gap: 10px; flex-wrap: wrap; }
    .search-input { flex: 1; min-width: 250px; padding: 10px 14px; background: var(--card-bg-subtle); border: 1px solid var(--card-border); border-radius: 8px; color: #FFF; outline: none; font-size: 13.5px; }
    .search-input:focus { border-color: #0284C7; }
    .filter-group { display: flex; gap: 6px; flex-wrap: wrap; align-items: center; }
    .group-label { font-size: 11px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; margin-right: 4px; }
    .filter-btn { padding: 6px 12px; background: var(--card-bg-subtle); border: 1px solid var(--card-border); color: var(--text-muted); border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 11.5px; transition: all 0.15s ease; }
    .filter-btn.active, .filter-btn:hover { background: #334155; color: #FFF; border-color: #475569; }
    
    /* Finding Cards */
    .cards-list { display: flex; flex-direction: column; gap: 14px; }
    .f-card { background: var(--card-bg); border-left: 3px solid var(--accent-blue); border-top: 1px solid var(--card-border); border-right: 1px solid var(--card-border); border-bottom: 1px solid var(--card-border); border-radius: 12px; padding: 18px 22px; }
    .f-card.Critical { border-left-color: var(--accent-red); }
    .f-card.High { border-left-color: var(--accent-amber); }
    .f-card.Medium { border-left-color: var(--accent-blue); }
    .f-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; gap: 12px; flex-wrap: wrap; }
    .f-title { font-size: 15.5px; font-weight: 700; color: #FFF; }
    .badge { padding: 3px 10px; border-radius: 4px; font-size: 10.5px; font-weight: 700; text-transform: uppercase; }
    .badge.Critical { background: rgba(239, 68, 68, 0.15); color: var(--accent-red); border: 1px solid rgba(239,68,68,0.3); }
    .badge.High { background: rgba(245, 158, 11, 0.15); color: var(--accent-amber); border: 1px solid rgba(245,158,11,0.3); }
    .badge.Medium { background: rgba(56, 189, 248, 0.15); color: var(--accent-blue); border: 1px solid rgba(56,189,248,0.3); }
    .f-desc { color: var(--text-muted); font-size: 13.5px; margin-bottom: 10px; line-height: 1.5; }
    
    /* Plain English / Turkish Explanation Box */
    .f-plain-box { background: rgba(56, 189, 248, 0.05); border: 1px dashed rgba(56, 189, 248, 0.25); border-radius: 8px; padding: 9px 12px; margin-bottom: 10px; font-size: 12.5px; line-height: 1.5; color: #BAE6FD; display: flex; align-items: flex-start; gap: 8px; }
    .f-plain-box.Critical { background: rgba(239, 68, 68, 0.05); border-color: rgba(239, 68, 68, 0.25); color: #FECDD3; }
    .f-plain-box.High { background: rgba(245, 158, 11, 0.05); border-color: rgba(245, 158, 11, 0.25); color: #FEF3C7; }
    
    .f-evidence { background: var(--card-bg-subtle); border: 1px solid var(--card-border); padding: 10px 14px; border-radius: 8px; font-size: 12.5px; color: #94A3B8; display: flex; justify-content: space-between; align-items: center; gap: 10px; }
    .copy-btn { padding: 4px 10px; background: #1E293B; border: 1px solid var(--card-border); border-radius: 6px; color: var(--text-main); font-size: 11px; cursor: pointer; font-weight: 600; white-space: nowrap; }
    .copy-btn:hover { background: #334155; }
    .f-footer { margin-top: 12px; padding-top: 10px; border-top: 1px solid rgba(255, 255, 255, 0.05); font-size: 11.5px; color: var(--text-muted); display: flex; gap: 18px; flex-wrap: wrap; }
    .f-footer-item { display: inline-flex; gap: 4px; align-items: center; }
    .f-footer-item b { color: var(--text-main); }
    
    /* Mods Table */
    .mods-table { width: 100%; border-collapse: collapse; background: var(--card-bg); border-radius: 12px; overflow: hidden; border: 1px solid var(--card-border); }
    .mods-table th { background: #1E293B; padding: 12px 14px; text-align: left; font-size: 11.5px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; border-bottom: 1px solid var(--card-border); }
    .mods-table td { padding: 10px 14px; font-size: 12.5px; border-bottom: 1px solid var(--card-border); color: var(--text-main); }
    .mods-table tr:hover td { background: rgba(255, 255, 255, 0.02); }
    .tag-clean { color: var(--accent-green); font-weight: 600; background: rgba(16,185,129,0.1); padding: 2px 7px; border-radius: 4px; }
    .tag-susp { color: var(--accent-red); font-weight: 600; background: rgba(239,68,68,0.1); padding: 2px 7px; border-radius: 4px; }
    
    .tab-pane { display: none; }
    .tab-pane.active { display: block; }
  </style>

</head>
<body>
  <div class="container">
    <!-- Header Bar -->
    <div class="header-card">
      <div class="brand">
        <h1 id="ui_title">VORTEX APEX FORENSIC INTELLIGENCE SUITE</h1>
        <p><span id="ui_user_lbl">Hedef Kullan&#305;c&#305;:</span> <b>__USER__</b> | <span id="ui_host_lbl">Cihaz:</span> <b>__HOST__</b> | <span id="ui_date_lbl">Tarih:</span> __TIMESTAMP__ | <b style="color: var(--accent-blue);">Coded By BayrdY</b></p>
      </div>
      <div class="header-actions">
        <button class="action-btn lang-btn" onclick="toggleLanguage()"><span style="font-weight:900;">&#127760;</span> <span id="ui_lang_btn">Dil: T&#252;rk&#231;e</span></button>
        <button class="action-btn" onclick="copyReportJson()"><span style="font-weight:900;">&#128190;</span> <span id="ui_btn_export">JSON D&#305;&#351;a Aktar</span></button>
        <button class="action-btn" onclick="window.print()"><span style="font-weight:900;">&#128424;&#65039;</span> <span id="ui_btn_print">Yazd&#305;r / PDF</span></button>
      </div>
    </div>

    <!-- Top Dash Grid -->
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
          <div class="stat-label" id="ui_stat_crit">Kritik Tehditler</div>
          <div class="stat-val" style="color: var(--accent-red);">__CRIT__</div>
        </div>
        <div class="stat-box">
          <div class="stat-label" id="ui_stat_high">Y&#252;ksek Risk</div>
          <div class="stat-val" style="color: var(--accent-amber);">__HIGH__</div>
        </div>
        <div class="stat-box">
          <div class="stat-label" id="ui_stat_mods">Taranan JAR Modlar&#305;</div>
          <div class="stat-val">__TOTAL_JARS__</div>
        </div>
        <div class="stat-box">
          <div class="stat-label" id="ui_stat_speed">Tarama S&#252;resi</div>
          <div class="stat-val" style="color: var(--accent-green); font-size: 22px;">__ELAPSED__s</div>
        </div>
      </div>
    </div>

    <!-- SMART EXECUTIVE FORENSIC VERDICT & SUMMARY -->
    <div class="ai-summary-card" id="aiSummarySection">
      <div class="ai-header">
        <div class="ai-title">
          <span>&#129302;</span>
          <span id="ai_summary_title">Ak&#305;ll&#305; Analiz & Yetkili Karar&#305;</span>
        </div>
        <span class="ai-badge" id="ai_status_badge">&#304;nceleniyor...</span>
      </div>
      <div class="ai-desc" id="ai_assessment_text">
        Tarama verileri adli zeka motoru taraf&#305;ndan de&#287;erlendiriliyor...
      </div>
      <div class="ai-highlights-title" id="ai_highlights_lbl">&#214;nemli Bulgular & Tespit Nedenleri:</div>
      <ul class="ai-bullets" id="ai_bullets_list"></ul>
      <div class="ai-recommendation-box" id="ai_rec_box">
        <span style="font-size: 20px;" id="ai_rec_icon">&#9878;&#65039;</span>
        <span id="ai_rec_text">Yetkili Tavsiyesi: Y&#252;kleniyor...</span>
      </div>
    </div>

    <!-- THREAT SCORE BREAKDOWN PANEL -->
    <div class="score-breakdown-card">
      <div class="score-header">
        <div class="score-title">
          <span>&#128202;</span>
          <span id="ui_breakdown_title">Risk Puan&#305; Hesaplama & Kategori Da&#287;&#305;l&#305;m&#305;</span>
        </div>
        <div style="font-size: 13px; color: var(--text-muted);" id="ui_formula_lbl">
          Form&#252;l: (Kritik x 30) + (Y&#252;ksek x 15) + (Orta x 5)
        </div>
      </div>
      <div class="scale-bar-wrapper">
        <div class="scale-bar-track">
          <div class="scale-seg clean" title="0-15: Temiz / G&#252;venli"></div>
          <div class="scale-seg low" title="16-45: &#350;&#252;pheli / &#304;ncelenmeli"></div>
          <div class="scale-seg high" title="46-75: Y&#252;ksek Risk"></div>
          <div class="scale-seg crit" title="76-100: Kesin Hile / Ban"></div>
        </div>
        <div class="scale-labels">
          <span style="color: var(--accent-green);" id="ui_scale_clean">&#128994; 0-15: G&#220;VENL&#304;</span>
          <span style="color: var(--accent-amber);" id="ui_scale_susp">&#128993; 16-45: &#350;&#220;PHEL&#304;</span>
          <span style="color: #F97316;" id="ui_scale_high">&#128999; 46-75: Y&#220;KSEK R&#304;SK</span>
          <span style="color: var(--accent-red);" id="ui_scale_ban">&#128308; 76-100: KES&#304;N H&#304;LE / BAN</span>
        </div>
        <div class="scale-cursor-info" id="ui_score_summary_badge">Mevcut Risk Puan&#305;: __SCORE__ / 100</div>
      </div>
      <div class="calc-grid" id="calcGrid"></div>
    </div>

    <!-- TABS -->
    <div class="tabs-nav">
      <button class="tab-btn active" onclick="switchTab('tab-findings', this)" id="tabBtnFindings">&#9888;&#65039; <span id="ui_tab_findings">Tespitler & Anomaliler</span> (__FINDINGS_COUNT__)</button>
      <button class="tab-btn" onclick="switchTab('tab-mods', this)" id="tabBtnMods">&#128230; <span id="ui_tab_mods">Mod Envanteri</span> (__TOTAL_JARS__)</button>
    </div>
    
    <!-- FINDINGS TAB -->
    <div id="tab-findings" class="tab-pane active">
      <div class="filter-section">
        <div class="search-row">
          <input type="text" id="searchInput" class="search-input" placeholder="Hile ad&#305;, imza, dosya yolu veya kan&#305;t ara..." onkeyup="filterFindings()">
        </div>
        <div class="filter-group">
          <span class="group-label" id="ui_lbl_sev">&#214;nem Derecesi:</span>
          <button class="filter-btn active" onclick="setSeverityFilter('all', this)" id="ui_btn_all_sev">T&#252;m&#252; (__FINDINGS_COUNT__)</button>
          <button class="filter-btn" onclick="setSeverityFilter('Critical', this)"><span id="ui_btn_crit">Kritik</span> (__CRIT__)</button>
          <button class="filter-btn" onclick="setSeverityFilter('High', this)"><span id="ui_btn_high">Y&#252;ksek</span> (__HIGH__)</button>
          <button class="filter-btn" onclick="setSeverityFilter('Medium', this)"><span id="ui_btn_med">Orta</span> (__MED__)</button>
        </div>
        <div class="filter-group">
          <span class="group-label" id="ui_lbl_cat">Kategori:</span>
          <button class="filter-btn active" onclick="setCategoryFilter('all', this)" id="ui_btn_all_cat">T&#252;m Kategoriler</button>
          <button class="filter-btn" onclick="setCategoryFilter('Memory', this)" id="ui_btn_mem">RAM / Bellek</button>
          <button class="filter-btn" onclick="setCategoryFilter('Bytecode', this)">Bytecode / Mod</button>
          <button class="filter-btn" onclick="setCategoryFilter('Forensics', this)" id="ui_btn_forensic">Adli Kay&#305;tlar</button>
          <button class="filter-btn" onclick="setCategoryFilter('Cleaner', this)" id="ui_btn_clean">Temizleyiciler & Silmeler</button>
          <button class="filter-btn" onclick="setCategoryFilter('Security', this)" id="ui_btn_sec">G&#252;venlik & &#199;ekirdek</button>
          <button class="filter-btn" onclick="setCategoryFilter('Network', this)" id="ui_btn_net">A&#287; & DNS</button>
        </div>
      </div>
      <div class="cards-list" id="findingsList"></div>
    </div>
    
    <!-- MODS INVENTORY TAB -->
    <div id="tab-mods" class="tab-pane">
      <div class="filter-section">
        <div class="search-row">
          <input type="text" id="modSearchInput" class="search-input" placeholder="JAR ad&#305;, SHA-1 &#246;zeti veya Mod ID ile filtrele..." onkeyup="filterMods()">
        </div>
        <div class="filter-group">
          <span class="group-label" id="ui_lbl_status">Durum:</span>
          <button class="filter-btn active" onclick="setModStatusFilter('all', this)" id="ui_btn_all_mods">T&#252;m Modlar (__TOTAL_JARS__)</button>
          <button class="filter-btn" onclick="setModStatusFilter('SUSPICIOUS', this)" id="ui_btn_susp_only">&#9888;&#65039; Yaln&#305;zca &#350;&#252;pheli / Hile</button>
          <button class="filter-btn" onclick="setModStatusFilter('CLEAN', this)" id="ui_btn_clean_only">&#10004; Yaln&#305;zca Temiz</button>
        </div>
      </div>
      <table class="mods-table">
        <thead>
          <tr>
            <th id="ui_th_file">Dosya Ad&#305;</th>
            <th id="ui_th_hash">SHA-1 &#214;zeti</th>
            <th id="ui_th_size">Boyut</th>
            <th id="ui_th_id">Mod ID</th>
            <th id="ui_th_status">Durum</th>
          </tr>
        </thead>
        <tbody id="modsTableBody"></tbody>
      </table>
    </div>

    <!-- Footer -->
    <div style="margin-top: 35px; padding: 20px 0; border-top: 1px solid var(--card-border); text-align: center; color: var(--text-muted); font-size: 12.5px; letter-spacing: 0.5px;">
      <span style="color: var(--accent-blue); font-weight: 700;">VORTEX APEX (VORTEX-AC)</span> &bull; ADVANCED FORENSIC INTELLIGENCE SUITE &bull; <span style="color: #FFF; font-weight: 700;">Coded By BayrdY</span>
    </div>
  </div>

  <script>
    const findingsData = __JSON_FINDINGS__;
    const modsData = __JSON_MODS__;
    const totalScore = __SCORE__;
    const critCount = __CRIT__;
    const highCount = __HIGH__;
    const medCount = __MED__;
    
    let currentSeverity = "all";
    let currentCategory = "all";
    let currentModStatus = "all";
    let isTurkish = true;

    const plainExplDictionary = {
      "Active RAM Cheat Signature": {
        tr: "Minecraft oyunu \u00E7al\u0131\u015F\u0131rken bilgisayar belle\u011Finde (RAM) hile kodlar\u0131 yakaland\u0131. Bu durum do\u011Frudan canl\u0131 hile kullan\u0131m\u0131n\u0131 veya arka planda \u00E7al\u0131\u015Fan bir injector/ghost client oldu\u011Funu kan\u0131tlar.",
        en: "Live cheat routines were found loaded directly inside the active Minecraft javaw.exe RAM space, confirming live cheat injection."
      },
      "Untrusted / Injected DLL Loaded in Java": {
        tr: "Minecraft JVM s\u00FCrecine harici bir DLL k\u00FCt\u00FCphanesi enjekte edilmi\u015F. Bu i\u015Flem genelde ESP, Chams veya otomatik t\u0131klay\u0131c\u0131 gibi hileleri oyuna sokmak i\u00E7in yap\u0131l\u0131r.",
        en: "An unverified dynamic link library (.dll) was injected into the Minecraft JVM process from a non-system folder."
      },
      "USN Journal Deleted File Record": {
        tr: "Oyuncu denetimden hemen \u00F6nce bir hile veya istemci dosyas\u0131n\u0131 silmi\u015F. Windows dosya sistemi g\u00FCnl\u00FC\u011F\u00FC (USN), silinen dosyan\u0131n ad\u0131n\u0131 ve tam silinme saatini kaydetmi\u015Ftir.",
        en: "The player recently deleted a cheat file prior to inspection. The NTFS change journal recorded the exact filename and deletion timestamp."
      },
      "Deleted Cheat in Recycle Bin": {
        tr: "Geri D\u00F6n\u00FC\u015F\u00FCm Kutusunda daha \u00F6nce indirilmi\u015F veya silinmi\u015F hile dosyas\u0131/ar\u015Fivi tespit edildi.",
        en: "A cheat executable or archive was found resting in the Windows Recycle Bin."
      },
      "Prefetch Execution Trace": {
        tr: "Windows Prefetch haf\u0131zas\u0131, bu hile program\u0131n\u0131n yak\u0131n zamanda bilgisayarda bizzat \u00E7al\u0131\u015Ft\u0131r\u0131ld\u0131\u011F\u0131n\u0131 kan\u0131tl\u0131yor.",
        en: "Windows Prefetch recorded historical execution of this cheat program on this machine."
      },
      "BAM Execution Record": {
        tr: "Windows Arka Plan Aktivite Y\u00F6neticisi (BAM), bu kullan\u0131c\u0131n\u0131n hile program\u0131n\u0131 \u00E7al\u0131\u015Ft\u0131rd\u0131\u011F\u0131n\u0131 kay\u0131t alt\u0131na alm\u0131\u015F.",
        en: "Background Activity Moderator recorded execution of this cheat binary under the user SID."
      },
      "UserAssist GUI Execution Record": {
        tr: "Kullan\u0131c\u0131 hile uygulamas\u0131n\u0131 masa\u00FCst\u00FCnden veya bir klas\u00F6rden \u00E7ift t\u0131klayarak \u00E7al\u0131\u015Ft\u0131rm\u0131\u015F.",
        en: "UserAssist logs confirm the user launched this cheat application from the graphical desktop interface."
      },
      "MUICache Execution Trace": {
        tr: "Windows uygulama \u00F6nbelle\u011Finde bu hile program\u0131n\u0131n \u00E7al\u0131\u015Ft\u0131r\u0131ld\u0131\u011F\u0131na dair kay\u0131t bulundu.",
        en: "MUICache registry stores an execution trace for this executable."
      },
      "Cheat / Macro Signatures Detected in Mod": {
        tr: "Minecraft mod dosyas\u0131n\u0131n (JAR) i\u00E7ine gizlenmi\u015F PvP makrosu, Reach veya AutoClicker kodlar\u0131 bulundu.",
        en: "The JAR mod contains compiled Java bytecode signatures matching known PvP macros and cheat routines."
      },
      "Suspicious Native OS Command Execution in Bytecode": {
        tr: "Mod dosyas\u0131 Minecraft d\u0131\u015F\u0131na \u00E7\u0131karak i\u015Fletim sisteminde gizli komutlar (cmd/powershell/vssadmin) \u00E7al\u0131\u015Ft\u0131rmaya \u00E7al\u0131\u015F\u0131yor.",
        en: "Mod executes arbitrary operating system commands inside bytecode (ProcessBuilder / Runtime.exec)."
      },
      "Commercial / Cheat Java Obfuscator Signature": {
        tr: "Mod dosyas\u0131 kodlar\u0131 gizlemek i\u00E7in ticari hile yap\u0131mc\u0131lar\u0131n\u0131n kulland\u0131\u011F\u0131 a\u011F\u0131r karart\u0131c\u0131larla (Zelix, Radon vb.) \u015Fifrelenmi\u015F.",
        en: "Mod was protected using obfuscators commonly favored by commercial cheat developers."
      },
      "Malicious Token Stealer / Webhook Exfiltration Detected": {
        tr: "Mod i\u00E7erisinde oyuncunun Discord veya oturum tokenlar\u0131n\u0131 \u00E7almaya \u00E7al\u0131\u015Fan zararl\u0131 yaz\u0131l\u0131m kodu tespit edildi.",
        en: "Mod contains embedded Discord webhook or browser token exfiltration endpoints."
      },
      "Hardware Macro / LUA AutoClicker Script Detected": {
        tr: "Logitech, Razer veya Bloody faresine ait otomatik t\u0131klama (AutoClicker) veya sekme engelleme (NoRecoil) makro beti\u011Fi bulundu.",
        en: "A gaming mouse macro script designed for automated CPS or recoil compensation was discovered."
      },
      "Cheat Keyword Search in Everything History": {
        tr: "Kullan\u0131c\u0131 denetim \u00F6ncesinde Everything arama program\u0131nda hile veya log temizleyici ara\u00E7lar\u0131 aram\u0131\u015F.",
        en: "User searched for cheat binaries or forensic cleaner tools in Voidtools Everything search history."
      },
      "Cheat / Ghost Client Domain in DNS Cache": {
        tr: "Bilgisayar bilinen bir hile web sitesine veya lisans do\u011Frulama sunucusuna (Vape, Drip vb.) ba\u011Flanm\u0131\u015F.",
        en: "Computer resolved a DNS query for a known cheat authentication server or client website."
      },
      "Anti-Forensic Cleaner Command in PowerShell History": {
        tr: "PowerShell ge\u00E7mi\u015Finde denetimi atlatmak i\u00E7in loglar\u0131 veya USN g\u00FCnl\u00FC\u011F\u00FCn\u00FC silmeye \u00E7al\u0131\u015Fan temizleyici komutlar \u00E7al\u0131\u015Ft\u0131r\u0131lm\u0131\u015F.",
        en: "PowerShell history contains evidence of log clearing or forensic journal purging."
      },
      "Self-Destruct Cleaner Batch Script in %TEMP%": {
        tr: "Hile program\u0131n\u0131n arkas\u0131nda b\u0131rakt\u0131\u011F\u0131 kendini imha eden (self-destruct) temizleme beti\u011Fi bulundu.",
        en: "A self-deleting batch script commonly dropped by cheat self-destruct routines was discovered."
      },
      "Suspicious Windows Defender Path Exclusion": {
        tr: "Windows Defender'\u0131n hileleri yakalamas\u0131n\u0131 engellemek i\u00E7in baz\u0131 klas\u00F6rler antivir\u00FCs taramas\u0131ndan hari\u00E7 tutulmu\u015F.",
        en: "A critical folder is excluded from Windows Defender real-time scanning to bypass detection."
      }
    };

    const trDictionary = {
      "Suspicious Native OS Command Execution in Bytecode": "Bytecode \u0130\u00E7inde \u015E\u00FCpheli Komut \u00C7al\u0131\u015Ft\u0131rma",
      "Mod executes arbitrary operating system commands inside bytecode.": "Mod, Java bytecode i\u00E7erisinde i\u015Fletim sistemi komutlar\u0131 \u00E7al\u0131\u015Ft\u0131rmaktad\u0131r.",
      "Cheat / Macro Signatures Detected in Mod": "Mod \u0130\u00E7inde Hile / Makro \u0130mzalar\u0131 Tespit Edildi",
      "Malicious Token Stealer / Webhook Exfiltration Detected": "Zararl\u0131 Token \u00C7al\u0131c\u0131 / Webhook S\u0131z\u0131nt\u0131s\u0131 Tespit Edildi",
      "Commercial / Cheat Java Obfuscator Signature": "Ticari / Hile Java Karart\u0131c\u0131 (Obfuscator) \u0130mzas\u0131",
      "Active RAM Cheat Signature": "Canl\u0131 RAM Hile \u0130mzas\u0131",
      "Untrusted / Injected DLL Loaded in Java": "Java'ya Y\u00FCklenen G\u00FCvenilmeyen / Enjekte Edilmi\u015F DLL",
      "Prefetch Execution Trace": "Prefetch \u00C7al\u0131\u015Ft\u0131rma \u0130zi",
      "BAM Execution Record": "BAM \u00C7al\u0131\u015Ft\u0131rma Kayd\u0131",
      "UserAssist GUI Execution Record": "UserAssist Aray\u00FCz \u00C7al\u0131\u015Ft\u0131rma Kayd\u0131",
      "MUICache Execution Trace": "MUICache \u00C7al\u0131\u015Ft\u0131rma \u0130zi",
      "Deleted Cheat in Recycle Bin": "Geri D\u00F6n\u00FC\u015F\u00FCm Kutusunda Silinmi\u015F Hile",
      "USN Journal Deleted File Record": "USN G\u00FCnl\u00FC\u011F\u00FC Silinmi\u015F Dosya Kayd\u0131",
      "Anti-Forensic Cleaner Command in PowerShell History": "PowerShell Ge\u00E7mi\u015Finde Temizleyici Komut",
      "Self-Destruct Cleaner Batch Script in %TEMP%": "%TEMP% Klas\u00F6r\u00FCnde Kendini Silen Temizleyici Betik",
      "Suspicious Windows Defender Path Exclusion": "Windows Defender \u015E\u00FCpheli Dizin D\u0131\u015Flama Tespiti",
      "Cheat / Ghost Client Domain in DNS Cache": "DNS \u00D6nbelle\u011Finde Hile / Ghost Client Alan Ad\u0131",
      "Hardware Macro / LUA AutoClicker Script Detected": "Donan\u0131m Makrosu / LUA AutoClicker Beti\u011Fi Tespit Edildi",
      "Cheat Keyword Search in Everything History": "Everything Arama Ge\u00E7mi\u015Finde Hile Arama \u0130zi"
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

    function getPlainExplanation(title, severity) {
      for (const [key, val] of Object.entries(plainExplDictionary)) {
        if (title.indexOf(key) !== -1) {
          return isTurkish ? val.tr : val.en;
        }
      }
      if (severity === "Critical") {
        return isTurkish ? "Bu bulgu, oyunda haks\u0131z avantaj sa\u011Flayan veya denetimden ka\u00E7maya y\u00F6nelik do\u011Frudan bir ihlale i\u015Faret eder." : "This finding indicates a severe anomaly or direct violation.";
      } else if (severity === "High") {
        return isTurkish ? "Bu bulgu, \u015F\u00FCpheli bir hile kal\u0131nt\u0131s\u0131 veya do\u011Frulanmam\u0131\u015F sistem aktivitesini temsil eder." : "This finding represents a suspicious artifact or unverified activity.";
      }
      return isTurkish ? "D\u00FC\u015F\u00FCk riskli sistem uyar\u0131s\u0131 veya s\u0131ra d\u0131\u015F\u0131 dosya kayd\u0131." : "Low-risk system warning or unusual file trace.";
    }

    function renderExecutiveBullets() {
      const bulletsList = document.getElementById("ai_bullets_list");
      bulletsList.innerHTML = "";

      const grouped = new Map();
      findingsData.forEach(function(f) {
        const key = f.Title;
        const baseName = f.TargetPath ? f.TargetPath.split(/[\\/]/).pop() : "";
        if (!grouped.has(key)) {
          grouped.set(key, {
            finding: f,
            count: 1,
            files: baseName ? [baseName] : []
          });
        } else {
          const g = grouped.get(key);
          g.count++;
          if (baseName && !g.files.includes(baseName)) {
            g.files.push(baseName);
          }
        }
      });

      const sorted = Array.from(grouped.values()).sort((a, b) => {
        const scoreMap = { "Critical": 3, "High": 2, "Medium": 1, "Low": 0 };
        return (scoreMap[b.finding.Severity] || 0) - (scoreMap[a.finding.Severity] || 0);
      });

      sorted.slice(0, 6).forEach(function(g) {
        const f = g.finding;
        const item = document.createElement("li");
        item.className = f.Severity === "Critical" ? "crit" : (f.Severity === "High" ? "warn" : "ok");
        const icon = f.Severity === "Critical" ? "&#10060; " : (f.Severity === "High" ? "&#9888;&#65039; " : "&#128269; ");
        
        let locInfo = "";
        if (g.files.length > 0) {
          if (g.count > 1) {
            locInfo = ' <i style="color: #94A3B8; font-size: 12px; font-weight: normal;">(' + g.count + (isTurkish ? ' farkl\u0131 dosyada: ' : ' different files: ') + g.files.slice(0, 2).join(", ") + (g.files.length > 2 ? ' ...' : '') + ')</i>';
          } else {
            locInfo = ' <i style="color: #94A3B8; font-size: 12px; font-weight: normal;">(' + g.files[0] + ')</i>';
          }
        }

        item.innerHTML = icon + '<b>' + translateText(f.Title) + locInfo + ':</b> ' + getPlainExplanation(f.Title, f.Severity);
        bulletsList.appendChild(item);
      });

      if (sorted.length < 3) {
        const hasMemCheat = findingsData.some(f => f.Category === "Memory");
        const hasDeletedCheat = findingsData.some(f => f.Category === "Cleaner" || f.Category === "Forensics");
        
        if (!hasMemCheat) {
          const okMem = document.createElement("li");
          okMem.className = "ok";
          okMem.innerHTML = '&#10004; <b>' + (isTurkish ? "RAM / Canl\u0131 Bellek Denetimi: " : "RAM & Live Heap: ") + '</b>' + (isTurkish ? "Aktif Minecraft JVM s\u00FCrecinde \u00E7al\u0131\u015Fan enjeksiyon veya ghost client bulunamad\u0131." : "No active injected cheat strings in running Minecraft RAM.");
          bulletsList.appendChild(okMem);
        }
        if (!hasDeletedCheat) {
          const okForn = document.createElement("li");
          okForn.className = "ok";
          okForn.innerHTML = '&#10004; <b>' + (isTurkish ? "Adli Log Silme & USN Journal: " : "Forensic Log Purge Check: ") + '</b>' + (isTurkish ? "Denetim \u00F6ncesi log temizleme, USN sildirme veya iz gizleme faaliyeti tespit edilmedi." : "No anti-forensic log tampering or USN journal deletion detected.");
          bulletsList.appendChild(okForn);
        }
      }
    }

    function updateExecutiveSummary() {
      const badge = document.getElementById("ai_status_badge");
      const desc = document.getElementById("ai_assessment_text");
      const bulletsList = document.getElementById("ai_bullets_list");
      const recBox = document.getElementById("ai_rec_box");
      const recIcon = document.getElementById("ai_rec_icon");
      const recText = document.getElementById("ai_rec_text");

      bulletsList.innerHTML = "";

      if (totalScore === 0) {
        badge.className = "ai-badge clean";
        badge.innerHTML = isTurkish ? "&#128994; TEM\u0130Z VE G\u00DCVENL\u0130" : "&#128994; CLEAN & VERIFIED";
        desc.innerText = isTurkish ? 
          "Yap\u0131lan derin adli inceleme sonucunda hedef sistemde ve Minecraft dosyalar\u0131nda hi\u00E7bir aktif hile, enjeksiyon, silinmi\u015F dosya kal\u0131nt\u0131s\u0131 veya log temizleme faaliyeti tespit edilmedi. Sistem standart ve temizdir." :
          "Comprehensive forensic inspection detected zero active cheats, injected modules, deleted cheat artifacts, or anti-forensic cleaner routines. System is verified clean.";
        
        bulletsList.innerHTML = isTurkish ? 
          '<li class="ok">&#10004; <b>RAM & Bellek:</b> javaw.exe adres alan\u0131nda hile deseni bulunamad\u0131.</li>' +
          '<li class="ok">&#10004; <b>Dosya B\u00FCt\u00FCnl\u00FC\u011F\u00FC:</b> Taranan t\u00FCm JAR modlar\u0131 standart ve temiz.</li>' +
          '<li class="ok">&#10004; <b>Adli Kay\u0131tlar:</b> Prefetch, BAM ve USN g\u00FCnl\u00FCklerinde silinmi\u015F hile izi yok.</li>' :
          '<li class="ok">&#10004; <b>RAM & Memory:</b> No cheat signatures in active javaw.exe process heap.</li>' +
          '<li class="ok">&#10004; <b>File Integrity:</b> All scanned JAR mods match clean baseline standards.</li>' +
          '<li class="ok">&#10004; <b>Forensics:</b> Zero deleted artifacts found in Prefetch, BAM, or USN journals.</li>';

        recBox.className = "ai-recommendation-box clean";
        recIcon.innerHTML = "&#9989;";
        recText.innerHTML = isTurkish ? 
          "<b>Yetkili Karar\u0131 / Tavsiye:</b> Oyuncunun sistemi tamamen temiz. Herhangi bir yapt\u0131r\u0131m gerekmez, oyuna / turnuvaya devam edebilir." :
          "<b>Staff Recommendation:</b> Player is clean. No restrictions required, verified for competitive play.";
      } else if (totalScore <= 20 && critCount === 0) {
        badge.className = "ai-badge susp";
        badge.innerHTML = isTurkish ? "&#128993; D\u00DC\u015E\u00DCK R\u0130SK / \u0130NCELENMEL\u0130" : "&#128993; LOW RISK / REVIEW";
        desc.innerText = isTurkish ?
          "Sistemde d\u00FC\u015F\u00FCk seviyeli baz\u0131 \u015F\u00FCpheli kay\u0131tlar veya do\u011Frulanmam\u0131\u015F sistem d\u0131\u015Flamalar\u0131 bulundu. Ancak canl\u0131 hile enjeksiyonu do\u011Frudan tespit edilmedi." :
          "Minor suspicious anomalies or unverified exclusions detected, though no active memory cheat was directly found.";

        renderExecutiveBullets();

        recBox.className = "ai-recommendation-box warn";
        recIcon.innerHTML = "&#9888;&#65039;";
        recText.innerHTML = isTurkish ?
          "<b>Yetkili Karar\u0131 / Tavsiye:</b> Kritik bir hile yok. \u015E\u00FCpheli bulunan mod dosyas\u0131n\u0131 veya DNS ge\u00E7mi\u015Fini ekran payla\u015F\u0131m\u0131nda kontrol etmeniz \u00F6nerilir." :
          "<b>Staff Recommendation:</b> No critical cheat detected. Manually verify the flagged mod or DNS endpoint if needed.";
      } else if (totalScore <= 55) {
        badge.className = "ai-badge susp";
        badge.innerHTML = isTurkish ? "&#128999; Y\u00DCKSEK R\u0130SK / H\u0130LE \u015E\u00DCPHES\u0130" : "&#128999; HIGH RISK SUSPECT";
        desc.innerText = isTurkish ?
          "Sistemde yak\u0131n zamanda silinmi\u015F hile dosyas\u0131 (USN), fare makro profili veya hile indirme ge\u00E7mi\u015Fi tespit edildi. Oyuncunun hile bulundurdu\u011Funa dair g\u00FC\u00E7l\u00FC adli kan\u0131tlar mevcuttur." :
          "Forensics revealed recently deleted cheat files (USN), mouse macros, or download history. Strong forensic evidence of cheat possession.";

        renderExecutiveBullets();

        recBox.className = "ai-recommendation-box warn";
        recIcon.innerHTML = "&#9878;&#65039;";
        recText.innerHTML = isTurkish ?
          "<b>Yetkili Karar\u0131 / Tavsiye:</b> Oyuncuda a\u00E7\u0131k hile / makro izleri mevcut. Lig ve sunucu kurallar\u0131na g\u00F6re i\u015Flem yap\u0131lmal\u0131 veya manuel ekran denetimi istenmelidir." :
          "<b>Staff Recommendation:</b> Clear cheat or macro artifacts found. Take appropriate league/server action.";
      } else {
        badge.className = "ai-badge danger";
        badge.innerHTML = isTurkish ? "&#128308; KR\u0130T\u0130K H\u0130LE TESP\u0130T\u0130 (BAN)" : "&#128308; CRITICAL CHEAT / BAN";
        desc.innerText = isTurkish ?
          "D\u0130KKAT: Minecraft RAM belle\u011Finde aktif hile imzas\u0131, bytecode seviyesinde gizli hile mod\u00FCl\u00FC veya denetimden delil ka\u00E7\u0131rmak i\u00E7in log temizleme faaliyeti tespit edildi!" :
          "CRITICAL ALERT: Active live RAM cheat descriptors, malicious mod bytecode, or deliberate anti-forensic log wiping detected!";

        renderExecutiveBullets();

        recBox.className = "ai-recommendation-box danger";
        recIcon.innerHTML = "&#128296;";
        recText.innerHTML = isTurkish ?
          "<b>Yetkili Karar\u0131 / Tavsiye:</b> Do\u011Frudan H\u0130LE \u0130HLAL\u0130. Oyuncunun hile kulland\u0131\u011F\u0131 veya kan\u0131tlar\u0131 sildi\u011Fi kesinle\u015Fti. Do\u011Frudan BAN / Men cezas\u0131 uygulanmas\u0131 \u00F6nerilir." :
          "<b>Staff Recommendation:</b> DEFINITE CHEAT VIOLATION. Direct ban / disqualification strongly recommended.";
      }
    }

    function updateScoreBreakdown() {
      const grid = document.getElementById("calcGrid");
      const critPoints = critCount * 30;
      const highPoints = highCount * 15;
      const medPoints = medCount * 5;

      const memPoints = findingsData.filter(f => f.Category === "Memory").reduce((acc, f) => acc + (f.Severity === "Critical" ? 30 : (f.Severity === "High" ? 15 : 5)), 0);
      const modPoints = findingsData.filter(f => f.Category === "Bytecode" || f.Category === "Obfuscation").reduce((acc, f) => acc + (f.Severity === "Critical" ? 30 : (f.Severity === "High" ? 15 : 5)), 0);
      const clnPoints = findingsData.filter(f => f.Category === "Cleaner" || f.Category === "Forensics").reduce((acc, f) => acc + (f.Severity === "Critical" ? 30 : (f.Severity === "High" ? 15 : 5)), 0);

      grid.innerHTML = 
        '<div class="calc-box">' +
          '<div class="calc-box-left">' +
            '<span class="calc-name" style="color: var(--accent-red);">' + (isTurkish ? "Kritik Bulgular" : "Critical Findings") + '</span>' +
            '<span class="calc-formula">' + critCount + ' &#215; 30 ' + (isTurkish ? "Puan" : "pts") + '</span>' +
          '</div>' +
          '<div class="calc-points" style="color: var(--accent-red);">+' + critPoints + '</div>' +
        '</div>' +
        '<div class="calc-box">' +
          '<div class="calc-box-left">' +
            '<span class="calc-name" style="color: var(--accent-amber);">' + (isTurkish ? "Y\u00FCksek Risk Bulgular" : "High Risk Findings") + '</span>' +
            '<span class="calc-formula">' + highCount + ' &#215; 15 ' + (isTurkish ? "Puan" : "pts") + '</span>' +
          '</div>' +
          '<div class="calc-points" style="color: var(--accent-amber);">+' + highPoints + '</div>' +
        '</div>' +
        '<div class="calc-box">' +
          '<div class="calc-box-left">' +
            '<span class="calc-name" style="color: var(--accent-blue);">' + (isTurkish ? "Orta Risk Bulgular" : "Medium Findings") + '</span>' +
            '<span class="calc-formula">' + medCount + ' &#215; 5 ' + (isTurkish ? "Puan" : "pts") + '</span>' +
          '</div>' +
          '<div class="calc-points" style="color: var(--accent-blue);">+' + medPoints + '</div>' +
        '</div>' +
        '<div class="calc-box">' +
          '<div class="calc-box-left">' +
            '<span class="calc-name">' + (isTurkish ? "RAM / Bellek \u0130hlali" : "RAM & Memory") + '</span>' +
            '<span class="calc-formula">' + (isTurkish ? "Canl\u0131 bellek etkisi" : "Live memory impact") + '</span>' +
          '</div>' +
          '<div class="calc-points" style="color: ' + (memPoints > 0 ? "var(--accent-red)" : "var(--accent-green)") + ';">' + memPoints + 'p</div>' +
        '</div>' +
        '<div class="calc-box">' +
          '<div class="calc-box-left">' +
            '<span class="calc-name">' + (isTurkish ? "Silinmi\u015F Hile / USN" : "Deleted / Forensics") + '</span>' +
            '<span class="calc-formula">' + (isTurkish ? "Adli silme izleri" : "Anti-forensic logs") + '</span>' +
          '</div>' +
          '<div class="calc-points" style="color: ' + (clnPoints > 0 ? "var(--accent-amber)" : "var(--accent-green)") + ';">' + clnPoints + 'p</div>' +
        '</div>';

      document.getElementById("ui_score_summary_badge").innerText = 
        (isTurkish ? "Mevcut Risk Puan\u0131: " : "Calculated Threat Score: ") + totalScore + " / 100";
    }

    function toggleLanguage() {
      isTurkish = !isTurkish;
      document.getElementById("ui_lang_btn").innerText = isTurkish ? "Dil: T\u00FCrk\u00E7e" : "Language: English";
      applyLanguageTexts();
      updateExecutiveSummary();
      updateScoreBreakdown();
      renderFindings(filterFindingsData());
      renderMods(filterModsData());
    }

    function applyLanguageTexts() {
      if (isTurkish) {
        document.getElementById("ui_title").innerText = "VORTEX APEX ANTICHEAT H\u0130LE RAPORU";
        document.getElementById("ui_user_lbl").innerText = "Hedef Kullan\u0131c\u0131:";
        document.getElementById("ui_host_lbl").innerText = "Cihaz:";
        document.getElementById("ui_date_lbl").innerText = "Tarih:";
        document.getElementById("ui_btn_export").innerText = "JSON D\u0131\u015Fa Aktar";
        document.getElementById("ui_btn_print").innerText = "Yazd\u0131r / PDF";
        document.getElementById("ui_stat_crit").innerText = "Kritik Tehditler";
        document.getElementById("ui_stat_high").innerText = "Y\u00FCksek Risk";
        document.getElementById("ui_stat_mods").innerText = "Taranan JAR Modlar\u0131";
        document.getElementById("ui_stat_speed").innerText = "Tarama S\u00FCresi";
        document.getElementById("ai_summary_title").innerText = "Ak\u0131ll\u0131 Analiz & Yetkili Karar\u0131";
        document.getElementById("ai_highlights_lbl").innerText = "\u00D6nemli Bulgular & Tespit Nedenleri:";
        document.getElementById("ui_breakdown_title").innerText = "Risk Puan\u0131 Hesaplama & Kategori Da\u011F\u0131l\u0131m\u0131";
        document.getElementById("ui_formula_lbl").innerText = "Form\u00FCl: (Kritik x 30) + (Y\u00FCksek x 15) + (Orta x 5)";
        document.getElementById("ui_scale_clean").innerHTML = "&#128994; 0-15: G\u00DCVENL\u0130";
        document.getElementById("ui_scale_susp").innerHTML = "&#128993; 16-45: \u015E\u00DCPHEL\u0130";
        document.getElementById("ui_scale_high").innerHTML = "&#128999; 46-75: Y\u00DCKSEK R\u0130SK";
        document.getElementById("ui_scale_ban").innerHTML = "&#128308; 76-100: KES\u0130N H\u0130LE / BAN";
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
        document.getElementById("ui_btn_forensic").innerText = "Adli Kay\u0131tlar";
        document.getElementById("ui_btn_clean").innerText = "Temizleyiciler & Silmeler";
        document.getElementById("ui_btn_sec").innerText = "G\u00FCvenlik & \u00C7ekirdek";
        document.getElementById("ui_btn_net").innerText = "A\u011F & DNS";
        document.getElementById("ui_lbl_status").innerText = "Durum:";
        document.getElementById("ui_btn_all_mods").innerText = "T\u00FCm Modlar (" + modsData.length + ")";
        document.getElementById("ui_btn_susp_only").innerHTML = "&#9888;&#65039; Yaln\u0131zca \u015E\u00FCpheli / Hile";
        document.getElementById("ui_btn_clean_only").innerHTML = "&#10004; Yaln\u0131zca Temiz";
        document.getElementById("ui_th_file").innerText = "Dosya Ad\u0131";
        document.getElementById("ui_th_hash").innerText = "SHA-1 \u00D6zeti";
        document.getElementById("ui_th_size").innerText = "Boyut";
        document.getElementById("ui_th_id").innerText = "Mod ID";
        document.getElementById("ui_th_status").innerText = "Durum";
        document.getElementById("searchInput").placeholder = "Hile ad\u0131, imza, dosya yolu veya kan\u0131t ara...";
        document.getElementById("modSearchInput").placeholder = "JAR ad\u0131, SHA-1 \u00F6zeti veya Mod ID ile filtrele...";
      } else {
        document.getElementById("ui_title").innerText = "VORTEX APEX FORENSIC INTELLIGENCE SUITE";
        document.getElementById("ui_user_lbl").innerText = "Target User:";
        document.getElementById("ui_host_lbl").innerText = "Host:";
        document.getElementById("ui_date_lbl").innerText = "Date:";
        document.getElementById("ui_btn_export").innerText = "Export JSON";
        document.getElementById("ui_btn_print").innerText = "Print / PDF";
        document.getElementById("ui_stat_crit").innerText = "Critical Threats";
        document.getElementById("ui_stat_high").innerText = "High Risk";
        document.getElementById("ui_stat_mods").innerText = "Scanned JAR Mods";
        document.getElementById("ui_stat_speed").innerText = "Scan Speed";
        document.getElementById("ai_summary_title").innerText = "Smart Forensic Verdict & Executive Summary";
        document.getElementById("ai_highlights_lbl").innerText = "Key Highlights & Detection Reasons:";
        document.getElementById("ui_breakdown_title").innerText = "Threat Score Breakdown & Formula";
        document.getElementById("ui_formula_lbl").innerText = "Formula: (Critical x 30) + (High x 15) + (Med x 5)";
        document.getElementById("ui_scale_clean").innerHTML = "&#128994; 0-15: CLEAN";
        document.getElementById("ui_scale_susp").innerHTML = "&#128993; 16-45: SUSPICIOUS";
        document.getElementById("ui_scale_high").innerHTML = "&#128999; 46-75: HIGH RISK";
        document.getElementById("ui_scale_ban").innerHTML = "&#128308; 76-100: DEFINITE BAN";
        document.getElementById("ui_tab_findings").innerText = "Detections & Anomalies";
        document.getElementById("ui_tab_mods").innerText = "Mod Inventory";
        document.getElementById("ui_lbl_sev").innerText = "Severity:";
        document.getElementById("ui_btn_all_sev").innerText = "All (" + findingsData.length + ")";
        document.getElementById("ui_btn_crit").innerText = "Critical";
        document.getElementById("ui_btn_high").innerText = "High";
        document.getElementById("ui_btn_med").innerText = "Medium";
        document.getElementById("ui_lbl_cat").innerText = "Category:";
        document.getElementById("ui_btn_all_cat").innerText = "All Categories";
        document.getElementById("ui_btn_mem").innerText = "RAM / Memory";
        document.getElementById("ui_btn_forensic").innerText = "Forensic Records";
        document.getElementById("ui_btn_clean").innerText = "Cleaners & Deletions";
        document.getElementById("ui_btn_sec").innerText = "Security & Kernel";
        document.getElementById("ui_btn_net").innerText = "Network & DNS";
        document.getElementById("ui_lbl_status").innerText = "Status:";
        document.getElementById("ui_btn_all_mods").innerText = "All Mods (" + modsData.length + ")";
        document.getElementById("ui_btn_susp_only").innerHTML = "&#9888;&#65039; Suspicious Only";
        document.getElementById("ui_btn_clean_only").innerHTML = "&#10004; Clean Only";
        document.getElementById("ui_th_file").innerText = "File Name";
        document.getElementById("ui_th_hash").innerText = "SHA-1 Hash";
        document.getElementById("ui_th_size").innerText = "Size";
        document.getElementById("ui_th_id").innerText = "Mod ID";
        document.getElementById("ui_th_status").innerText = "Status";
        document.getElementById("searchInput").placeholder = "Search detections, signatures, memory regions, paths...";
        document.getElementById("modSearchInput").placeholder = "Filter by JAR name, SHA-1 hash, or Mod ID...";
      }
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
        container.innerHTML = '<div class="f-card" style="text-align:center; padding: 45px; color: var(--accent-green);"><h3>&#10004; ' + noTitle + '</h3><p style="color: var(--text-muted); margin-top: 8px;">' + noDesc + '</p></div>';
        return;
      }
      container.innerHTML = items.map(function(f) {
        const title = translateText(f.Title);
        const desc = translateText(f.Description);
        const plainExp = getPlainExplanation(f.Title, f.Severity);
        const evLabel = isTurkish ? "KANIT:" : "EVIDENCE:";
        const catLabel = isTurkish ? "Kategori:" : "Category:";
        const tgtLabel = isTurkish ? "Hedef:" : "Target:";
        const timeLabel = isTurkish ? "Zaman:" : "Time:";
        const copyTxt = isTurkish ? "Kopyala" : "Copy";
        const meanLabel = isTurkish ? "&#128161; Ne Anlama Geliyor? " : "&#128161; What Does This Mean? ";

        return '<div class="f-card ' + f.Severity + '">' +
          '<div class="f-header">' +
            '<div class="f-title">' + title + '</div>' +
            '<span class="badge ' + f.Severity + '">' + f.Severity + '</span>' +
          '</div>' +
          '<div class="f-desc">' + desc + '</div>' +
          '<div class="f-plain-box ' + f.Severity + '"><span><b>' + meanLabel + '</b>' + plainExp + '</span></div>' +
          '<div class="f-evidence">' +
            '<span class="mono"><b>' + evLabel + '</b> ' + f.Evidence + '</span>' +
            '<button class="copy-btn" onclick="copyText(\'' + encodeURIComponent(f.Evidence) + '\')">' + copyTxt + '</button>' +
          '</div>' +
          '<div class="f-footer">' +
            '<span class="f-footer-item"><b>' + catLabel + '</b> ' + f.Category + '</span>' +
            '<span class="f-footer-item"><b>' + tgtLabel + '</b> <span class="mono" style="word-break: break-all;">' + f.TargetPath + '</span></span>' +
            '<span class="f-footer-item"><b>' + timeLabel + '</b> ' + f.Timestamp + '</span>' +
          '</div>' +
        '</div>';
      }).join("");
    }

    function filterModsData() {
      const q = document.getElementById("modSearchInput").value.toLowerCase();
      return modsData.filter(function(m) {
        const matchStatus = currentModStatus === "all" || m.Status === currentModStatus;
        const matchQ = !q || m.FileName.toLowerCase().indexOf(q) !== -1 || (m.Sha1 && m.Sha1.toLowerCase().indexOf(q) !== -1) || (m.ClaimedId && m.ClaimedId.toLowerCase().indexOf(q) !== -1);
        return matchStatus && matchQ;
      });
    }

    function renderMods(items) {
      const tbody = document.getElementById("modsTableBody");
      if (!items || items.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; padding: 25px; color: var(--text-muted);">' + (isTurkish ? "Mod bulunamad\u0131." : "No mods found.") + '</td></tr>';
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

    applyLanguageTexts();
    updateExecutiveSummary();
    updateScoreBreakdown();
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
            footer = @{ text = "Vortex Forensics Engine â€¢ Coded By BayrdY" }
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
