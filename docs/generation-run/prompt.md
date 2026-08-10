Only read `docs/rfw-components.md`. Use nothing that is not in it.

Write an order picking workflow for tenant A. It has three steps.

1. Pick order. The operator types the pick order number. It is required before he can continue.
2. Pick item. He reads where to go, "Rack A-12". The product is "Washers" with the SKU "WAS-001". He counts how many he took out.
3. Summary. He sees the pick order number, the product, the SKU, the quantity and the rack. Then he confirms.

The rack is not chosen by the operator. The system tells him where to go.

Write the result to `docs/generation-run/output-order-picking.rfwtxt`.
