from pathlib import Path
import shutil

CLASSES = [
    "JEEP_Grand_Cherokee_20132020",
    "FORD_Mustang_20142017",
    "FIAT_500_Abarth_2008Present",
    "FERRARI_F12_Berlinetta_20122015",
    "TOYOTA_Hilux_Double_Cab_2020Present",
    "CITROEN_2CV_19491990",
]

SOURCE = Path("dataset")
DESTINATION = Path("dataset_small")

for split in ["train", "test"]:
    for car_class in CLASSES:

        source = SOURCE / split / car_class
        destination = DESTINATION / split / car_class

        if not source.exists():
            print(f"❌ Classe introuvable : {source}")
            continue

        shutil.copytree(
            source,
            destination,
            dirs_exist_ok=True
        )

        nb_images = len(list(destination.iterdir()))

        print(
            f"✅ {split} - {car_class}: "
            f"{nb_images} images"
        )