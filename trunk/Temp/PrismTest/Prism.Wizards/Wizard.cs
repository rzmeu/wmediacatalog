﻿using System;
using System.Linq;
using System.Windows;
using Microsoft.Practices.Prism.Events;
using Microsoft.Practices.Prism.Regions;
using Microsoft.Practices.Unity;
using Prism.Wizards.Data;
using Prism.Wizards.Events;
using Prism.Wizards.Utils;
using Prism.Wizards.ViewModels;
using Prism.Wizards.Views;

namespace Prism.Wizards
{
    public class Wizard
    {
        public string RegionName { get; private set; }

        public string Name { get; private set; }

        public Wizard(IUnityContainer container, IWizardSettings wizardSettings, string wizardName)
        {
            wizardContainer = container.CreateChildContainer();
            wizardRegionManager = wizardContainer.Resolve<IRegionManager>();
            eventAggregator = wizardContainer.Resolve<IEventAggregator>();
            RegionName = Guid.NewGuid().ToString();
            Name = wizardName;

            InitWizardUiContainer();
            RegisterEvents();
            RegisterViewModel(wizardSettings);
        }

        public void Start()
        {
            wizardUiContainer.ShowDialog();
        }

        #region Event handlers

        private void RegisterEvents()
        {
            eventAggregator.GetEvent<WizardNavigationEvent>().Subscribe(OnWizardNavigationEvent, true);
            eventAggregator.GetEvent<CompleteWizardStepEvent>().Subscribe(OnCompleteWizardStepEvent, true);
        }

        private void OnCompleteWizardStepEvent(object parameter)
        {
            var context = wizardContainer.Resolve<IWizardContext>();
            var currentStep = context.Where(s => s.IsCurrent == true).FirstOrDefault();
            currentStep.IsComplete = true;
            context.LastCompletedStep = currentStep;

            OnWizardNavigationEvent(new NavigationSettings()
            {
                MoveForward = true,
                WizardName = Name
            });
        }

        private void OnWizardNavigationEvent(NavigationSettings settings)
        {
            var context = wizardContainer.Resolve<IWizardContext>();
            var currentStep = context.Where(s => s.IsCurrent == true).FirstOrDefault();

            if (settings.Step == null)
            {

                if (currentStep != null)
                {
                    int currentStepIndex = currentStep.Index;

                    if (settings.MoveForward)
                    {
                        if (currentStepIndex >= context.StepsCount || !currentStep.IsComplete)
                            return;
                    }

                    if (!settings.MoveForward && currentStepIndex <= 0)
                        return;

                    if (settings.MoveForward)
                    {
                        currentStepIndex += 1;
                        context.CurrentStep = currentStepIndex;
                    }
                    else
                    {
                        currentStepIndex -= 1;
                        context.CurrentStep = currentStepIndex;
                    }

                    var step = context.Where(s => s.Index == currentStepIndex).FirstOrDefault();
                    if (step != null)
                    {
                        SwitchStepView(currentStep, step, context);
                    }
                }
            }
            else
            {
                var nextStep = settings.Step;

                var allStepsBeforeNext = context.Where(s => s.Index < nextStep.Index);

                var allStepsBeforeNextCompleted = allStepsBeforeNext.All(s => s.IsComplete);

                if (!allStepsBeforeNextCompleted && nextStep.Index > currentStep.Index)
                    return;

                SwitchStepView(currentStep, nextStep, context);
            }
        }

        private void SwitchStepView(WizardStep currentStep, WizardStep nextStep, IWizardContext context)
        {
            if (currentStep != null)
            {
                if (currentStep.Index == nextStep.Index) // don't switch to already active step
                    return;

                currentStep.IsCurrent = false;

                var region = GetStepsRegion(wizardRegionManager);
                var viewToActivate = region.Views.Where((v) => v.GetType() == nextStep.View).FirstOrDefault();
                if (viewToActivate != null)
                {
                    region.Activate(viewToActivate);
                    eventAggregator.GetEvent<UpdateNavBarEvent>().Publish(context);

                    nextStep.IsCurrent = true;
                }
            }
        }

        #endregion

        private void InitWizardUiContainer()
        {
            wizardUiContainer = new Window()
            {
                WindowStartupLocation = WindowStartupLocation.CenterScreen

            };
            wizardUiContainer.Closed += new EventHandler(wizardUiContainer_Closed);

            RegionManager.SetRegionManager(wizardUiContainer, wizardRegionManager);
            RegionManager.SetRegionName(wizardUiContainer, RegionName);
        }

        private void wizardUiContainer_Closed(object sender, EventArgs e)
        {
            bool success = wizardRegionManager.Regions.Remove(RegionName);
        }

        private void RegisterViewModel(IWizardSettings wizardSettings)
        {
            var wizardContext = new WizardContext(wizardSettings);

            wizardContainer.RegisterInstance<IWizardContext>(wizardContext);
            wizardContainer.RegisterType<IWizardViewModel, WizardViewModel>(
                new InjectionProperty("WizardName", Name),
                new InjectionProperty("WizardRegionName", RegionName));

            wizardRegionManager.RegisterViewWithRegion(RegionName, () =>
            {
                return wizardContainer.Resolve<WizardView>();
            });

            RegisterViews(wizardContext);
        }

        private void RegisterViews(IWizardContext context)
        {
            ValidateContext(context);

            var stepsRegion = GetStepsRegion(wizardRegionManager);

            var orderedSteps = context.OrderBy((s) => s.Index).ToList();
            foreach (var step in orderedSteps)
            {
                wizardContainer.RegisterType(step.IViewModel, step.ViewModel);
                wizardRegionManager.RegisterViewWithRegion(stepsRegion.Name, () =>
                {
                    var viewType = step.View;
                    return wizardContainer.Resolve(viewType);
                });
            }

            var firstStep = orderedSteps.FirstOrDefault();
            if (firstStep != null)
            {
                firstStep.IsCurrent = true;
            }
        }

        private void ValidateContext(IWizardContext context)
        {
            var duplicateSteps = context.Select(ci => ci.Index).GroupBy(i => i).
                Where(g => g.Count() > 1).Select(g => g.Key);

            if (duplicateSteps.Count() > 0)
                throw new Exception("Found duplicated step indices. All step indices must be unique");

            var duplicateViewTypes = context.Select(ci => ci.View).GroupBy(i => i).
                Where(g => g.Count() > 1).Select(g => g.Key);

            if (duplicateViewTypes.Count() > 0)
                throw new Exception("Found duplicated view types. Each step should have it's own unique view type");
        }

        private IRegion GetStepsRegion(IRegionManager regionManager)
        {
            string stepsRegionName = StepsRegionNameResolver.ResolveRegionName(Name, RegionName);
            return regionManager.Regions[stepsRegionName];
        }

        private IUnityContainer wizardContainer;
        private IEventAggregator eventAggregator;
        private IRegionManager wizardRegionManager;
        private Window wizardUiContainer;
    }
}