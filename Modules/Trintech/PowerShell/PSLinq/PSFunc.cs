namespace Trintech.PowerShell.Linq
{
    using System;
    using System.Management.Automation;

    public static class PSFunc
    {
        public static Func<object> CreateNullaryFunction(ScriptBlock script)
        {
            return () => {
                return script.Invoke(null);
            };
        }

        public static Func<object,object> CreateUnaryFunction(ScriptBlock script)
        {
            return (arg1) => {
                return script.Invoke(null, arg1);
            };
        }

        public static Func<object,object,object> CreateBinaryFunction(ScriptBlock script)
        {
            return (arg1, arg2) => {
                return script.Invoke(null, arg1, arg2);
            };
        }

        public static Func<object,object,object,object> CreateTernaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3) => {
                return script.Invoke(null, arg1, arg2, arg3);
            };
        }

        public static Func<object,object,object,object,object> CreateQuaternaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4);
            };
        }

        public static Func<object,object,object,object,object,object> CreateQuinaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5);
            };
        }

        public static Func<object,object,object,object,object,object,object> CreateSenaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6);
            };
        }

        public static Func<object,object,object,object,object,object,object,object> CreateSeptenaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6, arg7) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
            };
        }

        public static Func<object,object,object,object,object,object,object,object,object> CreateOctonaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
            };
        }

        public static Func<object,object,object,object,object,object,object,object,object,object> CreateNovenaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
            };
        }

        public static Func<object,object,object,object,object,object,object,object,object,object,object> CreateDecenaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10);
            };
        }

        public static Func<object,object,object,object,object,object,object,object,object,object,object,object> CreateUndecenaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11);
            };
        }

        public static Func<object,object,object,object,object,object,object,object,object,object,object,object,object> CreateDodecenaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12);
            };
        }

        public static Func<object,object,object,object,object,object,object,object,object,object,object,object,object,object> CreateTridecenaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13);
            };
        }

        public static Func<object,object,object,object,object,object,object,object,object,object,object,object,object,object,object> CreateTetradecenaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14);
            };
        }

        public static Func<object,object,object,object,object,object,object,object,object,object,object,object,object,object,object,object> CreatePentadecenaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, ag15) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15);
            };
        }

        public static Func<object,object,object,object,object,object,object,object,object,object,object,object,object,object,object,object,object> CreateHexadecenaryFunction(ScriptBlock script)
        {
            return (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, ag15, arg16) => {
                return script.Invoke(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16);
            };
        }
    }
}