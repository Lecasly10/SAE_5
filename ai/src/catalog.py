import json
from collections import defaultdict
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
    # Anciens identifiants de cette voiture (une par génération auparavant)
    aliases: tuple[str, ...] = ()

    def to_dict(self):
        return {
            "id": self.id,
            "brand": self.brand,
            "model": self.model,
            "from_year": self.from_year,
            "to_year": self.to_year,
        }


def load_entries(path=CARS_PATH):
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)["cars"]


class CarCatalog:
    """Liste des voitures reconnues. Chaque voiture regroupe un ou plusieurs
    dossiers du grand dataset (voir cars.json)."""

    def __init__(self, cars):
        self.cars = list(cars)

        ids = [name for car in self.cars for name in (car.id, *car.aliases)]
        if len(set(ids)) != len(ids):
            raise ValueError("Les identifiants de cars.json doivent être uniques.")

        # Un ancien identifiant mène à la voiture qui l'a remplacé
        self.by_id = {name: car for car in self.cars for name in (car.id, *car.aliases)}

    @classmethod
    def load(cls, path=CARS_PATH):
        return cls(
            Car(
                id=entry["id"],
                brand=entry["brand"],
                model=entry["model"],
                from_year=entry["from_year"],
                to_year=entry["to_year"],
                sources=tuple(entry["sources"]),
                aliases=tuple(entry.get("aliases", ())),
            )
            for entry in load_entries(path)
        )

    def __iter__(self):
        return iter(self.cars)

    def __contains__(self, car_id):
        return car_id in self.by_id

    def get(self, car_id):
        return self.by_id[car_id]

    def merge(self, ranked):
        """Additionne les confiances des classes qui sont la même voiture (une
        par génération dans un ancien modèle). « autre » reste à part."""
        totals = defaultdict(float)
        for label, confidence in ranked:
            totals[self.by_id[label].id if label in self.by_id else label] += confidence
        return sorted(totals.items(), key=lambda item: item[1], reverse=True)
