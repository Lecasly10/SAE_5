import json
import tempfile
import unittest
from pathlib import Path

from src.catalog import CarCatalog


class CarCatalogTest(unittest.TestCase):

    def setUp(self):
        self.catalog = CarCatalog.load()

    def test_ids_are_unique_and_found(self):
        ids = [car.id for car in self.catalog]

        self.assertEqual(len(ids), len(set(ids)))
        for car_id in ids:
            self.assertIn(car_id, self.catalog)

    def test_years_are_consistent(self):
        for car in self.catalog:
            with self.subTest(car=car.id):
                self.assertTrue(car.brand and car.model)
                if car.to_year is not None:
                    self.assertLessEqual(car.from_year, car.to_year)

    def test_each_source_folder_belongs_to_one_car(self):
        sources = [name for car in self.catalog for name in car.sources]

        self.assertEqual(len(sources), len(set(sources)))
        for car in self.catalog:
            self.assertTrue(car.sources, car.id)

    def test_to_dict_exposes_only_public_fields(self):
        car = next(iter(self.catalog))

        self.assertEqual(
            set(car.to_dict()),
            {"id", "brand", "model", "from_year", "to_year"},
        )

    def test_old_ids_lead_to_the_merged_car(self):
        m4 = self.catalog.get("bmw_m4")

        self.assertIs(self.catalog.get("bmw_m4_g82_2020_present"), m4)
        self.assertIn("bmw_m4_f83_2014_2020", self.catalog)
        self.assertEqual(len(list(self.catalog)), len({car.id for car in self.catalog}))

    def test_merge_adds_up_the_generations_of_one_car(self):
        ranked = [
            ("bmw_2_series_f44_2017_2021", 7.5),
            ("bmw_m4_g82_2020_present", 5.6),
            ("bmw_m4_f83_2014_2020", 4.4),
            ("autre", 2.0),
        ]

        merged = self.catalog.merge(ranked)

        self.assertEqual(merged[0][0], "bmw_m4")
        self.assertAlmostEqual(merged[0][1], 10.0)
        self.assertEqual([label for label, _ in merged[1:]], [self.catalog.get("bmw_2_series_f44_2017_2021").id, "autre"])

    def test_duplicate_ids_are_rejected(self):
        entry = {
            "id": "a", "brand": "A", "model": "A",
            "from_year": 2000, "to_year": None, "sources": ["x"],
        }
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "cars.json"
            path.write_text(json.dumps({"cars": [entry, entry]}), encoding="utf-8")

            with self.assertRaises(ValueError):
                CarCatalog.load(path)


if __name__ == "__main__":
    unittest.main()
