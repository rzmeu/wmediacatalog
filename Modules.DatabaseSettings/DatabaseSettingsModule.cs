﻿using DataServices.Additional.Base;
using DataServices.Additional.Postgre;
using Microsoft.Practices.Prism.Modularity;
using Microsoft.Practices.Prism.Regions;
using Microsoft.Practices.Unity;
using Modules.DatabaseSettings.Controllers;
using Modules.DatabaseSettings.Services;
using Modules.DatabaseSettings.ViewModels;

namespace Modules.DatabaseSettings
{
    public class DatabaseSettingsModule : IModule
    {
        public DatabaseSettingsModule(IRegionManager regionManager, IUnityContainer container)
        {
            this.regionManager = regionManager;
            this.container = container;
        }

        #region IModule Members

        public void Initialize()
        {
            container.RegisterType<IExportProvider, PostgreExportProvider>();
            container.RegisterType<IImportProvider, PostgreImportProvider>();
            container.RegisterType<IDataService, DataService>();

            container.RegisterType<IConnectionSettingsViewModel, ConnectionSettingsViewModel>();
            container.RegisterType<IDatabaseToolsViewModel, DatabaseToolsViewModel>();

            controller = container.Resolve<DbSettingsController>();
        }

        #endregion

        private IRegionManager regionManager;
        private IUnityContainer container;
        private DbSettingsController controller;
    }
}
