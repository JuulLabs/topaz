# CON-4 — Related Origin Requests inside Topaz's web view

Throwaway harness and manual test plan for one question:

> Can a WebAuthn ceremony served from a non-`.com` regional storefront use the `juul.com`
> relying-party ID inside Topaz's `WKWebView`?

`juul.com` is a registrable suffix of `www.juul.com`, `app.juul.com`, `connect.juul.com` and
every `*.stage.juul.com` host, so the US path needs no related-origins mechanism at all. It is
*not* a registrable suffix of `www.juul.co.uk`, `www.juul.ca`, `www.juullabs.it` or
`www.juul.com.kw` — those markets work only if Related Origin Requests are honoured.

The deliverable is a recorded decision, not shippable code. Nothing here is built, linted or
shipped by the app; the pages are static and are meant to be deleted once the decision is
recorded on CON-4.

## Contents

| Path | Purpose |
| --- | --- |
| `probe.html` | Static page that runs `create()` / `get()` against an arbitrary RP ID and prints the exact result or error. `?rpId=` presets the field. |
| `well-known/webauthn-origin-listed.json` | `/.well-known/webauthn` body for the "regional origin is allowlisted" runs. |
| `well-known/webauthn-origin-omitted.json` | Same document with the regional origin removed, for the "present but absent from the list" run. |

`probe.html` needs no server: the challenge is generated locally and no assertion is verified.
The ceremony either reaches the platform authenticator or is rejected before it, and that
rejection is the whole measurement.

## Prerequisites (all external to this repo)

1. **A physical iPhone on a current iOS release**, signed into an iCloud account with iCloud
   Keychain enabled, with a device passcode and Face ID/Touch ID enrolled. A simulator cannot
   answer the Associated Domains half of the question.
2. **A Topaz development build with an Associated Domains entitlement containing
   `webcredentials:juul.com`** — and *only* that entry. Topaz has no entitlements file today
   (see `Topaz/debug.xcconfig`, `topaz.xcodeproj/project.pbxproj`); production entitlement work
   is CON-15. A single-entry entitlement is what makes the RP-ID-vs-origin question decidable:
   if a `www.juul.co.uk` page can assert `juul.com` under it, the check is keyed on the RP ID
   and Topaz needs one association, not thirteen.
3. **`probe.html` served over HTTPS from a `juul.com` host** (`www.juul.com` or a
   `*.stage.juul.com` host).
4. **`probe.html` served over HTTPS from a host that is not under the `juul.com` registrable
   domain** — a real regional storefront host is the honest choice.
5. **Write access to `https://<rp-id-host>/.well-known/webauthn`**, able to swap between the
   listed and omitted bodies. It must be served as `application/json` with no cookies, no
   insecure redirect and a valid certificate chain.

### Environment findings that constrain the above

* There is **no non-`.com` non-production storefront host**. Every lower environment is under
  `juul.com` (`*.stage.juul.com`, `*.preprod.juul.com`) or `juul-dev.com` (`*.qaN.juul-dev.com`)
  — see `pulumi/deploy/Pulumi.staging.yaml` and `pulumi/juulio-cdn/Pulumi.*.yaml` in `juulio`.
  Reproducing a cross-registrable-domain ceremony therefore needs either a production host or a
  throwaway host deliberately stood up outside `juul.com`. A `*.vercel.app` preview host is a
  valid stand-in for "origin whose registrable domain is not `juul.com`" — the PRD's note that
  preview hosts "cannot exercise passkeys at all" is true only in the absence of a
  related-origins entry, which is precisely what is under test.
* `https://juul.com/.well-known/webauthn` currently redirects to `www.juul.com` and returns
  **403 (S3 AccessDenied)** — the document does not exist yet. `apple-app-site-association` is
  served from `www.juul.com`, so the same bucket is the natural home for it.
* The RP ID host matters: WebKit derives the well-known URL from the **RP ID**, so with RP ID
  `juul.com` the fetch targets `https://juul.com/.well-known/webauthn`. The current redirect to
  `www.juul.com` is itself a risk worth recording — serve the document on the apex without a
  cross-origin redirect.

## Test matrix

Run every row twice: once in Topaz, once in Safari on the *same* device, back to back. Record
the exact `error.name` and `error.message` from the probe log, whether a system sheet appeared,
and what the sheet said.

