# Baseline Client Design Decisions

> App-specific decisions for `apps/baseline-client` (native baseline, no RFW).
> Cross-cutting decisions (affecting **both** baseline and SDUI/server) live in [`/docs/design-decisions.md`](../../../docs/design-decisions.md).

---

| Date | What | Why | Rejected |
| ---- | ---- | --- | -------- |
| 2026-06-29 | Baseline = the control for RQ3: time the same screens in both apps, the shared Flutter part cancels, the difference is the RFW cost. So the baseline must rebuild the RFW screens identically | RFW only builds widgets, never paints — the RFW cost can't be isolated inside one app, only by comparing against an identical native one | Measuring the RFW cost inside a single app; non-identical screens |
| 2026-06-30 | Baseline embodies one fixed tenant composition (tenant-b); no tenant switch, no AppBar dropdown | Native screens are baked into the binary at build time — another tenant or any layout change needs a code change + release (or a separate app per tenant); chose tenant-b because its 4-step structure matches the baseline's | Tenant dropdown / runtime switch — would only toggle build-time-baked variants yet falsely imply the server-driven recomposition the native client lacks |