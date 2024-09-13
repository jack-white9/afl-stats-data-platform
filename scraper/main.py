from bs4 import BeautifulSoup
from urllib.request import urlopen
import pandas as pd
import re


def create_player_df() -> pd.DataFrame:
    df = pd.DataFrame(
        columns=[
            "Team",
            "#",
            "Player",
            "Games played",
            "Kicks",
            "Marks",
            "Handballs",
            "Disposals",
            "Disposal average",
            "Goals",
            "Behinds",
            "Hit outs",
            "Tackles",
            "Rebound 50s",
            "Inside 50s",
            "Clearances",
            "Clangers",
            "Free kicks for",
            "Free kicks against",
            "Brownlow votes",
            "Contested possessions",
            "Uncontested possessions",
            "Contested marks",
            "Marks inside 50",
            "One percenters",
            "Bounces",
            "Goal assist",
            "Percentage of game played",
            "Sub (On/Off)",
        ]
    )
    return df


def parse_afl_tables(url: str, df: pd.DataFrame) -> pd.DataFrame:
    html = urlopen(url).read().decode("utf-8")
    soup = BeautifulSoup(html, "html.parser")

    # Find all tables on the page (each table is a team)
    teams = soup.find_all("table")
    for team in teams:
        table_body = team.find("tbody")

        # remove empty tables (e.g. abbreviation key)
        if table_body is None:
            continue

        # Get team name (regex to remove extra info in brackets)
        team_name = re.sub(
            r"\s\[.*\]", "", team.find("thead").find("tr").find("th").text
        )

        # Get player data from table rows and append to dataframe
        players = table_body.find_all("tr")
        for player in players:
            player_data = player.find_all("td")
            player_data = [col.text.strip() for col in player_data]
            df.loc[len(df)] = [team_name] + player_data


if __name__ == "__main__":
    df = create_player_df()
    parse_afl_tables("https://afltables.com/afl/stats/2024.html", df)
    print(df)
