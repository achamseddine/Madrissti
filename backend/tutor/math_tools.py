from fractions import Fraction
from pydantic import BaseModel, ConfigDict, Field, model_validator

class Rational(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    numerator: int = Field(ge=0, le=12)
    denominator: int = Field(ge=1, le=12)

    @model_validator(mode="after")
    def proper(self):
        if self.numerator > self.denominator:
            raise ValueError("Only fractions between zero and one are supported")
        return self

class FractionBars(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    whole_id: str = Field(min_length=1, max_length=80)
    values: list[Rational] = Field(min_length=1, max_length=4)

    def render(self):
        return {"type": "fraction_bars", **self.model_dump(), "description": "; ".join(
            f"{v.numerator}/{v.denominator} of the same whole" for v in self.values)}

def equivalent(answer: str, expected: str) -> bool:
    if len(answer) > 64:
        raise ValueError("Answer too long")
    try:
        return Fraction(answer) == Fraction(expected)
    except (ValueError, ZeroDivisionError):
        raise ValueError("Invalid rational answer") from None
