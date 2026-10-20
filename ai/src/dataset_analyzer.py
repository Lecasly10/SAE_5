from pathlib import Path

from src.config import DATASET_DIR
from src.images import list_images


class DatasetAnalyzer:
    """Compte les images de chaque voiture du grand dataset."""

    def __init__(self, source=DATASET_DIR, min_train_images=50):
        self.train_dir = Path(source) / "train"
        self.test_dir = Path(source) / "test"
        self.min_train_images = min_train_images

    def get_valid_classes(self):
        classes = []

        for class_path in self.train_dir.iterdir():
            if not class_path.is_dir():
                continue

            train_count = len(list_images(class_path))
            if train_count < self.min_train_images:
                continue

            test_path = self.test_dir / class_path.name
            test_count = len(list_images(test_path)) if test_path.exists() else 0

            classes.append((class_path.name, train_count, test_count))

        return sorted(classes, key=lambda car_class: car_class[1], reverse=True)

    def display_classes(self):
        classes = self.get_valid_classes()

        print(
            f"\nClasses avec au moins "
            f"{self.min_train_images} images d'entraînement :\n"
        )

        for class_name, train_count, test_count in classes:
            print(f"{train_count:4d} train | {test_count:3d} test | {class_name}")

        print(f"\nTotal : {len(classes)} classes")
