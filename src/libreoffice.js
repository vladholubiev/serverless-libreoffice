const { execSync } = require("child_process");
const { readFileSync } = require("fs");
const tar = require("tar-fs");
const zlib = require("zlib");
const path = require("path");

const convertCommand = `export HOME=/tmp && ./instdir/program/soffice.bin --headless --norestore --invisible --nodefault --nofirststartwizard --nolockcheck --nologo --convert-to "pdf:writer_pdf_Export" --outdir /tmp`;

/**
 * Converts a document to PDF from url by spawning LibreOffice process
 * @param inputFilename {String} Name of incoming file to convert in /tmp folder
 * @return {Buffer} Converted PDF file buffer
 */
module.exports.convertToPDF = function convertToPDF(inputFilename) {
  console.log(`[convertToPDF][file:${inputFilename}]`);
  const pdfFilename = getPDFFilename(inputFilename);

  try {
    // First run will produce predictable error, because of unknown issues
    execSync(`cd /tmp && ${convertCommand} ${inputFilename}`);
  } catch (e) {
    execSync(`cd /tmp && ${convertCommand} ${inputFilename}`);
  }
  console.log(`[converted]`);

  const pdfFileBuffer = readFileSync(`/tmp/${pdfFilename}`);

  return {
    pdfFileBuffer,
    pdfFilename
  };
};

function getPDFFilename(inputFilename) {
  const { name } = path.parse(inputFilename);
  return `${name}.pdf`;
}

module.exports.unpack = function({
  inputPath = `/var/task/lo.tar.br`,
  outputBaseDir = `/tmp`,
  outputPath = `/tmp/instdir`
}) {
  return new Promise((resolve, reject) => {
    let input = path.resolve(inputPath);
    let output = outputPath;

    if (fs.existsSync(output) === true) {
      return resolve(output);
    }

    const source = fs.createReadStream(input);
    const target = tar.extract(outputBaseDir);

    source.on("error", error => {
      return reject(error);
    });

    target.on("error", error => {
      return reject(error);
    });

    target.on("finish", () => {
      fs.chmod(output, "0755", error => {
        if (error) {
          return reject(error);
        }

        return resolve(output);
      });
    });

    source.pipe(zlib.createBrotliDecompress()).pipe(target);
  });
};
