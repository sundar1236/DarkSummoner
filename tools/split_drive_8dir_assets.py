"""
Splits Drive turnaround character/enemy/boss sheets into 8-directional transparent
sprite strips ([e, se, s, sw, w, nw, n, ne] = 8 horizontal frames) and builds
5 floor 720x1280 4-layer 2.5D environments from Drive arena art.

Usage:
    python tools/split_drive_8dir_assets.py
"""
from __future__ import annotations

import os
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
from scipy import ndimage

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DRIVE = os.path.join(ROOT, "assets", "references", "drive_material")

OUT_CHAR_8DIR = os.path.join(ROOT, "assets", "art", "characters", "8dir")
OUT_CHAR_ROOT = os.path.join(ROOT, "assets", "art", "characters")
OUT_ENEMY_8DIR = os.path.join(ROOT, "assets", "art", "enemies", "8dir")
OUT_BOSS_8DIR = os.path.join(ROOT, "assets", "art", "bosses", "8dir")
OUT_FLOORS = os.path.join(ROOT, "assets", "art", "environments", "floors")

for d in (OUT_CHAR_8DIR, OUT_CHAR_ROOT, OUT_ENEMY_8DIR, OUT_BOSS_8DIR, OUT_FLOORS):
    os.makedirs(d, exist_ok=True)


