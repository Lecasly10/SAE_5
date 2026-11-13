import tempfile
import unittest
import zipfile
from pathlib import Path

from src.catalog import Car, CarCatalog
from src.market import GBP_TO_EUR, build_market, dvm_market, load_market, ranks, save_market, vmmr_counts


def car(car_id, *sources):
    return Car(car_id, "Marque", "Modèle", 2000, None, sources)


class MarketTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_reads_prices_and_sales_of_dvm_car(self):
        tables = self.root / "tables.zip"
        with zipfile.ZipFile(tables, "w") as archive:
            archive.writestr("Basic_table.csv", "Automaker,Automaker_ID,Genmodel,Genmodel_ID\nAbarth,2,124 Spider,2_1\n")
            archive.writestr("Price_table.csv", "Maker, Genmodel, Genmodel_ID, Year, Entry_price\n"
                                                "Abarth,124 Spider,2_1,2016,20000\nAbarth,124 Spider,2_1,2017,\n")
            archive.writestr("Sales_table.csv", "Maker,Genmodel ,Genmodel ID  ,2020,2019\nABARTH,ABARTH 124,2_1,10,5\n")

        market = dvm_market(tables)

        self.assertEqual(market["DVM_abarth_124_spider"]["prices"], [20000 * GBP_TO_EUR])
        self.assertEqual(market["DVM_abarth_124_spider"]["sales"], 15)

    def test_counts_vmmr_photos_per_model(self):
        archive_path = self.root / "vmmr.zip"
        with zipfile.ZipFile(archive_path, "w") as archive:
            for name in ("honda_civic_2002/a.jpg", "honda_civic_2003/b.jpg", "ford_f250_2005/c.jpg"):
                archive.writestr(name, b"x")

        self.assertEqual(vmmr_counts(archive_path), {"VMMR_honda_civic": 2, "VMMR_ford_f250": 1})

    def test_ranks_go_from_least_to_most_seen(self):
        self.assertEqual(ranks({"rare": 1, "middle": 50, "everywhere": 900}), {"rare": 0, "middle": 0.5, "everywhere": 1})

    def test_each_car_gets_its_price_and_where_it_is_seen(self):
        catalog = CarCatalog([
            car("clio", "DVM_renault_clio", "RENAULT_Clio_2019Present"),
            car("f12", "DVM_ferrari_f12"),
            car("f250", "VMMR_ford_f250"),
            car("inconnue", "KAGGLE_ONLY"),
        ])
        dvm = {
            "DVM_renault_clio": {"prices": [9000, 11000], "sales": 500000},
            "DVM_ferrari_f12": {"prices": [279600], "sales": 300},
        }

        market = build_market(catalog, dvm, {"VMMR_ford_f250": 4000})

        self.assertEqual(market["clio"], {"price": 10000, "europe": 1, "america": None, "produced": None})
        self.assertEqual(market["f12"], {"price": 279600, "europe": 0, "america": None, "produced": None})
        self.assertEqual(market["f250"], {"price": None, "europe": None, "america": 0, "produced": None})
        self.assertEqual(market["inconnue"], {"price": None, "europe": None, "america": None, "produced": None})

    def test_limited_series_know_how_many_were_made(self):
        catalog = CarCatalog([car("ferrari_enzo", "FERRARI_Enzo_20022004")])

        self.assertEqual(build_market(catalog, {}, {})["ferrari_enzo"]["produced"], 400)

    def test_catalog_shares_the_market_with_the_app(self):
        path = self.root / "market.json"
        save_market({"clio": {"price": 10000, "europe": 1, "america": None}}, path)
        cars = self.root / "cars.json"
        cars.write_text(
            '{"cars": [{"id": "clio", "brand": "Renault", "model": "Clio", "from_year": 1990,'
            ' "to_year": null, "sources": ["X"]}]}',
            encoding="utf-8",
        )

        clio = CarCatalog.load(cars, path).get("clio")

        self.assertEqual(clio.to_dict()["price"], 10000)
        self.assertEqual(clio.to_dict()["seen"], {"europe": 1, "america": None})
        self.assertEqual(load_market(self.root / "absent.json"), {})


if __name__ == "__main__":
    unittest.main()
