def check(output: str, expected: dict) -> dict:
    details = []
    must_contain = expected.get("must_contain", [])
    must_not_contain = expected.get("must_not_contain", [])

    for keyword in must_contain:
        passed = keyword in output
        details.append({"rule": f"must_contain: {keyword}", "pass": passed})

    for keyword in must_not_contain:
        passed = keyword not in output
        details.append({"rule": f"must_not_contain: {keyword}", "pass": passed})

    total = len(details)
    if total == 0:
        return {"rule_score": 100.0, "details": details}

    passed_count = sum(1 for d in details if d["pass"])
    score = (passed_count / total) * 100

    return {"rule_score": score, "details": details}
