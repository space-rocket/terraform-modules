# OpenSearch Manual Data Import via Bastion

This guide outlines how to manually upload a large Elasticsearch/OpenSearch dataset to an AWS OpenSearch domain from within a bastion host using a split + bulk upload script.

---

## 🔧 Prerequisites

- ✅ A working **OpenSearch VPC domain** with fine-grained access control (FGAC)
- ✅ An accessible **bastion EC2 instance** in the same VPC/subnet as OpenSearch
- ✅ Your OpenSearch credentials (`admin` user and password)
- ✅ The `dump.json` file (exported from your original Elasticsearch)

---

## 🧪 1. Validate Access to OpenSearch

SSH into the bastion:

```bash
ssh ec2-user@<BASTION_PUBLIC_IP> -i ~/.ssh/<BASTION_KEY>.pem
```

Then test OpenSearch access:

```bash
curl -k -u <OS_USERNAME>:<OS_PASSWORD> https://<OPENSEARCH_VPC_ENDPOINT>
```

You should see JSON output like:

```json
{
  "cluster_name": "...",
  "version": { "number": "2.x" },
  "tagline": "The OpenSearch Project: https://opensearch.org/"
}
```

---

## 📂 2. Prepare Your Files

On your local machine, place the following in a folder:

- `dump.json` — the raw export from `elasticdump`
- `upload-to-opensearch.sh` — your bulk import script

> Script must be in the same folder as `dump.json`

---

## 📤 3. Upload Files to Bastion

```bash
scp -i ~/.ssh/<BASTION_KEY>.pem dump.json upload-to-opensearch.sh ec2-user@<BASTION_PUBLIC_IP>:~
```

---

## 🛠 4. Run the Import Script on Bastion

SSH into the bastion:

```bash
ssh ec2-user@<BASTION_PUBLIC_IP> -i ~/.ssh/<BASTION_KEY>.pem
```

Make sure dependencies are installed:

```bash
sudo yum install -y jq
chmod +x upload-to-opensearch.sh
```

Then run:

```bash
./upload-to-opensearch.sh
```

---

## ⚙️ Script Overview (`upload-to-opensearch.sh`)

This script:

1. Converts `dump.json` into OpenSearch `_bulk` format
2. Splits the output into manageable chunks
3. Uploads each chunk using the `_bulk` API
4. Verifies the import by checking index and doc count

You’ll need to customize inside the script:
- `OPENSEARCH_URL=https://<OPENSEARCH_VPC_ENDPOINT>`
- `AUTH=<OS_USERNAME>:<OS_PASSWORD>`

---

## ✅ Expected Output

```text
📦 Converting dump.json to _bulk format...
✂️ Splitting into chunks...
🚀 Importing chunk_aa...
...
📊 Verifying import...
✅ Import complete.
```

---

## 🧼 Optional: Fix Yellow Index Health

If your index shows `yellow` status:

```bash
curl -k -u <AUTH> -XPUT https://<OPENSEARCH_VPC_ENDPOINT>/<INDEX_NAME>/_settings \
  -H 'Content-Type: application/json' \
  -d '{"index": {"number_of_replicas": 0}}'
```

---

## 📌 Notes

- Ensure the bastion can reach the OpenSearch domain (same VPC, correct SG).
- Do not expose credentials in source-controlled scripts.
