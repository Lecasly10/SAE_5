"""Prix neuf de chaque voiture et fréquence à laquelle on la croise, pour
calculer sa rareté dans l'application.

- Prix neuf et ventes : tables de DVM-Car (voitures vendues au Royaume-Uni de
  2001 à 2020), le plus proche de ce qu'on croise en France.
- Fréquence aux États-Unis : nombre de photos d'annonces de VMMRdb.

- Nombre d'exemplaires : chiffres publics des constructeurs, seulement pour
  les séries limitées (aucun dataset ne les donne).

La fréquence est un rang entre 0 (la voiture la moins vue) et 1 (la plus
vue). null : la voiture n'existe pas dans ce pays, elle y est donc rare."""
import csv
import io
import json
import statistics
import zipfile
from collections import Counter, defaultdict

from src.config import MARKET_PATH
from src.extra_datasets import slug, vmmr_label

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


def dvm_market(tables_zip):
    """{dossier DVM : {"prices": [prix en €], "sales": ventes}}. Les dossiers
    sont nommés comme ceux de extra_datasets.py."""
    market = defaultdict(lambda: {"prices": [], "sales": 0})
    with zipfile.ZipFile(tables_zip) as tables:
        folders = {
            row["Genmodel_ID"]: f"DVM_{slug(row['Automaker'])}_{slug(row['Genmodel'])}"
            for row in read_table(tables, "Basic_table.csv")
        }
        for row in read_table(tables, "Price_table.csv"):
            if row["Genmodel_ID"] in folders and row["Entry_price"].isdigit():
                market[folders[row["Genmodel_ID"]]]["prices"].append(int(row["Entry_price"]) * GBP_TO_EUR)
        for row in read_table(tables, "Sales_table.csv"):
            folder = folders.get(row.get("Genmodel ID"))
            if folder:
                market[folder]["sales"] += sum(int(value) for key, value in row.items()
                                               if key.isdigit() and value.isdigit())
    return dict(market)


def vmmr_counts(vmmr_zip):
    """{dossier VMMR : nombre de photos d'annonces}."""
    counts = Counter()
    with zipfile.ZipFile(vmmr_zip) as archive:
        for name in archive.namelist():
            label = vmmr_label(name)
            if label:
                brand, model, _ = label
                counts[f"VMMR_{slug(brand)}_{slug(model)}"] += 1
    return counts


def ranks(values):
    """Rang de chaque valeur entre 0 (la plus petite) et 1 (la plus grande)."""
    ordered = sorted(values.values())
    last = max(len(ordered) - 1, 1)
    position = {value: index / last for index, value in enumerate(ordered)}
    return {key: round(position[value], 3) for key, value in values.items()}


def build_market(catalog, dvm, vmmr):
    """{id de voiture : {"price", "europe", "america"}} à partir des dossiers
    de chaque voiture (cars.json)."""
    prices, europe, america = {}, {}, {}
    for car in catalog:
        car_prices = [price for name in car.sources if name in dvm for price in dvm[name]["prices"]]
        if car_prices:
            prices[car.id] = round(statistics.median(car_prices), -2)
        if any(name in dvm for name in car.sources):
            europe[car.id] = sum(dvm[name]["sales"] for name in car.sources if name in dvm)
        if any(name in vmmr for name in car.sources):
            america[car.id] = sum(vmmr[name] for name in car.sources if name in vmmr)

    europe, america = ranks(europe), ranks(america)
    return {
        car.id: {
            "price": int(prices[car.id]) if car.id in prices else None,
            "europe": europe.get(car.id),
            "america": america.get(car.id),
            "produced": PRODUCED.get(car.id),
        }
        for car in catalog
    }


def save_market(market, path=MARKET_PATH):
    with open(path, "w", encoding="utf-8") as file:
        json.dump(market, file, indent=1, sort_keys=True)
        file.write("\n")


def load_market(path=MARKET_PATH):
    if not path.exists():
        return {}
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)
