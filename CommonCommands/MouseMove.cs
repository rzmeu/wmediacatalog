﻿
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
namespace Common.Commands
{
    public class MouseMove
    {
        #region CommandProperty

        public static ICommand GetCommand(DependencyObject obj)
        {
            return (ICommand)obj.GetValue(CommandProperty);
        }

        public static void SetCommand(DependencyObject obj, ICommand value)
        {
            obj.SetValue(CommandProperty, value);
        }

        // Using a DependencyProperty as the backing store for Command.
        //This enables animation, styling, binding, etc...
        public static readonly DependencyProperty CommandProperty =
            DependencyProperty.RegisterAttached("Command", typeof(ICommand), typeof(MouseMove),
                new PropertyMetadata(CommandProperty_Changed));

        private static void CommandProperty_Changed(DependencyObject dependencyObject, DependencyPropertyChangedEventArgs e)
        {
            Control element = dependencyObject as Control;
            if (element != null)
            {
                MouseMoveBehavior behavior = GetOrCreateBehavior(element);
                behavior.Command = e.NewValue as ICommand;
            }
        }

        #endregion

        #region CommandParameterProperty

        public static readonly DependencyProperty CommandParameterProperty =
             DependencyProperty.RegisterAttached("CommandParameter", typeof(object),
                typeof(MouseMove), new PropertyMetadata(CommandParameterProperty_Changed));

        public static object GetCommandParameter(DependencyObject obj)
        {
            return obj.GetValue(CommandParameterProperty);
        }

        public static void SetCommandParameter(DependencyObject obj, object value)
        {
            obj.SetValue(CommandParameterProperty, value);
        }

        private static void CommandParameterProperty_Changed(DependencyObject dependencyObject, DependencyPropertyChangedEventArgs e)
        {
            Control element = dependencyObject as Control;

            if (element != null)
                GetOrCreateBehavior(element).CommandParameter = e.NewValue;
        }

        #endregion

        private static MouseMoveBehavior GetOrCreateBehavior(Control element)
        {
            MouseMoveBehavior behavior = element.GetValue(MouseMoveBehaviorProperty) as MouseMoveBehavior;
            if (behavior == null)
            {
                behavior = new MouseMoveBehavior(element);
                element.SetValue(MouseMoveBehaviorProperty, behavior);
            }

            return behavior;
        }

        public static MouseMoveBehavior GetMouseMoveBehavior(DependencyObject obj)
        {
            return (MouseMoveBehavior)obj.GetValue(MouseMoveBehaviorProperty);
        }

        public static void SetMouseMoveBehavior(DependencyObject obj,
            MouseMoveBehavior value)
        {
            obj.SetValue(MouseMoveBehaviorProperty, value);
        }

        // Using a DependencyProperty as the backing store for MouseOverCommandBehavior.
        //This enables animation, styling, binding, etc...
        public static readonly DependencyProperty MouseMoveBehaviorProperty =
            DependencyProperty.RegisterAttached("MouseMoveBehavior",
                typeof(MouseMoveBehavior), typeof(MouseMove), null);
    }
}
