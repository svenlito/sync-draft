const aws = require("aws-sdk");

exports.handler = async (event) => {
  const params = {
    stateMachineArn:
      "arn:aws:states:ap-southeast-1:521196292520:stateMachine:humorous-porpoise-step-function",
    input: JSON.stringify(event),
  };
  const stepfunctions = new aws.StepFunctions();
  await stepfunctions.startExecution(params).promise();
};
