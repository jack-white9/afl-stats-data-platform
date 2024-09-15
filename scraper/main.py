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
            StructField("year", IntegerType(), True),
            StructField("team", StringType(), True),
            StructField("number", StringType(), True),
            StructField("player", StringType(), True),
            StructField("games_played", StringType(), True),
            StructField("kicks", StringType(), True),
            StructField("marks", StringType(), True),
            StructField("handballs", StringType(), True),
            StructField("disposals", StringType(), True),
            StructField("disposal_average", StringType(), True),
            StructField("goals", StringType(), True),
            StructField("behinds", StringType(), True),
            StructField("hit_outs", StringType(), True),
            StructField("tackles", StringType(), True),
            StructField("rebound_fifties", StringType(), True),
            StructField("inside_fifties", StringType(), True),
            StructField("clearances", StringType(), True),
            StructField("clangers", StringType(), True),
            StructField("free_kicks_for", StringType(), True),
            StructField("free_kicks_against", StringType(), True),
            StructField("brownlow_votes", StringType(), True),
            StructField("contested_possessions", StringType(), True),
            StructField("uncontested_possessions", StringType(), True),
            StructField("contested_marks", StringType(), True),
            StructField("marks_inside_fifty", StringType(), True),
            StructField("one_percenters", StringType(), True),
            StructField("bounces", StringType(), True),
            StructField("goal_assist", StringType(), True),
            StructField("percentage_of_game_played", StringType(), True),
            StructField("sub_on_off)", StringType(), True),
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
        "s3://afl-data-platform-raw-data/players", mode="overwrite"
    )
