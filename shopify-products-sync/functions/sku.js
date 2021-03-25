const AWS = require("aws-sdk");
const { v4: uuidv4 } = require("uuid");

AWS.config.update({ region: "ap-southeast-1" });
const DynamoDB = new AWS.DynamoDB();

exports.handler = async (event) => {
  console.log("sku_handler_lambda");
  console.log(event);

  const params = {
    TableName: "Products",
    Item: {
      ProductId: { S: uuidv4() },
    },
  };
  let created = false;
  const result = await DynamoDB.putItem(params).promise();
  if (result) {
    created = true;
  }

  return {
    statusCode: 200,
    created: created,
    body: "sku_handler_lambda",
  };
};
