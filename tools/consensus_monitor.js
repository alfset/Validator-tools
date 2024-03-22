const axios = require('axios');

const NODE_ADDR_LCD = "https://lcd.orai.io:443";
const NODE_ADDR_RPC = "https://rpc.orai.io:443";
const DECIMALS = 10 ** 6;

const getValidators = async () => {
    try {
        const {
            data: poolData
        } = await axios.get(`${NODE_ADDR_LCD}/cosmos/staking/v1beta1/pool`);
        const totalBonded = parseInt(poolData.pool.bonded_tokens) / DECIMALS;

        let parsed = 0;
        let page = 1;
        const valsMap = {};
        while (true) {
            const params = {
                params: {
                    "per_page": 500,
                    "page": page
                }
            };
            const {
                data: validatorsData
            } = await axios.get(`${NODE_ADDR_RPC}/validators`, params);
            const valsTendermint = validatorsData.result.validators;
            for (const val of valsTendermint) {
                valsMap[val.address] = {
                    'pub_key': val.pub_key.value,
                    'vp': Math.round((100 / totalBonded) * parseFloat(val.voting_power), 3)
                };
            }
            parsed += parseInt(validatorsData.result.count);
            const total = parseInt(validatorsData.result.total);
            page++;
            if (parsed >= total) {
                break;
            }
        }

        const {
            data: bondedValidatorsData
        } = await axios.get(`${NODE_ADDR_LCD}/cosmos/staking/v1beta1/validators?status=BOND_STATUS_BONDED`);
        const cosmosVals = bondedValidatorsData.validators;
        for (const val of cosmosVals) {
            const pubKey = val.consensus_pubkey.key;
            const moniker = val.description.moniker;
            for (const [k, v] of Object.entries(valsMap)) {
                if (v.pub_key === pubKey) {
                    v.moniker = moniker;
                }
            }
        }

        let lastHeight = 0;
        let lastProposer = '';
        while (true) {
            const {
                data: consensusData
            } = await axios.get(`${NODE_ADDR_RPC}/consensus_state`);
            const data = consensusData.result.round_state;
            const parts = data['height/round/step'].split('/');
            const height = parts[0];
            const round = parseInt(parts[1]);
            const step = parts[2];
            const proposer = valsMap[data.proposer.address].moniker;
            let prevotes = '';

            if (lastHeight === height && proposer !== lastProposer) {
                console.log(`\n\nProposer changed: ${lastProposer} -> ${proposer}\n`);
            }

            prevotes = data.height_vote_set[round].prevotes_bit_array;

            const spacing = ' '.repeat(50);
            console.log(`Consensus: ${height}/${round}/${step}, ${prevotes}, proposer: ${proposer}${spacing}`);
            lastHeight = height;
            lastProposer = proposer;
        }
    } catch (error) {
        console.error(error);
    }
};

getValidators();