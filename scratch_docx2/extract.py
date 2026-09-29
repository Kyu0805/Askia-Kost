import xml.etree.ElementTree as ET

ns = {
    'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
}

tree = ET.parse('unpacked/word/document.xml')
root = tree.getroot()

body = root.find('w:body', ns)

out = open('output.txt', 'w', encoding='utf-8')
for para in body.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}p'):
    texts = []
    for t in para.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}t'):
        texts.append(t.text or '')
    line = ''.join(texts)
    pStyle = para.find('.//w:pStyle', ns)
    style = pStyle.get('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}val') if pStyle is not None else ''
    has_drawing = para.find('.//w:drawing', ns) is not None
    marker = ' [IMAGE]' if has_drawing else ''
    if line.strip() or style or has_drawing:
        out.write(f'[{style}]{marker} {line}\n')
out.close()
