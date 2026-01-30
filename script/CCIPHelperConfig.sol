//SPDX-license-Identifier:MIT
pragma solidity^0.8.19;
library CCIPHelperConfig{
    error UnSupportedChain();
    struct NetworkDetails{
        uint64 chainSelector;
        address routerAddress;
        address linkAddress;
        address wrappedNativeAddress;
        address ccipBnMAddress;
        address ccipLnMAddress;
        address rmnProxyAddress;
        address registryModuleOwnerCustomAddress;
        address tokenAdminRegistryAddress;
    }
    function getNetworkDetails(uint256 chainId) public pure returns(NetworkDetails memory networkDetails)
    {
        //sepolia
        if(chainId ==11155111)
        {
            networkDetails = NetworkDetails({
                chainSelector:16015286601757825753,
                routerAddress:0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
                linkAddress:0x779877A7B0D9E8603169DdbD7836e478b4624789,
                wrappedNativeAddress:0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534,
                ccipBnMAddress:0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05,
                ccipLnMAddress:0x466D489b6d36E7E3b824ef491C225F5830E81cC1,
                rmnProxyAddress:0xba3f6251de62dED61Ff98590cB2fDf6871FbB991,
                registryModuleOwnerCustomAddress:0x62e731218d0D47305aba2BE3751E7EE9E5520790,
                tokenAdminRegistryAddress:0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82
            });

        }
        // arbitrum sepolia
        else if(chainId == 421614)
        {
            networkDetails = NetworkDetails({
                chainSelector:3478487238524512106,
                routerAddress:0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165,
                linkAddress:0xb1D4538B4571d411F07960EF2838Ce337FE1E80E,
                wrappedNativeAddress:0xE591bf0A0CF924A0674d7792db046B23CEbF5f34,
                ccipBnMAddress:0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D,
                ccipLnMAddress:0x139E99f0ab4084E14e6bb7DacA289a91a2d92927,
                rmnProxyAddress:0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2,
                registryModuleOwnerCustomAddress:0xE625f0b8b0Ac86946035a7729Aba124c8A64cf69,
                tokenAdminRegistryAddress:0x8126bE56454B628a88C17849B9ED99dd5a11Bd2f
            });

        }
        // polygon amoy
        else if(chainId == 80002)
        {
            networkDetails = NetworkDetails({
                chainSelector:16281711391670634445,
                routerAddress:0x9C32fCB86BF0f4a1A8921a9Fe46de3198bb884B2,
                linkAddress:0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904,
                wrappedNativeAddress:0x360ad4f9a9A8EFe9A8DCB5f461c4Cc1047E1Dcf9,
                ccipBnMAddress:0xcab0EF91Bee323d1A617c0a027eE753aFd6997E4,
                ccipLnMAddress:0x3d357fb52253e86c8Ee0f80F5FfE438fD9503FF2,
                rmnProxyAddress:0x7c1e545A40750Ee8761282382D51E017BAC68CBB,
                registryModuleOwnerCustomAddress:0x84ad5890A63957C960e0F19b0448A038a574936B,
                tokenAdminRegistryAddress:0x1e73f6842d7afDD78957ac143d1f315404Dd9e5B
            });
        } 
        //avalanchi fuji
        else if(chainId == 43113)
        {
            networkDetails = NetworkDetails({
                chainSelector:14767482510784806043,
                routerAddress:0xF694E193200268f9a4868e4Aa017A0118C9a8177,
                linkAddress:0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
                wrappedNativeAddress:0xd00ae08403B9bbb9124bB305C09058E32C39A48c,
                ccipBnMAddress:0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4,
                ccipLnMAddress:0x70F5c5C40b873EA597776DA2C21929A8282A3b35,
                rmnProxyAddress:0xAc8CFc3762a979628334a0E4C1026244498E821b,
                registryModuleOwnerCustomAddress:0x97300785aF1edE1343DB6d90706A35CF14aA3d81,
                tokenAdminRegistryAddress:0xA92053a4a3922084d992fD2835bdBa4caC6877e6
            });

        }
        else{
            revert UnSupportedChain();
        }
    }
}