#!/usr/bin/env python3
"""prepare_live_audio.py — живые ассеты «Дыши» из VSCO 2 CE (CC0).

Владелец забраковал все синтезы (2026-07-15/16) — звук фаз собирается из
НАСТОЯЩИХ записей: арфа (мелодия дыхания, утверждена владельцем) и фоновый
медитативный трек (дрон виолончели + «светлячки» арфы + далёкая флейта).

Источник: github.com/sgossner/VSCO-2-CE (CC0, атрибуция не нужна).
Скрипт КАЧАЕТ семплы через GitHub API (нужен залогиненный `gh`), готовые
ассеты коммитятся в репо — обычная пересборка ассетов (generate_audio.py)
этот скрипт НЕ требует.

Выход:
  assets/audio/sets/harp/note_0..7.wav  — лесенка пентатоники C4..E5
  assets/audio/common/background_loop.ogg — фон 60 c, бесшовный луп (ffmpeg)

Запуск: python tools/prepare_live_audio.py
"""
from __future__ import annotations

import base64
import json
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

SR = 44_100
REPO = "sgossner/VSCO-2-CE"
OUT = Path("assets/audio")
SAMPLES = {
    "harp_B3": "Strings/Harp/KSHarp_B3_mf.wav",
    "harp_D4": "Strings/Harp/KSHarp_D4_mf.wav",
    "harp_F4": "Strings/Harp/KSHarp_F4_mf.wav",
    "harp_C5": "Strings/Harp/KSHarp_C5_mf.wav",
    "cello_C3": "Strings/Cello Section/susvib/susvib_C3_v1_1.wav",
    "cello_G3": "Strings/Cello Section/susvib/susvib_G3_v1_1.wav",
    "flute_C4": "Woodwinds/Flute/susvib/LDFlute_susvib_C4_v1_1.wav",
}


def gh_json(endpoint: str) -> dict:
    res = subprocess.run(["gh", "api", endpoint], capture_output=True, text=True)
    if res.returncode != 0:
        raise SystemExit(f"gh api {endpoint}: {res.stderr[:300]}")
    return json.loads(res.stdout)


def download_samples(dst: Path) -> dict[str, Path]:
    tree = gh_json(f"repos/{REPO}/git/trees/HEAD?recursive=1")["tree"]
    sha_by_path = {e["path"]: e["sha"] for e in tree}
    files = {}
    for name, path in SAMPLES.items():
        target = dst / f"{name}.wav"
        if not target.exists():
            blob = gh_json(f"repos/{REPO}/git/blobs/{sha_by_path[path]}")
            target.write_bytes(base64.b64decode(blob["content"]))
        files[name] = target
        print(f"  · {name}: {target.stat().st_size} байт")
    return files


def read_wav(path: Path) -> np.ndarray:
    with wave.open(str(path), "rb") as w:
        sr, ch, sw, n = (w.getframerate(), w.getnchannels(),
                         w.getsampwidth(), w.getnframes())
        raw = w.readframes(n)
    if sw == 2:
        a = np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32768
    elif sw == 3:
        b = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3)
        a = ((b[:, 0].astype(np.int32)) | (b[:, 1].astype(np.int32) << 8)
             | (b[:, 2].astype(np.int32) << 16))
        a = np.where(a >= 1 << 23, a - (1 << 24), a).astype(np.float64) / (1 << 23)
    else:
        raise ValueError(f"sampwidth {sw}")
    if ch > 1:
        a = a.reshape(-1, ch).mean(axis=1)
    if sr != SR:
        x = np.arange(len(a)) / sr
        xi = np.arange(int(len(a) * SR / sr)) / SR
        a = np.interp(xi, x, a)
    return a


def write_wav(path: Path, sig: np.ndarray) -> None:
    ints = np.round(np.clip(sig, -1, 1) * 32767).astype("<i2")
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(ints.tobytes())


def transpose(note: np.ndarray, semitones: int) -> np.ndarray:
    if semitones == 0:
        return note
    f = 2.0 ** (semitones / 12)
    xi = np.arange(int(len(note) / f)) * f
    return np.interp(xi, np.arange(len(note)), note)


def norm(sig: np.ndarray, peak: float = 1.0) -> np.ndarray:
    m = float(np.max(np.abs(sig)))
    return sig * (peak / m) if m > 0 else sig


def trim_note(note: np.ndarray, dur: float = 3.5) -> np.ndarray:
    """Нота фикс. длины: естественный щипок + плавный fade хвоста."""
    n = int(dur * SR)
    out = note[:n].copy()
    if len(out) < n:
        out = np.pad(out, (0, n - len(out)))
    f = int(0.4 * SR)
    out[-f:] *= np.linspace(1, 0, f)
    return out


