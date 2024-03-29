﻿
using System;
using System.Collections.Generic;
using BusinessObjects;
using Common.Commands;
using Common.ViewModels;
using Microsoft.Practices.Prism.Commands;
namespace Modules.Albums.ViewModels
{
    public interface IAlbumEditViewModel : IDialogViewModel
    {
        IGenresListViewModel GenresListViewModel { get; }
        IArtistListViewModel ArtistsListViewModel { get; }
        ITracksListViewModel TracksListViewModel { get; }

        Album Album { get; set; }

        Func<object, string, bool> FilterTag { get; }
        IList<Tag> Tags { get; set; }
        string TagName { get; set; }

        IList<Genre> SelectedGenres { get; }
        IList<Artist> SelectedArtists { get; }

        DelegateCommand<object> AttachTagCommand { get; }
        DelegateCommand<object> DetachTagCommand { get; }
        DelegateCommand<MouseDoubleClickArgs> EditTagCommand { get; }

        DelegateCommand<DragArgs> DropGenreCommand { get; }
        DelegateCommand<MultiSelectionChangedArgs> SelectedGenresChangedCommand { get; }
        DelegateCommand<object> DetachGenreCommand { get; }

        DelegateCommand<DragArgs> DropArtistCommand { get; }
        DelegateCommand<MultiSelectionChangedArgs> SelectedArtistsChangedCommand { get; }
        DelegateCommand<object> DetachArtistCommand { get; }
    }
}
