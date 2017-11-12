const {execSync} = require('child_process');
const {readFileSync} = require('fs');
const path = require('path');

const convertCommand = `./instdir/program/soffice --headless --invisible --nodefault --nofirststartwizard --nolockcheck --nologo --norestore --convert-to pdf --outdir /tmp`;

/**
 * Converts a document to PDF from url by spawning LibreOffice process
 * @param inputFilename {String} Name of incoming file to convert in /tmp folder
 * @return {Buffer} Converted PDF file buffer
 */
module.exports.convertToPDF = function convertToPDF(inputFilename) {
  console.log(`[convertToPDF][file:${inputFilename}]`);
  const pdfFilename = getPDFFilename(inputFilename);

  execSync(`cd /tmp && ${convertCommand} ${inputFilename}`);
  console.log(`[converted]`);

  const pdfFileBuffer = readFileSync(`/tmp/${pdfFilename}`);

  return {
    pdfFileBuffer,
    pdfFilename
  };
};

function getPDFFilename(inputFilename) {
  const {name} = path.parse(inputFilename);
  return `${name}.pdf`;
}

module.exports.unpackArchive = function unpackArchive() {
  execSync(`cd /tmp && tar -xf /var/task/lo.tar.gz`);
};
