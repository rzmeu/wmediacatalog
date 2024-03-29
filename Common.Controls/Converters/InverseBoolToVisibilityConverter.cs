﻿using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace Common.Controls.Converters
{
    public class InverseBoolToVisibilityConverter : IValueConverter
    {
        public bool UseCollapsed { get; set; }

        public InverseBoolToVisibilityConverter()
        {
            UseCollapsed = true;
        }

        #region IValueConverter Members

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (!(bool)value)
                return Visibility.Visible;

            if (!UseCollapsed)
                return Visibility.Hidden;
            else
                return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }

        #endregion
    }
}
