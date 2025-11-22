import re
import json
import argparse
from typing import Dict

import pytesseract
from pdf2image import convert_from_path

def pdf_to_text(pdf_path: str, dpi: int = 300) -> str:
    """Convert all pages of a PDF to text using Tesseract (kor+eng)."""
    images = convert_from_path(pdf_path, dpi=dpi)
    texts = []
    for img in images:
        txt = pytesseract.image_to_string(img, lang="kor+eng")
        texts.append(txt)
    return "\n".join(texts)

def extract_fields(text: str) -> Dict[str, str | None]:
    """
    재학증명서 OCR 결과에서 주요 필드 추출 (단국대 양식 기준, 라벨 일부 깨지는 경우까지 고려).
    반환 값은 dict 형태.
    """

    def search(pattern: str, flags: int = 0):
        m = re.search(pattern, text, flags)
        return m.group(1).strip() if m else None

    # 1) 주민등록번호: 6자리-7자리, 하이픈은 -, — 등 다양한 문자 허용, 마스킹(*, #) 허용
    rrn = search(
        r"주민등록번호\s*[:：]?\s*([0-9]{6}\s*[-\-\—]\s*[0-9*#]{7,})"
    )
    if not rrn:
        rrn = search(r"([0-9]{6}\s*[-\-\—]\s*[0-9*#]{7,})")


    # 2) 입학일자: '입학일자 : 2022년 03월 01일' 우선, 없으면 YYYY년 MM월 DD일 중 첫 번째
    admission_date = search(
        r"입\s*학\s*일\s*자\s*[:：]?\s*([0-9]{4}년\s*[0-9]{2}월\s*[0-9]{2}일)"
    )
    if not admission_date:
        admission_date = search(
            r"([0-9]{4}년\s*[0-9]{2}월\s*[0-9]{2}일)"
        )

    # 3) 학교명: 텍스트에 '단국대학교'가 있으면 그대로 사용
    school_name = "단국대학교" if "단국대학교" in text else None

    return {
        "resident_reg_no": rrn,
        "admission_date": admission_date,
        "school_name": school_name,
    }


def run_local_ocr(pdf_path: str) -> Dict[str, object]:
    """
    전체 파이프라인:
      PDF -> (이미지들) -> Tesseract OCR -> raw text -> 필드 추출
    반환:
      {
        "fields": {...},   # 추출된 주요 필드
        "raw_text": "..."  # OCR 전체 텍스트
      }
    """
    raw_text = pdf_to_text(pdf_path)
    fields = extract_fields(raw_text)
    return {"fields": fields, "raw_text": raw_text}


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Local OCR for Dankook Univ. enrollment certificate (PDF)."
    )
    parser.add_argument("pdf", help="Path to input PDF file")
    parser.add_argument(
        "--show-raw",
        action="store_true",
        help="Also print raw OCR text to stderr for debugging",
    )
    args = parser.parse_args()

    result = run_local_ocr(args.pdf)

    # JSON 형식으로 필드 출력
    print(json.dumps(result["fields"], ensure_ascii=False, indent=2))

    if args.show_raw:
        import sys

        sys.stderr.write("\n===== RAW OCR TEXT =====\n")
        sys.stderr.write(result["raw_text"])
        sys.stderr.write("\n")


if __name__ == "__main__":
    main()
