resource "aws_athena_named_query" "http_5xx_error_counts_today" {
  database = aws_glue_catalog_database.fastly_logs.name
  name     = "http_5xx_count_by_path_today"
  query    = <<-QUERY
select
    url, status, count(1) as "count"
from
    ${aws_glue_catalog_table.govuk_www.name}
where
        date >= day(NOW())
    and month >= month(NOW())
    and year >= year(NOW())
    and status between 499 and 600
group by
    url, status
order by
    "count" desc
QUERY
}
