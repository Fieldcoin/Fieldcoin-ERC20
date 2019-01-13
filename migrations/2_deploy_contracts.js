const FieldCoin = artifacts.require("./contracts/FieldCoin.sol");
const FieldCoinSale = artifacts.require("./contracts/FieldCoinSale.sol");

module.exports = function () {

    let openingTime = 1554192000;
    let closingTime = 1570003200;
    let wallet = "0x969c1b456D178fFC7E8d7919d71D37E33293A772";
    let eth_usd = 10000;
    let minContribution = 10000;
    let maxContribution = 100000000;

    return deployer.deploy(FieldCoin).then(function(){
        return deployer.deploy(FieldCoinSale,
                        openingTime,
                        closingTime,
                        wallet,
                        FieldCoin.address,
                        eth_usd,
                        minContribution,
                        maxContribution)
    });
};