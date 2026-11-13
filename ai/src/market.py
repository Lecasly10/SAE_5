"""Prix neuf et nombre d'exemplaires de chaque voiture, pour calculer sa
rareté dans l'application.

- Prix neuf : tables de DVM-Car (voitures vendues au Royaume-Uni).
- Nombre d'exemplaires : chiffres publics des constructeurs, seulement pour
  les séries limitées (aucun dataset ne les donne)."""
import csv
import io
import json
import statistics
import zipfile
from collections import defaultdict

from src.config import MARKET_PATH
from src.extra_datasets import slug

# Prix des tables de DVM-Car en livres sterling
GBP_TO_EUR = 1.17

# Exemplaires fabriqués des séries limitées du catalogue (chiffres arrondis
# annoncés par les constructeurs, toutes versions du modèle comprises)
PRODUCED = {
    "bugatti_chiron": 500,
    "bugatti_veyron_grand_sport_vitesse": 450,
    "ferrari_212_inter": 80,
    "ferrari_365_gtb4_daytona": 1400,
    "ferrari_365_gts4": 120,
    "ferrari_575_m_superamerica": 560,
    "ferrari_599_gto": 600,
    "ferrari_enzo": 400,
    "ferrari_f40": 1300,
    "lamborghini_aventador_svj": 1700,
    "lamborghini_lp7804_ultimae": 600,
    "lamborghini_murcielago": 4100,
    "mclaren_675lt": 1000,
    "mclaren_p1": 375,
    "pagani_huayra": 100,
}


def read_table(tables, name):
    """Lignes d'une table de DVM-Car, noms de colonnes sans espaces autour."""
    with tables.open(name) as file:
        rows = csv.reader(io.TextIOWrapper(file, encoding="utf-8", errors="replace"))
        header = [column.strip() for column in next(rows)]
        for row in rows:
            yield dict(zip(header, (value.strip() for value in row)))


def dvm_prices(tables_zip):
    """{dossier DVM : [prix neufs en €]}. Les dossiers sont nommés comme ceux
    de extra_datasets.py."""
    prices = defaultdict(list)
    with zipfile.ZipFile(tables_zip) as tables:
        folders = {
            row["Genmodel_ID"]: f"DVM_{slug(row['Automaker'])}_{slug(row['Genmodel'])}"
            for row in read_table(tables, "Basic_table.csv")
        }
        for row in read_table(tables, "Price_table.csv"):
            if row["Genmodel_ID"] in folders and row["Entry_price"].isdigit():
                prices[folders[row["Genmodel_ID"]]].append(int(row["Entry_price"]) * GBP_TO_EUR)
    return dict(prices)


def build_market(catalog, prices):
    """{id de voiture : {"price", "produced"}} à partir des dossiers de chaque
    voiture (cars.json)."""
    market = {}
    for car in catalog:
        car_prices = [price for name in car.sources for price in prices.get(name, ())]
        market[car.id] = {
            "price": int(round(statistics.median(car_prices), -2)) if car_prices else None,
            "produced": PRODUCED.get(car.id),
        }
    return market


def save_market(market, path=MARKET_PATH):
    with open(path, "w", encoding="utf-8") as file:
        json.dump(market, file, indent=1, sort_keys=True)
        file.write("\n")


def load_market(path=MARKET_PATH):
    if path is None or not path.exists():
        return {}
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)
