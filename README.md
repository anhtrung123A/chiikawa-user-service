# 🧭 API Overview

## 📘 Introduction

This service is a **Ruby on Rails (API-only)** backend providing authentication, profile management, address handling, and account unlock functionality.
It follows RESTful conventions and uses **JWT-based authentication** for stateless sessions.

Key Features:

* 🔐 **Authentication & Session Management** (login, logout, refresh token)
* 👤 **User Registration & Profile API**
* 📫 **Address Management** (CRUD + default address)
* 🚪 **Account Unlock Flow**
* 🍪 **Secure Cookie & Token Handling**
* 📦 **Dockerized Setup** for easy local deployment

---

## 🧰 Tech Stack

| Component                       | Description                    |
| ------------------------------- | ------------------------------ |
| **Ruby on Rails**               | API backend framework          |
| **PostgreSQL**                  | Primary database               |
| **Redis (optional)**            | Background job & cache store   |
| **Devise**                      | Authentication framework       |
| **JWT (via Warden/Devise JWT)** | Access token authentication    |
| **Mailer (ActionMailer)**       | Account unlock & notifications |
| **Docker Compose**              | Environment orchestration      |

---

## ⚙️ Project Structure

```
app/
 ├─ controllers/
 │   ├─ api/
 │   │   ├─ v1/
 │   │   │   ├─ users/
 │   │   │   │   ├─ sessions_controller.rb
 │   │   │   │   ├─ registrations_controller.rb
 │   │   │   │   └─ confirmations_controller.rb
 │   │   │   ├─ profile_controller.rb
 │   │   │   ├─ token_controller.rb
 │   │   │   ├─ account_unlock_controller.rb
 │   │   │   ├─ addresses_controller.rb
 │   │   │   ├─ password_recovery_controller.rb
 │   │   │   └─ line_auth_controller.rb
 ├─ mailers/
 │   ├─ account_unlock_mailer.rb
 │   └─ password_recovery_mailer.rb
 ├─ models/
 │   ├─ user.rb
 │   └─ address.rb
 └─ services/
     ├─ refresh_token_service.rb
```

---

## 🐳 Running the Project with Docker Compose

### 1️⃣ Clone the Repository

```bash
git clone https://https://github.com/anhtrung123A/chiikawa-user-service/
cd chiikawa-user-service
```

### 2️⃣ Create `.env` File

Create a `.env` file in the project root:

```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=yourpassword
POSTGRES_DB=yourdb
RAILS_ENV=development
JWT_SECRET=your_jwt_secret
```

### 3️⃣ Start Services

```bash
docker compose up --build
```

This command will:

* Build the Rails API container
* Start PostgreSQL and Redis (if configured)
* Expose the API at `http://localhost:3000`

---

## 🚀 Available Services

| Service              | URL                     | Description               |
| -------------------- | ----------------------- | ------------------------- |
| **Rails API**        | `http://localhost:3000` | Main API backend          |
| **PostgreSQL**       | `localhost:5432`        | Database                  |
| **Redis (optional)** | `localhost:6379`        | Background jobs / caching |

---

## 🔑 Authentication

All protected endpoints require the JWT in the `Authorization` header:

```
Authorization: Bearer <your_access_token>
```

Tokens are issued on login and can be refreshed via the `/api/v1/token/refresh` endpoint.

---


## 📝 User Registration (Sign Up)

### Endpoint

```
POST /api/v1/users
```

### Description

Creates a new user account with email, password, and full name.
This endpoint uses **Devise** under the hood but returns a custom JSON response.

---

### Request

| Field                   | Type     | Required | Description                                 |
| ----------------------- | -------- | -------- | ------------------------------------------- |
| `email`                 | `string` | ✅        | User’s email address (must be unique).      |
| `password`              | `string` | ✅        | Password (minimum 6 characters by default). |
| `password_confirmation` | `string` | ✅        | Must match the password field.              |
| `full_name`             | `string` | ✅        | User’s full name.                           |

#### Example Request Body

