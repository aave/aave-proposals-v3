import {ConfigFile} from '../../generator/types';
export const config: ConfigFile = {
  rootOptions: {
    pools: ['AaveV3Ethereum'],
    title: 'Horizon RWA Instance Activation',
    shortName: 'HorizonRWAInstanceActivation',
    date: '20250812',
    author: 'Aave Labs',
    discussion: '',
    snapshot: '',
    votingNetwork: 'POLYGON',
  },
  poolOptions: {AaveV3Ethereum: {configs: {}, cache: {blockNumber: 23127785}}},
};
