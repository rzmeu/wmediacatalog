﻿
using System.Collections.ObjectModel;
using BusinessObjects;
using Microsoft.Practices.Prism.Commands;
namespace Modules.Import.ViewModels
{
    public interface IImportProgressViewModel
    {
        int ScanFilesCount { get; set; }
        int ScannedFilesCount { get; }
        string ScanPath { get; }
        ObservableCollection<Artist> Artists { get; }
        double CurrentProgress { get; }

        DelegateCommand<object> SelectScanPathCommand { get; }
        DelegateCommand<object> BeginScanCommand { get; }
    }
}