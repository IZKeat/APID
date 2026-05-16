const fs = require('fs');
try {
  let content = fs.readFileSync('functions_list.json', 'utf16le');
  const start = content.indexOf('{');
  const end = content.lastIndexOf('}');
  if (start !== -1 && end !== -1) {
    content = content.substring(start, end + 1);
    const json = JSON.parse(content);
    if (Array.isArray(json.result)) {
      console.log("First item full:", JSON.stringify(json.result[0], null, 2));
    }
  }
} catch (e) {
  console.error(e);
}
