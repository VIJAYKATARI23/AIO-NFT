// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";


contract Multichain is ERC721, AxelarExecutable {
    
    string public sourcechain;
    address public sourceaddress;
    uint sourcechainID;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    IAxelarGasService public immutable gasService;


    constructor(address gateway_ ,address gasReciver_,string memory sourcechain,address _sourceaddr,uint _sourcechainID) AxelarExecutable(gateway) ERC721("mani","MV"){
        gasService=IAxelarGasService(gasReciver_);
        sourcechain=_sourcechain;
        sourceaddress=_sourceaddr;
        sourcechainID=_sourcechainID;
    }


    function mint(address to) public payable{
        if(sourcechainID==block.chainid){
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        }else{
            // require(msg.value>0);
        
        bytes memory payload=abi.encodeWithSelector(this.mint.selector, to);

        gasService.payNativeGasForContractCall{value:msg.value}(
            address(this),
            sourcechain,
            Strings.toHexString(sourceaddress),
            payload,
            msg.sender);

        gateway.callContract(sourcechain, Strings.toHexString(sourceaddress), payload);
        }

    }
    function transferFrom(address from, address to, uint256 tokenId) public  override {
          if (block.chainid == sourcechainID) {
            _transfer(from, to, tokenId);
        }
        else{
            bytes memory payload=abi.encodeWithSelector(
                this.transferFrom.selector,
                from,
                to,
                tokenId
            );
            // require(address(this).balance>0);
        gasService.payNativeGasForContractCall{value:address(this).balance}(
            address(this),
            sourcechain,
            Strings.toHexString(sourceaddress),
            payload,
            msg.sender);

            gateway.callContract(sourcechain, Strings.toHexString(sourceaddress), payload);
        }
    }

    function _execute(
            string calldata SChain,
            string calldata SAddress,
            bytes calldata payload
        ) internal override {
        
         if (bytes4(payload[0:4]) == this.transferFrom.selector) {
            (address from, address to, uint256 tokenId) = abi.decode(
                payload[4:],
                (address, address, uint256)
            );
            _transfer(from, to, tokenId);
        }
        if(bytes4(payload[0:4]) == this.mint.selector){
             (address to) = abi.decode(
                payload[4:],
                (address));

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        }

        }



    
    
}
