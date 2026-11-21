# User guide

For farmers, traders, exporters and administrators using the True Root app on a phone, tablet or browser.

## What True Root does

Each lot of produce is a **batch** with its own ID, QR code and permanent history. Batches can change
hands (**ownership transfer**), be divided (**split**), combined (**merge**) or turned into a new product
(**transform**). The full chain from farm to exporter stays traceable and verifiable.

## Roles

| Role | Typical use |
|---|---|
| **Farmer** | Creates batches at the origin (harvest) |
| **Trader** | Buys lots, splits/merges them, passes them on |
| **Exporter** | Receives lots, transforms/packs them for distribution |
| **Admin** | Manages users, products, stages and can audit every batch |

Everyone can create batches, request purchases and approve requests for batches they own. Only admins can
manage products and stages.

## Getting started

### Sign in or create an account

1. Open the app. After the animated splash you reach the **Sign in** screen.
2. Enter email and password, then **Sign in**. Tick **Remember this account** to keep it under *Saved accounts*
   so you can switch with one tap later.
3. New user? Tap **Need an account? Register**, enter your name, email, a password (6+ characters) and your role.
4. **Demo accounts** (development servers): tap a role chip (Admin, Farmer...) to fill the form.
5. **Wrong server?** Tap the gear icon on the sign-in screen to set the API address (for example
   `https://api.example.com`). Your administrator will tell you the address.

On a computer the sign-in page shows a brand panel on the left and the form on the right.

### Navigation

| Screen size | Where the menu is |
|---|---|
| Phone | Floating bar at the bottom: Dashboard, Batches, Users, Profile |
| Tablet | Rail on the left |
| Desktop | Sidebar on the left with the logo |

The 🔔 button on each screen opens notifications. The theme (light/dark) follows your device and can be
toggled on the Profile screen.

## Dashboard

The Dashboard summarises your supply chain:

- **Banner** with a shortcut to your batches and a reminder of pending requests.
- **Active batches** and **Pending inbound** counters.
- **Purchase & Transfer Requests** - requests others made for your batches, with **Approve** / **Reject**.
- **My Batches & Lots** - your latest batches with their status.
- **Recent Activity** - the latest events across your batches.
- The search box filters all three lists. Pull down to refresh.

If you are offline, the last data is shown with an "Offline: showing cached data" note.

## Batches

Open the **Batches** tab.

### My Batches
Filter chips (All, Active, Transferred, Split, Merged, Archived, Disqualified) narrow the list. Tap a batch for details.

### Create a batch
Tap **New Batch**, choose the product, enter the quantity, and optionally the unit, grade and stage. The
batch gets a code and a QR code.

### Batch details
- Product, quantity, unit, grade, stage, status and owner.
- **QR code** to print or show; **Copy Data** copies the batch information.
- **History timeline** - every creation, split, merge, stage change, transfer and so on, in order.
- **Lineage** - the parent and child batches this lot came from or produced.
- A yellow *locked* notice means the batch is finalised, archived or already has derived batches, so some
  edits are no longer allowed.

### Actions on a batch you own
From the ⋮ menu or the action buttons:

| Action | Result |
|---|---|
| **Update** | Change quantity, grade, status or stage |
| **Split** | Divide into several smaller batches (quantities must add up) |
| **Merge** | Combine several batches into one new batch |
| **Transform** | Turn into a different product (for example raw to processed) |
| **Archive** | Retire the batch without deleting its history |
| **Mark not suitable** | Disqualify, with a reason |
| **Delete permanently** | Remove (only when allowed; cannot be undone) |

### Scan a QR code
Tap the scanner icon on the Batches screen, allow camera access, and point the camera at a batch QR code.
The batch details open. On web the scanner depends on browser camera support.

## Ownership transfers

1. Find the batch (scan its QR or open it from the **Users** tab).
2. Tap **Request Purchase / Transfer**, enter the quantity and an optional note, and send.
3. The owner sees it on their **Dashboard** and in **Batches -> Pending Requests** and chooses **Approve** or **Reject**.
4. On approval, ownership moves to the requester and the history records it.

You can follow your own requests in the Batches tab (**Pending Requests -> outbox**).

## Users tab

Browse the people and companies in the network (name, organisation, role, location). Tap a person to see
details and their batches, and to start a request.

## Profile

- Edit your name, organisation, location and account type.
- **Company** accounts can add **members** by email, and search the member list.
- **Save changes** stores the profile. The sun/moon button switches light and dark. The sign-out button logs you out.
- Admins see **Open Admin Console**.

## Admin console (admins only)

Open from the Profile screen (or go to `/admin` on the web version). The console has five sections:

| Section | What you can do |
|---|---|
| **Dashboard** | Totals and recent activity across the system |
| **Users** | Search, create, edit roles, delete users |
| **Products** | Add, rename and delete the product catalogue |
| **Stages** | Define supply-chain stages and their order (`sequence`), activate/deactivate |
| **Batches** | Audit any batch and its history |

Use the swap icon to jump to the normal user view and the sign-out icon to leave.

**First-time setup of a new system:** create the *Stages* (for example Harvested, Graded, Packed, Shipped) and
*Products* before users create batches.

## Tips

- Search boxes filter as you type; pull down on lists to refresh.
- Grades and statuses are free text, so agree a naming convention with your team.
- Keep QR codes attached to physical lots. A scan always shows the live status and history.
- Admin accounts should use strong, unique passwords.

## Getting help

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md), or contact your system administrator.
