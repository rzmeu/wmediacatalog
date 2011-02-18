﻿
using System.Collections.Generic;
using BusinessObjects;
using Common.Entities.Pagination;
namespace Modules.Albums.Services
{
    public interface IDataService
    {
        IPagedList<Artist> GetArtists(ILoadOptions options);
        IPagedList<Album> GetAlbums(ILoadOptions options);
        Album GetAlbum(int albumID);
        IList<Tag> GetTags();
        IPagedList<Genre> GetGenres(ILoadOptions loadOptions);
        bool SaveAlbum(Album album);
        bool SaveGenre(Genre genre);
    }
}