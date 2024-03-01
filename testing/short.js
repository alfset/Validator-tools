const fetchAndSortValidators = require('tools-comunitynode');
const ExcelJS = require('exceljs');

const url = 'https://lcd.orai.io/cosmos/staking/v1beta1/validators'; // Example URL

async function run() {
  const sortedValidators = await fetchAndSortValidators(url);

  // Create a new workbook
  const workbook = new ExcelJS.Workbook();
  // Add a sheet
  const sheet = workbook.addWorksheet('Validators');

  // Define the columns in the sheet
  sheet.columns = [
    { header: 'Operator Address', key: 'operator_address', width: 32 },
    { header: 'Tokens', key: 'tokens', width: 20 },
    // Add other columns as needed
  ];

  // Add rows to the sheet
  sortedValidators.forEach(validator => {
    sheet.addRow({
      operator_address: validator.operator_address,
      tokens: validator.tokens,
      // Add other fields as needed
    });
  });

  // Define a filename
  const filename = 'sorted_validators.xlsx';

  // Save the workbook to a file
  await workbook.xlsx.writeFile(filename);

  console.log(`Saved sorted validators to ${filename}`);
}

run();
