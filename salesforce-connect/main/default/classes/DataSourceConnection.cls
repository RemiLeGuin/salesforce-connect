global class DataSourceConnection extends DataSource.Connection {
    
    global DataSourceConnection() {}
    global DataSourceConnection(DataSource.ConnectionParams connectionParams) {}

    override global List<DataSource.Table> sync() {

        List<DataSource.Table> tables = new List<DataSource.Table>();

        List<DataSource.Column> columns = new List<DataSource.Column>();
        columns.add(DataSource.Column.text('ExternalId'));
        columns.add(DataSource.Column.url('DisplayUrl'));
        columns.add(DataSource.Column.get('Title', 'Title', 'Movie title.', true, true, DataSource.DataType.STRING_SHORT_TYPE, 255));
        columns.add(DataSource.Column.get('Language', 'Language', 'Movie language.', false, false, DataSource.DataType.STRING_SHORT_TYPE, 5));
        columns.add(DataSource.Column.get('Adult', 'Adult', 'Movie for adults.', false, false, DataSource.DataType.BOOLEAN_TYPE, 0));
        columns.add(DataSource.Column.get('Overview', 'Overview', 'Synopsis.', false, false, DataSource.DataType.STRING_LONG_TYPE, 131072));
        columns.add(DataSource.Column.get('Vote', 'Vote', 'Movie rating.', true, true, DataSource.DataType.NUMBER_TYPE, 3, 1));
        columns.add(DataSource.Column.get('Popularity', 'Popularity', 'Movie popularity.', true, true, DataSource.DataType.NUMBER_TYPE, 4, 1));
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
        else if (context.tableSelection.tableSelected == 'Movie'
                 && context.tableSelection.filter == null) {
            rows = getRows(context);
        }
        return DataSource.TableResult.get(context.TableSelection, rows);
    }

    private List<Map<String,Object>> getRow(DataSource.QueryContext context) {
        context = (DataSource.QueryContext)context;
        HttpResponse response = getMovie((String)context.tableSelection.filter.columnValue);
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

    private List<Map<String,Object>> getRows(DataSource.QueryContext context) {
        DataSource.ReadContext readContext = (DataSource.ReadContext)context;
        String sorting = getSorting(context);
        Decimal startingPage = readContext.offset;
        startingPage = startingPage.divide(20, 1) + 1;
        List<Movie.Result> movies = new List<Movie.Result> ();
        for (Integer i = startingPage.intValue(); i <= startingPage.intValue()+2; i++) {
            HttpResponse response = discoverMovies(sorting, i);
            Movie deserializedResponse = (Movie) System.JSON.deserialize(response.getBody(), Movie.class);
            List<Movie.Result> pageResults = deserializedResponse.results;
            movies.addAll(pageResults);
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

    private String getSorting(DataSource.QueryContext context) {
        String sorting = '';
        if (context != null) {
            List<DataSource.Order> order = context.tableSelection.order;
            String sortingColumnName, sortingDirection;
            if (order[0] != null && order[0].columnName != 'ExternalId') {
                sortingColumnName = order[0].columnName;
                sortingDirection = String.valueOf(order[0].direction);
            }
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

    private HttpResponse discoverMovies(String sorting, Integer page) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        String endpoint = 'callout:TheMovieDatabase/3/discover/movie?api_key=52121b8ffd37db19123c9f47321e259c&region=FR&page=' + String.valueOf(page);
        if (!String.isBlank(sorting)) {
            endpoint += '&sort_by=' + sorting;
        }
        request.setEndpoint(endpoint);
		request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1MjEyMWI4ZmZkMzdkYjE5MTIzYzlmNDczMjFlMjU5YyIsInN1YiI6IjVjNDc0NWFmMGUwYTI2NDk2NWNhNGFhZiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.tdMnNkQfXU__PtQSCyB-XPBJ3FJtIVwlU86LBJHeURU');
        return new Http().send(request);
    }

    private HttpResponse getMovie(String externalId) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        String endpoint = 'callout:TheMovieDatabase/3/movie/' + externalId + '?api_key=52121b8ffd37db19123c9f47321e259c';
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1MjEyMWI4ZmZkMzdkYjE5MTIzYzlmNDczMjFlMjU5YyIsInN1YiI6IjVjNDc0NWFmMGUwYTI2NDk2NWNhNGFhZiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.tdMnNkQfXU__PtQSCyB-XPBJ3FJtIVwlU86LBJHeURU');
        return new Http().send(request);
    }

}