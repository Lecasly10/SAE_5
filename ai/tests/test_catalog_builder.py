import csv
import tempfile
import unittest
from pathlib import Path

from src.catalog_builder import base_model, brand_name, build_catalog

FIELDS = ["brand", "model", "production_years", "dir_path"]


class CatalogBuilderTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.rows = []

    def add(self, brand, model, years, model_dir, years_dir, images=10):
        self.rows.append({
            "brand": brand,
            "model": model,
            "production_years": ", ".join(str(year) for year in years),
            "dir_path": f"images/{brand}/{model_dir}/{years_dir}",
        })
        folder = self.root / "train" / f"{model_dir}_{years_dir}"
        folder.mkdir(parents=True, exist_ok=True)
        for index in range(images):
            (folder / f"{index}.jpg").write_bytes(b"x")

    def build(self, min_images=10, known=()):
        path = self.root / "data_full.csv"
        with open(path, "w", newline="", encoding="utf-8") as file:
            writer = csv.DictWriter(file, fieldnames=FIELDS)
            writer.writeheader()
            writer.writerows(self.rows)
        return build_catalog(path, self.root / "train", min_images, known)

    def test_merges_every_generation_and_body_style_of_a_model(self):
        self.add("RENAULT", "RENAULT Clio 5 Doors", range(2012, 2017), "RENAULT_Clio_5_Doors", "20122016")
        self.add("RENAULT", "RENAULT Clio Estate", range(2013, 2017), "RENAULT_Clio_Estate", "20132016")
        self.add("RENAULT", "RENAULT Clio RS", range(2005, 2013), "RENAULT_Clio_RS", "20052012")
        self.add("RENAULT", "RENAULT Clio", range(2019, 2024), "RENAULT_Clio", "2019Present")

        [clio] = self.build()

        self.assertEqual(clio["id"], "renault_clio")
        self.assertEqual((clio["brand"], clio["model"]), ("Renault", "Clio"))
        self.assertEqual((clio["from_year"], clio["to_year"]), (2005, None))
        self.assertEqual(len(clio["sources"]), 4)

    def test_keeps_different_models_apart(self):
        self.add("PEUGEOT", "PEUGEOT 206", range(1998, 2010), "PEUGEOT_206", "19982009")
        self.add("PEUGEOT", "PEUGEOT 207", range(2006, 2013), "PEUGEOT_207", "20062012")
        self.add("PEUGEOT", "PEUGEOT 208", range(2012, 2020), "PEUGEOT_208", "20122019")
        self.add("PEUGEOT", "PEUGEOT 208", range(2019, 2024), "PEUGEOT_208", "2019Present")

        ids = [car["id"] for car in self.build()]

        self.assertEqual(ids, ["peugeot_206", "peugeot_207", "peugeot_208"])

    def test_generation_codes_and_versions_are_the_same_car(self):
        self.add("BMW", "BMW 3 Series Touring E46", range(2001, 2006), "BMW_3_Series_Touring_E46", "20012005")
        self.add("BMW", "BMW 3 Series E90", range(2005, 2009), "BMW_3_Series_E90", "20052008")
        self.add("BMW", "BMW M4 Competition Convertible M xDrive", range(2021, 2024),
                 "BMW_M4_Competition_Convertible_M_xDrive", "2021Present")
        self.add("BMW", "BMW M4 F83", range(2014, 2021), "BMW_M4_F83", "20142020")
        self.add("PORSCHE", "PORSCHE 911 Carrera 4S 991", range(2012, 2021), "PORSCHE_911_Carrera_4S_991", "20122020")
        self.add("PORSCHE", "PORSCHE 911 Turbo S 997", range(2009, 2013), "PORSCHE_911_Turbo_S_997", "20092012")
        self.add("VOLKSWAGEN", "VOLKSWAGEN Golf VII GTE", range(2014, 2021), "VOLKSWAGEN_Golf_VII_GTE", "20142020")
        self.add("VOLKSWAGEN", "VOLKSWAGEN Golf VI", range(2008, 2013), "VOLKSWAGEN_Golf_VI", "20082012")
        self.add("AUDI", "AUDI RS 3 Sportback", range(2015, 2018), "AUDI_RS_3_Sportback", "20152017")
        self.add("AUDI", "AUDI S3", range(2013, 2017), "AUDI_S3", "20132016")
        self.add("AUDI", "AUDI A3", range(2012, 2017), "AUDI_A3", "20122016")
        self.add("MERCEDESBENZ", "MERCEDES BENZ GLK", range(2008, 2013), "MERCEDES_BENZ_GLK", "20082012", images=20)
        self.add("MERCEDESBENZ", "MERCEDES BENZ GLK-Klasse X204", range(2009, 2013), "MERCEDES_BENZ_GLKKlasse_X204", "20092012")

        cars = {car["id"]: len(car["sources"]) for car in self.build()}

        self.assertEqual(cars, {
            "audi_a3": 3,
            "bmw_3_series": 2,
            "bmw_m4": 2,
            "mercedes_benz_glk": 2,
            "porsche_911": 2,
            "volkswagen_golf": 2,
        })

    def test_keeps_models_that_only_share_a_word(self):
        self.add("CITROEN", "CITROEN Grand C3 Picasso", range(2009, 2014), "CITROEN_Grand_C3_Picasso", "20092013")
        self.add("CITROEN", "CITROEN Grand C4 Picasso", range(2009, 2014), "CITROEN_Grand_C4_Picasso", "20092013")

        self.assertEqual(len(self.build()), 2)

    def test_still_produced_cars_have_no_end_year(self):
        self.add("DACIA", "DACIA Spring", range(2021, 2024), "DACIA_Spring", "2021Present")

        [spring] = self.build()

        self.assertIsNone(spring["to_year"])

    def test_skips_cars_with_too_few_images(self):
        self.add("FIAT", "FIAT Multipla", range(1998, 2005), "FIAT_Multipla", "19982004", images=3)
        self.add("FIAT", "FIAT Panda", range(2012, 2024), "FIAT_Panda", "2012Present", images=12)

        self.assertEqual([car["model"] for car in self.build()], ["Panda"])

    def test_skips_folders_without_years_or_images(self):
        self.add("AUDI", "AUDI S8", range(2006, 2010), "AUDI_S8", "S8")
        self.rows.append({
            "brand": "AUDI", "model": "AUDI A4", "production_years": "2015",
            "dir_path": "images/AUDI/AUDI_A4/20152019",
        })

        self.assertEqual(self.build(min_images=1), [])

    def test_old_cars_become_aliases_of_their_model(self):
        self.add("PEUGEOT", "PEUGEOT 206", range(1998, 2010), "PEUGEOT_206", "19982009")
        self.add("PEUGEOT", "PEUGEOT 206 SW", range(2001, 2008), "PEUGEOT_206_SW", "20012007")
        known = [
            {"id": "peugeot_206_1998_2009", "brand": "Peugeot", "model": "206",
             "from_year": 1998, "to_year": 2009, "sources": ["PEUGEOT_206_19982009"]},
            {"id": "peugeot_206", "brand": "Peugeot", "model": "206", "from_year": 1998,
             "to_year": 2009, "sources": ["PEUGEOT_206_19982009"], "aliases": ["peugeot_206_old"]},
        ]

        [car] = self.build(known=known)

        self.assertEqual(car["id"], "peugeot_206")
        self.assertEqual(car["aliases"], ["peugeot_206_1998_2009", "peugeot_206_old"])

    def test_known_folders_without_years_are_kept(self):
        folder = self.root / "train" / "CITROEN_2CV"
        folder.mkdir(parents=True)
        for index in range(10):
            (folder / f"{index}.jpg").write_bytes(b"x")
        known = [{"id": "citroen_2cv_1949_1990", "brand": "Citroën", "model": "2CV",
                  "from_year": 1949, "to_year": 1990, "sources": ["CITROEN_2CV"]}]

        [car] = self.build(known=known)

        self.assertEqual((car["id"], car["sources"]), ("citro_n_2cv", ["CITROEN_2CV"]))

    def test_brand_names_are_readable(self):
        self.assertEqual(brand_name("RENAULT"), "Renault")
        self.assertEqual(brand_name("BMW"), "BMW")
        self.assertEqual(brand_name("ALFAROMEO"), "Alfa Romeo")
        self.assertEqual(brand_name("DeLorean"), "DeLorean")

    def test_base_model_drops_brand_and_body_style(self):
        self.assertEqual(base_model("ALFAROMEO", "ALFA ROMEO Giulia Sedan"), "Giulia")
        self.assertEqual(base_model("BMW", "BMW 3 Series Touring"), "3 Series")
        self.assertEqual(base_model("RENAULT", "RENAULT Megane RS 5 Doors"), "Megane")
        self.assertEqual(base_model("PORSCHE", "PORSCHE 911 Carrera 4 991"), "911")
        self.assertEqual(base_model("BMW", "BMW X5 M"), "X5")
        self.assertEqual(base_model("PEUGEOT", "PEUGEOT 3008"), "3008")


if __name__ == "__main__":
    unittest.main()
