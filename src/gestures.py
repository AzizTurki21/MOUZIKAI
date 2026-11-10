from math import acos, degrees
from typing import Sequence


def _angle(a, b, c):
    """Return the angle ABC in degrees."""
    ba = (a.x - b.x, a.y - b.y, a.z - b.z)
    bc = (c.x - b.x, c.y - b.y, c.z - b.z)
    denominator = (sum(v * v for v in ba) ** 0.5) * (sum(v * v for v in bc) ** 0.5)
    if denominator == 0:
        return 0.0
    cosine = sum(x * y for x, y in zip(ba, bc)) / denominator
    cosine = max(-1.0, min(1.0, cosine))
    return degrees(acos(cosine))


def finger_states(points: Sequence):
    """Estimate extension for index, middle, ring and little fingers."""
    joints = ((5, 6, 7), (9, 10, 11), (13, 14, 15), (17, 18, 19))
    return tuple(_angle(points[a], points[b], points[c]) > 150 for a, b, c in joints)


def thumb_extended(points: Sequence):
    return _angle(points[2], points[3], points[4]) > 145


def classify_gesture(points: Sequence):
    index, middle, ring, little = finger_states(points)
    thumb = thumb_extended(points)

    if all((index, middle, ring, little)) and thumb:
        return "OPEN PALM"

    if not any((index, middle, ring, little)):
        if thumb:
            wrist_y = points[0].y
            tip_y = points[4].y
            if tip_y < wrist_y - 0.08:
                return "THUMB UP"
        return "FIST"

    if index and middle and not ring and not little:
        return "PEACE"

    if index and not middle and not ring and not little:
        return "INDEX"

    return "UNKNOWN"
