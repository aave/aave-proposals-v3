import {ConfigFile} from '../../generator/types';
export const config: ConfigFile = {
  rootOptions: {
    pools: ['AaveV3Ethereum'],
    title: 'Maintenance: Grant AL RETRY_ROLE on a.DI',
    shortName: 'MaintenanceGrantALRETRY_ROLEOnADI',
    date: '20260525',
    author: 'Aave Labs',
    discussion: 'https://governance.aave.com',
    snapshot: 'direct-to-aip',
    votingNetwork: 'AVALANCHE',
  },
  poolOptions: {AaveV3Ethereum: {configs: {OTHERS: {}}, cache: {blockNumber: 25169933}}},
};
