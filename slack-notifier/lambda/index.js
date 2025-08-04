const https = require('https');
const url = require('url');

exports.handler = async (event) => {
  const message = JSON.parse(event.Records[0].Sns.Message);
  const pipeline = message.detail.pipeline || "Unknown";
  const state = message.detail.state || "Unknown";
  const executionId = message.detail["execution-id"] || "N/A";
  const region = message.region || "us-east-1";

  const slackMessage = {
    text: `🛰 *CodePipeline Notification*\nPipeline: \`${pipeline}\`\nStatus: *${state}*\nExecution ID: \`${executionId}\`\nRegion: \`${region}\``
  };

  const webhookUrl = process.env.SLACK_WEBHOOK_URL;
  const parsedUrl = url.parse(webhookUrl);

  const options = {
    hostname: parsedUrl.hostname,
    path: parsedUrl.path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      res.setEncoding('utf8');
      res.on('data', (body) => {
        console.log('Slack response:', body);
        resolve();
      });
    });

    req.on('error', (err) => {
      console.error('Slack request failed:', err);
      reject(err);
    });

    req.write(JSON.stringify(slackMessage));
    req.end();
  });
};
