import json
from dataclasses import dataclass

from src.config import CARS_PATH


@dataclass(frozen=True)
class Car:
    id: str
    brand: str
    model: str
    from_year: int
    to_year: int | None
    sources: tuple[str, ...]

    def to_dict(self):
        return {
            "id": self.id,
            "brand": self.brand,
            "model": self.model,
            "from_year": self.from_year,
            "to_year": self.to_year,
        }


class CarCatalog:
    """Liste des voitures reconnues. Chaque voiture regroupe un ou plusieurs
    dossiers du grand dataset (voir cars.json)."""

    def __init__(self, cars):
        self.cars = list(cars)

        ids = [car.id for car in self.cars]
        if len(set(ids)) != len(ids):
            raise ValueError("Les identifiants de cars.json doivent être uniques.")

        self.by_id = {car.id: car for car in self.cars}

    @classmethod
    def load(cls, path=CARS_PATH):
        with open(path, "r", encoding="utf-8") as file:
            entries = json.load(file)["cars"]

        return cls(
            Car(
                id=entry["id"],
                brand=entry["brand"],
                model=entry["model"],
                from_year=entry["from_year"],
                to_year=entry["to_year"],
                sources=tuple(entry["sources"]),
            )
            for entry in entries
        )

    def __iter__(self):
        return iter(self.cars)

    def __contains__(self, car_id):
        return car_id in self.by_id

    def get(self, car_id):
        return self.by_id[car_id]
