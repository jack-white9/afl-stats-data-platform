from bs4 import BeautifulSoup
from urllib.request import urlopen
from pyspark.sql import SparkSession
from pyspark.sql import Row
from pyspark.sql.types import StructType, StructField, StringType, IntegerType
from datetime import datetime
import re

# Create Spark session for Glue
spark = SparkSession.builder.appName("AFL Player Stats").getOrCreate()


def create_player_schema() -> StructType:
    schema = StructType(
        [
            StructField("Year", IntegerType(), True),
            StructField("Team", StringType(), True),
            StructField("#", StringType(), True),
            StructField("Player", StringType(), True),
            StructField("Games played", StringType(), True),
            StructField("Kicks", StringType(), True),
            StructField("Marks", StringType(), True),
            StructField("Handballs", StringType(), True),
            StructField("Disposals", StringType(), True),
            StructField("Disposal average", StringType(), True),
            StructField("Goals", StringType(), True),
            StructField("Behinds", StringType(), True),
            StructField("Hit outs", StringType(), True),
            StructField("Tackles", StringType(), True),
            StructField("Rebound 50s", StringType(), True),
            StructField("Inside 50s", StringType(), True),
            StructField("Clearances", StringType(), True),
            StructField("Clangers", StringType(), True),
            StructField("Free kicks for", StringType(), True),
            StructField("Free kicks against", StringType(), True),
            StructField("Brownlow votes", StringType(), True),
            StructField("Contested possessions", StringType(), True),
            StructField("Uncontested possessions", StringType(), True),
            StructField("Contested marks", StringType(), True),
            StructField("Marks inside 50", StringType(), True),
            StructField("One percenters", StringType(), True),
            StructField("Bounces", StringType(), True),
            StructField("Goal assist", StringType(), True),
            StructField("Percentage of game played", StringType(), True),
            StructField("Sub (On/Off)", StringType(), True),
        ]
    )
    return schema


def parse_afl_tables(year: int) -> list:
    url = f"https://afltables.com/afl/stats/{year}.html"
    html = urlopen(url).read().decode("utf-8")
    soup = BeautifulSoup(html, "html.parser")

    # Find all tables on the page (each table is a team)
    teams = soup.find_all("table")
    rows = []
    for team in teams:
        table_body = team.find("tbody")

        # remove empty tables (e.g. abbreviation key)
        if table_body is None:
            continue

        # Get team name (regex to remove extra info in brackets)
        team_name = re.sub(
            r"\s\[.*\]", "", team.find("thead").find("tr").find("th").text
        )

        # Get player data from table rows and append to list
        players = table_body.find_all("tr")
        for player in players:
            player_data = player.find_all("td")
            player_data = [col.text.strip() for col in player_data]
            if player_data:  # Only add non-empty player data
                rows.append(Row(year, team_name, *player_data))

    return rows


if __name__ == "__main__":
    schema = create_player_schema()
    all_player_data = []

    # Loop through each year and collect player data
    for year in range(1897, datetime.now().year + 1):
        print(f"Parsing year: {year}")
        player_data = parse_afl_tables(year)
        all_player_data.extend(player_data)  # Collect all rows across years

    df = spark.createDataFrame(all_player_data, schema)
    df.show()
    df.write.partitionBy("Year").parquet(
        "s3://afl-data-platform-raw-data/afl_player_stats", mode="overwrite"
    )
