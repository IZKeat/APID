# Permission Control System - Backend Robustness Plan

## 1. Database Schema Design (Firestore)

We will add a `permissions` map field to the `users` collection. This allows for granular control without breaking existing role logic.

### Structure

```json
// users/{uid}
{
  "role": "student" | "merchant" | "admin",
  "permissions": {
    // Student Permissions
    "access_library": true,
    "access_main_gate": true,

    // Merchant Permissions
    "can_scan": true,
    "can_refund": false
  }
}
```

## 2. Permission Definitions

### Student Role

| Permission Key     | Description                    | Default |
| :----------------- | :----------------------------- | :------ |
| `access_library`   | Allows entry to library        | `true`  |
| `access_main_gate` | Allows entry through main gate | `true`  |

### Merchant Role

| Permission Key | Description              | Default |
| :------------- | :----------------------- | :------ |
| `can_scan`     | Allows scanning user QRs | `true`  |
| `can_refund`   | Allows issuing refunds   | `false` |

## 3. Backend Implementation Strategy

### `UserService` Updates

We will add the following methods to `lib/services/user_service.dart`:

1.  `updateUserPermissions(String uid, Map<String, bool> permissions)`: Updates the specific permissions for a user.
2.  `checkPermission(String uid, String permissionKey)`: Verifies if a user has a specific permission (useful for security rules or backend checks).

### Security Rules (Future Consideration)

Eventually, Firestore Security Rules should be updated to enforce these permissions at the database level.

## 4. Migration Strategy

- Existing users won't have the `permissions` field.
- The code must handle `null` permissions by defaulting to `true` (or `false` depending on security posture).
- We will implement a "lazy migration" where permissions are created when an admin first edits them.

## 5. Next Steps

1.  Modify `UserService` to include permission management logic.
2.  Create a test script to verify permission updates.
