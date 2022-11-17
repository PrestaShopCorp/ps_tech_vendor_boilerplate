# PS TechVendor Boilerplate Changelog

## 2022-11-17

[BREAKING] CloudSync Sharing Consent CDC now switches to a new, and definitive interface. The README is up-to-date, the new standard is:

```typescript
const cdc = window.cloudSyncSharingConsent;

// init the cdc on a given anchor, `#prestashop-cloudsync` by default.
cdc.init(anchorSelector = '#prestashop-cloudsync');

// listen to onboarding completed events
cdc.on(eventName: string, callback: function() => any);

// ask for the current state of onboarding
cdc.isOnboardingCompleted(callback?: function() => Boolean);

// asynchronously ask for the current state of onboarding
async cdc.isOnboardingCompleted(): Promise<Boolean>;
```

You may change the anchor name as well:

```html
<div id="share-consent-bar"></div>
```

To:

```html
<div id="prestashop-cloudsync"></div>
```

And remove the zoid script:

```html
<script
  src="https://cdnjs.cloudflare.com/ajax/libs/zoid/9.0.87/zoid.min.js"
  integrity="sha512-PqylMx5T7MS4lZRe4qziZWQ24VWWSF3rNiNJQuswCJHJb+HDW6aQvrTFrIrF+kPl0IS2eFf/ZkFNysjsahEahg=="
  crossorigin="anonymous"
  referrerpolicy="no-referrer"
></script>
```

This allows you to better integrate with the component, and get the proper callback when your onboarding can continues.
That's all!
