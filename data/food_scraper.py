import argparse
import hashlib
import time
from pathlib import Path

from icrawler.builtin import BingImageCrawler


TARGET_IMAGES = 600
MAX_PER_KEYWORD = 140
SLEEP_SECONDS = 2
RESET_FOLDERS = False
MAX_ROUNDS = 4
VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
NEGATIVE_TERMS = "-logo -menu -ingredients -raw -packaging -vector -drawing"
UNLINK_RETRIES = 6
UNLINK_SLEEP_SECONDS = 0.35

SCRAPE_EXISTING_DISHES = False

EXISTING_DISHES = {
    "fricasse_tunisien": [
        "plat fricasse tunisien",
        "assiette fricasse tunisien",
        "fricassé tunisien plat",
        "fricassé tunisien assiette",
        "plat fricassé tunisien traditionnel",
        "فريكاسي تونسي طبق",
        "فريكاسي تونسي في صحن",
        "طبق فريكاسي تونسي",
        "tunisian fricasse dish",
        "tunisian fricasse plate",
        "traditional fricasse plate",
    ],
    "makroudh": [
        "plat makroudh tunisien",
        "assiette makroudh tunisien",
        "makroudh tunisien en assiette",
        "plat makroud tunisien traditionnel",
        "مقروض تونسي طبق",
        "مقروض تونسي في صحن",
        "طبق مقروض تونسي",
        "tunisian makroudh dish",
        "tunisian makroudh plate",
        "traditional makroudh plate",
    ],
    "mloukhia_tunisienne": [
        "mloukhia tunisienne",
        "plat mloukhia tunisienne",
        "assiette mloukhia tunisienne",
        "mloukhia tunisienne plat traditionnel",
        "plat de mloukhia tunisienne",
        "ملوخية تونسية طبق",
        "ملوخية تونسية في صحن",
        "طبق ملوخية تونسية",
        "tunisian mloukhia dish",
        "tunisian mloukhia plate",
    ],
    "lablabi": [
        "plat lablabi",
        "assiette lablabi tunisien",
        "lablabi tunisien plat",
        "plat lablabi tunisien traditionnel",
        "لبلابي تونسي طبق",
        "لبلابي تونسي في صحن",
        "طبق لبلابي تونسي",
        "tunisian lablabi dish",
        "tunisian lablabi plate",
        "traditional lablabi plate",
    ],
    "brik_oeuf": [
        "plat brik a l oeuf tunisien",
        "assiette brik a l oeuf",
        "brik a l'oeuf tunisien plat",
        "brik tunisienne a l'oeuf assiette",
        "بريك تونسي بالبيض طبق",
        "بريك بالبيض في صحن",
        "طبق بريك تونسي بالبيض",
        "tunisian brik egg dish",
        "tunisian brik egg plate",
        "traditional brik egg plate",
    ],
    "chapati_tunisien": [
        "plat chapati tunisien",
        "assiette chapati tunisien",
        "chapati tunisien plat",
        "chapati tunisien en assiette",
        "شاباتي تونسي طبق",
        "شاباتي تونسي في صحن",
        "طبق شاباتي تونسي",
        "tunisian chapati dish",
        "tunisian chapati plate",
        "traditional chapati plate",
    ],
    "chakchouka": [
        "chakchouka tunisienne",
        "plat chakchouka tunisienne",
        "assiette chakchouka",
        "chakchouka tunisienne traditionnelle",
        "shakshuka tunisian style",
        "شاكشوكة تونسية",
        "شاكشوكة تونسية طبق",
        "طبق شاكشوكة تونسية",
        "tunisian chakchouka dish",
        "tunisian chakchouka plate",
    ],
    "couscous": [
        "couscous tunisien",
        "couscous tunisien au poisson",
        "couscous tunisien au poulet",
        "plat couscous tunisien",
        "assiette couscous tunisien",
        "كسكسي تونسي",
        "كسكسي تونسي طبق",
        "طبق كسكسي تونسي",
        "tunisian couscous dish",
        "tunisian couscous plate",
    ],
    "kafteji": [
        "kafteji tunisien",
        "kafteji tunisien plat",
        "assiette kafteji",
        "kafteji tunisien traditionnel",
        "كفتاجي تونسي",
        "كفتاجي تونسي طبق",
        "طبق كفتاجي تونسي",
        "tunisian kafteji dish",
        "tunisian kafteji plate",
        "traditional kafteji",
    ],
    "mlawi": [
        "mlawi tunisien",
        "mlawi tunisien sandwich",
        "mlawi tunisien farci",
        "assiette mlawi",
        "plat mlawi tunisien",
        "ملوي تونسي",
        "ملوي تونسي في صحن",
        "طبق ملوي تونسي",
        "tunisian mlawi",
        "tunisian mtabga mlawi",
    ],
}

