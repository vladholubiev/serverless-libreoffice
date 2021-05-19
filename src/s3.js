const { execSync } = require("child_process");
const { S3 } = require("aws-sdk");

const s3 = new S3({ region: "us-east-1" });

/**
 * Uploads converted PDF file to S3 bucket
 * and removes it from /tmp afterwards
 * @param filename {String} Name of pdf file
 * @param fileBuffer {Buffer} Converted PDF Buffer
 * @return {Promise.<String>} URL of uploaded pdf on S3
 */
function uploadPDF(filename, fileBuffer) {
  const options = {
    Bucket: process.env.S3_BUCKET_NAME,
    Key: `tmp/pdf/${filename}`,
    Body: fileBuffer,
    ACL: "public-read",
    ContentType: "application/pdf"
  };

  return s3
    .upload(options)
    .promise()
    .then(({ Location }) => Location)
    .then(Location => {
      execSync(`rm /tmp/${filename}`);
      console.log(`[removed]`);

      return Location;
    })
    .catch(error => {
      execSync(`rm /tmp/${filename}`);
      console.log(`[removed]`);

      throw error;
    });
}

module.exports = {
  uploadPDF
};
