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
      return cb(null, {
        headers: {
          'Access-Control-Allow-Origin': 'https://vladholubiev.com'
        },
        body: JSON.stringify({pdfFileURL})
      });
    })
    .catch(cb);
};