def sustained(note: np.ndarray, dur: float,
              a_sec: float = 1.2, b_sec: float = 2.6,
              xfade: float = 0.35) -> np.ndarray:
    """Тянущаяся нота: атака записи + бесшовный кроссфейд-луп середины."""
    a, b = int(a_sec * SR), int(b_sec * SR)
    attack, loop = note[:a], note[a:b].copy()
    xf = int(xfade * SR)
    w = np.linspace(0, 1, xf)
    loop[-xf:] = loop[-xf:] * (1 - w) + loop[:xf] * w
    out = attack
    need = int(dur * SR)
    while len(out) < need:
        out = np.concatenate([out, loop[xf:]])
    return out[:need]


def build_harp_scale(files: dict[str, Path]) -> None:
    """Лесенка пентатоники до: C4 D4 E4 G4 A4 C5 D5 E5 (транспозиции ≤2
    полутонов от живых нот — тембр сохраняется). Утверждена владельцем."""
    B3 = norm(read_wav(files["harp_B3"]))
    D4 = norm(read_wav(files["harp_D4"]))
    F4 = norm(read_wav(files["harp_F4"]))
    C5 = norm(read_wav(files["harp_C5"]))
    scale = [
        transpose(B3, 1),    # 0: C4
        D4,                  # 1: D4
        transpose(F4, -1),   # 2: E4
        transpose(F4, 2),    # 3: G4
        transpose(C5, -3),   # 4: A4
        C5,                  # 5: C5
        transpose(C5, 2),    # 6: D5
        transpose(C5, 4),    # 7: E5
    ]
    for i, note in enumerate(scale):
        write_wav(OUT / "sets" / "harp" / f"note_{i}.wav",
                  norm(trim_note(note), 0.5))
    print(f"  ✓ sets/harp/note_0..7.wav (пентатоника C4..E5)")


def build_background(files: dict[str, Path]) -> None:
    """Фон 60 c (утверждён владельцем в превью 09/10): дрон виолончели
    до+соль с медленной волной, «светлячки» арфы, далёкая флейта.
    Детерминирован (seed). Пишется в ogg (луп играет just_audio напрямую,
    в строгий таймлайн не входит — ПЛАН §10)."""
    rng = np.random.default_rng(20260716)
    LOOP = 60
    n = LOOP * SR
    t = np.arange(n) / SR

    cello_c = norm(read_wav(files["cello_C3"]))
    cello_g = norm(read_wav(files["cello_G3"]))
    drone = sustained(cello_c, LOOP) * 0.55 + sustained(cello_g, LOOP) * 0.4
    drone *= (0.75 + 0.25 * np.sin(2 * np.pi * t / 20 - np.pi / 2)) * 0.16

    D4 = norm(read_wav(files["harp_D4"]))
    F4 = norm(read_wav(files["harp_F4"]))
    C5 = norm(read_wav(files["harp_C5"]))
    spark = np.zeros(n)
    notes = [C5, transpose(F4, 2), transpose(F4, -1), D4]
    pos = 2.0
    while pos < LOOP - 6:
        note = notes[rng.integers(len(notes))]
        gain = 0.10 + 0.06 * rng.random()
        i = int(pos * SR)
        m = min(len(note), n - i)
        spark[i:i + m] += note[:m] * gain
        pos += 5.0 + 4.0 * rng.random()

    fl = sustained(norm(read_wav(files["flute_C4"])), 8)
    fl *= np.sin(np.linspace(0, np.pi, len(fl))) ** 2 * 0.07
    flute_layer = np.zeros(n)
    i = 26 * SR
    flute_layer[i:i + len(fl)] = fl

    bg = norm(drone + spark + flute_layer, 0.4)
    with tempfile.TemporaryDirectory() as tmp:
        tmp_wav = Path(tmp) / "bg.wav"
        write_wav(tmp_wav, bg)
        dst = OUT / "common" / "background_loop.ogg"
        res = subprocess.run(
            ["ffmpeg", "-y", "-i", str(tmp_wav), "-c:a", "libvorbis",
             "-q:a", "3", str(dst)],
            capture_output=True, text=True)
        if res.returncode != 0:
            raise SystemExit(f"ffmpeg: {res.stderr[-400:]}")
    print(f"  ✓ common/background_loop.ogg "
          f"({(OUT / 'common' / 'background_loop.ogg').stat().st_size // 1024} КБ)")


def main() -> None:
    cache = Path(tempfile.gettempdir()) / "vsco_cache"
    cache.mkdir(exist_ok=True)
    print(f"Семплы VSCO (кэш {cache}):")
    files = download_samples(cache)
    build_harp_scale(files)
    build_background(files)
    print("Готово.")


if __name__ == "__main__":
    main()
