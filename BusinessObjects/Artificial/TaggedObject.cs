﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace BusinessObjects.Artificial
{
    public class TaggedObject 
    {
        public int ID { get; set; }
        public string Name { get; set; }
        public TaggedObjectType ObjectType { get; set; }
    }
}
