/*
Compile this code to run a PowerShell command without using powershell.exe
Will run one command, wait for keypress, then exit.
*/

using System;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

namespace PSShell

{
    class Program
    {
        static void Main(string[] args)
        {
            Console.Write("PSShell> ");
            String cmd = Console.ReadLine();

            Runspace rs = RunspaceFactory.CreateRunspace();
            rs.Open();

            PowerShell ps = PowerShell.Create();
            ps.Runspace = rs;
            ps.AddScript(cmd);

            Collection<PSObject> output = ps.Invoke();

            if (output != null)
            {
                foreach (PSObject rtnItem in output)
                {
                    Console.WriteLine(rtnItem.ToString());
                }
            }

            rs.Close();
            Console.Write("Press any key to exit.");
            Console.ReadLine();
        }
    }
}
