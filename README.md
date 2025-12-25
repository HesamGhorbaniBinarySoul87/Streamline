# MiniFlux – Lightweight Streaming Payments for ERC-20

MiniFlux is a secure, gas-efficient, and easy-to-use Solidity contract for streaming ERC-20 tokens.  

It enables:

- Continuous token streaming between addresses  
- Pull-based withdrawals (claim anytime)  
- Cancelable streams  
- Lightweight and production-ready design  

---

## Features

- Create streams with start/end timestamps  
- Claim accrued tokens at any time  
- Cancel streams if allowed  
- Compatible with any ERC-20 token  
- Optimized for gas and security  

---

## Security

- Reentrancy safe  
- Overflow/underflow prevented  
- Pull payment pattern (no forced push)  
- Events emitted for all critical actions  

---

## Usage Example

1. Deploy MiniFlux.sol  
2. createStream(recipient, token, totalAmount, start, end, cancelable)  
3. Recipient calls claim(id) to withdraw accrued tokens  
4. Sender can cancel stream using cancel(id) if allowed  

---

## License

MIT
