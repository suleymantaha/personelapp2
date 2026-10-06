"""Check actual A4 pages and visible text for synthetic Heybet print fixtures."""
from pathlib import Path
import re
import subprocess

root = Path('build/heybet-previews')
rendered = root / 'excel-rendered'
rendered.mkdir(exist_ok=True)
for source in sorted(root.glob('*.xlsx')):
    subprocess.run(['libreoffice', '-env:UserInstallation=file:///tmp/heybet-print-profile',
                    '--headless', '--convert-to', 'pdf', '--outdir', str(rendered),
                    str(source)], check=True, timeout=90)


def check(path, count=None):
    result = subprocess.run(['pdftotext', '-layout', str(path), '-'],
                            check=True, capture_output=True, text=True)
    pages = [p for p in result.stdout.split('\f') if p.strip()]
    text = ' '.join(result.stdout.split())
    for value in ['TANZİM EDEN', 'TASDİK EDEN', 'İhsan DAĞLI', 'Serdar YILDIZ',
                  'J.Asb.Kd.Bçvş.', 'Eğt.Hrk. ve İsth.Ks.A', 'J.Yb.', 'J.Komd.Öz.Hrk.Tb.K.']:
        assert text.count(value) == 1, (path, value, text.count(value))
        assert value in ' '.join(pages[-1].split()), (path, 'split signatures', value)
    assert not re.search(r'Toplam|TOPLAM', text), (path, 'printed total')
    if count is not None:
        numbers = [int(v) for v in re.findall(r'Personel\s+(\d+)', text)]
        assert sorted(numbers) == list(range(1, count + 1)), (path, numbers)
        if count in (95, 100):
            assert len(pages) == 2, (path, len(pages))
    else:
        assert 'SONSATIR' in text, (path, 'truncated long name')
        assert 'ÜÇÜNCÜ' in text, (path, 'truncated long name')
    print(f'{path.name}: {len(pages)} A4 pages; complete personnel, signatures together, no totals')


for source in sorted(root.glob('*.pdf')):
    match = re.fullmatch(r'heybet-(\d+)\.pdf', source.name)
    check(source, int(match[1]) if match else None)
for source in sorted(rendered.glob('*.pdf')):
    match = re.fullmatch(r'heybet-(\d+)\.pdf', source.name)
    check(source, int(match[1]) if match else None)
