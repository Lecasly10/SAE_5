// Photo JPEG minimale avec une position GPS dans ses métadonnées EXIF
function jpegWithGps({ latitude, longitude, little = false }) {
  const tiff = Buffer.alloc(128);
  const u16 = (offset, value) => (little ? tiff.writeUInt16LE(value, offset) : tiff.writeUInt16BE(value, offset));
  const u32 = (offset, value) => (little ? tiff.writeUInt32LE(value, offset) : tiff.writeUInt32BE(value, offset));
  const entry = (offset, tag, type, count, value) => {
    u16(offset, tag);
    u16(offset + 2, type);
    u32(offset + 4, count);
    if (typeof value === 'string') tiff.write(value, offset + 8, 'latin1');
    else u32(offset + 8, value);
  };
  const angle = (offset, value) => {
    const abs = Math.abs(value);
    const minutes = (abs % 1) * 60;
    [[Math.floor(abs), 1], [Math.floor(minutes), 1], [Math.round((minutes % 1) * 60 * 100), 100]].forEach(
      ([top, bottom], index) => {
        u32(offset + index * 8, top);
        u32(offset + index * 8 + 4, bottom);
      }
    );
  };

  tiff.write(little ? 'II' : 'MM', 0, 'latin1');
  u16(2, 42);
  u32(4, 8);
  u16(8, 1);
  entry(10, 0x8825, 4, 1, 26);
  u16(26, 4);
  entry(28, 1, 2, 2, latitude < 0 ? 'S' : 'N');
  entry(40, 2, 5, 3, 80);
  entry(52, 3, 2, 2, longitude < 0 ? 'W' : 'E');
  entry(64, 4, 5, 3, 104);
  angle(80, latitude);
  angle(104, longitude);

  const app1 = Buffer.concat([Buffer.from('Exif\0\0', 'latin1'), tiff]);
  const header = Buffer.from([0xff, 0xe1, 0, 0]);
  header.writeUInt16BE(app1.length + 2, 2);
  return Buffer.concat([Buffer.from([0xff, 0xd8]), header, app1, Buffer.from([0xff, 0xda, 0, 2])]);
}

module.exports = { jpegWithGps };
