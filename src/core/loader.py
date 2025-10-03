import json, os

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def load_catalogs(base_dir):
    catalogs = {}
    for cat in ["tl1", "dlp", "tap"]:
        cdir = os.path.join(base_dir, "data/shared/catalogs", cat)
        if not os.path.isdir(cdir):
            continue
        for fn in os.listdir(cdir):
            if fn.endswith(".json"):
                path = os.path.join(cdir, fn)
                try:
                    data = load_json(path)
                    catalogs.setdefault(cat, {})[fn] = data
                except Exception as e:
                    print(f"[ERROR] Failed loading {path}: {e}")
    return catalogs
