# -*- coding: utf-8 -*-
"""ARB parçalarını birleştirir.

Metin göçü feature başına paralel yürüdü ve her parça kendi dosyasına
yazdı; iki ARB dosyasına aynı anda yazmak çakışma üretirdi. Bu araç
parçaları tek tek okuyup `app_tr.arb` ve `app_en.arb`'ye ekliyor.

Parça biçimi:

    {"anahtar": {"tr": "Türkçe", "en": "English"}}

Çakışan anahtar hata verir — iki feature aynı adı seçtiyse bu bir
karar gerektirir, sessizce üzerine yazmak yanlış olur.
"""

import io
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAGMENTS = os.path.join(ROOT, 'tools', 'l10n_fragments')
ARB_DIR = os.path.join(ROOT, 'app', 'lib', 'l10n')


def load(path):
    with io.open(path, encoding='utf-8') as f:
        return json.load(f)


def dump(path, data):
    with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


def main():
    tr_path = os.path.join(ARB_DIR, 'app_tr.arb')
    en_path = os.path.join(ARB_DIR, 'app_en.arb')
    tr, en = load(tr_path), load(en_path)

    added, conflicts = 0, []

    for name in sorted(os.listdir(FRAGMENTS)):
        if not name.endswith('.json'):
            continue
        fragment = load(os.path.join(FRAGMENTS, name))

        for key, values in fragment.items():
            if key in tr and tr[key] != values['tr']:
                conflicts.append('%s: %s (mevcut: %r, yeni: %r)'
                                 % (name, key, tr[key], values['tr']))
                continue
            tr[key] = values['tr']
            en[key] = values['en']
            added += 1

        print('%-28s %3d anahtar' % (name, len(fragment)))

    if conflicts:
        print('\nÇAKIŞMA — anahtar adları çakıştı, elle karara bağla:')
        for line in conflicts:
            print('  ' + line)
        return 1

    dump(tr_path, tr)
    dump(en_path, en)
    print('\ntoplam %d anahtar birleştirildi' % added)
    print('tr: %d, en: %d' % (
        len([k for k in tr if not k.startswith('@')]),
        len([k for k in en if not k.startswith('@')]),
    ))
    return 0


if __name__ == '__main__':
    sys.exit(main())