| # | Page origin | RP ID | `/.well-known/webauthn` | Browser | Expectation being tested |
| --- | --- | --- | --- | --- | --- |
| 1 | `juul.com` host | `juul.com` | absent | Safari | Control: registrable-suffix path needs no related origins. |
| 2 | `juul.com` host | `juul.com` | absent | Topaz | Does the entitlement alone permit a same-suffix ceremony in `WKWebView`? |
| 3 | non-`.com` host | `juul.com` | listed | Safari | Control: Related Origin Requests work at all on this device. |
| 4 | non-`.com` host | `juul.com` | listed | Topaz | **The question.** |
| 5 | non-`.com` host | `juul.com` | omitted | Safari | Rejection shape when the document exists but the origin is absent. |
| 6 | non-`.com` host | `juul.com` | omitted | Topaz | Same, inside the web view. |
| 7 | non-`.com` host | own origin's domain | n/a | Topaz | Isolates the entitlement from the related-origins mechanism: a ceremony Topaz is *not* associated with. |

Run `Read client capabilities` on every page before the ceremonies. `getClientCapabilities()`
reports a `relatedOrigins` key where supported; its presence or absence in Topaz versus Safari
is evidence on its own, and it costs one tap.

Also record for each run: iOS build number, Topaz build (commit or version), `navigator.userAgent`
(Topaz can switch UA mode — leave it on the default `topaz` mode), and whether the credential
created in row 2 is offered in row 4 (credentials only roam between origins that share an RP ID).

## Reading the result

* **Row 4 succeeds** → Related Origin Requests are honoured in `WKWebView` and the association
  is keyed on the RP ID. Recommendation: proceed as designed — one `webcredentials:juul.com`
  entry, one `/.well-known/webauthn` document, credentials roam across markets.
* **Row 4 fails while row 3 succeeds** → the web view, not the platform, is the limitation.
  Recommendation: the `juul.com` iframe fallback with
  `allow="publickey-credentials-get; publickey-credentials-create"` on non-`.com` storefronts,
  falling back to per-market RP IDs if the iframe is also refused. Test the iframe variant
  before committing — it is a second ceremony inside the same web view and may fail the same way.
* **Rows 3 and 4 both fail** → the device/OS does not support the mechanism as assumed; re-check
  the well-known document (content type, redirect, certificate) before concluding, then treat
  per-market RP IDs as the likely answer.
* **Row 7 succeeds** → the association check is *not* gating what we think it gates; stop and
  re-derive the entitlement requirement, because CON-15's scope changes.
* **Rows 5/6** are expected to reject. Record whether the rejection is `SecurityError` (the
  origin was evaluated and refused) or `NotAllowedError` (indistinguishable from a user
  cancellation) — the classification decides what error copy viewlio can honestly show.

## Desk research (not a substitute for the runs)

Collected while the device prerequisites were outstanding. Consistent with "row 4 succeeds",
but it does not answer the Associated Domains half at all, which is why the spike exists.

* WebKit implemented the browser side of related origins in
  [WebKit#23548](https://github.com/WebKit/WebKit/pull/23548) (Feb 2024, shipped in Safari 18 /
  iOS 18). It **removed** WebCore's same-registrable-domain rejection, stating that "validating
  the RPID against the current origin is now done by AuthenticationServices" — i.e. the check
  moved into the system framework that `WKWebView` also calls, rather than living in the browser.
* The open [WebKit#72038](https://github.com/WebKit/WebKit/pull/72038) moves that validation back
  into WebKit so the fetch uses the page's proxy configuration. Its validator derives
  `/.well-known/webauthn` from the **RP ID**, parses the `origins` member, and forwards related
  origins only when the caller origin appears in the list; its tests expect rejection for a
  missing document, wrong content type, insecure redirect, timeout, oversized body, untrusted
  certificate, and an absent caller origin.
* Apple's passkey documentation states that a `WKWebView`-hosted ceremony requires the host app
  to carry a `webcredentials` association for the RP ID in use, because the host app can inject
  JavaScript into any page it loads. Whether "the RP ID in use" or "the page origin" is what gets
  matched is exactly what rows 4 and 7 measure.
* Topaz adds no WebAuthn-specific configuration or bridge of its own — `WebConfigLoader` builds a
  plain `WKWebViewConfiguration` and injects only the Bluetooth polyfill — so whatever the runs
  show is platform behaviour, not Topaz behaviour.

## Recording the outcome

Fill the matrix in, paste the probe logs and the recommendation into a comment on
[CON-4](https://linear.app/juul/issue/CON-4), and fold the decision into the Biometric Login PRD
(the project's only decisions document, Linear-only). Then delete this directory.
