#!/usr/bin/env python3
"""
generate_audio.py — синтез аудио-ассетов приложения «Дыши».

100 % программный синтез, без внешних источников и API-ключей → лицензионно
чисто (см. ПЛАН_и_архитектура.md §10, риск R9). Скрипт детерминирован:
одни и те же входные параметры дают побайтово одинаковые файлы.

Зависимости: ТОЛЬКО `numpy` + стандартный модуль `wave`.
    Отклонение от плана (§10 упоминает scipy.io.wavfile): для записи PCM-WAV
    stdlib-модуль `wave` полностью достаточен, не тянет тяжёлую C-зависимость
    и гарантированно доступен (на свежем Python 3.14 колёс scipy может не быть).
    Синтез — на numpy. Если понадобится scipy — write_wav() тривиально заменить.

Запуск:
    python tools/generate_audio.py --out assets/audio

Формат вывода: WAV PCM 44100 Гц / 16 бит / моно.
    Намеренно НЕ ogg/aac: сигналы миксуются рендерером в единый PCM-таймлайн
    (см. §3.3); WAV читается без декодера и без кодек-паддинга, у которого
    «плывёт» начало — прямой удар по требованию ±50 мс (ТЗ §11.1).
    Длинные фоновые лупы timer-техник (ambient/) остаются в ogg — их играет
    just_audio напрямую, они не участвуют в строгом таймлайне.
"""

from __future__ import annotations

import argparse
import json
import wave
from pathlib import Path

import numpy as np

SR = 44_100  # sample rate ассетов == sample rate таймлайна (микс без ресемплинга)


# --------------------------------------------------------------------------- #
# Утилиты уровня и записи
# --------------------------------------------------------------------------- #
def dbfs_to_amp(dbfs: float) -> float:
    """dBFS → линейная амплитуда пика (0 dBFS == 1.0)."""
    return float(10.0 ** (dbfs / 20.0))


def peak_normalize(sig: np.ndarray, target_dbfs: float) -> np.ndarray:
    """Пик-нормализация сигнала к целевому уровню dBFS."""
    peak = float(np.max(np.abs(sig)))
    if peak < 1e-12:
        return sig
    return sig * (dbfs_to_amp(target_dbfs) / peak)


def write_wav(path: Path, sig: np.ndarray, sr: int = SR) -> int:
    """Записать float-сигнал [-1..1] как WAV PCM 16 бит моно. Вернуть число сэмплов."""
    data = np.clip(sig, -1.0, 1.0)
    ints = np.round(data * 32767.0).astype("<i2")  # little-endian int16
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(ints.tobytes())
    return int(ints.shape[0])


# --------------------------------------------------------------------------- #
# Огибающие
# --------------------------------------------------------------------------- #
def _t(dur_ms: float) -> np.ndarray:
    n = max(1, int(round(SR * dur_ms / 1000.0)))
    return np.arange(n, dtype=np.float64) / SR


def raised_cosine_env(n: int, attack_ms: float, release_ms: float) -> np.ndarray:
    """Огибающая: плавный подъём (raised-cosine) и спад, без щелчков на краях."""
    env = np.ones(n, dtype=np.float64)
    a = min(n, int(round(SR * attack_ms / 1000.0)))
    r = min(n - a, int(round(SR * release_ms / 1000.0)))
    if a > 0:
        env[:a] = 0.5 * (1.0 - np.cos(np.pi * np.arange(a) / a))
    if r > 0:
        env[n - r:] = 0.5 * (1.0 + np.cos(np.pi * np.arange(r) / r))
    return env


# --------------------------------------------------------------------------- #
# Генераторы сигналов
# --------------------------------------------------------------------------- #
def steady_tone(freq: float, dur_ms: float,
                attack_ms: float = 10.0, release_ms: float = 120.0) -> np.ndarray:
    t = _t(dur_ms)
    sig = np.sin(2.0 * np.pi * freq * t)
    return sig * raised_cosine_env(t.size, attack_ms, release_ms)


def sweep(f0: float, f1: float, dur_ms: float,
          attack_ms: float = 10.0, release_ms: float = 120.0) -> np.ndarray:
    """Экспоненциальный частотный свип f0→f1. Фаза = 2π·∫f(t)dt (непрерывна)."""
    t = _t(dur_ms)
    T = t[-1] if t.size > 1 else 1.0 / SR
    r = f1 / f0
    if abs(r - 1.0) < 1e-9:
        phase = 2.0 * np.pi * f0 * t
    else:
        # f(t) = f0 * r**(t/T);  ∫0..t f = f0 * T/ln(r) * (r**(t/T) - 1)
        phase = 2.0 * np.pi * f0 * (T / np.log(r)) * (np.power(r, t / T) - 1.0)
    sig = np.sin(phase)
    return sig * raised_cosine_env(t.size, attack_ms, release_ms)


def click(freq: float, dur_ms: float, decay_tau_ms: float,
          attack_ms: float = 1.0) -> np.ndarray:
    """Короткий клик: синус × резкая экспоненциальная огибающая."""
    t = _t(dur_ms)
    exp_env = np.exp(-t / (decay_tau_ms / 1000.0))
    # микро-атака, чтобы не было разрыва в первом сэмпле
    a = max(1, int(round(SR * attack_ms / 1000.0)))
    atk = np.ones(t.size)
    atk[:a] = 0.5 * (1.0 - np.cos(np.pi * np.arange(a) / a))
    return np.sin(2.0 * np.pi * freq * t) * exp_env * atk


