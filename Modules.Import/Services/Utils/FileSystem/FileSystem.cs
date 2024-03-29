﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Common;

namespace Modules.Import.Services.Utils.FileSystem
{
    public class FileSystem : IFileSystem
    {
        #region IFileSystem Members

        public IEnumerable<FsFile> GetFiles(Dir dir, IFileSelector selector)
        {
            return selector.SelectFiles(dir.FullName);
        }

        public IEnumerable<Dir> GetSubDirectories(Dir dir)
        {
            if (dir == null)
                return new Dir[] { };

            if (!Directory.Exists(dir.FullName))
                return new Dir[] { };

            var dirInfo = new DirectoryInfo(dir.FullName);

            IEnumerable<Dir> result = null;

            try
            {
                result = dirInfo.GetDirectories().Select<DirectoryInfo, Dir>(d => new Dir(d.FullName));
            }
            catch (Exception ex)
            {
                result = new Dir[] { };
            }

            return result;
        }

        public int CountFilesRecursively(Dir dir, IFileSelector selector)
        {
            if (dir == null)
                throw new NullReferenceException("Illegal null-reference dir");

            if (!Directory.Exists(dir.FullName))
                return 0;

            int result = 0;

            Stack<DirectoryInfo> stack = new Stack<DirectoryInfo>();
            stack.Push(new DirectoryInfo(dir.FullName));

            while (stack.Count > 0)
            {
                DirectoryInfo top = stack.Pop();

                try
                {
                    var subDirs = top.GetDirectories();
                    foreach (var sd in subDirs)
                        stack.Push(sd);

                    result += selector.SelectFiles(top.FullName).Count();
                }
                catch (Exception ex)
                {
                    Logger.Write(ex);
                }
            }

            return result;
        }

        #endregion
    }
}
