﻿
using Common.Enums;
using Microsoft.Practices.Prism.Events;
namespace Common.Events
{
    public class ChangeWorkspaceEvent : CompositePresentationEvent<WorkspaceNameEnum>
    {
    }
}
