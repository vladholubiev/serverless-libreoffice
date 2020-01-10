const { unpack } = require("./libreoffice");
const { convertFileToPDF } = require("./logic");

module.exports.handler = async (event, context, cb) => {
  await unpack();
  if (event.warmup) {
    return cb();
  }

  const { filename, base64File } = JSON.parse(event.body);
  const pdfFileURL = await convertFileToPDF(base64File, filename).catch(cb);
  return cb(null, {
    headers: {
      "Access-Control-Allow-Origin": "https://vladholubiev.com"
    },
    body: JSON.stringify({ pdfFileURL })
  });
};
