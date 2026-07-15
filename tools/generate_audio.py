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
# Набор «Природа» (отзыв №5: свипы/тоны неприятны → волны и капли)
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


def wave_pair(dur_ms: float = 260.0, gap_ms: float = 120.0) -> np.ndarray:
    """Ритм Вима Хофа: короткий накат + пауза + откат (вместо свип-пары)."""
    up = ocean_wave(dur_ms, rising=True, seed_offset=71)
    down = ocean_wave(dur_ms, rising=False, seed_offset=72)
    gap = np.zeros(int(round(SR * gap_ms / 1000.0)))
    return np.concatenate([up, gap, down])


# --------------------------------------------------------------------------- #
# Набор «Чаши» (2026-07-15: владелице нужен третий вариант — НЕ дыхание/шум
# и НЕ синтетический писк). Поющие чаши и колокольчики: тёплые негармонические
# парциалы, знакомый медитативный тембр.
# --------------------------------------------------------------------------- #
# Соотношения парциалов тибетской чаши (измерения реальных чаш ~1:2.8:5.2:8.4);
# амплитуды ~1/k, высокие затухают быстрее — как в gong(), но тембр «чище».
_BOWL_PARTIALS = (1.0, 2.78, 5.18, 8.36)


def bowl_strike(f0: float, dur_ms: float, tau0_ms: float = 1400.0) -> np.ndarray:
    """Удар чаши: мгновенная атака, долгое тёплое затухание (выдох)."""
    t = _t(dur_ms)
    rng = np.random.default_rng(_RNG_SEED + int(f0))
    sig = np.zeros(t.size, dtype=np.float64)
    for k, mult in enumerate(_BOWL_PARTIALS, start=1):
        detune = 1.0 + rng.uniform(-0.002, 0.002)
        tau = (tau0_ms / mult) / 1000.0
        sig += (1.0 / k) * np.sin(2.0 * np.pi * f0 * mult * detune * t) \
            * np.exp(-t / tau)
    a = max(1, int(round(SR * 4.0 / 1000.0)))  # атака 4 мс без щелчка
    sig[:a] *= 0.5 * (1.0 - np.cos(np.pi * np.arange(a) / a))
    return sig


def bowl_swell(f0: float, dur_ms: float) -> np.ndarray:
    """«Смычок» по чаше: звук нарастает к концу (вдох). Лёгкое вибрато
    оживляет длинную ноту; спад в самом конце — фаза передаёт эстафету."""
    t = _t(dur_ms)
    rng = np.random.default_rng(_RNG_SEED + int(f0) + 7)
    sig = np.zeros(t.size, dtype=np.float64)
    vibrato = 1.0 + 0.004 * np.sin(2.0 * np.pi * 4.5 * t)
    for k, mult in enumerate(_BOWL_PARTIALS[:3], start=1):
        detune = 1.0 + rng.uniform(-0.002, 0.002)
        sig += (1.0 / k) * np.sin(2.0 * np.pi * f0 * mult * detune * t * vibrato)
    n = t.size
    x = np.arange(n) / max(1, n - 1)
    swell = x ** 1.5  # медленный подъём, максимум к концу вдоха
    sig *= swell * raised_cosine_env(n, attack_ms=30.0, release_ms=150.0)
    return sig


def chime(f0: float, dur_ms: float = 500.0, tau_ms: float = 220.0) -> np.ndarray:
    """Колокольчик: два лёгких парциала, быстрое серебристое затухание
    (задержки дыхания — события, не длящиеся фазы)."""
    t = _t(dur_ms)
    sig = np.sin(2.0 * np.pi * f0 * t) \
        + 0.4 * np.sin(2.0 * np.pi * f0 * 2.51 * t)
    a = max(1, int(round(SR * 3.0 / 1000.0)))
    atk = np.ones(t.size)
    atk[:a] = 0.5 * (1.0 - np.cos(np.pi * np.arange(a) / a))
    return sig * np.exp(-t / (tau_ms / 1000.0)) * atk


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
    return [
        # --- Набор «Минимал» (синтетические свипы/тоны, исторический) ---
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
        # --- Набор «Природа» (дефолт: волны на фазы, капли на события) ---
        dict(id="inhale", path="sets/nature/inhale.wav", dbfs=-6.0,
             gen=lambda: ocean_wave(1200.0, rising=True, seed_offset=1),
             purpose="фаза вдоха — накат волны (шум, растущая яркость)"),
        dict(id="hold_in", path="sets/nature/hold_in.wav", dbfs=-8.0,
             gen=lambda: droplet(500.0, 1000.0, 220.0, decay_tau_ms=70.0),
             purpose="задержка на вдохе — капля повыше"),
        dict(id="exhale", path="sets/nature/exhale.wav", dbfs=-6.0,
             gen=lambda: ocean_wave(1500.0, rising=False, seed_offset=2),
             purpose="фаза выдоха — откат волны (спадающая яркость)"),
        dict(id="hold_out", path="sets/nature/hold_out.wav", dbfs=-8.0,
             gen=lambda: droplet(350.0, 700.0, 220.0, decay_tau_ms=70.0),
             purpose="задержка на выдохе — капля пониже (различима от hold_in)"),
        dict(id="tick", path="sets/nature/tick.wav", dbfs=-16.0,
             gen=lambda: droplet(600.0, 900.0, 60.0, decay_tau_ms=18.0),
             purpose="тик метронома — тихая капелька"),
        dict(id="tick_accent", path="sets/nature/tick_accent.wav", dbfs=-12.0,
             gen=lambda: droplet(700.0, 1200.0, 90.0, decay_tau_ms=25.0),
             purpose="акцентный тик — капля ярче"),
        # --- Набор «Чаши» (новый дефолт 2026-07-15) ---
        dict(id="inhale", path="sets/bowls/inhale.wav", dbfs=-7.0,
             gen=lambda: bowl_swell(392.0, 1200.0),  # соль первой октавы
             purpose="фаза вдоха — «смычок» по чаше, звук нарастает"),
        dict(id="hold_in", path="sets/bowls/hold_in.wav", dbfs=-10.0,
             gen=lambda: chime(1318.5),  # ми третьей октавы
             purpose="задержка на вдохе — колокольчик повыше"),
        dict(id="exhale", path="sets/bowls/exhale.wav", dbfs=-6.0,
             gen=lambda: bowl_strike(261.6, 1500.0),  # до первой октавы
             purpose="фаза выдоха — удар чаши, тёплое затухание"),
        dict(id="hold_out", path="sets/bowls/hold_out.wav", dbfs=-10.0,
             gen=lambda: chime(987.8),  # си второй октавы
             purpose="задержка на выдохе — колокольчик пониже"),
        dict(id="tick", path="sets/bowls/tick.wav", dbfs=-16.0,
             gen=lambda: wood_tap(),
             purpose="тик метронома — глухой деревянный тап"),
        dict(id="tick_accent", path="sets/bowls/tick_accent.wav", dbfs=-12.0,
             gen=lambda: wood_tap(freq=330.0),
             purpose="акцентный тик — тап повыше"),
        # --- Общие (для всех наборов) ---
        dict(id="prep_beep", path="common/prep_beep.wav", dbfs=-8.0,
             gen=lambda: droplet(450.0, 850.0, 160.0, decay_tau_ms=50.0),
             purpose="отсчёт «3…2…1» — капля (бип 800 Гц был неприятен, №5)"),
        dict(id="wim_hof_pace", path="common/wim_hof_pace.wav", dbfs=-8.0,
             gen=lambda: wave_pair(),
             purpose="ритм дыханий Вима Хофа — накат+откат (вместо свип-пары)"),
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
