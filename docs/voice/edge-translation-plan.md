# Edge translation plan

How “They speak” and “I ask” work on the Asha phone, why spoken lines are weaker than typed English, and how to raise accuracy and speed without leaving the device.

The phone this plan is written for is the connected Redmi `21091116AI` (model `evergo`, Android 13, arm64). The code runs speech and translation on CPU with 2 threads. No latency number in this note was measured on that phone. The first engineering task is to record those numbers.

## What the worker does

Two directions. Neither one sets the triage colour.

1. **They speak.** The family talks. The phone writes what it heard, translates that into English, and can read the English aloud.
2. **I ask.** The worker types English. The phone translates into the family’s language. If that language is Hindi and auto-speak is on, a Hindi voice reads it. Bengali, Marathi, Tamil, Telugu, Gujarati, Punjabi, and Odia stay on the screen. Kannada and Malayalam can be typed into, not heard. Assamese is an app language but is not in this translation list.

The screen is `LanguageBridgeScreen`, which opens `HomePage` in `mobile/lib/core/bhasha/home_page.dart`.

## Full flow

```
They speak
  mic (WAV)
    -> Dolphin CTC int8          SpeechEngine.transcribe
    -> strip a leading <hi> tag  cleanHeardText
    -> IndicTrans2 indic→en int8 translateOnPhone
         glossary swap, script normalize, greedy decode, max 128 tokens
    -> English on screen
    -> Piper en_US if auto-speak is on

I ask
  English typed by the worker
    -> IndicTrans2 en→indic int8  translateEnglishOnPhone
         shield a few phrases the model mangles, then put them back
    -> text in the family script
    -> Piper hi_IN only when the language is Hindi
```

Each call loads one model and frees it before the next, so the hearing model and the translator are not in RAM together (`SpeechEngine`, `IndicTranslator`). That protects a 4–6 GB phone and adds a load cost on every sentence.

### Packs on disk

Downloaded once by `ModelStore` into app documents.

| Pack | Role | Approx size | Languages |
| --- | --- | --- | --- |
| `mt/` IndicTrans2 indic→en distilled 200M INT8 | They speak, text | ~260 MB of ONNX plus tokenizers | 10 Indic languages into English |
| `asr/` Dolphin base CTC multi-lang INT8 | They speak, hearing | ~99 MB | hi, mr, bn, ta, te, gu, pa, or, and others. Not kn, ml |
| `tts/` Piper English | Read the English | medium VITS | English only |
| `mt-en/` IndicTrans2 en→indic distilled 200M INT8 | I ask | ~310 MB | English into the same 10 |
| `tts-hi/` Piper Hindi | Read Hindi answers | ~21 MB | Hindi only |

“I ask” is a second download, about 300 MB, the first time it is used.

The 12 app languages and this pack are not the same list. The shell can show Assamese. This pack cannot translate Assamese, and it cannot hear Kannada or Malayalam.

## Why speech is worse than typing

The translation model was trained on **written** sentences. The hearing model was trained on **cleaner, more standard** speech across many languages, not on one district’s way of talking.

What the family actually says:

- Mixed language. “Baby ko fever hai, ORS dena hai” in one breath.
- A dialect or a village register, not the textbook sentence the model saw.
- Short, soft, noisy audio. The phone is outdoors. The clip must be at least ~800 bytes or the app throws it away.
- English medical words said inside an Indic sentence: BP, ORS, fever, tablet, ANC.

Dolphin then does three things that hurt the next step:

- It is one model for many languages. The app does **not** tell it “this clip is Bengali”. A Marathi sentence can come back as Hindi, or as the wrong script.
- It is CTC greedy search, 2 CPU threads. There is no word list for ORS, खिचड़ी, or ডায়রিয়া.
- INT8 is the file we ship (`model.int8.onnx`). That is the right size. It is a little less accurate than the float model.

IndicTrans2 then translates **whatever text came out**, as if it were clean writing. A wrong script or a wrong language tag makes a confident wrong English line. The field glossary (`field_glossary.dart`) repairs Devanagari food and clinic words (ढोकला, बीपी, गोली). It does not have Bengali, Tamil, Telugu, or the other scripts, so those languages get no repair.

