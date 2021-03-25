exports.handler = async (event) => {
  console.log("stream_trigger_lambda");
  console.log(event);
  return {
    statusCode: 200,
    body: "stream_trigger_lambda",
  };
};
