from pathlib import Path
import shutil


class DatasetPreparer:
    CLASSES = [
        "JEEP_Grand_Cherokee_20132020",
        "FORD_Mustang_20142017",
        "FIAT_500_Abarth_2008Present",
        "FERRARI_F12_Berlinetta_20122015",
        "TOYOTA_Hilux_Double_Cab_2020Present",
        "CITROEN_2CV_19491990",
    ]

    def __init__(
        self,
        classes=None,
        source="dataset",
        destination="dataset_small"
    ):
        self.classes = list(classes) if classes is not None else self.CLASSES.copy()
        self.source = Path(source)
        self.destination = Path(destination)

    def prepare(self):
        for split in ["train", "test"]:
            for car_class in self.classes:
                source = self.source / split / car_class
                destination = self.destination / split / car_class

                if not source.exists():
                    print(f"❌ Classe introuvable : {source}")
                    continue

                shutil.copytree(
                    source,
                    destination,
                    dirs_exist_ok=True,
                )

                nb_images = sum(
                    1 for path in destination.iterdir()
                    if path.is_file()
                )

                print(
                    f"✅ {split} - {car_class}: "
                    f"{nb_images} images"
                )