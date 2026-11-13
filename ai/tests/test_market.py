import tempfile
import unittest
import zipfile
from pathlib import Path

from src.catalog import Car, CarCatalog
from src.market import GBP_TO_EUR, build_market, dvm_prices, load_market, save_market


def car(car_id, *sources):
    return Car(car_id, "Marque", "Modèle", 2000, None, sources)


class MarketTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_reads_new_prices_of_dvm_car(self):
        tables = self.root / "tables.zip"
        with zipfile.ZipFile(tables, "w") as archive:
            archive.writestr("Basic_table.csv", "Automaker,Automaker_ID,Genmodel,Genmodel_ID\nAbarth,2,124 Spider,2_1\n")
            archive.writestr("Price_table.csv", "Maker, Genmodel, Genmodel_ID, Year, Entry_price\n"
                                                "Abarth,124 Spider,2_1,2016,20000\nAbarth,124 Spider,2_1,2017,\n")

        self.assertEqual(dvm_prices(tables), {"DVM_abarth_124_spider": [20000 * GBP_TO_EUR]})

    def test_each_car_gets_its_price(self):
        catalog = CarCatalog([
            car("clio", "DVM_renault_clio", "RENAULT_Clio_2019Present"),
            car("inconnue", "KAGGLE_ONLY"),
        ])

        market = build_market(catalog, {"DVM_renault_clio": [9000, 11000]})

        self.assertEqual(market["clio"], {"price": 10000, "produced": None})
        self.assertEqual(market["inconnue"], {"price": None, "produced": None})

    def test_limited_series_know_how_many_were_made(self):
        catalog = CarCatalog([car("ferrari_enzo", "FERRARI_Enzo_20022004")])

        self.assertEqual(build_market(catalog, {})["ferrari_enzo"]["produced"], 400)

    def test_catalog_shares_the_market_with_the_app(self):
        path = self.root / "market.json"
        save_market({"clio": {"price": 10000, "produced": None}}, path)
        cars = self.root / "cars.json"
        cars.write_text(
            '{"cars": [{"id": "clio", "brand": "Renault", "model": "Clio", "from_year": 1990,'
            ' "to_year": null, "sources": ["X"]}]}',
            encoding="utf-8",
        )

        clio = CarCatalog.load(cars, path).get("clio")

        self.assertEqual(clio.to_dict()["price"], 10000)
        self.assertEqual(load_market(self.root / "absent.json"), {})


if __name__ == "__main__":
    unittest.main()
