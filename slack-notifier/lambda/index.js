const https = require('https');

exports.handler = async (event) => {
  const message = JSON.parse(event.Records[0].Sns.Message);
  const status = message.detail.state;
  const pipeline = message.detail.pipeline;
  const stage = message.detail.stage || "N/A";

  const text = `*CodePipeline Notification*\nPipeline: ${pipeline}\nStatus: *${status}*\nStage: ${stage}`;

  const data = JSON.stringify({ text });

  const options = {
    hostname: 'hooks.slack.com',
    path: process.env.SLACK_WEBHOOK_URL.replace('https://hooks.slack.com', ''),
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  };

  await new Promise((resolve, reject) => {
    const req = https.request(options, res => {
      res.on('data', d => process.stdout.write(d));
      res.on('end', resolve);
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });

  return { statusCode: 200, body: 'Notification sent' };
};
