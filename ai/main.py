import argparse

from src.config import DATASET_DIR, SAMPLE_IMAGE

# Les modules qui utilisent TensorFlow sont importés au dernier moment pour que
# l'analyse et la préparation du dataset marchent sans TensorFlow installé.


def analyze(args):
    from src.dataset_analyzer import DatasetAnalyzer
    from src.dataset_preparer import MIN_TRAIN_IMAGES

    DatasetAnalyzer(args.source, MIN_TRAIN_IMAGES).display_classes()


def prepare(args):
    from src.catalog import CarCatalog
    from src.dataset_preparer import DatasetPreparer

    DatasetPreparer(CarCatalog.load(), source=args.source).prepare()


def train(args):
    from src.trainer import MobileNetTrainer

    MobileNetTrainer().run()


def evaluate(args):
    from src.evaluate import main

    main()


def predict(args):
    from src.predictor import CarPredictor

    CarPredictor().display_predictions(args.image)


COMMANDS = {
    "analyze": ("Analyser le dataset", analyze),
    "prepare": ("Préparer dataset_small", prepare),
    "train": ("Entraîner le modèle", train),
    "evaluate": ("Évaluer le modèle", evaluate),
    "predict": ("Tester une image", predict),
}


def build_parser():
    parser = argparse.ArgumentParser(description="Outils IA de Spot'It")
    subparsers = parser.add_subparsers(dest="command")

    for name, (help_text, function) in COMMANDS.items():
        command = subparsers.add_parser(name, help=help_text)
        command.set_defaults(function=function)

        if name in ("analyze", "prepare"):
            command.add_argument(
                "--source", default=DATASET_DIR,
                help="dossier du grand dataset, avec train/ et test/",
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
