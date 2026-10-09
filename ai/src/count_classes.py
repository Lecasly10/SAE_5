from pathlib import Path

TRAIN_DIR = Path("dataset/train")
TEST_DIR = Path("dataset/test")

MIN_TRAIN_IMAGES = 100

classes = []

for class_path in TRAIN_DIR.iterdir():

    if not class_path.is_dir():
        continue

    train_count = len([
        file
        for file in class_path.iterdir()
        if file.is_file()
    ])

    test_path = TEST_DIR / class_path.name

    if test_path.exists():
        test_count = len([
            file
            for file in test_path.iterdir()
            if file.is_file()
        ])
    else:
        test_count = 0

    if train_count >= MIN_TRAIN_IMAGES:
        classes.append(
            (
                class_path.name,
                train_count,
                test_count
            )
        )


classes.sort(
    key=lambda x: x[1],
    reverse=True
)


print(
    f"\nClasses avec au moins "
    f"{MIN_TRAIN_IMAGES} images d'entraînement :\n"
)

for class_name, train_count, test_count in classes:

    print(
        f"{train_count:4d} train | "
        f"{test_count:3d} test | "
        f"{class_name}"
    )

print(f"\nTotal : {len(classes)} classes")