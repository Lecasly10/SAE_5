from src.dataset_analyzer import DatasetAnalyzer
from src.dataset_preparer import DatasetPreparer
from src.predictor import CarPredictor
from src.trainer import MobileNetTrainer


CLASSES = [
    "JEEP_Grand_Cherokee_20132020",
    "FORD_Mustang_20142017",
    "FIAT_500_Abarth_2008Present",
    "FERRARI_F12_Berlinetta_20122015",
    "TOYOTA_Hilux_Double_Cab_2020Present",
    "CITROEN_2CV_19491990",
]


def analyze_dataset():
    print("\n========== ANALYSE DU DATASET ==========\n")

    analyzer = DatasetAnalyzer(
        min_train_images=100
    )

    analyzer.display_classes()


def prepare_dataset():
    print("\n========== PRÉPARATION DU DATASET ==========\n")

    preparer = DatasetPreparer(
        classes=CLASSES
    )

    preparer.prepare()


def train_model():
    print("\n========== ENTRAÎNEMENT ==========\n")

    trainer = MobileNetTrainer(
        epochs=10
    )

    trainer.run()


def predict_image():
    print("\n========== PRÉDICTION ==========\n")

    predictor = CarPredictor()

    predictor.display_predictions(
        "images/f12.jpg"
    )


def display_menu():
    print("\n========== SPOT'IT IA ==========\n")

    print("1 - Analyser le dataset")
    print("2 - Préparer dataset_small")
    print("3 - Entraîner le modèle")
    print("4 - Tester une image")
    print("0 - Quitter")


def main():

    while True:

        display_menu()

        choice = input("\nChoix : ")

        match choice:

            case "1":
                analyze_dataset()

            case "2":
                prepare_dataset()

            case "3":
                train_model()

            case "4":
                predict_image()

            case "0":
                print("\nAu revoir !")
                break

            case _:
                print("\n❌ Choix invalide.")


if __name__ == "__main__":
    main()