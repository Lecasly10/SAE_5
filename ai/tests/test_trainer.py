import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from src import trainer


class UseGpuTest(unittest.TestCase):

    def setUp(self):
        printer = mock.patch("builtins.print")
        printer.start()
        self.addCleanup(printer.stop)

    @mock.patch.object(trainer.tf.config.experimental, "set_memory_growth")
    @mock.patch.object(trainer.tf.config, "list_physical_devices")
    def test_uses_every_gpu_found(self, list_devices, set_memory_growth):
        gpus = ["gpu0", "gpu1"]
        list_devices.return_value = gpus

        self.assertTrue(trainer.use_gpu_if_available())
        list_devices.assert_called_once_with("GPU")
        self.assertEqual(
            set_memory_growth.call_args_list,
            [mock.call(gpu, True) for gpu in gpus],
        )

    @mock.patch.object(trainer.tf.config.experimental, "set_memory_growth")
    @mock.patch.object(trainer.tf.config, "list_physical_devices", return_value=[])
    def test_falls_back_to_cpu(self, list_devices, set_memory_growth):
        self.assertFalse(trainer.use_gpu_if_available())
        set_memory_growth.assert_not_called()


class KeepBestModelTest(unittest.TestCase):

    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.classes = Path(tmp.name) / "classes.json"
        self.metrics = Path(tmp.name) / "metrics.json"
        for name, value in ((self.classes, ["a", "b"]), (self.metrics, {"accuracy": 0.8})):
            name.write_text(json.dumps(value), encoding="utf-8")

        for target, value in (("CLASSES_PATH", self.classes), ("METRICS_PATH", self.metrics)):
            patcher = mock.patch.object(trainer, target, value)
            patcher.start()
            self.addCleanup(patcher.stop)

        printer = mock.patch("builtins.print")
        printer.start()
        self.addCleanup(printer.stop)

        self.trainer = trainer.CarTrainer()
        self.trainer.class_names = ["a", "b"]

    def test_keeps_the_current_model_when_the_new_one_is_worse(self):
        self.assertFalse(self.trainer.is_better_than_current(0.79))
        self.assertTrue(self.trainer.is_better_than_current(0.8))

    def test_new_cars_make_the_scores_incomparable(self):
        self.trainer.class_names = ["a", "b", "c"]

        self.assertTrue(self.trainer.is_better_than_current(0.1))

    def test_first_training_is_always_kept(self):
        self.metrics.unlink()

        self.assertTrue(self.trainer.is_better_than_current(0.1))


class SometimesTest(unittest.TestCase):

    def setUp(self):
        self.images = trainer.tf.ones([8, 4, 4, 3])
        self.zero = trainer.tf.keras.layers.Lambda(lambda images: images * 0)

    def test_rate_decides_how_many_photos_change(self):
        untouched = trainer.Sometimes(self.zero, 0.0)(self.images, training=True)
        changed = trainer.Sometimes(self.zero, 1.0)(self.images, training=True)

        self.assertEqual(float(trainer.tf.reduce_min(untouched)), 1.0)
        self.assertEqual(float(trainer.tf.reduce_max(changed)), 0.0)

    def test_photos_are_never_changed_outside_training(self):
        result = trainer.Sometimes(self.zero, 1.0)(self.images, training=False)

        self.assertEqual(float(trainer.tf.reduce_min(result)), 1.0)


class SaveModelTest(unittest.TestCase):

    def test_saved_model_has_no_augmentation_and_the_same_answers(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        folder = Path(tmp.name)
        for target, value in (("CLASSES_PATH", folder / "classes.json"),
                              ("MODEL_PATH", folder / "model.keras")):
            patcher = mock.patch.object(trainer, target, value)
            patcher.start()
            self.addCleanup(patcher.stop)

        car_trainer = trainer.CarTrainer(img_size=(64, 64))
        car_trainer.class_names = ["a", "b", "c"]
        car_trainer.number_of_classes = 3
        car_trainer.model, car_trainer.base_model = car_trainer.create_network(None)
        with mock.patch("builtins.print"):
            car_trainer.save_model()

        saved = trainer.tf.keras.models.load_model(folder / "model.keras")
        images = trainer.tf.random.uniform([2, 64, 64, 3], maxval=255)

        self.assertFalse(any(isinstance(layer, trainer.Sometimes) for layer in saved.layers))
        self.assertTrue(trainer.np.allclose(
            saved(images, training=False), car_trainer.model(images, training=False), atol=1e-5
        ))


if __name__ == "__main__":
    unittest.main()
