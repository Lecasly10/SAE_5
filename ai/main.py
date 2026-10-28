import argparse
import os
from pathlib import Path

from src.config import DATASET_DIR, SAMPLE_IMAGE

# Les modules qui utilisent TensorFlow sont importés au dernier moment pour que
# l'analyse et la préparation du dataset marchent sans TensorFlow installé.


def analyze(args):
    from src.dataset_analyzer import DatasetAnalyzer
    from src.dataset_preparer import MIN_TRAIN_IMAGES

    DatasetAnalyzer(args.source, MIN_TRAIN_IMAGES).display_classes()


def catalog(args):
    from src.catalog import load_entries
    from src.catalog_builder import build_catalog, save_catalog
    from src.dataset_preparer import MIN_TRAIN_IMAGES

    cars = build_catalog(
        Path(args.source) / "data_full.csv",
        Path(args.source) / "train",
        MIN_TRAIN_IMAGES,
        known=load_entries(),
    )
    save_catalog(cars)
    print(f"{len(cars)} voitures de {len({car['brand'] for car in cars})} marques")


def collect(args):
    from pymongo import MongoClient
    from pymongo.errors import PyMongoError

    from src.catalog import CarCatalog
    from src.config import DB_NAME
    from src.detector import CarDetector
    from src.user_photos import collect_user_photos

    uri = os.environ.get("MONGODB_URI")
    if not uri:
        print("MONGODB_URI absent : pas de photos de l'application")
        return

    # Une base injoignable ne doit pas empêcher l'entraînement de la nuit
    try:
        with MongoClient(uri, serverSelectionTimeoutMS=15000) as client:
            added = collect_user_photos(client[DB_NAME], CarCatalog.load(), CarDetector())
    except PyMongoError as error:
        print(f"Base injoignable, photos de l'application ignorées : {error}")
        return

    print(f"{added} nouvelle(s) photo(s) de l'application")


def prepare(args):
    from src.catalog import CarCatalog
    from src.dataset_preparer import DatasetPreparer

    DatasetPreparer(CarCatalog.load(), source=args.source).prepare()


def train(args):
    from src.trainer import CarTrainer

    CarTrainer().run()


def retrain(args):
    """Tout l'entraînement d'une nuit : photos de l'application, dataset complet,
    entraînement, puis évaluation si le nouveau modèle est meilleur."""
    from src.trainer import CarTrainer

    collect(args)
    prepare(args)
    if CarTrainer().run():
        evaluate(args)


def evaluate(args):
    from src.evaluate import main

    main()


def predict(args):
    from src.predictor import CarPredictor

    CarPredictor().display_predictions(args.image)


COMMANDS = {
    "analyze": ("Analyser le dataset", analyze),
    "catalog": ("Créer la liste des voitures (cars.json)", catalog),
    "collect": ("Récupérer les photos confirmées dans l'application", collect),
    "prepare": ("Préparer dataset_small", prepare),
    "train": ("Entraîner le modèle", train),
    "retrain": ("Tout réentraîner (collect, prepare, train, evaluate)", retrain),
    "evaluate": ("Évaluer le modèle", evaluate),
    "predict": ("Tester une image", predict),
}


def build_parser():
    parser = argparse.ArgumentParser(description="Outils IA de Spot'It")
    subparsers = parser.add_subparsers(dest="command")

    for name, (help_text, function) in COMMANDS.items():
        command = subparsers.add_parser(name, help=help_text)
        command.set_defaults(function=function)

        if name in ("analyze", "catalog", "prepare", "retrain"):
            command.add_argument(
                "--source", default=DATASET_DIR,
                help="dossier du grand dataset, avec train/, test/ et data_full.csv",
            )
        if name == "predict":
            command.add_argument("image", nargs="?", default=SAMPLE_IMAGE)

    return parser


def run_menu(parser):
    names = list(COMMANDS)

    while True:
        print("\n========== SPOT'IT IA ==========\n")
        for number, name in enumerate(names, start=1):
            print(f"{number} - {COMMANDS[name][0]}")
        print("0 - Quitter")

        choice = input("\nChoix : ")

        if choice == "0":
            return
        if choice.isdigit() and 1 <= int(choice) <= len(names):
            arguments = parser.parse_args([names[int(choice) - 1]])
            arguments.function(arguments)
        else:
            print("\nChoix invalide.")


def main():
    parser = build_parser()
    arguments = parser.parse_args()

    if arguments.command:
        arguments.function(arguments)
    else:
        run_menu(parser)


if __name__ == "__main__":
    main()
