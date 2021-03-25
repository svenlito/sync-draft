exports.handler = async (event) => {
  console.log("shopify_lambda");
  console.log(event);
  return {
    statusCode: 200,
    body: "shopify_lambda",
  };
};
