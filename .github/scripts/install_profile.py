#!/usr/bin/env python3
import jwt, time, requests, os, base64

KEY = open(os.path.expanduser("~/private_keys/AuthKey_9AHH974Y96.p8")).read()
KEY_ID = "9AHH974Y96"
ISSUER_ID = "69a6de87-5a54-47e3-e053-5b8c7c11a4d1"
PROFILE_UUID = os.environ["PROFILE_UUID"]
PROFILE_DIR = os.path.expanduser("~/Library/MobileDevice/Provisioning Profiles")

now = int(time.time())
token = jwt.encode(
    {"iss": ISSUER_ID, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
    KEY, algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"}
)

r = requests.get(
    "https://api.appstoreconnect.apple.com/v1/profiles",
    headers={"Authorization": f"Bearer {token}"},
    params={"filter[uuid]": PROFILE_UUID, "fields[profiles]": "profileContent,uuid,name"}
)
r.raise_for_status()
data = r.json()["data"]
if not data:
    raise RuntimeError(f"Profile {PROFILE_UUID} not found")

profile_b64 = data[0]["attributes"]["profileContent"]
profile_bytes = base64.b64decode(profile_b64)
os.makedirs(PROFILE_DIR, exist_ok=True)
out_path = os.path.join(PROFILE_DIR, f"{PROFILE_UUID}.mobileprovision")
with open(out_path, "wb") as f:
    f.write(profile_bytes)
print(f"Installed profile: {out_path}")
