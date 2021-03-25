exports.handler = async (event) => {
  console.log("consumer_lambda");
  console.log(event);
  return {
    statusCode: 200,
    body: "consumer_lambda",
  };
};
