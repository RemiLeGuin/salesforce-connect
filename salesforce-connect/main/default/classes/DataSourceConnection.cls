global class DataSourceConnection extends DataSource.Connection {
    
    global DataSourceConnection() {}
    global DataSourceConnection(DataSource.ConnectionParams connectionParams) {}

    override global List<DataSource.Table> sync() {

        List<DataSource.Table> tables = new List<DataSource.Table>();

        List<DataSource.Column> columns = new List<DataSource.Column>();
        columns.add(DataSource.Column.get('ExternalId', 'ExternalId', '', false, false, DataSource.DataType.STRING_SHORT_TYPE, 255));
        columns.add(DataSource.Column.get('DisplayUrl', 'DisplayUrl', '', false, false, DataSource.DataType.URL_TYPE, 1000));
        columns.add(DataSource.Column.get('Title', 'Title', 'Movie title.', true, false, DataSource.DataType.STRING_SHORT_TYPE, 255));
        columns.add(DataSource.Column.get('Language', 'Language', 'Movie language.', false, true, DataSource.DataType.STRING_SHORT_TYPE, 5));
        columns.add(DataSource.Column.get('Adult', 'Adult', 'Movie for adults.', false, false, DataSource.DataType.BOOLEAN_TYPE, 0));
        columns.add(DataSource.Column.get('Overview', 'Overview', 'Synopsis.', false, false, DataSource.DataType.STRING_LONG_TYPE, 131072));
        columns.add(DataSource.Column.get('Vote', 'Vote', 'Movie rating.', true, true, DataSource.DataType.NUMBER_TYPE, 3, 1));
        columns.add(DataSource.Column.get('Popularity', 'Popularity', 'Movie popularity.', true, false, DataSource.DataType.NUMBER_TYPE, 4, 1));
        columns.add(DataSource.Column.get('ReleaseDate', 'Release Date', 'Release date.', true, true, DataSource.DataType.DATETIME_TYPE, 24));

        DataSource.Table table = new DataSource.Table();
        table.labelSingular = 'Movie';
        table.labelPlural = 'Movies';
        table.name = 'Movie';
        table.description = 'From \'The Movie Database\'.';
        table.nameColumn = 'Title';
        table.columns = columns;
        tables.add(table);

        return tables;

    }

    override global List<DataSource.TableResult> search(DataSource.SearchContext context) {
        System.debug('SEARCH');
        List<DataSource.TableResult> results = new List<DataSource.TableResult>();
        for (DataSource.TableSelection tableSelection : context.tableSelections) {}
        return results;
    }

    override global DataSource.TableResult query(DataSource.QueryContext context) {
        List<Map<String, Object>> rows;
        context = (DataSource.QueryContext)context;
        if (context.tableSelection.tableSelected == 'Movie'
            && context.tableSelection.filter != null
            && context.tableSelection.filter.subfilters == null
            && context.tableSelection.filter.tableName == 'Movie'
            && context.tableSelection.filter.columnName == 'ExternalId'
            && context.tableSelection.filter.type == DataSource.FilterType.EQUALS
            && context.tableSelection.filter.columnValue instanceOf String) {
            rows = getRow(context);
        }
        else if (context.tableSelection.tableSelected == 'Movie') {
            rows = getRows(context);
        }
        return DataSource.TableResult.get(context.TableSelection, rows);
    }

    private static List<Map<String,Object>> getRow(DataSource.QueryContext context) {
        context = (DataSource.QueryContext)context;
        HttpResponse response = MoviesCallout.getMovie((String)context.tableSelection.filter.columnValue);
        Movie movie = (Movie) System.JSON.deserialize(response.getBody(), Movie.class);
        List<Map<String, Object>> rows = new List<Map<String, Object>> ();
        rows.add(new Map<String, Object> {
            'ExternalId' => movie.id,
            'Title' => movie.original_title,
            'Language' => movie.original_language,
            'Adult' => movie.adult,
            'Overview' => movie.overview,
            'Popularity' => movie.popularity,
            'Vote' => movie.vote_average,
            'ReleaseDate' => movie.release_date
        });
        return rows;
    }

    private static List<Map<String,Object>> getRows(DataSource.QueryContext context) {
        DataSource.ReadContext readContext = (DataSource.ReadContext)context;
        List<DataSource.Order> order = context.tableSelection.order;
        String sortingColumnName, sortingDirection;
        if (order!= null & !order.isEmpty() && order[0] != null && order[0].columnName != 'ExternalId') {
            sortingColumnName = order[0].columnName;
            sortingDirection = order[0].direction == null ? null : String.valueOf(order[0].direction);
        }
        String sorting = getSortingWording(sortingColumnName, sortingDirection);
        Map<String, String> filters = getFilters(context);
        String language, releaseDateGte, releaseDateLte, voteAverageGte, voteAverageLte;
        if (filters != null) {
            language = filters.get('with_original_language');
            releaseDateGte = filters.get('release_date.gte');
            releaseDateLte = filters.get('release_date.lte');
            voteAverageGte = filters.get('vote_average.gte');
            voteAverageLte = filters.get('vote_average.lte');
        }
        Decimal offset = readContext.offset;
        Decimal startingPage = offset.divide(20, 1) + 1;
        List<Movie.Result> movies = new List<Movie.Result> ();
        Integer pagesToRetrieve = readContext.maxResults == 51 ? startingPage.intValue()+2 : 100;
        for (Integer i = startingPage.intValue(); i <= pagesToRetrieve; i++) {
            HttpResponse response = MoviesCallout.discoverMovies(sorting, i, language, releaseDateGte, releaseDateLte, voteAverageGte, voteAverageLte);
            Movie deserializedResponse = (Movie) System.JSON.deserialize(response.getBody(), Movie.class);
            List<Movie.Result> pageResults = deserializedResponse.results;
            movies.addAll(pageResults);
        }
        if (readContext.maxResults == 51) {
            cropMovies(movies, offset);
        }
        movies = sortMovies(movies, sortingColumnName, sortingDirection);
        if (readContext.maxResults == 51) {
            Movie.Result additionalMovie = new Movie.Result();
            additionalMovie.id = 'x';
            movies.add(additionalMovie);
        }
        List<Map<String, Object>> rows = new List<Map<String, Object>> ();
        for (Movie.Result movie : movies) {
            rows.add(new Map<String, Object> {
                'ExternalId' => movie.id,
                'Title' => movie.original_title,
                'Language' => movie.original_language,
                'Adult' => movie.adult,
                'Overview' => movie.overview,
                'Popularity' => movie.popularity,
                'Vote' => movie.vote_average,
                'ReleaseDate' => movie.release_date
            });
        }
        return rows;
    }

    private static Map<String, String> getFilters(DataSource.QueryContext context) {
        Map<String, String> filters = new Map<String, String> ();
        if (context.tableSelection.filter != null && context.tableSelection.filter.columnName != null) {
            switch on context.tableSelection.filter.columnName {
                when 'Language' {
                    if (context.tableSelection.filter.type.name() == 'EQUALS') {
                        filters.put('with_original_language', String.valueOf(context.tableSelection.filter.columnValue));
                    }
                }
                when 'ReleaseDate' {
                    if (context.tableSelection.filter.type.name() == 'GREATER_THAN_OR_EQUAL_TO'
                        || context.tableSelection.filter.type.name() == 'GREATER_THAN') {
                        filters.put('release_date.gte', String.valueOf(Date.valueOf(context.tableSelection.filter.columnValue)));
                    }
                    else if (context.tableSelection.filter.type.name() == 'LESS_THAN_OR_EQUAL_TO'
                        || context.tableSelection.filter.type.name() == 'LESS_THAN') {
                        filters.put('release_date.lte', String.valueOf(Date.valueOf(context.tableSelection.filter.columnValue)));
                    }
                }
                when 'Vote' {
                    if (context.tableSelection.filter.type.name() == 'GREATER_THAN_OR_EQUAL_TO'
                        || context.tableSelection.filter.type.name() == 'GREATER_THAN') {
                        filters.put('vote_average.gte', String.valueOf(context.tableSelection.filter.columnValue));
                    }
                    else if (context.tableSelection.filter.type.name() == 'LESS_THAN_OR_EQUAL_TO'
                        || context.tableSelection.filter.type.name() == 'LESS_THAN') {
                        filters.put('vote_average.lte', String.valueOf(context.tableSelection.filter.columnValue));
                    }
                }
            }
        }
        return filters.isEmpty() ? null : filters;
    }

    private static String getSortingWording(String sortingColumnName, String sortingDirection) {
        String sorting = '';
        if (!String.isBlank(sortingColumnName) && !String.isBlank(sortingDirection)) {
            switch on sortingColumnName {
                when 'Title' {
                    sorting = 'original_title';
                }
                when 'Vote' {
                    sorting = 'vote_average';
                }
                when 'Popularity' {
                    sorting = 'popularity';
                }
                when 'ReleaseDate' {
                    sorting = 'release_date';
                }
            }
            if (!String.isBlank(sorting) && sortingDirection == 'ASCENDING') {
                sorting += '.asc';
            }
            else if (!String.isBlank(sorting) && sortingDirection == 'DESCENDING') {
                sorting += '.desc';
            }
        }
        return sorting;
    }

    private static List<Movie.Result> cropMovies(List<Movie.Result> movies, Decimal offset) {
        if (String.valueOf(offset).right(2).left(1) == '5') {
            for (Integer i = 0; i < 10; i++) {
                movies.remove(0);
            }
        }
        else if (String.valueOf(offset).right(2).left(1) == '0') {
            for (Integer i = movies.size() - 10; i < movies.size(); i++) {
                movies.remove(movies.size() - 1);
            }
        }
        return movies;
    }

    private static List<Movie.Result> sortMovies(List<Movie.Result> movies, String sortingColumnName, String sortingDirection) {
        List<MoviesSorting> sorting = new List<MoviesSorting> ();
        for (Movie.Result movie : movies) {
            sorting.add(new MoviesSorting(movie, sortingColumnName, sortingDirection));
        }
        sorting.sort();
        List<Movie.Result> sortedMovies = new List<Movie.Result> ();
        for (MoviesSorting item : sorting) {
            sortedMovies.add(item.movieRow);
        }
        return sortedMovies;
    }

    private class MoviesSorting implements Comparable {
        
        public Movie.Result movieRow;
        public String sortingColumnName;
        public String sortingDirection;

        public MoviesSorting(Movie.Result movieRow, String sortingColumnName, String sortingDirection) {
            this.movieRow = movieRow;
            this.sortingColumnName = sortingColumnName;
            this.sortingDirection = sortingDirection;
        }

        public Integer compareTo(Object compareTo) {
            MoviesSorting compareToMovieRow = (MoviesSorting)compareTo;
            Integer returnValue = 0;
            if (sortingDirection == 'ASCENDING') {
                switch on sortingColumnName {
                    when 'Title' {
                        if (movieRow.original_title > compareToMovieRow.movieRow.original_title) {
                            returnValue = 1;
                        }
                        else if (movieRow.original_title < compareToMovieRow.movieRow.original_title) {
                            returnValue = -1;
                        }
                    }
                    when 'Vote' {
                        if (movieRow.vote_average > compareToMovieRow.movieRow.vote_average) {
                            returnValue = 1;
                        }
                        else if (movieRow.vote_average < compareToMovieRow.movieRow.vote_average) {
                            returnValue = -1;
                        }
                    }
                    when 'Popularity' {
                        if (movieRow.popularity > compareToMovieRow.movieRow.popularity) {
                            returnValue = 1;
                        }
                        else if (movieRow.popularity < compareToMovieRow.movieRow.popularity) {
                            returnValue = -1;
                        }
                    }
                    when 'ReleaseDate' {
                        if (movieRow.release_date > compareToMovieRow.movieRow.release_date) {
                            returnValue = 1;
                        }
                        else if (movieRow.release_date < compareToMovieRow.movieRow.release_date) {
                            returnValue = -1;
                        }
                    }
                }
            }
            else if (sortingDirection == 'DESCENDING') {
                switch on sortingColumnName {
                    when 'Title' {
                        if (movieRow.original_title < compareToMovieRow.movieRow.original_title) {
                            returnValue = 1;
                        }
                        else if (movieRow.original_title > compareToMovieRow.movieRow.original_title) {
                            returnValue = -1;
                        }
                    }
                    when 'Vote' {
                        if (movieRow.vote_average < compareToMovieRow.movieRow.vote_average) {
                            returnValue = 1;
                        }
                        else if (movieRow.vote_average > compareToMovieRow.movieRow.vote_average) {
                            returnValue = -1;
                        }
                    }
                    when 'Popularity' {
                        if (movieRow.popularity < compareToMovieRow.movieRow.popularity) {
                            returnValue = 1;
                        }
                        else if (movieRow.popularity > compareToMovieRow.movieRow.popularity) {
                            returnValue = -1;
                        }
                    }
                    when 'ReleaseDate' {
                        if (movieRow.release_date < compareToMovieRow.movieRow.release_date) {
                            returnValue = 1;
                        }
                        else if (movieRow.release_date > compareToMovieRow.movieRow.release_date) {
                            returnValue = -1;
                        }
                    }
                }
            }
            return returnValue;
        }

    }

}