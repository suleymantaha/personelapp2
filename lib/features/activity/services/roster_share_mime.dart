String rosterMimeType(String name) => name.toLowerCase().endsWith('.png')
    ? 'image/png'
    : name.toLowerCase().endsWith('.pdf')
        ? 'application/pdf'
        : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
