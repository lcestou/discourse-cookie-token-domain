# discourse-cookie-token-domain

A Discourse plugin to add an additional cookie token at the second-level domain, for sites wanting to do cross-site credential management.

This essentially allows an install at `forums.example.com` to create a cookie token valid at `*.example.com`.

## Requirements

- Discourse 3.0+
- Ruby 3.2+

## Installation

Follow the [Install a Plugin](https://meta.discourse.org/t/install-a-plugin/19157) guide, using `https://github.com/lcestou/discourse-cookie-token-domain` as the repository URL.

## Configuration

After installation, go to **Admin → Settings → Plugins** and configure:

1. **cookie_token_domain_enabled**: Enable/disable the plugin
2. **cookie_token_domain_key**: Set a secret key (minimum 16 characters) for HMAC signing

> ⚠️ **Security Note**: The default is disabled and requires you to set a strong secret key before enabling.

## How It Works

When a user logs in, the plugin creates a cookie named `logged_in` containing:

```json
{
  "username": "CapitaineJohn",
  "user_id": 2,
  "avatar": "/user_avatar/forum.example.com/bonclay/{size}/117_1.png",
  "group": "[VIP]",
  "hmac": "e40575e0f828bcf91b5e30c174dfa4399c72a5acbb32b2a483f8fce42798b1ac"
}
```

The cookie value is Base64 encoded and includes an HMAC signature for verification.

## Verifying the Cookie

### Algorithm

1. Get the `logged_in` cookie
2. URL decode the cookie value
3. Base64 decode the result
4. Parse as JSON
5. Extract the user data (without `hmac`)
6. Compute SHA256 of the JSON payload
7. Compute HMAC-SHA256 using your secret key
8. Compare with the `hmac` field in the cookie

### PHP Example

```php
<?php
$cookie = urldecode($_COOKIE["logged_in"]);
$cookie = base64_decode($cookie);

$user_infos = json_decode($cookie);

$array_hash = [
    'username' => $user_infos->username,
    'user_id' => $user_infos->user_id,
    'avatar' => $user_infos->avatar,
    'group' => $user_infos->group
];

$hash_test = hash('sha256', json_encode($array_hash, JSON_UNESCAPED_SLASHES));
$computed_hmac = hash_hmac('sha256', $hash_test, 'YOUR_SECRET_KEY');

if (hash_equals($computed_hmac, $user_infos->hmac)) {
    echo 'User is logged in';
} else {
    echo 'User is not logged in';
}
```

### Node.js Example

```javascript
const crypto = require('crypto');

// Get the cookie value from your request
const valueOfLoggedInCookie = req.cookies.logged_in;

const uriDecodedPayload = decodeURIComponent(valueOfLoggedInCookie);
const base64DecodedBuffer = Buffer.from(uriDecodedPayload, 'base64');
const preJsonPayload = JSON.parse(base64DecodedBuffer.toString());

const jsonPayload = {
  username: preJsonPayload.username,
  user_id: preJsonPayload.user_id,
  avatar: preJsonPayload.avatar,
  group: preJsonPayload.group,
};

const payloadSha = crypto
  .createHash('sha256')
  .update(JSON.stringify(jsonPayload))
  .digest('hex');

const signed = crypto
  .createHmac('sha256', 'YOUR_SECRET_KEY')
  .update(payloadSha)
  .digest('hex');

if (crypto.timingSafeEqual(Buffer.from(signed), Buffer.from(preJsonPayload.hmac))) {
  console.log('User is logged in');
} else {
  console.log('User is not logged in');
}
```

### SvelteKit Example

```typescript
import { createHash, createHmac, timingSafeEqual } from 'crypto';
import type { Cookies } from '@sveltejs/kit';

interface DiscourseUser {
  username: string;
  user_id: number;
  avatar: string;
  group: string | null;
  hmac: string;
}

export function verifyDiscourseUser(cookies: Cookies, secretKey: string): DiscourseUser | null {
  const cookieValue = cookies.get('logged_in');
  if (!cookieValue) return null;

  try {
    const decoded = Buffer.from(decodeURIComponent(cookieValue), 'base64').toString();
    const payload: DiscourseUser = JSON.parse(decoded);

    const dataToSign = {
      username: payload.username,
      user_id: payload.user_id,
      avatar: payload.avatar,
      group: payload.group,
    };

    const payloadSha = createHash('sha256')
      .update(JSON.stringify(dataToSign))
      .digest('hex');

    const computedHmac = createHmac('sha256', secretKey)
      .update(payloadSha)
      .digest('hex');

    const isValid = timingSafeEqual(
      Buffer.from(computedHmac),
      Buffer.from(payload.hmac)
    );

    return isValid ? payload : null;
  } catch {
    return null;
  }
}
```

## Security Considerations

- Always use HTTPS in production
- Use a strong, random secret key (32+ characters recommended)
- The cookie is set with `httponly: false` (intentionally - for client-side JS reading), `secure` (in production), and `same_site: lax`
- Use timing-safe comparison functions when verifying the HMAC
- **Why `httponly: false`?** This cookie is designed to be read by JavaScript on subdomains. It contains only public user info (username, avatar, group) plus an HMAC signature. No session tokens or sensitive data.

## Changelog

### v0.2
- Updated for Discourse 3.x compatibility
- Added `frozen_string_literal` pragma
- Modernized file structure with proper namespacing
- Renamed settings to follow plugin naming conventions
- Added `secure` and `same_site` cookie attributes
- **Changed `httponly` to `false`** - enables client-side JavaScript reading on subdomains
- Changed default to disabled for security
- Marked secret key setting as `secret: true`
- Improved cookie deletion on logout
- Added check for plugin enabled state before setting cookie

### v0.1
- Initial release by mpgn

## License

MIT

## Credits

- Original plugin by [mpgn](https://github.com/mpgn)
- Updated by [lcestou](https://github.com/lcestou)