def gong(f0: float, dur_ms: float,
         partials=(1.0, 2.0, 2.9, 4.2, 5.4),
         tau0_ms: float = 2500.0,
         attack_ms: float = 5.0) -> np.ndarray:
    """Колокол/гонг: сумма негармонических парциалов с индивидуальным затуханием.

    Амплитуда k-го парциала ~ 1/k, высокие затухают быстрее (τ_k = τ0 / mult),
    лёгкая расстройка ±0.3 % даёт живые биения. Детерминировано (фикс. seed).
    """
    t = _t(dur_ms)
    rng = np.random.default_rng(20260711)  # фикс. seed → воспроизводимость
    sig = np.zeros(t.size, dtype=np.float64)
    for k, mult in enumerate(partials, start=1):
        detune = 1.0 + rng.uniform(-0.003, 0.003)
        freq = f0 * mult * detune
        tau = (tau0_ms / mult) / 1000.0
        sig += (1.0 / k) * np.sin(2.0 * np.pi * freq * t) * np.exp(-t / tau)
    a = max(1, int(round(SR * attack_ms / 1000.0)))
    sig[:a] *= 0.5 * (1.0 - np.cos(np.pi * np.arange(a) / a))
    return sig


def two_tap(dur_ms: float = 150.0, gap_ms: float = 120.0) -> np.ndarray:
    """Двухтактный ритм-сигнал «вдох-выдох» для метода Вима Хофа (этап 2)."""
    up = sweep(300.0, 520.0, dur_ms, attack_ms=6.0, release_ms=60.0)
    down = sweep(520.0, 300.0, dur_ms, attack_ms=6.0, release_ms=60.0)
    gap = np.zeros(int(round(SR * gap_ms / 1000.0)))
    return np.concatenate([up, gap, down])


# --------------------------------------------------------------------------- #
# Спецификация набора (см. ПЛАН §10.2)
# --------------------------------------------------------------------------- #
def build_specs() -> list[dict]:
    return [
        # id, relpath, target dBFS, generator (lambda), назначение
        dict(id="inhale", path="sets/minimal/inhale.wav", dbfs=-6.0,
             gen=lambda: sweep(300.0, 600.0, 700.0),
             purpose="фаза вдоха — восходящий свип 300→600 Гц"),
        dict(id="hold_in", path="sets/minimal/hold_in.wav", dbfs=-6.0,
             gen=lambda: steady_tone(450.0, 500.0),
             purpose="задержка на вдохе — ровный тон 450 Гц"),
        dict(id="exhale", path="sets/minimal/exhale.wav", dbfs=-6.0,
             gen=lambda: sweep(600.0, 300.0, 700.0),
             purpose="фаза выдоха — нисходящий свип 600→300 Гц"),
        dict(id="hold_out", path="sets/minimal/hold_out.wav", dbfs=-6.0,
             gen=lambda: steady_tone(400.0, 500.0),
             purpose="задержка на выдохе — ровный тон 400 Гц (различим от hold_in)"),
        dict(id="tick", path="sets/minimal/tick.wav", dbfs=-14.0,
             gen=lambda: click(1000.0, 30.0, decay_tau_ms=6.0),
             purpose="тик метронома"),
        dict(id="tick_accent", path="sets/minimal/tick_accent.wav", dbfs=-10.0,
             gen=lambda: click(1500.0, 40.0, decay_tau_ms=8.0),
             purpose="акцентный тик на смене фазы"),
        dict(id="prep_beep", path="common/prep_beep.wav", dbfs=-8.0,
             gen=lambda: steady_tone(800.0, 120.0, attack_ms=8.0, release_ms=40.0),
             purpose="бип обратного отсчёта «3…2…1»"),
        dict(id="gong", path="common/gong.wav", dbfs=-3.0,
             gen=lambda: gong(220.0, 6000.0),
             purpose="гонг в конце сессии"),
        dict(id="wim_hof_pace", path="common/wim_hof_pace.wav", dbfs=-8.0,
             gen=lambda: two_tap(),
             purpose="ритм дыханий Вима Хофа (этап 2)"),
    ]


def main() -> None:
    ap = argparse.ArgumentParser(description="Синтез аудио-ассетов «Дыши».")
    ap.add_argument("--out", default="assets/audio", help="каталог вывода")
    args = ap.parse_args()

    out = Path(args.out)
    manifest: dict[str, dict] = {}

    print(f"Синтез аудио-ассетов → {out}  (WAV {SR} Гц / 16 бит / моно)")
    for spec in build_specs():
        sig = peak_normalize(spec["gen"](), spec["dbfs"])
        dest = out / spec["path"]
        n = write_wav(dest, sig)
        dur_ms = round(1000.0 * n / SR, 1)
        manifest[spec["id"]] = dict(
            file=spec["path"], duration_ms=dur_ms,
            level_dbfs=spec["dbfs"], purpose=spec["purpose"],
        )
        print(f"  ✓ {spec['path']:<28} {dur_ms:>7.1f} мс  {spec['dbfs']:>5} dBFS")

    manifest_path = out / "manifest.json"
    manifest_path.write_text(
        json.dumps({"sample_rate": SR, "format": "wav_pcm_s16_mono",
                    "assets": manifest}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    total = sum(
        (out / m["file"]).stat().st_size for m in manifest.values()
    )
    print(f"  ✓ manifest.json ({len(manifest)} записей)")
    print(f"Готово. Суммарный размер набора: {total / 1024:.1f} КБ")


if __name__ == "__main__":
    main()