NEW_DISHES = {
    "ojja_merguez": [
        "ojja merguez tunisienne",
        "plat ojja merguez tunisienne",
        "assiette ojja merguez",
        "ojja merguez tunisienne plat traditionnel",
        "عجة مرقاز تونسية",
        "عجة مرقاز طبق",
        "طبق عجة مرقاز تونسية",
        "tunisian ojja merguez dish",
        "tunisian ojja merguez plate",
        "traditional ojja merguez",
    ],
    "salade_mechouia": [
        "salade mechouia tunisienne",
        "assiette salade mechouia",
        "salade mechouia tunisienne en assiette",
        "salade mechouia tunisienne traditionnelle",
        "سلطة مشوية تونسية",
        "سلطة مشوية في صحن",
        "طبق سلطة مشوية تونسية",
        "tunisian mechouia salad",
        "tunisian mechouia salad plate",
        "traditional tunisian mechouia",
    ],
    "tajine_tunisien": [
        "tajine tunisien",
        "tajine tunisien au four",
        "plat tajine tunisien",
        "assiette tajine tunisien",
        "tajine tunisien aux oeufs",
        "طاجين تونسي",
        "طاجين تونسي طبق",
        "طبق طاجين تونسي",
        "tunisian tajine dish",
        "tunisian tajine casserole",
    ],
    "chorba_frik": [
        "chorba frik tunisienne",
        "chorba frik tunisienne plat",
        "assiette chorba frik",
        "chorba frik tunisienne traditionnelle",
        "شربة فريك تونسية",
        "شربة فريك في صحن",
        "طبق شربة فريك تونسية",
        "tunisian chorba frik soup",
        "tunisian frik soup bowl",
        "traditional chorba frik",
    ],
    "kabkabou": [
        "kabkabou tunisien",
        "kabkabou poisson tunisien",
        "plat kabkabou tunisien",
        "assiette kabkabou tunisien",
        "كابكابو تونسي",
        "كابكابو تونسي طبق",
        "طبق كابكابو تونسي",
        "tunisian kabkabou fish stew",
        "tunisian kabkabou dish",
        "traditional kabkabou",
    ],
    "marqa_jelbana": [
        "marqa jelbana tunisienne",
        "marqa jelbana tunisienne plat",
        "assiette marqa jelbana",
        "marqa jelbana tunisienne traditionnelle",
        "مرقة جلبانة تونسية",
        "مرقة جلبانة في صحن",
        "طبق مرقة جلبانة تونسية",
        "tunisian peas stew",
        "tunisian marqa jelbana dish",
        "traditional tunisian peas stew",
    ],
    "rouz_jerbi": [
        "rouz jerbi tunisien",
        "riz djerbien tunisien",
        "plat rouz jerbi",
        "assiette riz djerbien",
        "rouz jerbi tunisien plat traditionnel",
        "رز جربي تونسي",
        "رز جربي في صحن",
        "طبق رز جربي تونسي",
        "tunisian djerbian rice",
        "djerbian rice plate",
    ],
    "bambalouni": [
        "bambalouni tunisien",
        "bambalouni tunisien sucre",
        "bambalouni tunisien beignet",
        "bambalouni tunisien street food",
        "بمبالوني تونسي",
        "بمبالوني في صحن",
        "طبق بمبالوني تونسي",
        "tunisian bambalouni doughnut",
        "tunisian bambalouni donut",
        "traditional bambalouni tunisian",
    ],
    "kaak_warka": [
        "kaak warka tunisien",
        "kaak el warka tunisien",
        "plat kaak warka tunisien",
        "assiette kaak warka",
        "كعك الورقة تونسي",
        "كعك الورقة في صحن",
        "طبق كعك الورقة تونسي",
        "tunisian kaak warka",
        "tunisian almond pastry kaak",
        "traditional kaak warka",
    ],
    "assida_zgougou": [
        "assida zgougou tunisienne",
        "assida zgougou tunisienne moulid",
        "assida zgougou plat",
        "assiette assida zgougou",
        "عصيدة الزقوقو تونسية",
        "عصيدة الزقوقو في صحن",
        "طبق عصيدة الزقوقو تونسية",
        "tunisian assida zgougou",
        "tunisian zgougou pudding",
        "traditional assida zgougou",
    ],
}

DISHES_TO_SCRAPE = (
    {**EXISTING_DISHES, **NEW_DISHES} if SCRAPE_EXISTING_DISHES else NEW_DISHES
)


def get_image_files(folder: Path):
    return sorted(
        [
            path
            for path in folder.iterdir()
            if path.is_file() and path.suffix.lower() in VALID_EXTENSIONS
        ]
    )