Published quality, for context, not for our phone:

- The INT8 indic→en export keeps about **94 BLEU** against its own float model on clean written fixtures, and about **86%** of sentences stay word-for-word the same. Spoken input is outside that test.
- On a harder speech-translation test (IndicConformer then IndicTrans2, before extra fine-tuning), Hindi→English was about **31 BLEU** and Bengali→English about **28 BLEU**. After fine-tuning the cascade, those moved up. Our stack is the small models, with no field fine-tune.
- A cascade (hear, then translate) beats a single speech-to-English model for this job. IWSLT 2024 saw about **51 BLEU** for a tuned cascade and about **19 BLEU** for an end-to-end speech translator on the same Indic task. We should keep the two-step design.

## Accuracy plan

Do these in order. Each one is useful even if the later ones wait.

### 1. Tell the hearing model which language was picked

The worker already chooses Bengali, Hindi, Marathi, and the rest. Pass that code into decode. Reject a result whose script does not match the pick, and ask them to speak again. Today `cleanHeardText` only deletes a `<hi>`-style tag. It does not check it.

### 2. Repair the text before translation

Run a small, on-device pass on the heard line:

- Map roman clinic words to a stable form: BP, ORS, ANC, tablet, fever, loose motion.
- Extend `fieldTerms` with the same meaning in each script we ship, not only Devanagari. Bengali ডায়রিয়া and Tamil காய்ச்சல் must hit the glossary the way ढोकला does.
- If the line is roman Indic (“bacha ko bukhar hai”), transliterate into the chosen script before IndicTrans2. The model expects its normal script, not Latin letters.
- Keep code-switched English tokens as placeholders (`<G1>`) the way I ask already shields a few phrases, then put the English word back after translation.

This is the highest gain for the way people actually speak. It does not need a new model.

### 3. Bias the recognizer toward field words

Add a phrase list per language: danger-sign words, ORS, fever, drink, vomit, convulsion, the local food names. In sherpa this is a hotword or context-graph list on the CTC decoder. A short beam (4) only when the first greedy pass looks empty or off-script. Greedy stays the fast path.

### 4. Confirm low-trust lines

The app already has `confidence_confirmation_dialog.dart` and an ASR feedback queue (`asr_feedback_store.dart`) that can sync later. Use them on this screen. If the heard line is very short, has no Indic letters, or the script mismatches, show the text and let the worker fix it before translation. Do not silently show a bad English sentence.

### 5. Only then change the model

Stay inside what this Redmi can hold.

| Option | Size | When to use it |
| --- | --- | --- |
| Keep Dolphin base INT8 | 99 MB | Default. Fast enough to try first. |
| Dolphin small INT8 | ~239 MB | If base WER on our clips is poor after steps 1–3. |
| One IndicConformer INT8 for the language in use | ~190 MB each | When the worker’s language is fixed for the day (Hindi, Bengali, Marathi, Tamil, …). Better on Indian speech than a 40-language model. Do not download all of them. |
| Whisper small INT8 | a few hundred MB | Last resort. Stronger on mixed language, slower, and English-heavy. |

Do not put the 1B IndicTrans2 or a 4 GB Indic–Indic model on this phone. English in the middle is the right pivot: worker reads English, family reads their language.

Kannada and Malayalam need a hearing model before “They speak” can be offered. Assamese needs to be added to `indicLanguages` only if the 200M model’s tag list includes it (`asm_Beng`). Check the tokenizer before promising it in the UI.

### 6. Voices for the other languages

I ask is text-only outside Hindi and English. Piper has Indic voices for several of these languages. Add one voice pack for the selected language, the same way Hindi is optional (~20 MB). Do not bundle all of them.

## Speed plan

The slow part is model load plus a long decode, not the network. After the packs are downloaded, the path is offline.

