import json
from collections import defaultdict
from dataclasses import dataclass

from src.config import CARS_PATH, MARKET_PATH
from src.market import load_market


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
    # Prix neuf en euros et fréquence sur la route, en Europe et aux
    # États-Unis (voir market.py) ; None quand on ne sait pas
    price: int | None = None
    europe: float | None = None
    america: float | None = None
    # Exemplaires fabriqués, seulement pour les séries limitées
    produced: int | None = None

    def to_dict(self):
        return {
            "id": self.id,
            "brand": self.brand,
            "model": self.model,
            "from_year": self.from_year,
            "to_year": self.to_year,
            "price": self.price,
            "seen": {"europe": self.europe, "america": self.america},
            "produced": self.produced,
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
    def load(cls, path=CARS_PATH, market_path=MARKET_PATH):
        market = load_market(market_path)
        return cls(
            Car(
                id=entry["id"],
                brand=entry["brand"],
                model=entry["model"],
                from_year=entry["from_year"],
                to_year=entry["to_year"],
                sources=tuple(entry["sources"]),
                aliases=tuple(entry.get("aliases", ())),
                **market.get(entry["id"], {}),
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
