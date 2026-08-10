# RFW Component Catalog

Maintained by hand. This file is the context an LLM is given when it generates a workflow definition (`.rfwtxt`) at development time.

Source implementation: `apps/rfw-client/lib/local_widgets.dart`.

Event handling and data store: `apps/rfw-client/lib/workflow_screen.dart`.

Reference examples: `apps/server/definitions/tenant-a/workflows/goods-receipt.rfwtxt`, `apps/server/definitions/tenant-b/workflows/goods-receipt.rfwtxt`.

## Composition Rules

Every step is one screen and follows this shape.

```rfwtxt
import core.widgets;
import local.widgets;

widget Step0 = ActivityContainer(
  child: ListView(
    children: [
      ActivityHeader(step: 1, title: "..."),
      // the input and display widgets of this step
      ConfirmButton(text: "Continue", onPressed: event "next" { }),
    ]
  )
);
```

- Steps are named `Step0`, `Step1`, `Step2` and so on. The numbering starts at 0 and has no gaps. The client renders the current step by this name.
- The `ConfirmButton` of the last step fires `submit`. Every other one fires `next`.
- Definitions contain no conditions and no loops.
- Use `SizedBox(height: 16.0)` for vertical spacing.

## Data Namespace

The client stores everything the operator enters under one namespace, `data.workflow`. Definitions only read from it. There are no other keys, and no server-side data is available.

| Key | Type | Written by event | Notes |
|---|---|---|---|
| `data.workflow.orderNumber` | `string` | `setOrderNumber` | |
| `data.workflow.quantity` | `string` | `incrementQuantity`, `decrementQuantity` | Starts at `"1"`. A string, not an int. |
| `data.workflow.photoPath` | `string` | `photoTaken` | Absolute file path on the device. Absent until a photo is taken. |
| `data.workflow.location` | `string` | `selectLocation` | |

## Event Vocabulary

The client handles exactly these seven event names.

| Event | Fired by | Arguments | Effect |
|---|---|---|---|
| `next` | `ConfirmButton.onPressed` | none | Renders the next step. |
| `submit` | `ConfirmButton.onPressed` (last step) | none | Completes the workflow, resets to `Step0`. |
| `setOrderNumber` | `TextInput.onChanged` | `value: string`, supplied by the widget | Writes `data.workflow.orderNumber`. |
| `incrementQuantity` | `QuantityStepper.onIncrement` | none | Increments `data.workflow.quantity`. |
| `decrementQuantity` | `QuantityStepper.onDecrement` | none | Decrements `data.workflow.quantity`, never below 1. |
| `photoTaken` | `PhotoButton.onPressed` | `photoPath: string`, supplied by the widget | Writes `data.workflow.photoPath`. |
| `selectLocation` | `SelectableOption.onPressed` | `location: string`, **must be written into the definition** | Writes `data.workflow.location`. |

## Local Widgets

### ActivityContainer

Frames one step's screen.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `child` | `widget` | yes | | Always a `ListView` holding the step's widgets. |

Example:

```rfwtxt
ActivityContainer(
  child: ListView(
    children: [
      ActivityHeader(step: 1, title: "Goods Receipt")
    ]
  )
)
```

### ActivityHeader

Displays a small step label and the step title.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `step` | `int` | yes | | Human step number, starts at 1 while widget names start at `Step0`. |
| `title` | `string` | yes | | |

Example:

```rfwtxt
ActivityHeader(step: 2, title: "Storage Location")
```

### ConfirmButton

Displays the primary button that advances the workflow. Can stay disabled until a field is filled.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `text` | `string` | yes | | |
| `require` | `bool` | no | `false` | Turns the gate on. |
| `requiredValue` | `string` | only with `require: true` | | Bind to the field the step requires. Button stays disabled while it is empty. |
| `onPressed` | `handler` | yes | | `event "next" { }`, or `event "submit" { }` on the last step. |

Example:

```rfwtxt
ConfirmButton(
  text: "Continue",
  require: true,
  requiredValue: data.workflow.orderNumber,
  onPressed: event "next" { },
)
```

### TextInput

Displays a single-line text field. Fires its event on every keystroke and supplies the typed text as `value`.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `label` | `string` | yes | | |
| `onChanged` | `handler` | yes | | `event "setOrderNumber" { }`, empty braces. |

Example:

```rfwtxt
TextInput(label: "Order number", onChanged: event "setOrderNumber" { })
```

### ProductDetail

Displays one read-only row for the expected delivery line. Both values are literals, there is no product lookup.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `description` | `string` | yes | | |
| `sku` | `string` | yes | | Rendered as `SKU <value>`. |

Example:

```rfwtxt
ProductDetail(description: "Screws M6x20", sku: "ACM-001")
```

### QuantityStepper

Displays a counter with a minus and a plus button.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `label` | `string` | yes | | |
| `value` | `string` | yes | | Bind to `data.workflow.quantity`. A string, not an int. |
| `onIncrement` | `handler` | yes | | `event "incrementQuantity" { }` |
| `onDecrement` | `handler` | yes | | `event "decrementQuantity" { }` |

Example:

```rfwtxt
QuantityStepper(
  label: "Received quantity",
  value: data.workflow.quantity,
  onIncrement: event "incrementQuantity" { },
  onDecrement: event "decrementQuantity" { },
)
```

### InfoBox

Displays a short centered note.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `text` | `string` | yes | | |

Example:

```rfwtxt
InfoBox(text: "Check the goods for damage.")
```

### PhotoButton

Displays a camera button. Opens the camera, fires only if a photo was taken and supplies the file path as `photoPath`.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `text` | `string` | yes | | |
| `onPressed` | `handler` | yes | | `event "photoTaken" { }`, empty braces. |

Example:

```rfwtxt
PhotoButton(text: "Add condition photo", onPressed: event "photoTaken" { })
```

### ImagePreview

Displays a captured photo. Renders nothing while `previewPath` is absent, so it is safe to place before a photo exists.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `previewPath` | `string` | yes | | Bind to `data.workflow.photoPath`. |

Example:

```rfwtxt
ImagePreview(previewPath: data.workflow.photoPath)
```

### SelectableOption

Displays one tappable option in a fixed list. Highlights itself when its own `value` equals `selectedValue`.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `label` | `string` | yes | | |
| `value` | `string` | yes | | This option's own value. |
| `selectedValue` | `string` | yes | | Bind to `data.workflow.location`. |
| `onPressed` | `handler` | yes | | Must carry the value. `event "selectLocation" { location: "..." }` |

Example:

```rfwtxt
SelectableOption(
  label: "Cold Storage",
  value: "Cold Storage",
  selectedValue: data.workflow.location,
  onPressed: event "selectLocation" { location: "Cold Storage" },
)
```

### SummaryRow

Displays a label on the left and its value on the right.

| Prop | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `label` | `string` | yes | | |
| `value` | `string` | yes | | A literal or a `data.workflow` binding. |

Example:

```rfwtxt
SummaryRow(label: "Order number", value: data.workflow.orderNumber)
```

## Core Widgets

`import core.widgets;` makes the standard RFW widgets available. The workflow definitions use only these two:

| Widget | Props |
|---|---|
| `ListView` | `children`: list<widget> |
| `SizedBox` | `height`: double |