```json
{
  "user": {
    "email": "phamtrung.tlh@gmail.com",
    "password": "123456",
    "password_confirmation": "123456",
    "full_name": "Trung Pham"
  }
}
```

---

### Response

#### ✅ **201 Created**

```json
{
  "message": "signed up successfully",
  "user": {
    "id": 8,
    "email": "phamtrung.tlh@gmail.com",
    "full_name": "Trung Pham"
  }
}
```

#### ❌ **422 Unprocessable Entity**

Returned when validation fails (e.g., email already taken, password mismatch, etc.)

```json
{
  "errors": [
    "Email has already been taken",
    "Password confirmation doesn't match Password"
  ]
}
```

---

### Example Request (cURL)

```bash
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "phamtrung.tlh@gmail.com",
      "password": "123456",
      "password_confirmation": "123456",
      "full_name": "Trung Pham"
    }
  }'
```

---

## 🔐 User Session — Login

### **Endpoint**

```
POST /api/v1/users/sign_in
```

### **Description**

Authenticate a user using their email and password.
If credentials are valid and the account is active, the server issues a **refresh token cookie** and returns basic user information.
If the account is locked, login is forbidden.

---

### **Headers**

| Key            | Value              | Required | Description              |
| -------------- | ------------------ | -------- | ------------------------ |
| `Content-Type` | `application/json` | ✅        | Body format              |
| `Accept`       | `application/json` | ✅        | Expected response format |

---

### **Request Body**

```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "remember_me": true
  }
}
```

| Field         | Type    | Required | Description                                           |
| ------------- | ------- | -------- | ----------------------------------------------------- |
| `email`       | string  | ✅        | User’s email                                          |
| `password`    | string  | ✅        | User’s password                                       |
| `remember_me` | boolean | ❌        | Keep user logged in longer (persistent refresh token) |

---

### **Behavior**

* The server checks whether the user is **locked** using `LockedUserChecker`.
* If **locked**, a 403 response is returned.
* Otherwise:

  * A **refresh token** is generated and stored (via `RefreshTokenService.create_for_user`).
  * A **signed refresh token cookie** is set (via `cookies_sign`).
  * The user’s tracking fields (e.g., last sign-in) are updated.
  * The response returns a success message and user info.

---

### **Success Response**

**Status:** `200 OK`

```json
{
  "message": "signed in successfully",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "line_user_id": "U4a0f2938472..."
  }
}
```

| Field               | Type          | Description                    |
| ------------------- | ------------- | ------------------------------ |
| `message`           | string        | Success message                |
| `user.id`           | integer       | User ID                        |
| `user.email`        | string        | User email                     |
| `user.full_name`    | string        | Full name                      |
| `user.line_user_id` | string / null | Linked LINE account ID, if any |

---

### **Error Responses**

#### 🔸 Account Locked

**Status:** `403 Forbidden`

```json
{
  "message": "your account has been locked"
}
```

#### 🔸 Invalid Credentials (handled by Devise)

**Status:** `401 Unauthorized`

```json
{
  "error": "Invalid email or password"
}
```

---

### **Cookies**

| Name            | Type          | Description                                                 |
| --------------- | ------------- | ----------------------------------------------------------- |
| `refresh_token` | Signed cookie | Long-lived refresh token used for issuing new access tokens |

> **Note:** The `refresh_token` cookie is set automatically in the response.
> Use `/api/v1/token/refresh` to obtain a new access token when it expires.

---

### **Example cURL**

```bash
curl -X POST http://localhost:3000/api/v1/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{
        "user": {
          "email": "user@example.com",
          "password": "password123",
          "remember_me": true
        }
      }' \
  -c cookies.txt
```

*This command also stores the signed refresh token cookie into `cookies.txt` for future requests.*

---

## 🚪 User Session — Logout

### **Endpoint**

```
DELETE /api/v1/users/sign_out
```

### **Description**

Logs out the currently authenticated user.
The request must include a valid **JWT access token** in the `Authorization` header.
The server will invalidate the associated refresh token (if present) and clear authentication cookies.

