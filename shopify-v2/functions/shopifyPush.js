exports.handler = async (event) => {
  console.log(event);
  console.log("event", event.Input.Records[0].eventID);
  return {
    eventID: event.Input.Records[0].eventID,
  };
};
