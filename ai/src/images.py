from pathlib import Path

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png"}


def list_images(folder):
    return sorted(
        path for path in Path(folder).iterdir()
        if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
    )