---

### **Headers**

| Key             | Value                       | Required | Description                     |
| --------------- | --------------------------- | -------- | ------------------------------- |
| `Authorization` | `Bearer <jwt_access_token>` | ✅        | JWT token obtained during login |
| `Accept`        | `application/json`          | ✅        | Expected response format        |

---

### **Behavior**

1. The server extracts the JWT from the `Authorization` header.
2. The corresponding refresh token (if any) is deleted via `RefreshTokenService.delete_token`.
3. All cookies are cleared using `cookies_delete`.
4. A `204 No Content` response is returned — no response body.

---

### **Success Response**

**Status:** `204 No Content`

```json
(no body)
```

✅ The user’s session is fully terminated.
✅ Both access and refresh tokens become invalid.

---

### **Error Responses**

#### 🔸 Missing or invalid JWT token

**Status:** `401 Unauthorized`

```json
{
  "error": "Missing or invalid Authorization header"
}
```

#### 🔸 Token already invalidated / expired

**Status:** `401 Unauthorized`

```json
{
  "error": "Token has expired or is no longer valid"
}
```

---

### **Example cURL**

```bash
curl -X DELETE http://localhost:3000/api/v1/users/sign_out \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5..."
```

---

### **Notes**

* The logout endpoint **requires** a valid JWT token in the `Authorization` header.
* Once logout succeeds:

  * The JWT token should be considered invalid.
  * Any stored refresh token is removed.
  * User must log in again to receive new tokens.

---

## 🔁 Token — Refresh Access Token

### **Endpoint**

```
POST /api/v1/token/refresh
```

### **Description**

Use a valid **refresh token** to obtain a new **JWT access token**.
This endpoint supports two ways of passing the refresh token:

1. In the **request body** (`refresh_token`)
2. Or automatically via a **signed cookie** (`cookies.signed[:refresh_token]`)

---

### **Headers**

| Key            | Value                          | Required | Description                        |
| -------------- | ------------------------------ | -------- | ---------------------------------- |
| `Content-Type` | `application/json`             | ✅        | Body format                        |
| `Accept`       | `application/json`             | ✅        | Expected response format           |
| `Cookie`       | `refresh_token=<signed_token>` | ❌        | Used if token is stored in cookies |

---

### **Request Body (Option 1: JSON Body)**

```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5..."
}
```

### **Request Body (Option 2: Cookie-based)**

No JSON body is needed if the signed `refresh_token` cookie is already present from login.

---

### **Behavior**

* Reads refresh token from:

  * `params[:refresh_token]`, or
  * `cookies.signed[:refresh_token]`.
* If no refresh token is provided → returns `400 Bad Request`.
* If the refresh token is invalid → raises `InvalidRefreshTokenError` → returns `401 Unauthorized`.
* Otherwise, issues a **new JWT access token** using `RefreshTokenService.issue_access_token`.

---

### **Success Response**

**Status:** `200 OK`

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

| Field   | Type   | Description                      |
| ------- | ------ | -------------------------------- |
| `token` | string | New short-lived JWT access token |

---

### **Error Responses**

#### 🔸 Missing refresh token

**Status:** `400 Bad Request`

```json
{
  "error": "missing refresh token"
}
```

#### 🔸 Invalid or expired refresh token

**Status:** `401 Unauthorized`

```json
{
  "error": "invalid refresh token"
}
```

---

### **Example cURL (Body token)**

```bash
curl -X POST http://localhost:3000/api/v1/token/refresh \
  -H "Content-Type: application/json" \
  -d '{
        "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5..."
      }'
```

---

### **Example cURL (Cookie token)**

```bash
curl -X POST http://localhost:3000/api/v1/token/refresh \
  -b cookies.txt
```

---

### **Notes**

---

## 💚 LINE Authentication — Login with LINE

### **Endpoint**

```
POST /api/v1/auth/line
```

### **Description**

