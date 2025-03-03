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
    
    // Verify policy creation event
    const createEvent = block.receipts[0].events[0];
    assertEquals(createEvent.type, "contract_event");
    assertEquals(createEvent.data.value.event, "policy-created");
  },
});

Clarinet.test({
  name: "Ensure can pay premium and file claim",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("safe-stream-core", "pay-premium",
        [types.uint(1), types.uint(50000)],
        wallet_1.address
      ),
      Tx.contractCall("safe-stream-core", "file-claim",
        [types.uint(1), types.uint(500000)],
        wallet_1.address
      )
    ]);

    assertEquals(block.receipts[0].result.expectOk(), true);
    assertEquals(block.receipts[1].result.expectOk(), "u1");
  },
});

Clarinet.test({
  name: "Ensure voting mechanism works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("safe-stream-dao", "create-proposal",
        [types.uint(1)],
        wallet_1.address
      ),
      Tx.contractCall("safe-stream-dao", "vote",
        [types.uint(1), types.uint(100000), types.bool(true)],
        wallet_2.address
      )
    ]);

    assertEquals(block.receipts[0].result.expectOk(), "u1");
    assertEquals(block.receipts[1].result.expectOk(), true);
  },
});
