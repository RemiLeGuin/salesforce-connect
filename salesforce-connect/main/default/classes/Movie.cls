public class Movie {

    public Integer page { get; set; }
    public List<Result> results { get; set; }
    public Result result { get; set; }
    public String id { get; set; }
    public String original_title { get; set; }
    public String original_language { get; set; }
    public Boolean adult { get; set; }
    public String overview { get; set; }
    public Decimal popularity { get; set; }
    public Decimal vote_average { get; set; }
    public Datetime release_date { get; set; }

    public class Result {
        public String id { get; set; }
        public String original_title { get; set; }
        public String original_language { get; set; }
        public Boolean adult { get; set; }
        public String overview { get; set; }
        public Decimal popularity { get; set; }
        public Decimal vote_average { get; set; }
        public Datetime release_date { get; set; }
    }

}