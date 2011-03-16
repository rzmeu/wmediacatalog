﻿
namespace BusinessObjects
{
    public class BusinessObject : NotificationObject
    {
        public const int NewEntityID = 0;

        public int ID
        {
            get
            {
                return id;
            }
            set
            {
                if (value != id)
                {
                    id = value;
                    NotifyPropertyChanged(() => ID);
                }
            }
        }

        public bool NeedValidate
        {
            get
            {
                return needValidate;
            }
            set
            {
                if (value != needValidate)
                {
                    needValidate = value;
                    NotifyPropertyChanged(() => NeedValidate);
                }
            }
        }

        public bool IsNew
        {
            get
            {
                return ID == NewEntityID;
            }
        }

        #region Private fields

        private int id;
        private bool needValidate;

        #endregion
    }
}