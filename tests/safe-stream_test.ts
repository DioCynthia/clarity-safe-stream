import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can create policy with valid parameters",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("safe-stream-core", "create-policy", 
        [types.uint(1000000), types.uint(50000)], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), "u1");
  },
});

Clarinet.test({
  name: "Ensure can file claim on active policy",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("safe-stream-core", "file-claim",
        [types.uint(1), types.uint(500000)],
        wallet_1.address
      )
    ]);

    assertEquals(block.receipts[0].result.expectOk(), "u1");
  },
});
