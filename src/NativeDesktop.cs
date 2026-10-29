using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

namespace WebAnalyzer
{
    public sealed class BrowserWindow
    {
        public long Handle;
        public uint ProcessId;
        public string ProcessName;
        public string Title;
        public string MonitorDevice;
        public bool IsPrimary;
        public bool Visible;
        public bool Minimized;
        public bool Cloaked;
    }

    public static class NativeDesktop
    {
        private delegate bool EnumCallback(IntPtr handle, IntPtr state);
        [DllImport("user32.dll")] private static extern bool EnumWindows(EnumCallback callback, IntPtr state);
        [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr handle);
        [DllImport("user32.dll")] private static extern bool IsIconic(IntPtr handle);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern int GetWindowText(IntPtr handle, StringBuilder text, int capacity);
        [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr handle, out uint processId);
        [DllImport("user32.dll")] private static extern IntPtr MonitorFromWindow(IntPtr handle, uint flags);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern bool GetMonitorInfo(IntPtr monitor, ref MonitorInfo info);
        [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] private static extern bool SetForegroundWindow(IntPtr handle);
        [DllImport("user32.dll", SetLastError = true)] public static extern bool PrintWindow(IntPtr handle, IntPtr deviceContext, uint flags);
        [DllImport("user32.dll", SetLastError = true)] public static extern bool GetWindowRect(IntPtr handle, out WindowRect rect);
        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
        [DllImport("dwmapi.dll")] private static extern int DwmGetWindowAttribute(IntPtr handle, int attribute, out int value, int size);

        [StructLayout(LayoutKind.Sequential)]
        public struct WindowRect { public int Left, Top, Right, Bottom; }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct MonitorInfo
        {
            public int Size, Left, Top, Right, Bottom, WorkLeft, WorkTop, WorkRight, WorkBottom;
            public uint Flags;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string Device;
        }

        public static long ForegroundHandle() { return GetForegroundWindow().ToInt64(); }

        public static bool Focus(long handle)
        {
            IntPtr target = new IntPtr(handle);
            if (GetForegroundWindow() == target) return true;
            SetForegroundWindow(target);
            return GetForegroundWindow() == target;
        }

        public static BrowserWindow[] GetWindows()
        {
            var result = new List<BrowserWindow>();
            // Collect in managed code: callback pipeline output is unreliable in PowerShell.
            EnumWindows(delegate(IntPtr handle, IntPtr state)
            {
                if (!IsWindowVisible(handle)) return true;
                var monitor = new MonitorInfo();
                monitor.Size = Marshal.SizeOf(monitor);
                if (!GetMonitorInfo(MonitorFromWindow(handle, 2), ref monitor)) return true;
                // Never traverse page contents on secondary monitors.
                if ((monitor.Flags & 1) == 0) return true;
                uint processId;
                GetWindowThreadProcessId(handle, out processId);
                string processName;
                try { using (Process p = Process.GetProcessById((int)processId)) { processName = p.ProcessName; } }
                catch (ArgumentException) { return true; }
                catch (InvalidOperationException) { return true; }
                if (!String.Equals(processName, "chrome", StringComparison.OrdinalIgnoreCase)) return true;
                var title = new StringBuilder(4096);
                GetWindowText(handle, title, title.Capacity);
                int cloaked;
                int status = DwmGetWindowAttribute(handle, 14, out cloaked, sizeof(int));
                result.Add(new BrowserWindow {
                    Handle = handle.ToInt64(), ProcessId = processId, ProcessName = processName,
                    Title = title.ToString(), MonitorDevice = monitor.Device,
                    IsPrimary = true, Visible = true, Minimized = IsIconic(handle),
                    Cloaked = status == 0 && cloaked != 0
                });
                return true;
            }, IntPtr.Zero);
            return result.ToArray();
        }
    }
}
