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
# Генераторы (волны/капли/тапы; свипы и тоны истории — см. git до 2026-07-15)
# --------------------------------------------------------------------------- #
_RNG_SEED = 20260715  # фикс. seed всех шумов → побайтовая воспроизводимость


def _fft_lowpass(sig: np.ndarray, cutoff_hz: float) -> np.ndarray:
    """Brick-wall lowpass через rfft (без scipy)."""
    spec = np.fft.rfft(sig)
    freqs = np.fft.rfftfreq(sig.size, d=1.0 / SR)
    spec[freqs > cutoff_hz] = 0.0
    return np.fft.irfft(spec, n=sig.size)


def _fft_bandpass(sig: np.ndarray, lo_hz: float, hi_hz: float) -> np.ndarray:
    """Brick-wall bandpass через rfft."""
    spec = np.fft.rfft(sig)
    freqs = np.fft.rfftfreq(sig.size, d=1.0 / SR)
    spec[(freqs < lo_hz) | (freqs > hi_hz)] = 0.0
    return np.fft.irfft(spec, n=sig.size)


def ocean_wave(dur_ms: float, rising: bool, seed_offset: int = 0) -> np.ndarray:
    """Накат/откат волны: фильтрованный шум, огибающая и яркость движутся вместе.

    rising=True — волна «накатывает» (вдох): громкость и яркость растут;
    rising=False — «откатывает» (выдох): спадают. Яркость — кроссфейд тёмного
    (НЧ) и светлого (СЧ) слоёв одного шума, чтобы не было двух разных «источников».
    """
    t = _t(dur_ms)
    n = t.size
    rng = np.random.default_rng(_RNG_SEED + seed_offset)
    noise = rng.standard_normal(n)
    dark = _fft_bandpass(noise, 120.0, 650.0)
    bright = _fft_bandpass(noise, 120.0, 2400.0)
    # Ход волны 0→1 (или 1→0): половина косинуса — плавный, без рывка.
    x = 0.5 * (1.0 - np.cos(np.pi * np.arange(n) / max(1, n - 1)))
    if not rising:
        x = x[::-1]
    sig = dark * (1.0 - x) + bright * x
    # Громкость следует ходу волны + короткие края от щелчков.
    amp = 0.15 + 0.85 * x
    sig = sig * amp * raised_cosine_env(n, attack_ms=40.0, release_ms=120.0)
    return sig


def droplet(f0: float, f1: float, dur_ms: float,
            decay_tau_ms: float = 60.0) -> np.ndarray:
    """Капля: короткое глиссандо вверх × экспоненциальный спад («кап»)."""
    t = _t(dur_ms)
    # Линейный ход частоты; фаза = 2π·∫f dt — без разрывов.
    T = t[-1] if t.size > 1 else 1.0 / SR
    phase = 2.0 * np.pi * (f0 * t + (f1 - f0) * t * t / (2.0 * T))
    exp_env = np.exp(-t / (decay_tau_ms / 1000.0))
    a = max(1, int(round(SR * 3.0 / 1000.0)))  # микро-атака 3 мс
    atk = np.ones(t.size)
    atk[:a] = 0.5 * (1.0 - np.cos(np.pi * np.arange(a) / a))
    return np.sin(phase) * exp_env * atk


def wood_tap(dur_ms: float = 45.0, freq: float = 220.0) -> np.ndarray:
    """Глухой деревянный тап (тик метронома): низкий короткий стук без
    пронзительности — «деревянная рыба» из практик, не системный клик."""
    t = _t(dur_ms)
    rng = np.random.default_rng(_RNG_SEED + 99)
    tone = np.sin(2.0 * np.pi * freq * t) * np.exp(-t / 0.012)
    knock = _fft_lowpass(rng.standard_normal(t.size), 900.0) \
        * np.exp(-t / 0.006)
    return tone + 0.5 * knock


