--
-- PostgreSQL database dump
--

-- Started on 2011-05-07 16:32:03

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 380 (class 2612 OID 53115)
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: -
--

CREATE PROCEDURAL LANGUAGE plpgsql;


SET search_path = public, pg_catalog;

--
-- TOC entry 20 (class 1255 OID 53116)
-- Dependencies: 380 6
-- Name: find_missing_genres(xml); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION find_missing_genres(genresxml xml) RETURNS xml
    LANGUAGE plpgsql
    AS $$
declare
  xmlStr xml; 
  missingGenresXml text;
  arrayLength integer;
  xelement xml;
  list text[];
begin
  list := (select * from (select xpath('/genres/g/text()',genresXml)::text[] x) as x);
  arrayLength := (select array_upper(list, 1));
  missingGenresXml := '<genres>';
  
  FOR i IN 1..arrayLength LOOP
    if ((select count(1) from genres where name like list[i]) = 0) then
      --RAISE NOTICE 'array[i][1]=% not found in db', list[i]; 
      xelement := (select xmlelement(name g, text (list[i])));
      missingGenresXml := missingGenresXml || xelement;
    end if;
  END LOOP;

  missingGenresXml := missingGenresXml || '</genres>';
  
  return missingGenresXml;

end; $$;


--
-- TOC entry 29 (class 1255 OID 53117)
-- Dependencies: 380 6
-- Name: import_media(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION import_media(xmlstr character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
 xml_data xml;
 albumsCount integer;
 genresCount integer;
 artistsCount integer;
 artistList text[];
 albumList text[];
 genreList text[];
 i int; j int; k int;
 artistID int; albumID int;
 xpathQuery character varying;
 currentAlbum character varying; currentArtist character varying;
 currentGenre character varying;
 albumYear int;
 genreID int;
begin
 xml_data = xmlStr::xml;
 --process all genres and ensure all of them are persisted into db
 genreList := (select xpath('//artists/a/al/gn/g/@name',xml_data)::text[] x);

 genresCount := array_upper(genreList,1);
 if genresCount > 0 then
	 --loop throigh unique genre names
	 for currentGenre in ( select distinct lower(a) from unnest(genreList) a) loop
	   --make first chars of genre words capital
	   insert into genres (name) select initcap(currentGenre)
	     where not exists (select g.name from genres g where
		g.name=initcap(currentGenre));
	 end loop;
 end if;


 artistList := (select xpath('//artists/a/@name',xml_data)::text[] x);

 artistsCount := array_upper(artistList,1);
 if artistsCount > 0 then
	 for i in 1..artistsCount loop
	   currentArtist := artistList[i];

	   --get or create new artist by name and fetch it's id
	    artistID = (select id from artists a where lower(a.name) =
		trim(lower(currentArtist)));
	    if artistID is null then
	      insert into artists(name) values(trim(currentArtist)) returning	id into artistID;
	    end if;

	   --process albums for given artist
	   xpathQuery := '//artists/a[@name="' || currentArtist || '"]/al/@name';
	   albumList := (select xpath(xpathQuery,xml_data)::text[] y);
           if ( array_upper(albumList,1) > 0 ) then
		   for j in 1..array_upper(albumList,1) loop
		     currentAlbum := albumList[j];

		     --check whether album with given name exists in database
		     albumsCount = (select count(1) from albums a where a.name = currentAlbum);
		     if ( albumsCount = 0 ) then
		       --get album year
		       xpathQuery := '//artists/a[@name="' || currentArtist || '"]/al[@name="' || currentAlbum || '"]/@year';
		       albumYear := (select y[1] from (select xpath(xpathQuery,xml_data)::text[] y) as y);

		       if ( albumYear is null ) then
			 albumYear := 1900;
		       end if;

		       --create new album and link with artist
		       insert into albums(name,rating,year) values(trim(currentAlbum),0,to_date('01 01 ' || albumYear, 'DD MM YYYY'))
			 returning id into albumID;
		     else
		       albumID := (select a.id from albums a where a.name = currentAlbum);
		     end if;

		     --check whether album is already bound to artists
		     albumsCount := (select count(1) from artists_albums where artist_id = artistID and album_id = albumID);
		     if ( albumsCount = 0 ) then
		       insert into artists_albums(artist_id,album_id) values(artistID,albumID);
		     end if;

		     --process genres of given album
		     xpathQuery := '//artists/a[@name="' || currentArtist ||
			'"]/al[@name="' || currentAlbum || '"]/gn/g/@name';
		     genreList := (select xpath(xpathQuery,xml_data)::text[] z);

		     genresCount := array_upper(genreList,1);
		     if genresCount > 0 then
		       for k in 1..genresCount loop
			 currentGenre := genreList[k];
			 genreID := (select id from genres g where g.name = currentGenre );
			 if genreID is not null then
			   if ( select count(1) from albums_genres where album_id = albumID and genre_id = genreID ) = 0 then
			     insert into albums_genres(album_id,genre_id) values(albumID, genreID);
			   end if;
			 end if;
		       end loop;
		     end if;
		   end loop;
	  end if;
	 end loop;
 end if;

 return 0;
end;
$$;


--
-- TOC entry 21 (class 1255 OID 53118)
-- Dependencies: 380 6
-- Name: insert_test_artists(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_test_artists(itemscount integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare 
  index integer;
begin
  for index  in 1..itemsCount loop
    insert into artists(name,private_marks,biography) values('Artist' || index, 'Some marks' || index, 'Some biography' || index);
  end loop;
  return index;
end;
$$;


--
-- TOC entry 22 (class 1255 OID 53119)
-- Dependencies: 380 6
-- Name: insert_test_data(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_test_data() RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare 
  tagsCount integer;
  genresCount integer;
  artistsCount integer;
  albumsCount integer;
  tagsPerArtist integer;
  tracksPerAlbum integer;
  artistsPerAlbum integer;
  tagsPerAlbum integer;
  genresPerAlbum integer;
  index integer;
  i2 integer;
  maxArtistID integer;
  randomArtistID integer;
  displayNotification boolean;
  buf character varying;

  artistName character varying;
  albumName character varying;
  albumLabel character varying;
  albumTextID character varying;
  albumFreedbID character varying;
begin
  tagsCount := 500;
  genresCount := 500;

  artistsCount := 5;
  tagsPerArtist := 50;
  
  -- 20 albums per artist average
  albumsCount := artistsCount * 5; 
  tagsPerAlbum := 50;
  tracksPerAlbum := 25;
  artistsPerAlbum := 1;
  genresPerAlbum := 15;

  truncate table albums cascade;
  truncate table artists cascade;
  truncate table tags cascade;
  truncate table genres cascade;
  truncate table tracks cascade;

  raise notice 'Preparing sequences';

  perform SETVAL('tags_id_seq', 0);
  perform SETVAL('artists_id_seq', 0);
  perform SETVAL('albums_id_seq', 0);
  perform SETVAL('genres_id_seq', 0);
  perform SETVAL('tracks_id_seq', 0);
  

  raise notice 'Inserting tags...';

  for index in 1..tagsCount loop
    insert into tags(name) values('tag' || index);
  end loop;

  raise notice 'Inserting genres...';

  for index in 1..tagsCount loop
    insert into genres(name) values('genre' || index);
  end loop;

  -- inserting artists

  for index  in 1..artistsCount loop
    if index % 100 = 0 then
      displayNotification := true;
    else
      displayNotification = false;
    end if;

    if displayNotification then
      raise notice 'Inserting artist : % of %',index,artistsCount;
    end if;

    select random_full_name() into buf;
    insert into artists(name,private_marks,biography) values(buf, 'Some marks' || index, 'Some biography' || index);

    --insert tags for artist
    for i2 in 1..tagsPerArtist loop
      insert into tags_artists(tag_id,artist_id) values(i2,index);
    end loop;
  end loop;

  -- inserting albums

  select max(id) into maxArtistID from artists;

  for index in 1..albumsCount loop
    if index % 100 = 0 then
      displayNotification := true;
    else
      displayNotification = false;
    end if;   

    if displayNotification then
      raise notice 'Inserting album : % of %. Percentage done: [%]',
			index,albumsCount,CAST(index AS FLOAT)/CAST(albumsCount AS FLOAT)*100;
    end if;

    select random_album_name() into albumName;
    select random_noun() into albumLabel;
    select random_string(10) into albumTextID;
    select random_string(8) into albumFreedbID;
    insert into albums(name,rating,label,asin,freedb_id,discs_count) values(albumName,1,albumLabel,albumTextID,albumFreedbID,1);


    --insert tags for albums
    for i2 in 1..tagsPerAlbum loop
      insert into tags_albums(tag_id,album_id) values(i2,index);
    end loop;    

    --insert genres for albums
    for i2 in 1..genresPerAlbum loop
      insert into albums_genres(album_id,genre_id) values(index,i2);
    end loop; 
       
    --insert tracks for albums
    for i2 in 1..tracksPerAlbum loop
      insert into tracks(name,track_index,album_id) values('track' || i2,i2, index);
    end loop;     

    --insert artists for albums
    for i2 in 1..artistsPerAlbum loop
      select random_integer(maxArtistID) + 1 into randomArtistID;
      insert into artists_albums(artist_id,album_id) values(randomArtistID,index);
    end loop;
  end loop;
  
  return index;
end;
$$;


--
-- TOC entry 23 (class 1255 OID 53120)
-- Dependencies: 6 380
-- Name: insert_test_genres(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_test_genres(itemscount integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare 
  index integer;
begin
  for index  in 1..itemsCount loop
    insert into genres(name) values('genre' || index);
  end loop;
  return index;
end;
$$;


--
-- TOC entry 24 (class 1255 OID 53121)
-- Dependencies: 380 6
-- Name: insert_test_tags(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_test_tags(itemscount integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare 
  index integer;
begin
  for index  in 1..itemsCount loop
    insert into tags(name) values('tag' || index);
  end loop;
  return index;
end;
$$;


--
-- TOC entry 25 (class 1255 OID 53122)
-- Dependencies: 6 380
-- Name: random_album_name(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION random_album_name() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  adjective_index integer;
  max_adjectives integer;
  noun_index integer;
  max_nouns integer;
  adjective character varying;
  noun character varying;
  buf1 character varying;
  buf2 character varying;
begin
  select count(1) into max_adjectives from sys_adjectives;
  select count(1) into max_nouns from sys_nouns;

  select random_integer(max_adjectives) + 1 into adjective_index;
  select random_integer(max_nouns) + 1 into noun_index;

  select value into adjective from sys_adjectives where id = adjective_index;
  buf1 = upper(substr(adjective,1,1));
  buf2 = substr(adjective,2,length(adjective));
  adjective = buf1 || buf2;
  
  select value into noun from sys_nouns where id = noun_index;
  buf1 = upper(substr(noun,1,1));
  buf2 = substr(noun,2,length(noun));
  noun = buf1 || buf2;
  
  return adjective || ' ' || noun;
end;
$$;


--
-- TOC entry 26 (class 1255 OID 53123)
-- Dependencies: 380 6
-- Name: random_full_name(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION random_full_name() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  first_name_index integer;
  max_first_names integer;
  last_name_index integer;
  max_last_names integer;
  firstName character varying;
  lastName character varying;
begin
  select count(1) into max_first_names from sys_first_names;
  select count(1) into max_last_names from sys_last_names;

  select random_integer(max_first_names) + 1 into first_name_index;
  select random_integer(max_last_names) + 1 into last_name_index;

  select value into firstName from sys_first_names where id = first_name_index;
  select value into lastName from sys_last_names where id = last_name_index;
  
  return lastName || ' ' ||firstName;
end;
$$;


--
-- TOC entry 27 (class 1255 OID 53124)
-- Dependencies: 380 6
-- Name: random_integer(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION random_integer(maxvalue integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
begin
  return trunc(random()*maxValue)::int;
end;
$$;


--
-- TOC entry 28 (class 1255 OID 53125)
-- Dependencies: 380 6
-- Name: random_noun(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION random_noun() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  noun_index integer;
  max_nouns integer;
  noun character varying;
  buf1 character varying;
  buf2 character varying;
begin
  select count(1) into max_nouns from sys_nouns;

  select random_integer(max_nouns) + 1 into noun_index;

  select value into noun from sys_nouns where id = noun_index;
  buf1 = upper(substr(noun,1,1));
  buf2 = substr(noun,2,length(noun));
  noun = buf1 || buf2;
  
  return noun;
end;
$$;


--
-- TOC entry 19 (class 1255 OID 53126)
-- Dependencies: 380 6
-- Name: random_string(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION random_string(string_length integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
possible_chars TEXT = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
output TEXT = '';
i INT4;
pos INT4;
BEGIN
FOR i IN 1..string_length LOOP
pos := 1 + cast( random() * ( length(possible_chars) - 1) as INT4 );
output := output || substr(possible_chars, pos, 1);
END LOOP;
RETURN output;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 1567 (class 1259 OID 53127)
-- Dependencies: 1878 6
-- Name: albums; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE albums (
    id integer NOT NULL,
    name character varying NOT NULL,
    description character varying,
    private_marks character varying,
    label character varying(128),
    asin character varying,
    freedb_id character varying,
    year date,
    discs_count integer,
    rating integer NOT NULL,
    is_waste boolean DEFAULT false NOT NULL
);


--
-- TOC entry 1568 (class 1259 OID 53134)
-- Dependencies: 6
-- Name: albums_genres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE albums_genres (
    album_id integer NOT NULL,
    genre_id integer NOT NULL
);


--
-- TOC entry 1569 (class 1259 OID 53137)
-- Dependencies: 6 1567
-- Name: albums_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE albums_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 0
    CACHE 1;


--
-- TOC entry 1965 (class 0 OID 0)
-- Dependencies: 1569
-- Name: albums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE albums_id_seq OWNED BY albums.id;


--
-- TOC entry 1570 (class 1259 OID 53139)
-- Dependencies: 1880 6
-- Name: artists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE artists (
    id integer NOT NULL,
    name character varying NOT NULL,
    private_marks character varying,
    biography character varying,
    is_waste boolean DEFAULT false NOT NULL
);


--
-- TOC entry 1571 (class 1259 OID 53146)
-- Dependencies: 6
-- Name: artists_albums; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE artists_albums (
    artist_id integer NOT NULL,
    album_id integer NOT NULL
);


--
-- TOC entry 1572 (class 1259 OID 53149)
-- Dependencies: 1570 6
-- Name: artists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE artists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 0
    CACHE 1;


--
-- TOC entry 1966 (class 0 OID 0)
-- Dependencies: 1572
-- Name: artists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE artists_id_seq OWNED BY artists.id;


--
-- TOC entry 1573 (class 1259 OID 53151)
-- Dependencies: 6
-- Name: genres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE genres (
    id integer NOT NULL,
    name character varying NOT NULL,
    private_marks character varying,
    comments character varying,
    description character varying
);


--
-- TOC entry 1574 (class 1259 OID 53157)
-- Dependencies: 6 1573
-- Name: genres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE genres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 0
    CACHE 1;


--
-- TOC entry 1967 (class 0 OID 0)
-- Dependencies: 1574
-- Name: genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE genres_id_seq OWNED BY genres.id;


--
-- TOC entry 1575 (class 1259 OID 53159)
-- Dependencies: 6
-- Name: listens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE listens (
    id integer NOT NULL,
    date timestamp with time zone NOT NULL,
    review character varying,
    private_marks character varying,
    comments character varying,
    mood_id integer NOT NULL,
    album_id integer NOT NULL,
    listen_rating integer,
    place_id integer NOT NULL
);


--
-- TOC entry 1576 (class 1259 OID 53165)
-- Dependencies: 1575 6
-- Name: listens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE listens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- TOC entry 1968 (class 0 OID 0)
-- Dependencies: 1576
-- Name: listens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE listens_id_seq OWNED BY listens.id;


--
-- TOC entry 1577 (class 1259 OID 53167)
-- Dependencies: 6
-- Name: moods; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE moods (
    id integer NOT NULL,
    name character varying NOT NULL,
    private_marks character varying,
    comment character varying,
    description character varying
);


--
-- TOC entry 1578 (class 1259 OID 53173)
-- Dependencies: 1577 6
-- Name: moods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE moods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- TOC entry 1969 (class 0 OID 0)
-- Dependencies: 1578
-- Name: moods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE moods_id_seq OWNED BY moods.id;


--
-- TOC entry 1579 (class 1259 OID 53175)
-- Dependencies: 6
-- Name: places; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE places (
    id integer NOT NULL,
    name character varying NOT NULL,
    private_marks character varying,
    comment character varying,
    description character varying
);


--
-- TOC entry 1580 (class 1259 OID 53181)
-- Dependencies: 6 1579
-- Name: places_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE places_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- TOC entry 1970 (class 0 OID 0)
-- Dependencies: 1580
-- Name: places_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE places_id_seq OWNED BY places.id;


--
-- TOC entry 1581 (class 1259 OID 53183)
-- Dependencies: 6
-- Name: sys_adjectives; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sys_adjectives (
    id integer NOT NULL,
    value character varying NOT NULL
);


--
-- TOC entry 1582 (class 1259 OID 53189)
-- Dependencies: 1581 6
-- Name: sys_adjectives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sys_adjectives_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 0
    CACHE 1;


--
-- TOC entry 1971 (class 0 OID 0)
-- Dependencies: 1582
-- Name: sys_adjectives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sys_adjectives_id_seq OWNED BY sys_adjectives.id;


--
-- TOC entry 1583 (class 1259 OID 53191)
-- Dependencies: 6
-- Name: sys_first_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sys_first_names (
    id integer NOT NULL,
    value character varying NOT NULL
);


--
-- TOC entry 1584 (class 1259 OID 53197)
-- Dependencies: 1583 6
-- Name: sys_first_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sys_first_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 0
    CACHE 1;


--
-- TOC entry 1972 (class 0 OID 0)
-- Dependencies: 1584
-- Name: sys_first_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sys_first_names_id_seq OWNED BY sys_first_names.id;


--
-- TOC entry 1585 (class 1259 OID 53199)
-- Dependencies: 6
-- Name: sys_last_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sys_last_names (
    id integer NOT NULL,
    value character varying NOT NULL
);


--
-- TOC entry 1586 (class 1259 OID 53205)
-- Dependencies: 1585 6
-- Name: sys_last_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sys_last_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 0
    CACHE 1;


--
-- TOC entry 1973 (class 0 OID 0)
-- Dependencies: 1586
-- Name: sys_last_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sys_last_names_id_seq OWNED BY sys_last_names.id;


--
-- TOC entry 1587 (class 1259 OID 53207)
-- Dependencies: 6
-- Name: sys_nouns; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sys_nouns (
    id integer NOT NULL,
    value character varying NOT NULL
);


--
-- TOC entry 1588 (class 1259 OID 53213)
-- Dependencies: 1587 6
-- Name: sys_nouns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sys_nouns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 0
    CACHE 1;


--
-- TOC entry 1974 (class 0 OID 0)
-- Dependencies: 1588
-- Name: sys_nouns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sys_nouns_id_seq OWNED BY sys_nouns.id;


--
-- TOC entry 1589 (class 1259 OID 53215)
-- Dependencies: 6
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    id integer NOT NULL,
    name character varying NOT NULL,
    private_marks character varying,
    comments character varying,
    description character varying,
    create_date timestamp with time zone
);


--
-- TOC entry 1590 (class 1259 OID 53221)
-- Dependencies: 6
-- Name: tags_albums; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags_albums (
    tag_id integer NOT NULL,
    album_id integer NOT NULL
);


--
-- TOC entry 1591 (class 1259 OID 53224)
-- Dependencies: 6
-- Name: tags_artists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags_artists (
    tag_id integer NOT NULL,
    artist_id integer NOT NULL
);


--
-- TOC entry 1592 (class 1259 OID 53227)
-- Dependencies: 6 1589
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 0
    CACHE 1;


--
-- TOC entry 1975 (class 0 OID 0)
-- Dependencies: 1592
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- TOC entry 1593 (class 1259 OID 53229)
-- Dependencies: 6
-- Name: tracks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tracks (
    id integer NOT NULL,
    name character varying NOT NULL,
    track_index integer,
    length integer,
    album_id integer NOT NULL
);


--
-- TOC entry 1594 (class 1259 OID 53235)
-- Dependencies: 6 1593
-- Name: tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tracks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 0
    CACHE 1;


--
-- TOC entry 1976 (class 0 OID 0)
-- Dependencies: 1594
-- Name: tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tracks_id_seq OWNED BY tracks.id;


--
-- TOC entry 1595 (class 1259 OID 53237)
-- Dependencies: 6
-- Name: user_logins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_logins (
    id integer NOT NULL,
    user_id integer NOT NULL,
    login_date timestamp without time zone NOT NULL
);


--
-- TOC entry 1596 (class 1259 OID 53240)
-- Dependencies: 1595 6
-- Name: user_logins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_logins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- TOC entry 1977 (class 0 OID 0)
-- Dependencies: 1596
-- Name: user_logins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_logins_id_seq OWNED BY user_logins.id;


--
-- TOC entry 1597 (class 1259 OID 53242)
-- Dependencies: 6
-- Name: user_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_settings (
    id integer NOT NULL,
    user_id integer NOT NULL,
    value1 character varying
);


--
-- TOC entry 1598 (class 1259 OID 53248)
-- Dependencies: 6 1597
-- Name: user_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- TOC entry 1978 (class 0 OID 0)
-- Dependencies: 1598
-- Name: user_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_settings_id_seq OWNED BY user_settings.id;


--
-- TOC entry 1599 (class 1259 OID 53250)
-- Dependencies: 6
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    user_name character varying NOT NULL,
    password character varying NOT NULL
);


--
-- TOC entry 1600 (class 1259 OID 53256)
-- Dependencies: 1599 6
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- TOC entry 1979 (class 0 OID 0)
-- Dependencies: 1600
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- TOC entry 1879 (class 2604 OID 53258)
-- Dependencies: 1569 1567
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE albums ALTER COLUMN id SET DEFAULT nextval('albums_id_seq'::regclass);


--
-- TOC entry 1881 (class 2604 OID 53259)
-- Dependencies: 1572 1570
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE artists ALTER COLUMN id SET DEFAULT nextval('artists_id_seq'::regclass);


--
-- TOC entry 1882 (class 2604 OID 53260)
-- Dependencies: 1574 1573
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE genres ALTER COLUMN id SET DEFAULT nextval('genres_id_seq'::regclass);


--
-- TOC entry 1883 (class 2604 OID 53261)
-- Dependencies: 1576 1575
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE listens ALTER COLUMN id SET DEFAULT nextval('listens_id_seq'::regclass);


--
-- TOC entry 1884 (class 2604 OID 53262)
-- Dependencies: 1578 1577
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE moods ALTER COLUMN id SET DEFAULT nextval('moods_id_seq'::regclass);


--
-- TOC entry 1885 (class 2604 OID 53263)
-- Dependencies: 1580 1579
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE places ALTER COLUMN id SET DEFAULT nextval('places_id_seq'::regclass);


--
-- TOC entry 1886 (class 2604 OID 53264)
-- Dependencies: 1582 1581
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sys_adjectives ALTER COLUMN id SET DEFAULT nextval('sys_adjectives_id_seq'::regclass);


--
-- TOC entry 1887 (class 2604 OID 53265)
-- Dependencies: 1584 1583
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sys_first_names ALTER COLUMN id SET DEFAULT nextval('sys_first_names_id_seq'::regclass);


--
-- TOC entry 1888 (class 2604 OID 53266)
-- Dependencies: 1586 1585
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sys_last_names ALTER COLUMN id SET DEFAULT nextval('sys_last_names_id_seq'::regclass);


--
-- TOC entry 1889 (class 2604 OID 53267)
-- Dependencies: 1588 1587
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sys_nouns ALTER COLUMN id SET DEFAULT nextval('sys_nouns_id_seq'::regclass);


--
-- TOC entry 1890 (class 2604 OID 53268)
-- Dependencies: 1592 1589
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- TOC entry 1891 (class 2604 OID 53269)
-- Dependencies: 1594 1593
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE tracks ALTER COLUMN id SET DEFAULT nextval('tracks_id_seq'::regclass);


--
-- TOC entry 1892 (class 2604 OID 53270)
-- Dependencies: 1596 1595
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_logins ALTER COLUMN id SET DEFAULT nextval('user_logins_id_seq'::regclass);


--
-- TOC entry 1893 (class 2604 OID 53271)
-- Dependencies: 1598 1597
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_settings ALTER COLUMN id SET DEFAULT nextval('user_settings_id_seq'::regclass);


--
-- TOC entry 1894 (class 2604 OID 53272)
-- Dependencies: 1600 1599
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- TOC entry 1896 (class 2606 OID 53274)
-- Dependencies: 1567 1567
-- Name: pk_albums; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY albums
    ADD CONSTRAINT pk_albums PRIMARY KEY (id);


--
-- TOC entry 1898 (class 2606 OID 53276)
-- Dependencies: 1570 1570
-- Name: pk_artists; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY artists
    ADD CONSTRAINT pk_artists PRIMARY KEY (id);


--
-- TOC entry 1902 (class 2606 OID 53278)
-- Dependencies: 1573 1573
-- Name: pk_genres; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY genres
    ADD CONSTRAINT pk_genres PRIMARY KEY (id);


--
-- TOC entry 1907 (class 2606 OID 53280)
-- Dependencies: 1575 1575
-- Name: pk_listens; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY listens
    ADD CONSTRAINT pk_listens PRIMARY KEY (id);


--
-- TOC entry 1909 (class 2606 OID 53282)
-- Dependencies: 1577 1577
-- Name: pk_moods; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY moods
    ADD CONSTRAINT pk_moods PRIMARY KEY (id);


--
-- TOC entry 1913 (class 2606 OID 53284)
-- Dependencies: 1579 1579
-- Name: pk_places; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY places
    ADD CONSTRAINT pk_places PRIMARY KEY (id);


--
-- TOC entry 1917 (class 2606 OID 53286)
-- Dependencies: 1581 1581
-- Name: pk_sys_adjectives; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sys_adjectives
    ADD CONSTRAINT pk_sys_adjectives PRIMARY KEY (id);


--
-- TOC entry 1925 (class 2606 OID 53288)
-- Dependencies: 1585 1585
-- Name: pk_sys_last_names; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sys_last_names
    ADD CONSTRAINT pk_sys_last_names PRIMARY KEY (id);


--
-- TOC entry 1921 (class 2606 OID 53290)
-- Dependencies: 1583 1583
-- Name: pk_sys_names; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sys_first_names
    ADD CONSTRAINT pk_sys_names PRIMARY KEY (id);


--
-- TOC entry 1929 (class 2606 OID 53292)
-- Dependencies: 1587 1587
-- Name: pk_sys_nouns; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sys_nouns
    ADD CONSTRAINT pk_sys_nouns PRIMARY KEY (id);


--
-- TOC entry 1933 (class 2606 OID 53294)
-- Dependencies: 1589 1589
-- Name: pk_tags; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT pk_tags PRIMARY KEY (id);


--
-- TOC entry 1937 (class 2606 OID 53296)
-- Dependencies: 1593 1593
-- Name: pk_tracks; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tracks
    ADD CONSTRAINT pk_tracks PRIMARY KEY (id);


--
-- TOC entry 1939 (class 2606 OID 53298)
-- Dependencies: 1595 1595
-- Name: pk_user_logins; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_logins
    ADD CONSTRAINT pk_user_logins PRIMARY KEY (id);


--
-- TOC entry 1941 (class 2606 OID 53300)
-- Dependencies: 1597 1597
-- Name: pk_user_settings; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_settings
    ADD CONSTRAINT pk_user_settings PRIMARY KEY (id);


--
-- TOC entry 1943 (class 2606 OID 53302)
-- Dependencies: 1599 1599
-- Name: pk_users; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT pk_users PRIMARY KEY (id);


--
-- TOC entry 1900 (class 2606 OID 53304)
-- Dependencies: 1570 1570
-- Name: uq_artists(name); Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY artists
    ADD CONSTRAINT "uq_artists(name)" UNIQUE (name);


--
-- TOC entry 1904 (class 2606 OID 53306)
-- Dependencies: 1573 1573
-- Name: uq_genres(name); Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY genres
    ADD CONSTRAINT "uq_genres(name)" UNIQUE (name);


--
-- TOC entry 1911 (class 2606 OID 53308)
-- Dependencies: 1577 1577
-- Name: uq_moods(name); Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY moods
    ADD CONSTRAINT "uq_moods(name)" UNIQUE (name);


--
-- TOC entry 1915 (class 2606 OID 53310)
-- Dependencies: 1579 1579
-- Name: uq_places(name); Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY places
    ADD CONSTRAINT "uq_places(name)" UNIQUE (name);


--
-- TOC entry 1919 (class 2606 OID 53312)
-- Dependencies: 1581 1581
-- Name: uq_sys_adjectives(value); Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sys_adjectives
    ADD CONSTRAINT "uq_sys_adjectives(value)" UNIQUE (value);


--
-- TOC entry 1927 (class 2606 OID 53314)
-- Dependencies: 1585 1585
-- Name: uq_sys_last_names(value); Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sys_last_names
    ADD CONSTRAINT "uq_sys_last_names(value)" UNIQUE (value);


--
-- TOC entry 1923 (class 2606 OID 53316)
-- Dependencies: 1583 1583
-- Name: uq_sys_names(value); Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sys_first_names
    ADD CONSTRAINT "uq_sys_names(value)" UNIQUE (value);


--
-- TOC entry 1931 (class 2606 OID 53318)
-- Dependencies: 1587 1587
-- Name: uq_sys_nouns(value); Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sys_nouns
    ADD CONSTRAINT "uq_sys_nouns(value)" UNIQUE (value);


--
-- TOC entry 1935 (class 2606 OID 53320)
-- Dependencies: 1589 1589
-- Name: uq_tags(name); Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT "uq_tags(name)" UNIQUE (name);


--
-- TOC entry 1945 (class 2606 OID 53322)
-- Dependencies: 1599 1599
-- Name: uq_users(user_name); Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT "uq_users(user_name)" UNIQUE (user_name);


--
-- TOC entry 1905 (class 1259 OID 53323)
-- Dependencies: 1575
-- Name: fki_listens_places; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fki_listens_places ON listens USING btree (place_id);


--
-- TOC entry 1946 (class 2606 OID 53324)
-- Dependencies: 1568 1567 1895
-- Name: albums_genres_to_albums; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY albums_genres
    ADD CONSTRAINT albums_genres_to_albums FOREIGN KEY (album_id) REFERENCES albums(id);


--
-- TOC entry 1947 (class 2606 OID 53329)
-- Dependencies: 1901 1573 1568
-- Name: albums_genres_to_genres; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY albums_genres
    ADD CONSTRAINT albums_genres_to_genres FOREIGN KEY (genre_id) REFERENCES genres(id);


--
-- TOC entry 1948 (class 2606 OID 53334)
-- Dependencies: 1571 1895 1567
-- Name: fk_artists_albums_to_albums; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY artists_albums
    ADD CONSTRAINT fk_artists_albums_to_albums FOREIGN KEY (album_id) REFERENCES albums(id);


--
-- TOC entry 1949 (class 2606 OID 53339)
-- Dependencies: 1570 1897 1571
-- Name: fk_artists_albums_to_artists; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY artists_albums
    ADD CONSTRAINT fk_artists_albums_to_artists FOREIGN KEY (artist_id) REFERENCES artists(id);


--
-- TOC entry 1950 (class 2606 OID 53344)
-- Dependencies: 1895 1575 1567
-- Name: fk_listens_albums; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listens
    ADD CONSTRAINT fk_listens_albums FOREIGN KEY (album_id) REFERENCES albums(id);


--
-- TOC entry 1951 (class 2606 OID 53349)
-- Dependencies: 1577 1908 1575
-- Name: fk_listens_moods; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listens
    ADD CONSTRAINT fk_listens_moods FOREIGN KEY (mood_id) REFERENCES moods(id);


--
-- TOC entry 1952 (class 2606 OID 53354)
-- Dependencies: 1912 1575 1579
-- Name: fk_listens_places; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listens
    ADD CONSTRAINT fk_listens_places FOREIGN KEY (place_id) REFERENCES places(id);


--
-- TOC entry 1953 (class 2606 OID 53359)
-- Dependencies: 1895 1567 1590
-- Name: fk_tags_albums_to_albums; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags_albums
    ADD CONSTRAINT fk_tags_albums_to_albums FOREIGN KEY (album_id) REFERENCES albums(id);


--
-- TOC entry 1954 (class 2606 OID 53364)
-- Dependencies: 1932 1589 1590
-- Name: fk_tags_albums_to_tags; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags_albums
    ADD CONSTRAINT fk_tags_albums_to_tags FOREIGN KEY (tag_id) REFERENCES tags(id);


--
-- TOC entry 1955 (class 2606 OID 53369)
-- Dependencies: 1570 1897 1591
-- Name: fk_tags_artists_to_artists; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags_artists
    ADD CONSTRAINT fk_tags_artists_to_artists FOREIGN KEY (artist_id) REFERENCES artists(id);


--
-- TOC entry 1956 (class 2606 OID 53374)
-- Dependencies: 1589 1932 1591
-- Name: fk_tags_artists_to_tags; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags_artists
    ADD CONSTRAINT fk_tags_artists_to_tags FOREIGN KEY (tag_id) REFERENCES tags(id);


--
-- TOC entry 1957 (class 2606 OID 53379)
-- Dependencies: 1567 1593 1895
-- Name: fk_tracks_albums; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracks
    ADD CONSTRAINT fk_tracks_albums FOREIGN KEY (album_id) REFERENCES albums(id);


--
-- TOC entry 1958 (class 2606 OID 53384)
-- Dependencies: 1942 1595 1599
-- Name: fk_user_logins_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_logins
    ADD CONSTRAINT fk_user_logins_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- TOC entry 1959 (class 2606 OID 53389)
-- Dependencies: 1599 1942 1597
-- Name: fk_user_settings_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_settings
    ADD CONSTRAINT fk_user_settings_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- TOC entry 1964 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM "user";
GRANT ALL ON SCHEMA public TO "user";
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2011-05-07 16:32:04

--
-- PostgreSQL database dump complete
--

