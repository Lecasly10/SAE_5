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

    def test_merges_body_styles_of_one_generation(self):
        self.add("RENAULT", "RENAULT Clio 5 Doors", range(2012, 2017), "RENAULT_Clio_5_Doors", "20122016")
        self.add("RENAULT", "RENAULT Clio Estate", range(2013, 2017), "RENAULT_Clio_Estate", "20132016")
        self.add("RENAULT", "RENAULT Clio RS", range(2013, 2024), "RENAULT_Clio_RS", "2013Present")

        [clio] = self.build()

        self.assertEqual(clio["id"], "renault_clio_2012_2016")
        self.assertEqual((clio["brand"], clio["model"]), ("Renault", "Clio"))
        self.assertEqual((clio["from_year"], clio["to_year"]), (2012, 2016))
        self.assertEqual(len(clio["sources"]), 3)

    def test_keeps_generations_and_models_apart(self):
        self.add("PEUGEOT", "PEUGEOT 206", range(1998, 2010), "PEUGEOT_206", "19982009")
        self.add("PEUGEOT", "PEUGEOT 207", range(2006, 2013), "PEUGEOT_207", "20062012")
        self.add("PEUGEOT", "PEUGEOT 208", range(2012, 2020), "PEUGEOT_208", "20122019")
        self.add("PEUGEOT", "PEUGEOT 208", range(2019, 2024), "PEUGEOT_208", "2019Present")

        ids = [car["id"] for car in self.build()]

        self.assertEqual(ids, [
            "peugeot_206_1998_2009",
            "peugeot_207_2006_2012",
            "peugeot_208_2012_2019",
            "peugeot_208_2019_present",
        ])

    def test_merges_dataset_duplicates_of_one_generation(self):
        self.add("BMW", "BMW 3 Series E90", range(2008, 2012), "BMW_3_Series_E90", "20082011")
        self.add("BMW", "BMW 3 Series Touring E91", range(2008, 2013), "BMW_3_Series_Touring_E91", "20082012")
        self.add("MERCEDESBENZ", "MERCEDES BENZ GLK", range(2008, 2013), "MERCEDES_BENZ_GLK", "20082012", images=20)
        self.add("MERCEDESBENZ", "MERCEDES BENZ GLK-Klasse X204", range(2009, 2013), "MERCEDES_BENZ_GLKKlasse_X204", "20092012")
        self.add("VOLKSWAGEN", "VOLKSWAGEN Passat Variant", range(2014, 2020), "VOLKSWAGEN_Passat_Variant", "20142019")
        self.add("VOLKSWAGEN", "VOLKSWAGEN Passat", range(2014, 2020), "VOLKSWAGEN_Passat", "20142019")

        cars = {car["id"]: len(car["sources"]) for car in self.build()}

        self.assertEqual(cars, {
            "bmw_3_series_e90_2008_2012": 2,
            "mercedes_benz_glk_2008_2012": 2,
            "volkswagen_passat_2014_2019": 2,
        })

    def test_keeps_generations_with_different_chassis_apart(self):
        self.add("BMW", "BMW 3 Series Touring E46", range(2001, 2006), "BMW_3_Series_Touring_E46", "20012005")
        self.add("BMW", "BMW 3 Series E90", range(2005, 2009), "BMW_3_Series_E90", "20052008")

        self.assertEqual(len(self.build()), 2)

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

    def test_keeps_known_cars_and_their_folders(self):
        self.add("PEUGEOT", "PEUGEOT 206", range(1998, 2010), "PEUGEOT_206", "19982009")
        self.add("PEUGEOT", "PEUGEOT 308", range(2008, 2014), "PEUGEOT_308", "20082013")
        known = {
            "id": "peugeot_206_1998_2012", "brand": "Peugeot", "model": "206",
            "from_year": 1998, "to_year": 2012, "sources": ["PEUGEOT_206_19982009"],
        }

        cars = self.build(known=[known])

        self.assertEqual([car["id"] for car in cars], ["peugeot_206_1998_2012", "peugeot_308_2008_2013"])
        self.assertIs(cars[0], known)

    def test_brand_names_are_readable(self):
        self.assertEqual(brand_name("RENAULT"), "Renault")
        self.assertEqual(brand_name("BMW"), "BMW")
        self.assertEqual(brand_name("ALFAROMEO"), "Alfa Romeo")
        self.assertEqual(brand_name("DeLorean"), "DeLorean")

    def test_base_model_drops_brand_and_body_style(self):
        self.assertEqual(base_model("ALFAROMEO", "ALFA ROMEO Giulia Sedan"), "Giulia")
        self.assertEqual(base_model("BMW", "BMW 3 Series Touring"), "3 Series")
        self.assertEqual(base_model("RENAULT", "RENAULT Megane RS 5 Doors"), "Megane")


if __name__ == "__main__":
    unittest.main()
