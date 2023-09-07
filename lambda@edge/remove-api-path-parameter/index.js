exports.handler = async (event) => {
  const request = event.Records[0].cf.request;

  request.uri = request.uri.replace(/^\/api\//, '/');

  return request;
};
