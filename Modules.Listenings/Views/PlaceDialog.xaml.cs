﻿using System.Windows.Input;
using Common.Dialogs;
using Modules.Listenings.ViewModels;

namespace Modules.Listenings.Views
{
    /// <summary>
    /// Interaction logic for MoodDialog.xaml
    /// </summary>
    public partial class PlaceDialog : DialogWindow
    {
        public PlaceDialog(IPlaceViewModel viewModel)
        {
            InitializeComponent();

            DataContext = viewModel;
        }

        private void HeaderBorder_MouseDown(object sender, MouseButtonEventArgs e)
        {
            this.DragMove();
        }
    }
}