import os
import sys
import requests

PINATA_API_KEY = os.environ["PINATA_API_KEY"]
PINATA_SECRET_API_KEY = os.environ["PINATA_SECRET_API_KEY"]
VERSION = sys.argv[1]

files = [
        ("file", (f"cactus-{VERSION}/{VERSION}/cactus.js",     open('dist/cactus.js'),     'text/javascript')),
        ("file", (f"cactus-{VERSION}/{VERSION}/style.css",     open('dist/style.css'),     'text/css')),
        ("file", (f"cactus-{VERSION}/{VERSION}/cactus.js.map", open('dist/cactus.js.map'), 'application/json')),
        ("file", (f"cactus-{VERSION}/{VERSION}/style.css.map", open('dist/style.css.map'), 'application/json'))
]

print(f"Uploading {VERSION}: {len(files)} files...", file=sys.stderr)
r = requests.post(
      "https://api.pinata.cloud/pinning/pinFileToIPFS",
      headers={
          "pinata_api_key": PINATA_API_KEY,
          "pinata_secret_api_key": PINATA_SECRET_API_KEY
      },
      files=files
)

if r.status_code == 200:
    print(r.json()['IpfsHash'])
else:
    print(f"Error: {r.status_code}", file=sys.stderr)
