from pathlib import Path
import shutil

CLASSES = [
    "BMW_Z4_Coupe_E86_20062009",
    "BMW_Z4_M_Roadster_E85_20062009",
    "BMW_Z4_Roadster_E89_20092013",
    "BMW_Z4_Roadster_LCI_E89_20132016",
    "BMW_Z4_G29_2018Present",
    "MAZDA_MX5__Miata_2015Present",
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