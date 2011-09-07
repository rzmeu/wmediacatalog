﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NHibernate.Transform;
using System.Collections;
using DataLayer.Entities;

namespace DataLayer
{
    public class TagResultTransformer : IResultTransformer
    {
        #region IResultTransformer Members

        public IList TransformList(IList collection)
        {
            return collection;
        }

        public object TransformTuple(object[] tuple, string[] aliases)
        {
            int tagID = Convert.ToInt32(tuple[0]);
            string tagName = Convert.ToString(tuple[1]);
            int entitiesCount = Convert.ToInt32(tuple[2]);

            return new TagEntity()
            {
                ID = tagID,
                Name = tagName,
                AssociatedEntitiesCount = entitiesCount
            };
        }

        #endregion
    }
}
