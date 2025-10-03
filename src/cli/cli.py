import argparse, os, json
from core import loader, validator
from parsers import parser as tl1parser

def main():
    ap = argparse.ArgumentParser(description="1603 Assistant CLI")
    ap.add_argument("--validate", action="store_true", help="Validate catalogs")
    ap.add_argument("--catalog", choices=["tl1","dlp","tap"], help="Inspect a catalog")
    ap.add_argument("--find", help="Find by id/code (e.g., RTRV-ATTR-T1, DLP-203, TAP-047)")
    ap.add_argument("--parse", help="Parse a TL1 raw test file")
    args = ap.parse_args()
    root = os.path.expanduser("~/1603_assistant")

    if args.validate:
        results = validator.validate_all(root)
        any_fail = False
        for path, errs in results.items():
            if errs:
                any_fail = True
                print(f"[FAIL] {path}: {errs}")
            else:
                print(f"[OK]   {path}")
        if any_fail:
            return

    if args.catalog and args.find:
        cats = loader.load_catalogs(root)
        haystack = cats.get(args.catalog, {})
        match = None
        for fn, data in haystack.items():
            seq = data if isinstance(data, list) else ([data] if isinstance(data, dict) else [])
            for item in seq:
                if not isinstance(item, dict):
                    continue
                for k in ("command_code","command_id","dlp_id","tap_id"):
                    if item.get(k) == args.find:
                        match = item; break
                if match: break
            if match: break
        print(json.dumps(match if match else {"message":"No match"}, indent=2))

    if args.parse:
        result = tl1parser.parse_raw_tl1(args.parse)
        print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
