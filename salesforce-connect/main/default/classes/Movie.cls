public class Movie {

    public Integer page;
    public List<Result> results;
    public Result result;
    public String id;
    public String original_title;
    public String original_language;
    public Boolean adult;
    public String overview;
    public Decimal popularity;
    public Decimal vote_average;
    public Datetime release_date;

    public class Result {
        public String id;
        public String original_title;
        public String original_language;
        public Boolean adult;
        public String overview;
        public Decimal popularity;
        public Decimal vote_average;
        public Datetime release_date;
    }

}