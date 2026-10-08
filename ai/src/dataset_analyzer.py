from pathlib import Path


class DatasetAnalyzer:

    def __init__(
        self,
        train_dir="dataset/train",
        test_dir="dataset/test",
        min_train_images=100
    ):
        self.train_dir = Path(train_dir)
        self.test_dir = Path(test_dir)
        self.min_train_images = min_train_images

    @staticmethod
    def count_images(directory):
        if not directory.exists():
            return 0

        return sum(
            1
            for file in directory.iterdir()
            if file.is_file()
        )

    def get_valid_classes(self):
        classes = []

        for class_path in self.train_dir.iterdir():

            if not class_path.is_dir():
                continue

            train_count = self.count_images(class_path)

            if train_count < self.min_train_images:
                continue

            test_path = self.test_dir / class_path.name
            test_count = self.count_images(test_path)

            classes.append(
                (
                    class_path.name,
                    train_count,
                    test_count
                )
            )

        return sorted(
            classes,
            key=lambda car_class: car_class[1],
            reverse=True
        )

    def display_classes(self):
        classes = self.get_valid_classes()

        print(
            f"\nClasses avec au moins "
            f"{self.min_train_images} images d'entraînement :\n"
        )

        for class_name, train_count, test_count in classes:
            print(
                f"{train_count:4d} train | "
                f"{test_count:3d} test | "
                f"{class_name}"
            )

        print(f"\nTotal : {len(classes)} classes")


if __name__ == "__main__":
    analyzer = DatasetAnalyzer()
    analyzer.display_classes()