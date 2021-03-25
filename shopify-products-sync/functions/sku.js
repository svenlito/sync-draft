exports.handler = async (event) => {
  console.log("sku_handler_lambda");
  console.log(event);
  return {
    statusCode: 200,
    body: "sku_handler_lambda",
  };
};
