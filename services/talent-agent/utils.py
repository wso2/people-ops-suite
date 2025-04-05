import re

def validate_year(year):
    try:
        year = int(year)
        if year <= 0:
            raise ValueError
    except ValueError:
        return None
    if not re.match(r"^\d{4}$", str(year)):
        return None
    return year
