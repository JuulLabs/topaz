# Passkey sign-in — manual test plan (CON-15)

Passkey registration and sign-in inside Topaz require both halves of the web-credentials
association: an Associated Domains entitlement in the app (`webcredentials:<rp-id-host>`,
see `Topaz/topaz.entitlements`) **and** the app-site-association document served from the
RP-ID host naming `5EH8QG4538.com.juullabs.topaz` in `webcredentials.apps`. Either half
missing produces the same failure — and **only** in Topaz, which reads like a Topaz bug
rather than a configuration gap. Verify both before testing.

The biometric prompt cannot be automated and the Associated Domains check needs a real
device, so this plan is the coverage for the Topaz path; every other surface is exercised
by the device-backed suites via password sign-in.

## Prerequisites

1. A physical iPhone on a current iOS release, signed in to iCloud with iCloud Keychain
   enabled, passcode and Face ID/Touch ID set. A simulator cannot exercise the
   web-credentials association.
2. A Topaz build signed with a provisioning profile that carries the Associated Domains
   capability — see `Topaz/topaz.entitlements` and the "Topaz Development" /
   "Topaz Distribution" profiles.
3. A staging account on a `*.stage.juul.com` storefront: one with no passkey registered,
   and permission to enroll one. Safari on the same device is the control for every step.
4. The AASA check, done two ways before any ceremony:
   - File: `curl https://stage.juul.com/.well-known/apple-app-site-association` (or the
     apex redirect target) lists `5EH8QG4538.com.juullabs.topaz` under
     `webcredentials.apps`.
   - Device: connect the phone, stream `swcd` in Console (`process:swcd`), install the
     build, and confirm the association registers without error. A missing or stale
     entry shows up here first.

## Test matrix

Run every row in Topaz, then repeat in Safari on the same device as the control. Record
iOS build number, Topaz build/commit, and the exact error name where a ceremony fails.

| # | Scenario | Steps | Expected |
| --- | --- | --- | --- |
| 1 | Enroll | Sign in with password on staging → accept the post-sign-in passkey prompt → complete Face ID/Touch ID | System passkey sheet appears; credential created; enrollment completes |
| 2 | Sign in | Sign out → "Sign in with a passkey" → Face ID/Touch ID | Credential picker offers the enrolled passkey; sign-in completes the full SSO journey and reaches the app |
| 3 | Cancel | "Sign in with a passkey" → cancel the biometric sheet | Land back on the sign-in form; password sign-in still works |
| 4 | No credential | "Sign in with a passkey" on an account with no passkey | Clear "no passkey found" result; never a lockout |
| 5 | OAuth journey | Rows 2–4 launched from the ConX app's OAuth flow | Redirect completes and returns an authorization code; the app reaches its authenticated home |
| 6 | Regional storefront | Row 2 on a non-`.com` staging storefront (or the CON-4 recorded fallback if that path was ruled out) | Same passkey works via Related Origin Requests under the single `webcredentials` RP-host association |

## Symptom of a missing or stale association

If a passkey ceremony resolves in Safari but fails inside Topaz **on the same device**,
the web-credentials association — not app code — is the first suspect:

- The sheet never appears and the ceremony rejects with `NotAllowedError`
  ("The request is not allowed by the user agent or the platform in the current
  context") when the app lacks the entitlement or the AASA omits the app id.
- Check `swcd` in Console during install/launch for the association verdict before
  debugging anything else.
- CON-4 observed that a *removed* association keeps working in Topaz until the device
  reboots — a stale positive result survives even reinstalling the app — so negative
  test results require a reboot to be trustworthy.
