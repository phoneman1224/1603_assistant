import json, os
from jsonschema import Draft202012Validator

def _load(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def _schema_for(data_path, root):
    p = os.path.normpath(data_path)
    if "/catalogs/tl1/" in p:
        return os.path.join(root, "data/shared/schemas", "tl1_catalog.schema.json")
    if "/catalogs/dlp/" in p and p.endswith("dlp_index.json"):
        return os.path.join(root, "data/shared/schemas", "dlp_index.schema.json")
    if "/catalogs/tap/" in p and p.endswith("tap_index.json"):
        return os.path.join(root, "data/shared/schemas", "tap_index.schema.json")
    if "/shared/alarms/" in p and p.endswith("alarm_map.json"):
        return os.path.join(root, "data/shared/schemas", "alarm_map.schema.json")
    return None  # unknown => skip

def validate_all(root):
    results = {}
    targets = [
        os.path.join(root, "data/shared/catalogs/tl1"),
        os.path.join(root, "data/shared/catalogs/dlp"),
        os.path.join(root, "data/shared/catalogs/tap"),
        os.path.join(root, "data/shared/alarms"),
    ]
    for base in targets:
        if not os.path.isdir(base): 
            continue
        for fn in os.listdir(base):
            if not fn.endswith(".json"):
                continue
            dpath = os.path.join(base, fn)
            schema_path = _schema_for(dpath, root)
            if not schema_path:
                results[dpath] = []
                continue
            try:
                schema = _load(schema_path)
                data = _load(dpath)
                validator = Draft202012Validator(schema)
                errors = sorted(validator.iter_errors(data), key=lambda e: e.path)
                results[dpath] = [e.message for e in errors]
            except Exception as e:
                results[dpath] = [f"LOAD/VALIDATE ERROR: {e}"]
    return results