Authenticate a user using their **LINE account**.
The endpoint receives an **authorization code** from the LINE OAuth 2.0 flow, exchanges it for an access token, retrieves the user’s LINE profile, and logs them into the system if the account is already linked.

If the LINE account has never been linked before, the API responds with a message indicating that.

---

### **Headers**

| Key            | Value              | Required | Description              |
| -------------- | ------------------ | -------- | ------------------------ |
| `Content-Type` | `application/json` | ✅        | Body format              |
| `Accept`       | `application/json` | ✅        | Expected response format |

---

### **Request Body**

```json
{
  "code": "dskjfldsjklfjsdlfjsdlf",
  "remember_me": true
}
```

| Field         | Type    | Required | Description                                          |
| ------------- | ------- | -------- | ---------------------------------------------------- |
| `code`        | string  | ✅        | LINE authorization code obtained from OAuth redirect |
| `remember_me` | boolean | ❌        | Whether to issue a long-lived refresh token          |

---

### **Behavior**

1. The server receives the LINE OAuth `code`.
2. Calls `https://api.line.me/oauth2/v2.1/token` to exchange the code for a LINE access token.
3. Uses the LINE access token to call `https://api.line.me/v2/profile` and retrieve the user’s LINE ID.
4. Finds a user in the database with a matching `line_user_id`.

   * If none found → returns 401 “not linked”.
   * If found but locked → returns 403 “account locked”.
   * If found and active → logs in the user:

     * Issues refresh token via `RefreshTokenService.create_for_user`
     * Sets signed refresh token cookie
     * Generates JWT access token
     * Sets `Authorization` header (`Bearer <jwt>`)
     * Returns success response with user info

---

### **Success Response**

**Status:** `200 OK`

**Response Headers**

```
Authorization: Bearer <jwt_access_token>
```

**Response Body**

```json
{
  "message": "signed in successfully",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "line_user_id": "U1234567890abcdef"
  }
}
```

| Field               | Type    | Description          |
| ------------------- | ------- | -------------------- |
| `message`           | string  | Status message       |
| `user.id`           | integer | User ID              |
| `user.email`        | string  | User email           |
| `user.full_name`    | string  | Full name            |
| `user.line_user_id` | string  | LINE user identifier |

---

### **Error Responses**

#### 🔸 Missing authorization code

**Status:** `400 Bad Request`

```json
{
  "error": "Code is required"
}
```

#### 🔸 Invalid or expired LINE code

**Status:** `401 Unauthorized`

```json
{
  "error": "invalid_grant"
}
```

#### 🔸 LINE account not linked

**Status:** `401 Unauthorized`

```json
{
  "message": "this line account has never been linked"
}
```

#### 🔸 Account locked

**Status:** `403 Forbidden`

```json
{
  "message": "your account has been locked"
}
```

---

### **Example cURL**

```bash
curl -X POST http://localhost:3000/api/v1/auth/line \
  -H "Content-Type: application/json" \
  -d '{
        "code": "Yh2df9kfj39skdf02lkj4",
        "remember_me": true
      }'
```

---

### **Notes**

* The `code` must come from LINE’s OAuth flow after the user approves your app.
* On success:

  * A new access token (JWT) is returned in the `Authorization` header.
  * A signed refresh token cookie is also issued.
* If the LINE account isn’t linked, prompt the user to **link it first** using the `PATCH /api/v1/auth/line` endpoint.

---

## 🧍‍♂️ Get Profile

### Endpoint

```
GET /api/v1/users/get_profile
```

### Description

Returns the currently authenticated user's profile information along with their default address.

### Authentication

🔒 **Required** — Include a valid **JWT access token** in the request header.

| Header          | Type     | Required | Description                  |
| --------------- | -------- | -------- | ---------------------------- |
| `Authorization` | `string` | ✅        | Format: `Bearer <JWT_TOKEN>` |

---

### Response

#### ✅ **200 OK**

