---
name: ugc-image-gen
description: >-
  AI 느낌 없는 UGC(BeReal/인스타 스토리) 톤 이미지를 gpt-image-2로 생성한다.
  "친구폰 캔디드 스냅" 톤이 핵심 — 광고티를 지우고 진짜 인증샷처럼 보이게.
  "UGC 이미지 만들어줘", "인스타 스냅 느낌으로", "광고티 없애줘", "BeReal 톤",
  "AI느낌 없애줘", "/ugc-image-gen" 요청에 사용.
allowed-tools: Bash, Read, Write
---

# ugc-image-gen — AI틱 없는 UGC 톤 이미지 생성

## 왜 이 스킬이 필요한가

일반적인 AI 이미지 생성(`photorealistic documentary photo` / `soft flat illustration`)은
광고·마케팅 소재로 쓸 때 "AI가 만든 티"가 나서 젠지 타겟에게 광고임이 바로 보인다.

**"친구폰 BeReal 톤(자연광·imperfect framing·정면응시 회피)이 AI티를 죽인다"** — 실증된 핵심 인사이트.

---

## AI티 제거 6가지 규칙

| 문제 | 해법 |
|---|---|
| 얼굴이 정면·또렷 → AI티↑ | `face three-quarter not straight at camera` |
| 조명이 깔끔 → 스튜디오 티 | `natural daylight, NO studio lighting` |
| 프레임이 완벽 → 광고 티 | `slightly imperfect and spontaneous framing` |
| "professional ad shoot" 느낌 | `NOT a professional ad shoot, looks real and unpolished` |
| 인물이 모델처럼 → 연출 티 | `ordinary relatable person, NOT a celebrity, generic face` |
| 배경이 너무 예쁨 → 연출 티 | `candid, un-posed and a little messy` |

---

## 프롬프트 템플릿

### UGC 공통 스템
```
casual smartphone snapshot candidly taken by a friend [or: by herself / in the passenger seat],
vertical 9:16 phone photo, slightly imperfect and spontaneous framing,
natural daylight with NO studio lighting,
authentic Instagram-story / BeReal aesthetic,
mild phone-camera look and grain, un-posed and a little messy,
NOT a professional ad shoot, looks real and unpolished like a friend just snapped it,
Korean [woman/man] in [her/his] early 20s, ordinary relatable person, NOT a celebrity, generic face,
generous empty space at the TOP for text overlay,
face natural three-quarter not straight at camera.
```

### Subject 슬롯 (피사체 기술, 여기만 바꾸면 됨)
```
[피사체 상황 묘사]
예) in the driver's seat of a NORMAL hard-top sedan (steering wheel on the LEFT),
    summer sunglasses, relaxed confident posture, one hand on the wheel,
    window down with sunny summer street bokeh. Closed-roof sedan, not a convertible.
```

**전체 프롬프트 = UGC 스템 + "Subject: " + Subject 슬롯**

---

## 실행 — 환경 자동 감지

```bash
# Python 경로 (hermes venv 우선, 없으면 시스템 python3)
if [ -f ~/.hermes/hermes-agent/venv/bin/python3 ]; then
  PY=~/.hermes/hermes-agent/venv/bin/python3
else
  PY=python3
fi

# 스크립트 경로 (hermes 스킬 우선, 없으면 /tmp에 즉석 생성)
if [ -f ~/.hermes/skills/creative/dt-image-gen/scripts/gen_image.py ]; then
  SK=~/.hermes/skills/creative/dt-image-gen/scripts/gen_image.py
else
  SK=/tmp/ugc_gen_image.py
  # hermes 없는 환경: Claude가 Write 도구로 아래 스크립트를 /tmp/ugc_gen_image.py에 즉석 생성
fi

# API 키: ~/.hermes/.env의 OPENAI_API_KEY 또는 환경변수 OPENAI_API_KEY 자동 탐지
```

**hermes 없는 환경의 gen_image.py (즉석 생성용):**
```python
#!/usr/bin/env python3
import os, sys, base64, json, argparse, urllib.request, pathlib

def load_key():
    for path in (os.path.expanduser("~/.hermes/.env"),):
        if os.path.exists(path):
            for line in open(path):
                if line.startswith("OPENAI_API_KEY="):
                    return line.strip().split("=", 1)[1].strip().strip('"').strip("'")
    k = os.environ.get("OPENAI_API_KEY")
    if k: return k
    sys.exit("OPENAI_API_KEY 없음 (~/.hermes/.env 또는 환경변수로 설정)")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prompt")
    ap.add_argument("--out", default=None)
    ap.add_argument("--size", default="1024x1536")
    ap.add_argument("--quality", default="high", choices=["high", "medium", "low", "auto"])
    ap.add_argument("--n", type=int, default=1)
    ap.add_argument("--model", default="gpt-image-2")
    args = ap.parse_args()

    key = load_key()
    out = pathlib.Path(args.out) if args.out else pathlib.Path("/tmp/ugc-image.png")
    out.parent.mkdir(parents=True, exist_ok=True)

    body = json.dumps({"model": args.model, "prompt": args.prompt,
                       "size": args.size, "quality": args.quality, "n": args.n}).encode()
    req = urllib.request.Request(
        "https://api.openai.com/v1/images/generations", data=body,
        headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as r:
        data = json.load(r)
    b64 = data["data"][0]["b64_json"]
    out.write_bytes(base64.b64decode(b64))
    print(f"저장: {out}")

if __name__ == "__main__":
    main()
```

**실행 예시:**
```bash
PROMPT="$UGC_STEM Subject: $MY_SUBJECT"
"$PY" "$SK" "$PROMPT" --out ./output/hero.png --size 1024x1536 --quality high
```

---

## 사용 흐름

1. Subject 슬롯에 피사체 상황 기술 (한 줄~세 줄)
2. UGC 스템 + Subject 합쳐서 실행
3. `--quality medium` 으로 빠르게 탐색 → 맘에 들면 `--quality high` 로 최종
4. 결과 PNG를 Read 도구로 열어 AI티 여부 눈검증
5. **AI티 잔존 시 추가 주문**: `face partially hidden by hair/sunglasses` / `messier framing` / `camera slightly tilted`

---

## 비포·애프터 한 쌍 만들기

같은 구도에서 표정·자세만 교체하면 Before→After 광고 서사가 완성된다:

- **Before (긴장·두려움)**: `tense expression, stiff shoulders, gripping tightly, uncertain`
- **After (자신감·여유)**: `relaxed easy confident posture, subtle smile, owning the moment`

UGC 스템은 동일하게 유지, Subject만 Before/After로 교체.

---

## 주의

- OpenAI 크레딧 과금 (이미지당 수 센트). 대량 생성 전 사용자에게 고지.
- `gpt-image-2` 기준 `--quality high` = 장당 약 1~2분 소요.
- 탐색은 `--quality medium`, 최종본은 `--quality high` 권장.