def _estimate_bg_map(rgb: np.ndarray) -> np.ndarray:
    """Estimate smooth studio gradient background without smearing foreground edge pixels."""
    h, w, _ = rgb.shape
    top_strip = rgb[:max(6, min(16, h // 10)), :, :]
    top_med = np.median(top_strip.reshape(-1, 3), axis=0)

    # Compute local gradient & chroma so only smooth neutral margin pixels contribute to row_bg
    gx = np.abs(np.diff(rgb, axis=1, prepend=rgb[:, :1, :])).max(axis=2)
    gy = np.abs(np.diff(rgb, axis=0, prepend=rgb[:1, :, :])).max(axis=2)
    grad = np.maximum(gx, gy)
    chroma = np.max(rgb, axis=2) - np.min(rgb, axis=2)

    margin = max(8, min(18, w // 12))
    side_rgb = np.concatenate([rgb[:, :margin, :], rgb[:, -margin:, :]], axis=1)
    side_grad = np.concatenate([grad[:, :margin], grad[:, -margin:]], axis=1)
    side_chroma = np.concatenate([chroma[:, :margin], chroma[:, -margin:]], axis=1)
    dist_top = np.linalg.norm(side_rgb - top_med[None, None, :], axis=2)

    row_bg = np.zeros((h, 3), dtype=np.float32)
    last_valid = top_med.copy()
    for y in range(h):
        # Accept smooth neutral studio gradient (even if brighter/darker near the floor)
        smooth_neutral = (side_grad[y] < 8.5) & (side_chroma[y] < 12.0) & (dist_top[y] < 120.0)
        valid = side_rgb[y][smooth_neutral]
        if len(valid) >= 3:
            last_valid = np.median(valid, axis=0)
        row_bg[y] = last_valid

    # Smooth vertically so no single row ever creates a horizontal band
    for c in range(3):
        row_bg[:, c] = ndimage.median_filter(row_bg[:, c], size=31)
        row_bg[:, c] = ndimage.gaussian_filter1d(row_bg[:, c], sigma=8.0)

    return np.broadcast_to(row_bg[:, None, :], (h, w, 3)).copy()


def extract_foreground_rgba(
    crop_rgb: np.ndarray,
    exclude_rects: list[tuple[int, int, int, int]] | None = None,
    bg_thresh: float = 19.0,
    soft_band: float = 11.0,
    keep_secondary_ratio: float = 0.06,
) -> Image.Image:
    """
    Remove studio grey/neutral background cleanly via border-seeded flood fill
    so internal light/dark pixels of the character are never punched out.
    """
    rgb = crop_rgb.astype(np.float32)
    h, w, _ = rgb.shape

    if exclude_rects:
        # Paint excluded accessory/logo rectangles with local median border color
        border_col = np.median(
            np.concatenate([rgb[0, :, :], rgb[:, 0, :], rgb[:, -1, :]], axis=0), axis=0
        )
        for rx0, ry0, rx1, ry1 in exclude_rects:
            x0, y0 = max(0, rx0), max(0, ry0)
            x1, y1 = min(w, rx1), min(h, ry1)
            if x1 > x0 and y1 > y0:
                rgb[y0:y1, x0:x1] = border_col

    bg = _estimate_bg_map(rgb)
    # Pad by 4px with estimated edge background so figures touching crop edges
    # never block the outer flood fill from wrapping all sides cleanly.
    pad = 4
    rgb_p = np.pad(rgb, ((pad, pad), (pad, pad), (0, 0)), mode="edge")
    bg_p = np.pad(bg, ((pad, pad), (pad, pad), (0, 0)), mode="edge")
    # Force outer 2px ring to exact bg_p so flood fill enters from every side
    rgb_p[:2, :, :] = bg_p[:2, :, :]
    rgb_p[-2:, :, :] = bg_p[-2:, :, :]
    rgb_p[:, :2, :] = bg_p[:, :2, :]
    rgb_p[:, -2:, :] = bg_p[:, -2:, :]

    hp, wp, _ = rgb_p.shape
    diff_p = np.linalg.norm(rgb_p - bg_p, axis=2)

    # Also measure chroma and local spatial gradient so flat grey studio floor/shadow
    # gradients clear cleanly while sharp character boot/armor silhouettes stop flood fill.
    chroma_p = np.max(rgb_p, axis=2) - np.min(rgb_p, axis=2)
    gx_p = np.abs(np.diff(rgb_p, axis=1, prepend=rgb_p[:, :1, :])).max(axis=2)
    gy_p = np.abs(np.diff(rgb_p, axis=0, prepend=rgb_p[:1, :, :])).max(axis=2)
    grad_p = np.maximum(gx_p, gy_p)
    is_bg_candidate = (
        (diff_p < bg_thresh)
        | ((diff_p < min(bg_thresh * 1.45, bg_thresh + 9.0)) & (chroma_p < 9.0))
        | ((diff_p < bg_thresh * 2.4) & (chroma_p < 9.0) & (grad_p < 7.5))
    )

    # Border-seeded flood fill (4-connected) on padded canvas
    visited = np.zeros((hp, wp), dtype=bool)
    q = deque()
    for x in range(wp):
        visited[0, x] = True
        q.append((0, x))
        visited[hp - 1, x] = True
        q.append((hp - 1, x))
    for y in range(1, hp - 1):
        visited[y, 0] = True
        q.append((y, 0))
        visited[y, wp - 1] = True
        q.append((y, wp - 1))

    while q:
        cy, cx = q.popleft()
        if cy > 0 and not visited[cy - 1, cx] and is_bg_candidate[cy - 1, cx]:
            visited[cy - 1, cx] = True
            q.append((cy - 1, cx))
        if cy + 1 < hp and not visited[cy + 1, cx] and is_bg_candidate[cy + 1, cx]:
            visited[cy + 1, cx] = True
            q.append((cy + 1, cx))
        if cx > 0 and not visited[cy, cx - 1] and is_bg_candidate[cy, cx - 1]:
            visited[cy, cx - 1] = True
            q.append((cy, cx - 1))
        if cx + 1 < wp and not visited[cy, cx + 1] and is_bg_candidate[cy, cx + 1]:
            visited[cy, cx + 1] = True
            q.append((cy, cx + 1))

    visited = visited[pad:pad + h, pad:pad + w]
    diff = diff_p[pad:pad + h, pad:pad + w]
    fg_mask = ~visited

    # Keep main body + close floating orbs/flames/crowns; drop tiny distant noise
    lbl, num = ndimage.label(fg_mask)
    if num > 0:
        sizes = ndimage.sum(fg_mask, lbl, range(1, num + 1))
        max_sz = float(np.max(sizes))
        # Find centroid/bbox of primary component
        main_idx = int(np.argmax(sizes)) + 1
        my, mx = np.where(lbl == main_idx)
        my0, my1 = int(my.min()), int(my.max())
        mx0, mx1 = int(mx.min()), int(mx.max())
        pad_x = max(24, int((mx1 - mx0) * 0.28))
        pad_y = max(24, int((my1 - my0) * 0.20))

        keep = np.zeros_like(fg_mask)
        for idx in range(1, num + 1):
            sz = float(sizes[idx - 1])
            if idx == main_idx:
                keep |= (lbl == idx)
            elif sz >= max(40.0, max_sz * keep_secondary_ratio):
                cy_i, cx_i = np.where(lbl == idx)
                cym, cxm = float(cy_i.mean()), float(cx_i.mean())
                if (mx0 - pad_x <= cxm <= mx1 + pad_x) and (my0 - pad_y <= cym <= my1 + pad_y):
                    keep |= (lbl == idx)
        fg_mask = keep

    # Compute smooth alpha along edges using color distance
    alpha = np.where(fg_mask, 255.0, 0.0).astype(np.float32)
    edge_band = ndimage.binary_dilation(visited, iterations=2) & fg_mask
    soft_alpha = np.clip((diff - (bg_thresh - 4.0)) / max(soft_band, 1.0), 0.0, 1.0) * 255.0
    alpha[edge_band] = np.minimum(alpha[edge_band], soft_alpha[edge_band])

    # Slight 0.6px blur on alpha for anti-aliased edge
    alpha_img = Image.fromarray(np.clip(alpha, 0, 255).astype(np.uint8), mode="L")
    alpha_img = alpha_img.filter(ImageFilter.GaussianBlur(radius=0.6))
    alpha_arr = np.array(alpha_img, dtype=np.uint8)

    # Clean dark/grey halo on semi-transparent fringe pixels
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    rgba[:, :, 3] = alpha_arr
    return Image.fromarray(rgba, mode="RGBA")


def trim_and_place(im: Image.Image, cell_size: int, fill_height: float = 0.88) -> Image.Image:
    """Crop tight to alpha bbox and center horizontally, foot-aligned near bottom."""
    bbox = im.getbbox()
    canvas = Image.new("RGBA", (cell_size, cell_size), (0, 0, 0, 0))
    if bbox is None:
        return canvas
    cropped = im.crop(bbox)
    cw, ch = cropped.size
    target_h = int(cell_size * fill_height)
    target_w = int(cell_size * 0.90)
    scale = min(target_w / max(1, cw), target_h / max(1, ch))
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    ox = (cell_size - nw) // 2
    oy = int(cell_size * 0.94) - nh
    oy = max(0, min(cell_size - nh, oy))
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def make_rear_3q_variant(back_img: Image.Image, turn_right: bool) -> Image.Image:
    """
    Create a subtle NE/NW rear-three-quarter pose from the clean BACK view
    without ever duplicating front facial features.
    """
    w, h = back_img.size
    # Slight horizontal perspective squash + gentle directional lean/shift
    shift_x = int(w * (0.02 if turn_right else -0.02))
    skew = -0.045 if turn_right else 0.045
    src = back_img if turn_right else back_img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    transformed = src.transform(
        (w, h),
        Image.Transform.AFFINE,
        (1.03, skew, -shift_x - skew * h * 0.5, 0.0, 1.0, 0.0),
        resample=Image.Resampling.BICUBIC,
    )
    return transformed


def build_8dir_strip(
    views: dict[str, Image.Image],
    front_3q_dir: str,
    side_dir: str,
    cell_size: int,
) -> Image.Image:
    """
    Build 8-column strip ordered in CharacterAnimationController octant order:
        0: e, 1: se, 2: s, 3: sw, 4: w, 5: nw, 6: n, 7: ne
    """
    front = trim_and_place(views["front"], cell_size)
    back = trim_and_place(views["back"], cell_size)

    f3q = trim_and_place(views["front_3q"], cell_size)
    if front_3q_dir == "left":
        sw = f3q
        se = f3q.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    else:
        se = f3q
        sw = f3q.transpose(Image.Transpose.FLIP_LEFT_RIGHT)

    side = trim_and_place(views["side"], cell_size)
    if side_dir == "left":
        w_img = side
        e_img = side.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    else:
        e_img = side
        w_img = side.transpose(Image.Transpose.FLIP_LEFT_RIGHT)

    n_img = back
    ne_img = make_rear_3q_variant(back, turn_right=True)
    nw_img = make_rear_3q_variant(back, turn_right=False)

    ordered = [e_img, se, front, sw, w_img, nw_img, n_img, ne_img]
    strip = Image.new("RGBA", (cell_size * 8, cell_size), (0, 0, 0, 0))
    for i, frame in enumerate(ordered):
        strip.paste(frame, (i * cell_size, 0), frame)
    return strip


def _row4_boxes(w: int, h: int, y0: int = 20, y1: int | None = None, splits: tuple[int, int, int] | None = None):
    if y1 is None:
        y1 = h - 20
    if splits is None:
        s1, s2, s3 = w // 4, w // 2, (3 * w) // 4
    else:
        s1, s2, s3 = splits
    return [
        (0, y0, s1, y1),
        (s1, y0, s2, y1),
        (s2, y0, s3, y1),
        (s3, y0, w, y1),
    ]


# Sheet specifications:
# layout="4col": order specifies which view is in columns 0..3
# layout="custom": boxes maps view_name -> (x0, y0, x1, y1)
SPECS: list[dict] = [
    # --- PLAYABLE HEROES (384x384 per cell -> 3072x384 strip) ---
    {
        "id": "soul_binder",
        "category": "character",
        "src": os.path.join(DRIVE, "main_characters", "summaner.jpg"),
        "cell_size": 384,
        "layout": "4col",
        "order": ["front", "side", "back", "front_3q"],
        "y0": 40,
        "y1": 640,
        "splits": (385, 690, 1005),
        "side_dir": "left",
        "front_3q_dir": "right",
        "bg_thresh": 18.0,
    },
    {
        "id": "shadow_hunter",
        "category": "character",
        "src": os.path.join(DRIVE, "main_characters", "assasin.jpg"),
        "cell_size": 384,
        "layout": "4col",
        "order": ["front", "side", "back", "front_3q"],
        "y0": 40,
        "y1": 640,
        "splits": (378, 678, 995),
        "side_dir": "left",
        "front_3q_dir": "right",
        "bg_thresh": 18.0,
    },
    {
        "id": "storm_reaper",
        "category": "character",
        "src": os.path.join(DRIVE, "main_characters", "knight.jpg"),
        "cell_size": 384,
        "layout": "4col",
        "order": ["front", "side", "back", "front_3q"],
        "y0": 80,
        "y1": 655,
        "splits": (395, 650, 995),
        "side_dir": "right",
        "front_3q_dir": "left",
        "bg_thresh": 18.0,
    },

    # --- FLOOR 1 ENEMIES & BOSS ---
    {
        "id": "f1_swarmer",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_1", "Crypt Skeleton.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 10,
        "y1": 715,
        "splits": (390, 755, 1005),
        "side_dir": "right",
        "front_3q_dir": "left",
        "excludes": {"front_3q": [(0, 0, 260, 120)]},
    },
    {
        "id": "f1_cultist",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_1", "Cursed Archer.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 60,
        "y1": 715,
        "splits": (385, 765, 1015),
        "side_dir": "left",
        "front_3q_dir": "left",
    },
    {
        "id": "f1_charger",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_1", "Grave Crawler.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 50,
        "y1": 710,
        "splits": (390, 755, 1015),
        "side_dir": "left",
        "front_3q_dir": "left",
        "excludes": {"front_3q": [(0, 0, 270, 100)]},
    },
    {
        "id": "f1_elite",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_1", "Crypt Guardian.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 65,
        "y1": 715,
        "splits": (395, 720, 1015),
        "side_dir": "left",
        "front_3q_dir": "left",
    },
    {
        "id": "boss_1",
        "category": "boss",
        "src": os.path.join(DRIVE, "monsters", "floor_1", "BOSS NAME Ancient Crypt Lord floor 1.jpg"),
        "cell_size": 384,
        "layout": "custom",
        "boxes": {
            "front_3q": (30, 20, 425, 456),
            "front": (440, 20, 760, 412),
            "side": (795, 20, 1020, 412),
            "back": (1035, 20, 1365, 412),
        },
        "side_dir": "left",
        "front_3q_dir": "left",
        "bg_thresh": 14.5,
    },

    # --- FLOOR 2 ENEMIES & BOSS ---
    {
        "id": "f2_swarmer",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_2", "Rootling.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 95,
        "y1": 670,
        "splits": (385, 730, 1020),
        "side_dir": "right",
        "front_3q_dir": "left",
    },
    {
        "id": "f2_cultist",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_2", "Corrupted Treant.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 50,
        "y1": 715,
        "splits": (385, 755, 1025),
        "side_dir": "right",
        "front_3q_dir": "left",
    },
    {
        "id": "f2_charger",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_2", "Venom Spider.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 80,
        "y1": 675,
        "splits": (385, 725, 1050),
        "side_dir": "left",
        "front_3q_dir": "left",
    },
    {
        "id": "f2_elite",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_2", "Floor 02 – Cursed Forest.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 60,
        "y1": 715,
        "splits": (385, 720, 1030),
        "side_dir": "right",
        "front_3q_dir": "left",
        "excludes": {"front_3q": [(0, 0, 140, 290)], "back": [(0, 0, 380, 45)]},
    },
    {
        "id": "boss_2",
        "category": "boss",
        "src": os.path.join(DRIVE, "monsters", "floor_2", "BOSS NAME Hollowwood Ancient floor 2.jpg"),
        "cell_size": 384,
        "layout": "custom",
        "boxes": {
            "front_3q": (12, 5, 445, 412),
            "front": (468, 5, 982, 412),
            "side": (1040, 5, 1396, 412),
            "back": (12, 405, 445, 765),
        },
        "side_dir": "left",
        "front_3q_dir": "left",
        "bg_thresh": 30.0,
    },

    # --- FLOOR 3 ENEMIES & BOSS ---
    {
        "id": "f3_swarmer",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_3", "Ember Imp.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 45,
        "y1": 700,
        "splits": (385, 720, 1030),
        "side_dir": "left",
        "front_3q_dir": "left",
    },
    {
        "id": "f3_cultist",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_3", "Flame Warlock.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 60,
        "y1": 715,
        "splits": (385, 725, 1035),
        "side_dir": "right",
        "front_3q_dir": "left",
        "excludes": {"front_3q": [(0, 0, 240, 100)]},
    },
    {
        "id": "f3_charger",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_3", "Magma Crawler.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 95,
        "y1": 700,
        "splits": (385, 745, 1025),
        "side_dir": "right",
        "front_3q_dir": "left",
    },
    {
        "id": "f3_elite",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_3", "Infernal Knight.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 75,
        "y1": 705,
        "splits": (405, 795, 1010),
        "side_dir": "left",
        "front_3q_dir": "left",
    },
    {
        "id": "boss_3",
        "category": "boss",
        "src": os.path.join(DRIVE, "monsters", "floor_3", "BOSS NAME Infernal Warden floor 3.jpg"),
        "cell_size": 384,
        "layout": "custom",
        "boxes": {
            "front_3q": (20, 30, 480, 505),
            "front": (480, 20, 912, 725),
            "side": (922, 375, 1125, 715),
            "back": (1128, 375, 1395, 715),
        },
        "side_dir": "right",
        "front_3q_dir": "right",
    },

    # --- FLOOR 4 ENEMIES & BOSS ---
    {
        "id": "f4_swarmer",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_4", "Frost Wraith.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 65,
        "y1": 710,
        "splits": (395, 735, 1020),
        "side_dir": "right",
        "front_3q_dir": "left",
        "excludes": {
            "front_3q": [(0, 0, 230, 80), (0, 80, 105, 290), (275, 80, 395, 290)],
            "front": [(240, 35, 340, 285)],
            "back": [(240, 110, 385, 250)],
        },
    },
    {
        "id": "f4_cultist",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_4", "Crystal Mage.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 65,
        "y1": 670,
        "splits": (365, 725, 1030),
        "side_dir": "right",
        "front_3q_dir": "left",
    },
    {
        "id": "f4_charger",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_4", "Ice Wolf.jpg"),
        "cell_size": 256,
        "layout": "custom",
        "boxes": {
            "front_3q": (45, 30, 455, 415),
            "front": (415, 315, 675, 695),
            "side": (700, 10, 1255, 360),
            "back": (1095, 325, 1390, 695),
        },
        "side_dir": "left",
        "front_3q_dir": "right",
    },
    {
        "id": "f4_elite",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_4", "Floor 04 – Frozen Abyss.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 65,
        "y1": 665,
        "splits": (375, 725, 1030),
        "side_dir": "right",
        "front_3q_dir": "left",
        "excludes": {"front_3q": [(0, 0, 230, 80)]},
    },
    {
        "id": "boss_4",
        "category": "boss",
        "src": os.path.join(DRIVE, "monsters", "floor_4", "BOSS NAME Glacial Monarch floor 4.jpg"),
        "cell_size": 384,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 45,
        "y1": 508,
        "splits": (345, 695, 1045),
        "side_dir": "left",
        "front_3q_dir": "left",
        "excludes": {"front_3q": [(0, 0, 210, 80)]},
    },

    # --- FLOOR 5 ENEMIES & BOSS ---
    {
        "id": "f5_swarmer",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_5", "Voidling.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 150,
        "y1": 690,
        "splits": (365, 695, 915),
        "side_dir": "right",
        "front_3q_dir": "left",
    },
    {
        "id": "f5_cultist",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_5", "Abyssal Mage.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 60,
        "y1": 668,
        "splits": (365, 695, 1035),
        "side_dir": "right",
        "front_3q_dir": "left",
        "excludes": {
            "front_3q": [(0, 0, 250, 90)],
            "side": [(0, 170, 90, 440)],
        },
    },
    {
        "id": "f5_charger",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_5", "Shadow Assassin.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 65,
        "y1": 670,
        "splits": (395, 735, 1015),
        "side_dir": "right",
        "front_3q_dir": "left",
        "excludes": {"front_3q": [(0, 0, 250, 90)]},
    },
    {
        "id": "f5_elite",
        "category": "enemy",
        "src": os.path.join(DRIVE, "monsters", "floor_5", "Fallen Champion.jpg"),
        "cell_size": 256,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 55,
        "y1": 695,
        "splits": (385, 745, 1045),
        "side_dir": "right",
        "front_3q_dir": "left",
        "excludes": {
            "front_3q": [(0, 0, 210, 58)],
            "side": [(215, 200, 300, 620)],
            "back": [(0, 200, 45, 620)],
        },
    },
    {
        "id": "boss_5",
        "category": "boss",
        "src": os.path.join(DRIVE, "monsters", "floor_5", "BOSS NAME Abyssal Sovereign floor 5.jpg"),
        "cell_size": 384,
        "layout": "4col",
        "order": ["front_3q", "front", "side", "back"],
        "y0": 15,
        "y1": 498,
        "splits": (345, 725, 1005),
        "side_dir": "left",
        "front_3q_dir": "left",
        "bg_thresh": 18.0,
        "excludes": {
            "side": [(0, 0, 50, 310), (195, 0, 280, 310)],
            "back": [(0, 0, 35, 340)],
        },
    },
]


def process_actors() -> None:
    for spec in SPECS:
        src_path = spec["src"]
        if not os.path.exists(src_path):
            raise FileNotFoundError(src_path)
        im = Image.open(src_path).convert("RGB")
        w, h = im.size
        arr = np.array(im)

        views: dict[str, Image.Image] = {}
        excludes = spec.get("excludes", {})
        bg_thresh = float(spec.get("bg_thresh", 19.0))

        if spec["layout"] == "4col":
            boxes = _row4_boxes(w, h, spec.get("y0", 20), spec.get("y1"), spec.get("splits"))
            for view_name, (x0, y0, x1, y1) in zip(spec["order"], boxes):
                crop = arr[y0:y1, x0:x1]
                views[view_name] = extract_foreground_rgba(
                    crop, exclude_rects=excludes.get(view_name), bg_thresh=bg_thresh
                )
        else:
            for view_name, (x0, y0, x1, y1) in spec["boxes"].items():
                crop = arr[y0:y1, x0:x1]
                views[view_name] = extract_foreground_rgba(
                    crop, exclude_rects=excludes.get(view_name), bg_thresh=bg_thresh
                )

        cell_size = int(spec["cell_size"])
        strip = build_8dir_strip(
            views,
            front_3q_dir=spec["front_3q_dir"],
            side_dir=spec["side_dir"],
            cell_size=cell_size,
        )

        cat = spec["category"]
        actor_id = spec["id"]
        if cat == "character":
            out_path = os.path.join(OUT_CHAR_8DIR, f"{actor_id}_8dir.png")
            strip.save(out_path)
            # Also save crisp front showcase & portrait cutouts for UI
            front_cut = trim_and_place(views["front"], 512, fill_height=0.90)
            front_cut.save(os.path.join(OUT_CHAR_ROOT, f"{actor_id}_portrait.png"))
            if actor_id == "soul_binder":
                front_cut.save(os.path.join(OUT_CHAR_ROOT, "hero_soul_binder_front.png"))
                front_cut.save(os.path.join(OUT_CHAR_ROOT, "hero_soul_binder_showcase.png"))
                tq_cut = trim_and_place(views["front_3q"], 512, fill_height=0.90)
                tq_cut.save(os.path.join(OUT_CHAR_ROOT, "hero_soul_binder_tq.png"))
        elif cat == "enemy":
            out_path = os.path.join(OUT_ENEMY_8DIR, f"{actor_id}_8dir.png")
            strip.save(out_path)
        else:
            out_path = os.path.join(OUT_BOSS_8DIR, f"{actor_id}_8dir.png")
            strip.save(out_path)
        print(f"[8DIR] {actor_id} -> {os.path.relpath(out_path, ROOT)} ({strip.size[0]}x{strip.size[1]})")


def _fit_cover_720x1280(im: Image.Image, crop_top_frac: float = 0.0, crop_bottom_frac: float = 1.0) -> Image.Image:
    w, h = im.size
    y0 = int(h * crop_top_frac)
    y1 = int(h * crop_bottom_frac)
    cropped = im.crop((0, y0, w, y1))
    cw, ch = cropped.size
    target_w, target_h = 720, 1280
    scale = max(target_w / cw, target_h / ch)
    nw, nh = int(round(cw * scale)), int(round(ch * scale))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    ox = (nw - target_w) // 2
    oy = (nh - target_h) // 2
    return resized.crop((ox, oy, ox + target_w, oy + target_h))


def _remove_top_left_badge(im: Image.Image, badge_w: int = 720, badge_h: int = 230) -> Image.Image:
    """Inpaint/blend out the corner UI badge on wide landscape concept art before portrait crop."""
    arr = np.array(im.convert("RGB"), dtype=np.float32)
    h, w, _ = arr.shape
    bw = min(badge_w, w - 1)
    bh = min(badge_h, h - 1)
    # Sample dark smoky backdrop right below & right of the badge
    right_strip = arr[:bh, bw:min(w, bw + 60), :]
    bottom_strip = arr[bh:min(h, bh + 50), :bw, :]
    fill_col = np.median(
        np.concatenate([right_strip.reshape(-1, 3), bottom_strip.reshape(-1, 3)], axis=0),
        axis=0,
    )
    arr[:bh, :bw, :] = fill_col
    patched = Image.fromarray(arr.astype(np.uint8), mode="RGB")
    # Soft feather over the boundary
    blur = patched.filter(ImageFilter.GaussianBlur(radius=18))
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.rectangle([0, 0, bw + 12, bh + 12], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=16))
    return Image.composite(blur, patched, mask)


def build_floor_environments() -> None:
    floor_sources = [
        (1, os.path.join(DRIVE, "environments", "FORGOTTEN_CRYPT_arena_1.jpg"), 0.0, 1.0, True, (110, 65, 220)),
        (2, os.path.join(DRIVE, "environments", "CURSED_FOREST_arena.jpg"), 0.09, 1.0, False, (55, 215, 115)),
        (3, os.path.join(DRIVE, "monsters", "floor_3", "INFERNAL FORGE.jpg"), 0.0, 1.0, False, (255, 110, 35)),
        (4, os.path.join(DRIVE, "monsters", "floor_4", "FROZEN ABYSS.jpg"), 0.0, 1.0, False, (70, 205, 255)),
        (5, os.path.join(DRIVE, "monsters", "floor_2", "ABYSSAL TEMPLE.jpg"), 0.045, 1.0, False, (195, 70, 255)),
    ]

    for fn, src_path, top_f, bot_f, strip_badge, accent_rgb in floor_sources:
        im = Image.open(src_path).convert("RGB")
        if strip_badge:
            im = _remove_top_left_badge(im, badge_w=780, badge_h=240)
        arena = _fit_cover_720x1280(im, crop_top_frac=top_f, crop_bottom_frac=bot_f)

        # 1. background: slightly dimmed/blurred outer depth atmosphere
        bg = ImageEnhance.Brightness(arena).enhance(0.75).convert("RGBA")
        bg.save(os.path.join(OUT_FLOORS, f"floor_{fn}_background.png"))

        # 2. floor: crisp arena surface with subtle center playability balance
        fl = arena.convert("RGBA")
        fl.save(os.path.join(OUT_FLOORS, f"floor_{fn}_floor.png"))

        # 3. props: soft ambient corner braziers / rune ring highlights (transparent RGBA)
        props = Image.new("RGBA", (720, 1280), (0, 0, 0, 0))
        d_pr = ImageDraw.Draw(props)
        cx, cy = 360, 640
        d_pr.ellipse([cx - 190, cy - 190, cx + 190, cy + 190], outline=(*accent_rgb, 65), width=3)
        for corner in [(72, 112), (648, 112), (72, 1110), (648, 1110)]:
            for r in range(52, 8, -8):
                a = int(34 * (1.0 - r / 56.0))
                d_pr.ellipse([corner[0] - r, corner[1] - r, corner[0] + r, corner[1] + r], fill=(*accent_rgb, a))
        props = props.filter(ImageFilter.GaussianBlur(radius=3))
        props.save(os.path.join(OUT_FLOORS, f"floor_{fn}_props.png"))

        # 4. foreground: cinematic dark vignette framing the 720x1280 viewport
        fg = Image.new("RGBA", (720, 1280), (0, 0, 0, 0))
        yy, xx = np.mgrid[0:1280, 0:720]
        nx = (xx - 360.0) / 360.0
        ny = (yy - 640.0) / 640.0
        dist = np.sqrt(nx * nx + ny * ny)
        vig_alpha = np.clip((dist - 0.72) / 0.55, 0.0, 1.0) ** 1.6 * 150.0
        fg_arr = np.zeros((1280, 720, 4), dtype=np.uint8)
        fg_arr[:, :, 3] = vig_alpha.astype(np.uint8)
        fg = Image.fromarray(fg_arr, mode="RGBA")
        fg.save(os.path.join(OUT_FLOORS, f"floor_{fn}_foreground.png"))

        print(f"[FLOOR] Floor {fn} 4-layer 720x1280 written from {os.path.basename(src_path)}")


if __name__ == "__main__":
    process_actors()
    build_floor_environments()
    print("ALL_8DIR_AND_FLOOR_ASSETS_READY")
