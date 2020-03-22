public class MoviesCallout {

    public static HttpResponse discoverMovies(String sorting, Integer page, String originalLanguage,
                                              String releaseDateGte, String releaseDateLte,
                                              String voteAverageGte, String voteAverageLte) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        String endpoint = 'callout:TheMovieDatabase/3/discover/movie?api_key=52121b8ffd37db19123c9f47321e259c&region=FR&page=' + String.valueOf(page);
        if (!String.isBlank(sorting)) {
            endpoint += '&sort_by=' + sorting;
        }
        if (!String.isBlank(originalLanguage)) {
            endpoint += '&with_original_language=' + originalLanguage;
        }
        if (!String.isBlank(releaseDateGte)) {
            endpoint += '&release_date.gte=' + releaseDateGte;
        }
        if (!String.isBlank(releaseDateLte)) {
            endpoint += '&release_date.lte=' + releaseDateLte;
        }
        if (!String.isBlank(voteAverageGte)) {
            endpoint += '&vote_average.gte=' + voteAverageGte;
        }
        if (!String.isBlank(voteAverageLte)) {
            endpoint += '&vote_average.lte=' + voteAverageLte;
        }
        request.setEndpoint(endpoint);
		request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1MjEyMWI4ZmZkMzdkYjE5MTIzYzlmNDczMjFlMjU5YyIsInN1YiI6IjVjNDc0NWFmMGUwYTI2NDk2NWNhNGFhZiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.tdMnNkQfXU__PtQSCyB-XPBJ3FJtIVwlU86LBJHeURU');
        HttpResponse response;
        try {
            response = new Http().send(request);
        }
        catch(CalloutException e) {
            e.setMessage(Label.MoviesCalloutError);
            throw e;
        }
        return response;
    }

    public static HttpResponse getMovie(String externalId) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        String endpoint = 'callout:TheMovieDatabase/3/movie/' + externalId + '?api_key=52121b8ffd37db19123c9f47321e259c';
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI1MjEyMWI4ZmZkMzdkYjE5MTIzYzlmNDczMjFlMjU5YyIsInN1YiI6IjVjNDc0NWFmMGUwYTI2NDk2NWNhNGFhZiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.tdMnNkQfXU__PtQSCyB-XPBJ3FJtIVwlU86LBJHeURU');
        HttpResponse response;
        try {
            response = new Http().send(request);
        }
        catch(CalloutException e) {
            e.setMessage(Label.MoviesCalloutError);
            throw e;
        }
        return response;
    }

}