def file_sha256(file_path: Path) -> str:
    hasher = hashlib.sha256()
    with file_path.open("rb") as file:
        for chunk in iter(lambda: file.read(8192), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def safe_unlink(file_path: Path) -> bool:
    for attempt in range(UNLINK_RETRIES):
        try:
            file_path.unlink()
            return True
        except FileNotFoundError:
            return True
        except PermissionError:
            if attempt < UNLINK_RETRIES - 1:
                time.sleep(UNLINK_SLEEP_SECONDS)
                continue
            return False
        except OSError:
            if attempt < UNLINK_RETRIES - 1:
                time.sleep(UNLINK_SLEEP_SECONDS)
                continue
            return False


def remove_duplicate_images(folder: Path) -> int:
    seen_hashes = {}
    removed_count = 0

    for file_path in get_image_files(folder):
        try:
            image_hash = file_sha256(file_path)
        except (FileNotFoundError, PermissionError, OSError):
            continue
        if image_hash in seen_hashes:
            if safe_unlink(file_path):
                removed_count += 1
        else:
            seen_hashes[image_hash] = file_path

    return removed_count


def trim_to_target(folder: Path, target_count: int) -> int:
    images = get_image_files(folder)
    if len(images) <= target_count:
        return 0

    removed_count = 0
    for file_path in images[target_count:]:
        if safe_unlink(file_path):
            removed_count += 1

    return removed_count


def clear_images(folder: Path) -> None:
    for file_path in get_image_files(folder):
        safe_unlink(file_path)


def build_round_keywords(base_keywords: list[str], round_idx: int) -> list[str]:
    if round_idx == 0:
        return base_keywords
    if round_idx == 1:
        return [f"{kw} food photo" for kw in base_keywords]
    if round_idx == 2:
        return [f"{kw} close up" for kw in base_keywords]
    return [f"{kw} top view" for kw in base_keywords]


def scrape_dish(base_data_path: Path, folder_name: str, keywords: list[str]) -> None:
    dish_path = base_data_path / folder_name
    dish_path.mkdir(parents=True, exist_ok=True)

    existing_count = len(get_image_files(dish_path))
    if not RESET_FOLDERS and existing_count >= TARGET_IMAGES:
        print(
            f"\n=== Skipping: {folder_name} === "
            f"(already has {existing_count}/{TARGET_IMAGES} images)"
        )
        return

    if RESET_FOLDERS:
        clear_images(dish_path)

    crawler = BingImageCrawler(storage={"root_dir": str(dish_path)}, downloader_threads=2)
    offset = len(get_image_files(dish_path))

    print(f"\n=== Scraping: {folder_name} ===")

    for round_idx in range(MAX_ROUNDS):
        current_count = len(get_image_files(dish_path))
        if current_count >= TARGET_IMAGES:
            break

        round_keywords = build_round_keywords(keywords, round_idx)
        print(f"Round {round_idx + 1}/{MAX_ROUNDS} | current={current_count}")

        for keyword in round_keywords:
            current_count = len(get_image_files(dish_path))
            if current_count >= TARGET_IMAGES:
                break

            remaining = TARGET_IMAGES - current_count
            max_num = min(MAX_PER_KEYWORD, remaining + 60)

            strict_keyword = f"{keyword} {NEGATIVE_TERMS}"
            print(f"Keyword: {strict_keyword} | max_num={max_num}")
            crawler.crawl(keyword=strict_keyword, max_num=max_num, file_idx_offset=offset)
            offset += max_num
            time.sleep(SLEEP_SECONDS)

            removed_now = remove_duplicate_images(dish_path)
            if removed_now > 0:
                print(f"Duplicates removed in-round: {removed_now}")

    removed_duplicates = remove_duplicate_images(dish_path)
    removed_extra = trim_to_target(dish_path, TARGET_IMAGES)
    final_count = len(get_image_files(dish_path))

    print(
        f"Result {folder_name}: {final_count} images | "
        f"duplicates removed={removed_duplicates} | extra removed={removed_extra}"
    )

    if final_count < TARGET_IMAGES:
        print(f"Warning: only {final_count}/{TARGET_IMAGES} images found for {folder_name}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Collect food images into class folders.")
    parser.add_argument("--data-path", type=Path, default=Path(__file__).resolve().parents[1] / "datasets" / "tunisian")
    data_path = parser.parse_args().data_path.expanduser()
    data_path.mkdir(parents=True, exist_ok=True)

    for folder_name, keywords in DISHES_TO_SCRAPE.items():
        scrape_dish(data_path, folder_name, keywords)

    total = 0
    for folder_name in DISHES_TO_SCRAPE:
        count = len(get_image_files(data_path / folder_name))
        total += count
        print(f"{folder_name}: {count}/{TARGET_IMAGES}")

    print(f"\nDone. Total images: {total}/{TARGET_IMAGES * len(DISHES_TO_SCRAPE)}")


if __name__ == "__main__":
    main()