```json
{
  "user": {
    "id": 6,
    "email": "phamtrung.tlh@gmail.com",
    "full_name": "Trung Pham",
    "line_user_id": "Uf2f39b8a3b729c7f7e8c5c3c5a8d4e1b",
    "created_at": "2025-10-09T06:21:38.123Z",
    "updated_at": "2025-10-09T08:45:00.123Z"
  },
  "default_address": {
    "id": 3,
    "city": "Ho Chi Minh City",
    "location_detail": "123 Lê Lợi, Q.1",
    "phone_number": "0909123456",
    "recipient_name": "Trung Pham",
    "is_default_address": true
  }
}
```

#### 🔒 **401 Unauthorized**

Returned if the JWT token is missing or invalid.

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

### Example Request

```bash
curl -X GET http://localhost:3000/api/v1/users/get_profile \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

---

## 🔐 Password Recovery Flow

### Overview

This feature allows users to reset their password securely using a One-Time Password (OTP) sent via email.
The process has **three steps**:

1. Request an OTP (`POST /api/v1/password_recovery`)
2. Verify the OTP (`POST /api/v1/password_recovery/verify_otp`)
3. Reset the password (`PATCH /api/v1/password_recovery/recover`)

---

## 1️⃣ Request Password Recovery OTP

### Endpoint

```
POST /api/v1/password_recovery
```

### Description

Send an OTP code to the user's email if it exists in the system.
Prevents multiple requests in short time by enforcing a cooldown via Redis TTL.

### Request Body

| Field   | Type     | Required | Description                          |
| ------- | -------- | -------- | ------------------------------------ |
| `email` | `string` | ✅        | The user’s registered email address. |

#### Example

```json
{
  "email": "phamtrung.tlh@gmail.com"
}
```

---

### Response

#### ✅ **200 OK**

When an OTP is successfully sent:

```json
{
  "message": "OTP sent to your email"
}
```

If the user requests OTP too soon (still under cooldown):

```json
{
  "message": "Please wait 45 seconds before requesting a new OTP"
}
```

If the email does not exist:

```json
{
  "error": "Email not found"
}
```

---

## 2️⃣ Verify OTP

### Endpoint

```
POST /api/v1/password_recovery/verify_otp
```

### Description

Verifies the 6-digit OTP code.
If valid, returns a **temporary recovery session token** valid for 15 minutes.

### Request Body

| Field   | Type      | Required | Description                        |
| ------- | --------- | -------- | ---------------------------------- |
| `email` | `string`  | ✅        | User’s email address.              |
| `otp`   | `integer` | ✅        | The 6-digit OTP received by email. |

#### Example

```json
{
  "email": "phamtrung.tlh@gmail.com",
  "otp": 123456
}
```

---

### Response

#### ✅ **200 OK**

```json
{
  "message": "success",
  "token": "fjdslkfjlsdjfkjdsfkljsdklfjsdf"
}
```

#### ❌ **200 OK** (invalid OTP)

```json
{
  "error": "OTP is invalid or expired"
}
```

---

## 3️⃣ Recover Password

### Endpoint

```
PATCH /api/v1/password_recovery/recover
```

### Description

Reset the password using the **temporary recovery token** issued from step 2.

### Request Body

| Field                   | Type     | Required | Description                    |
| ----------------------- | -------- | -------- | ------------------------------ |
| `email`                 | `string` | ✅        | User’s email.                  |
| `token`                 | `string` | ✅        | Recovery session token.        |
| `password`              | `string` | ✅        | New password.                  |
| `password_confirmation` | `string` | ✅        | Must match the password field. |

#### Example

```json
{
  "email": "phamtrung.tlh@gmail.com",
  "token": "fdnsjkfdsnjkdfsjkdfsnjfksd",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

---

### Response

#### ✅ **200 OK**

```json
{
  "message": "Password has been successfully updated"
}
```

#### ❌ **401 Unauthorized**

Invalid or expired session token.

```json
{
  "error": "Session token is invalid or expired"
}
```

#### ❌ **422 Unprocessable Entity**

When passwords don’t match or are same as the old one.

```json
{
  "error": "Passwords do not match"
}
```

#### ❌ **404 Not Found**

```json
{
  "error": "User not found"
}
```

---

## 🔓 Account Unlock

### Overview

If a user’s account has been locked (for example due to too many failed login attempts), they can request an unlock email.
The email contains a link that calls the `unlock` endpoint to restore account access.

---

## 1️⃣ Request Unlock Instruction Email

### Endpoint

```
POST /api/v1/users/unlock
```

### Description

Sends an **account unlock email** to the user if the account is currently locked.
If the account is not locked, the API will respond accordingly.

---

### Request Body

| Field   | Type     | Required | Description                              |
| ------- | -------- | -------- | ---------------------------------------- |
| `email` | `string` | ✅        | The registered email of the locked user. |

#### Example

```json
{
  "email": "phamtrung.tlh@gmail.com"
}
```

---

### Response

#### ✅ **200 OK**

If the user is locked and an email is sent:

```json
{
  "message": "Unlock instruction email has been sent to your email"
}
```

If the user exists but is not locked:

```json
{
  "message": "user is not locked"
}
```

#### ❌ **404 Not Found**

```json
{
  "error": "user not found"
}
```

#### ❌ **422 Unprocessable Entity**

```json
{
  "error": "Failed to create unlock token",
  "details": ["Unlock token can't be blank"]
}
```

---

## 2️⃣ Unlock Account (via Email Link)

### Endpoint

```
GET /api/v1/users/unlock
```

### Description

Unlocks a user’s account using the token included in the email link.
This request is normally triggered when the user clicks the unlock URL in the email.

---

### Query Parameters

| Parameter      | Type      | Required | Description                      |
| -------------- | --------- | -------- | -------------------------------- |
| `user_id`      | `integer` | ✅        | The ID of the user to unlock.    |
| `unlock_token` | `string`  | ✅        | The unlock token sent via email. |

#### Example

```
GET /api/v1/users/unlock?user_id=12&unlock_token=abc123xyz
```

---

### Response

#### ✅ **302 Redirect**

Redirects the user to the login page on successful unlock:

```
https://chiikawamarket.jp/en/account/login
```

#### ❌ **422 Unprocessable Entity**

If parameters are missing or malformed:

```json
{
  "message": "bad format"
}
```

#### ❌ **401 Unauthorized**

If the unlock token is invalid:

```json
{
  "error": "unlock token invalid"
}
```

#### ❌ **404 Not Found**

If the user ID does not exist:

```json
{
  "error": "user not found"
}
```

#### ❌ **422 Unprocessable Entity**

If the unlock operation fails:

```json
{
  "error": "Failed to unlock account",
  "details": ["Locked_at can't be nil"]
}
```

---

## 🏠 Address Management

### Overview

All address endpoints require authentication (`Bearer <JWT>`).
Each user can manage multiple addresses, with **one default address** at a time.

---

### 🔐 Authentication

| Header          | Type     | Required | Description                  |
| --------------- | -------- | -------- | ---------------------------- |
| `Authorization` | `string` | ✅        | Format: `Bearer <JWT_TOKEN>` |

---

## 📋 Get All Addresses

### Endpoint

```
GET /api/v1/addresses
```

### Description

Fetches all addresses that belong to the current authenticated user.

### Response

#### ✅ **200 OK**

```json
{
  "data": [
    {
      "id": 1,
      "city": "Ho Chi Minh City",
      "location_detail": "123 Lê Lợi, Q.1",
      "recipient_name": "Trung Pham",
      "phone_number": "0909123456",
      "country": "Vietnam",
      "province": "HCM",
      "is_default_address": true
    }
  ]
}
```

---

## 📍 Get a Specific Address

### Endpoint

```
GET /api/v1/addresses/:id
```

### Description

Returns details for a single address owned by the authenticated user.

### Example

```
GET /api/v1/addresses/3
```

### Response

#### ✅ **200 OK**

```json
{
  "data": {
    "id": 3,
    "city": "Hanoi",
    "location_detail": "25 Nguyễn Trãi",
    "recipient_name": "Phuong Le",
    "phone_number": "0988000111",
    "country": "Vietnam",
    "province": "HN",
    "is_default_address": false
  }
}
```

#### ❌ **404 Not Found**

```json
{
  "error": "address not found"
}
```

---

## ➕ Create Address

### Endpoint

```
POST /api/v1/addresses
```

### Description

Creates a new address for the current user.
If it’s the user’s **first address**, it automatically becomes the default.

### Request Body

| Field                | Type      | Required | Description                                         |
| -------------------- | --------- | -------- | --------------------------------------------------- |
| `city`               | `string`  | ✅        | City name.                                          |
| `location_detail`    | `string`  | ✅        | Detailed address (street, ward, etc.).              |
| `recipient_name`     | `string`  | ✅        | Recipient’s name.                                   |
| `phone_number`       | `string`  | ✅        | Recipient’s phone number.                           |
| `country`            | `string`  | ✅        | Country.                                            |
| `province`           | `string`  | ✅        | Province/State.                                     |
| `is_default_address` | `boolean` | ❌        | Optional; ignored if it’s the user’s first address. |

#### Example

```json
{
  "address": {
    "city": "Da Nang",
    "location_detail": "45 Tran Hung Dao",
    "recipient_name": "Trung Pham",
    "phone_number": "0912345678",
    "country": "Vietnam",
    "province": "DN"
  }
}
```

### Response

#### ✅ **201 Created**

```json
{
  "message": "success"
}
```

#### ❌ **422 Unprocessable Entity**

```json
{
  "errors": ["City can't be blank"]
}
```

---

## ✏️ Update Address

### Endpoint

```
PATCH /api/v1/addresses/:id
```

### Description

Updates an existing address and resets all others to `is_default_address: false`.

### Example

```json
{
  "address": {
    "city": "Hanoi",
    "location_detail": "25 Nguyễn Trãi",
    "is_default_address": true
  }
}
```

### Response

#### ✅ **200 OK**

```json
{
  "message": "success",
  "data": {
    "id": 3,
    "city": "Hanoi",
    "location_detail": "25 Nguyễn Trãi",
    "recipient_name": "Phuong Le",
    "is_default_address": true
  }
}
```

#### ❌ **422 Unprocessable Entity**

```json
{
  "errors": ["Phone number can't be blank"]
}
```

---

## 🗑️ Delete Address

### Endpoint

```
DELETE /api/v1/addresses/:id
```

### Description

Deletes an existing address unless it is the **default address**.

### Response

#### ✅ **200 OK**

```json
{
  "message": "success"
}
```

#### ❌ **400 Bad Request**

```json
{
  "error": "You can't delete default address."
}
```

#### ❌ **422 Unprocessable Entity**

```json
{
  "errors": ["Failed to delete address"]
}
```

---

## ⭐ Set Default Address

### Endpoint

```
PATCH /api/v1/addresses/set_default_address?id=:id
```

### Description

Marks a specific address as default and clears the default flag on all others.

### Example

```
PATCH /api/v1/addresses/set_default_address?id=5
```

### Response

#### ✅ **200 OK**

```json
{
  "message": "success"
}
```

#### ❌ **422 Unprocessable Entity**

```json
{
  "errors": ["Invalid address ID"]
}
```

---

## 🏠 Get Default Address

### Endpoint

```
GET /api/v1/addresses/default_address
```

### Description

Fetches the user’s current default address.

### Response

#### ✅ **200 OK**

```json
{
  "data": {
    "id": 3,
    "city": "Ho Chi Minh City",
    "location_detail": "123 Lê Lợi, Q.1",
    "recipient_name": "Trung Pham",
    "phone_number": "0909123456",
    "country": "Vietnam",
    "province": "HCM",
    "is_default_address": true
  }
}
```

#### ✅ **200 OK (no address yet)**

```json
{
  "message": "You haven't created any addresses yet."
}
```

---





