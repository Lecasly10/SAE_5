from pathlib import Path

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png"}


def list_images(folder):
    return sorted(
        path for path in Path(folder).iterdir()
        if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
    )


def crop_to_box(image, box, margin=0.1):
    """Garde la voiture du cadre (coordonnées entre 0 et 1) avec un peu de
    marge autour, pour que le décor ne compte pas dans la reconnaissance."""
    width, height = image.size
    dx, dy = box["width"] * margin, box["height"] * margin

    return image.crop((
        round(max(0.0, box["x"] - dx) * width),
        round(max(0.0, box["y"] - dy) * height),
        round(min(1.0, box["x"] + box["width"] + dx) * width),
        round(min(1.0, box["y"] + box["height"] + dy) * height),
    ))
