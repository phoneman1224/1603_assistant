def parse_raw_tl1(path):
    lines = []
    with open(path,"r",encoding="utf-8",errors="ignore") as f:
        for ln in f:
            lines.append(ln.strip())
    if not lines:
        return {"error":"empty file"}
    header = lines[0] if lines else ""
    body = lines[1:-1] if len(lines)>2 else []
    footer = lines[-1] if len(lines)>1 else ""
    return {"header":header,"body":body,"footer":footer,"line_count":len(lines)}