- **Keep the translator session warm** while the screen is open. Free it when the worker leaves. Loading three ONNX graphs per sentence is the cost we pay today for RAM.
- **Keep Dolphin warm** only during They speak. Unload it before I ask so both packs are not resident. The two translation directions are separate folders (`mt` and `mt-en`). Only one needs to be mapped.
- **Cap the utterance.** 8 seconds is enough for one answer. Longer clips dominate the hearing time. The UI already rejects tiny clips. Add a max as well.
- **Cap new tokens** to the length of the input, with a floor of 32 and the existing ceiling of 128. Clinic sentences are short. Decoding 128 tokens when 20 would do is wasted CPU.
- **Stay at 2 threads** on this Dimensity-class chip unless a bench shows 4 is faster and does not heat the device. More threads are not free on a small CPU.
- **Do not use beam 5 by default.** A published on-device note for this same INT8 model saw about 6 seconds per short sentence at beam 5. Greedy is the right default. Beam is only the retry.
- **Speak after the text is on screen.** TTS can start while the worker reads. Do not block the English line on Piper.

## What to measure

Add one timing record per turn, on device, stored locally. No audio leaves the phone unless the worker later opts into the existing ASR feedback upload.

Fields:

- language code
- direction: they-speak or i-ask
- audio duration, or typed character count
- load milliseconds (0 if the session was already warm)
- hear milliseconds
- translate milliseconds
- speak milliseconds
- total milliseconds from tap to text on screen
- whether the worker edited the heard line
- device model, RAM bucket, battery saver on or off

Report these, not a single average:

- median and 95th percentile of total time
- the same split into hear / translate / speak
- real-time factor: hear time divided by audio duration
- empty-result rate
- script-mismatch rate
- edit rate (worker changed the heard text)
- a small fixed set of clinic sentences scored by hand: 20 per language, spoken, not read from a clean script

### Budgets for this phone

These are targets to accept or reject a change. They are not measurements.

| Step | Target | Reject if |
| --- | --- | --- |
| Hear a 5 second clip, model already loaded | under 2.5 s | over 4 s at the 95th percentile |
| Translate one clinic sentence, model already loaded | under 1.5 s | over 3 s at the 95th percentile |
| Tap to English text, warm models | under 4 s | over 7 s at the 95th percentile |
| First sentence after opening the screen (cold load) | show a status line, finish under 8 s | a blank wait with no status |
| Peak extra RAM while one model is open | stay under about 600 MB | the app is killed on a 4 GB device |

Accuracy targets on the 20-sentence set, after the worker’s normal speech, not studio audio:

- They speak: the English line keeps the clinical fact (fever, unable to drink, blood in stool) in at least 90% of Hindi and Marathi clips, and at least 80% of Bengali, Tamil, Telugu, Gujarati, Punjabi, and Odia clips.
- I ask: a worker who knows the language accepts the sentence without a rewrite in at least 90% of cases. Proper names and drug names stay as shielded tokens.

If a change misses the speed budget, do not ship it for a small BLEU gain. The worker is standing with a family.

## Work order

1. Instrument the timings above and run the 20-sentence set on this Redmi for Hindi, Marathi, and Bengali. That is the baseline report.
2. Language check, roman-to-script, and a glossary row per language. Re-score the same 20 sentences.
3. Keep the ONNX session warm. Re-measure the latency table.
4. Hotwords and the confirm-before-translate dialog. Re-score.
5. Only if step 4 is still under the accuracy target, try IndicConformer INT8 for that one language and put both rows in the report.
6. Add a Piper voice for the selected non-Hindi language so I ask is not silent.

## Files

- `mobile/lib/core/bhasha/home_page.dart` — record, hear, translate, speak
- `mobile/lib/core/bhasha/speech_engine.dart` — Dolphin and Piper
- `mobile/lib/core/bhasha/indic_translator.dart` — greedy IndicTrans2, 128 tokens
- `mobile/lib/core/bhasha/model_store.dart` — download URLs and sizes
- `mobile/lib/core/bhasha/languages.dart` — the 10 languages, speech flag
- `mobile/lib/core/bhasha/field_glossary.dart` — Devanagari repairs
- `mobile/lib/features/triage/presentation/language_bridge_screen.dart` — entry from triage