# --------------------------------------------------------------------------- #
# Спецификация наборов (см. ПЛАН §10.2; «Природа» — отзыв №5 2026-07-14)
# --------------------------------------------------------------------------- #
def build_specs() -> list[dict]:
    # ЕДИНСТВЕННЫЙ звуковой вариант — «прибой» (решение владельца 2026-07-15,
    # наборы minimal/nature/bowls удалены). Фазы дыхания синтезируются
    # РЕНДЕРЕРОМ на всю длительность фазы (lib/services/audio/surf_synth.dart);
    # здесь остались клипы-события + фиксированные волны для one-shot'ов
    # Вима Хофа (у него длительность фазы задаёт темп, клипы короткие).
    return [
        dict(id="tick", path="common/tick.wav", dbfs=-16.0,
             gen=lambda: wood_tap(),
             purpose="тик метронома — глухой деревянный тап"),
        dict(id="tick_accent", path="common/tick_accent.wav", dbfs=-12.0,
             gen=lambda: wood_tap(freq=330.0),
             purpose="акцентный тик — тап повыше"),
        dict(id="prep_beep", path="common/prep_beep.wav", dbfs=-8.0,
             gen=lambda: droplet(450.0, 850.0, 160.0, decay_tau_ms=50.0),
             purpose="отсчёт «3…2…1» — капля (бип 800 Гц был неприятен, №5)"),
        dict(id="breath_in", path="common/breath_in.wav", dbfs=-8.0,
             gen=lambda: ocean_wave(1200.0, rising=True, seed_offset=1),
             purpose="волна-вдох для one-shot'ов Вима Хофа"),
        dict(id="breath_out", path="common/breath_out.wav", dbfs=-8.0,
             gen=lambda: ocean_wave(1500.0, rising=False, seed_offset=2),
             purpose="волна-выдох для one-shot'ов Вима Хофа"),
    ]


# Внешние ассеты: НЕ синтезируются, лежат в git готовыми.
# Обработка и лицензии — tools/audio_sources/README.md.
EXTERNAL_ASSETS = [
    dict(id="gong", path="common/gong.wav", dbfs=-3.0,
         purpose="гонг в конце сессии — freesound #42095 fauxpress, CC0 "
                 "(одобрен владельцем; синтез-фолбэк: gong(220, 6000))"),
]


def main() -> None:
    ap = argparse.ArgumentParser(description="Синтез аудио-ассетов «Дыши».")
    ap.add_argument("--out", default="assets/audio", help="каталог вывода")
    args = ap.parse_args()

    out = Path(args.out)
    # Манифест: sets/<набор>/<id> + common/<id> — по каталогу файла.
    manifest: dict = {"common": {}, "sets": {}}

    def put(spec: dict, dur_ms: float) -> None:
        entry = dict(file=spec["path"], duration_ms=dur_ms,
                     level_dbfs=spec["dbfs"], purpose=spec["purpose"])
        parts = Path(spec["path"]).parts
        if parts[0] == "sets":
            manifest["sets"].setdefault(parts[1], {})[spec["id"]] = entry
        else:
            manifest["common"][spec["id"]] = entry

    print(f"Синтез аудио-ассетов → {out}  (WAV {SR} Гц / 16 бит / моно)")
    for spec in build_specs():
        sig = peak_normalize(spec["gen"](), spec["dbfs"])
        dest = out / spec["path"]
        n = write_wav(dest, sig)
        dur_ms = round(1000.0 * n / SR, 1)
        put(spec, dur_ms)
        print(f"  ✓ {spec['path']:<28} {dur_ms:>7.1f} мс  {spec['dbfs']:>5} dBFS")

    for spec in EXTERNAL_ASSETS:
        src = out / spec["path"]
        if not src.exists():
            raise SystemExit(f"Внешний ассет отсутствует: {src} "
                             "(см. tools/audio_sources/README.md)")
        with wave.open(str(src), "rb") as w:
            if w.getframerate() != SR or w.getnchannels() != 1:
                raise SystemExit(f"{src}: ожидается {SR} Гц моно")
            dur_ms = round(1000.0 * w.getnframes() / SR, 1)
        put(spec, dur_ms)
        print(f"  = {spec['path']:<28} {dur_ms:>7.1f} мс  (внешний, не трогаем)")

    manifest_path = out / "manifest.json"
    manifest_path.write_text(
        json.dumps({"sample_rate": SR, "format": "wav_pcm_s16_mono",
                    **manifest}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    all_entries = list(manifest["common"].values()) + [
        e for s in manifest["sets"].values() for e in s.values()
    ]
    total = sum((out / m["file"]).stat().st_size for m in all_entries)
    print(f"  ✓ manifest.json ({len(all_entries)} записей)")
    print(f"Готово. Суммарный размер наборов: {total / 1024:.1f} КБ")


if __name__ == "__main__":
    main()
