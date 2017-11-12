const {unpackArchive} = require('./libreoffice');
const {convertFileToPDF} = require('./logic');

unpackArchive();

module.exports.handler = (event, context, cb) => {
  if (event.warmup) {
    return cb();
  }

  const {filename, base64File} = JSON.parse(event.body);

  return convertFileToPDF(base64File, filename)
    .then(pdfFileURL => {
      return cb(null, {body: JSON.stringify({pdfFileURL})});
    })
    .catch(cb);
};
