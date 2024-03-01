const axios = require('axios');

async function fetchAndSortValidators(url) {
  try {
    const response = await axios.get(url);
    const validators = response.data.validators;

    if (!validators) {
      console.error('No validators found in the response.');
      return [];
    }

    // Filter validators to include only those with a bonded status
    const bondedValidators = validators.filter(validator => validator.status === 'BOND_STATUS_BONDED');

    // Sort the bonded validators by the staked amount in descending order
    return bondedValidators.sort((a, b) => parseInt(b.tokens) - parseInt(a.tokens));
  } catch (error) {
    console.error('Failed to fetch validators:', error);
    return [];
  }
}

module.exports = fetchAndSortValidators;
