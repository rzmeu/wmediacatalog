﻿
using System.Collections.Generic;
using DbTool.Data;
namespace DbTool
{
    public interface IViewModel
    {
        string Login { get; set; }
        string Password { get; set; }
        string Database { get; }
        string PsqlPath { get; }
        string CurrentLookupDir { get; }
        bool IsSearching { get; }
        bool DeployStarted { get; }
        bool DeployFinished { get; }
        IList<PsqlScriptTask> Tasks { get; }

        DelegateCommand<object> UILoadedCommand { get; }
        DelegateCommand<object> StartDeployCommand { get; }
        DelegateCommand<object> LocatePsqlCommand { get; }
        DelegateCommand<object> FinishToolCommand { get; }
        DelegateCommand<object> ShowLogCommand { get; }
    }
}
