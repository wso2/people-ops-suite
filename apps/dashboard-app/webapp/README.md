# Authentication & Authorization in IAPM Web Template

### TL;DR

We use **Asgardeo** (`asgardeo/auth-react`) for authentication and a small **state machine** to steer the UI through `loading → authenticating → authenticated/unauthenticated`. After a successful sign-in, we initialize an API client with the ID token, fetch user data, privileges, and app config into **Redux**, and then render either the app or a login screen. We also show an **idle-session warning** after 15 minutes of inactivity.

## High-Level Architecture

```jsx
<App>
  └─ <AuthProvider config={asgardeoConfig}>   // from asgardeo/auth-react
       └─ <AppAuthProvider>                   // our wrapper & logic
            └─ <SecureApp fallback={<PreLoader/>}>  // guards the tree
                 └─ renderContent()                 // state-driven UI:
                      • "loading"         → <PreLoader/>
                      • "authenticating"  → <PreLoader/>
                      • "authenticated"   → {children} (with AuthContext)
                      • "unauthenticated" → <LoginScreen/>

```

- **AuthProvider** (Asgardeo): SDK wrapper configured via a `config` object.
- **AppAuthProvider**: Our context provider + auth flow coordination.
- **SecureApp**: Asgardeo’s secure mount that protects the app tree.
- **Redux**: Stores user info, decoded ID token, privileges, and app config.

## The Auth Context:

`AuthContext.tsx` exports:

- **Provider**: `AppAuthProvider`
- **Hook**: `useAppAuthContext()`

From Asgardeo’s `useAuthContext()` hook, we use:

- `signIn()`, `signOut()`
- `isAuthenticated()`
- `trySignInSilently()`
- `getBasicUserInfo()`, `getDecodedIDToken()`, `getIDToken()`
- `refreshAccessToken()` (refresh logic)
- `state` (e.g., `state.isLoading`, `state.isAuthenticated`)

> On the very first load, we cache the URL the user wanted in localStorage['iapm-app-redirect-url'] so we can return them there after login.

### The Simple State Machine

**We model the UI around a tiny state machine:**

```tsx
type AppState = "loading" | "unauthenticated" | "authenticating" | "authenticated";
```

**The core effect reacts to Asgardeo’s state:**

```tsx
useEffect(() => {
  let mounted = true;

  const initializeAuth = async () => {
    try {
      setAppState("loading");

      if (state.isLoading) return;

      if (state.isAuthenticated) {
        setAppState("authenticating");
        await setupAuthenticatedUser();
        if (mounted) setAppState("authenticated");
      } else {
        const silentSignInSuccess = await trySignInSilently();
        if (mounted) {
          setAppState(silentSignInSuccess ? "authenticating" : "unauthenticated");
        }
      }
    } catch {
      if (mounted) {
        // Example: update an error status if you track auth failures
        // auth.status = State.failed;
        setAppState("unauthenticated");
      }
    }
  };

  initializeAuth();
  return () => {
    mounted = false;
  };
}, [state.isAuthenticated, state.isLoading]);
```

**What this does**

1. We call the initializeAuth() method to initialize a user. First, it will set the appState to “loading” and return if the asgardeo is still loading.
2. If the asgardeo is loaded and already **authenticated**, switch to **`authenticating`** and run our post-login setup.
3. If not authenticated, attempt **silent sign-in**:
   - Success → **`authenticating`** (continue setup)
     - It will run the useEffect again.
   - Fail → **`unauthenticated`** (show login)
     - If it failed, we’ll log out the user session and direct the user to a login screen. ( Most of the time, it will directly redirect to the asgardeo login screen because we are logging out the user session )

### Post-Login Setup (Fetching What We Need)

```tsx
const setupAuthenticatedUser = async () => {
  const [userInfo, idToken, decodedIdToken] = await Promise.all([
    getBasicUserInfo(),
    getIDToken(),
    getDecodedIDToken(),
  ]);

  // Store identity in Redux
  dispatch(setUserAuthData({ userInfo, decodedIdToken }));

  // Initialize API client with auth
  new APIService(idToken, refreshAccessToken); // or a refresh function

  // Load the rest of the app context
  await dispatch(getUserInfo()); // HRIS user profile
  await dispatch(loadPrivileges()); // authorization data
  await dispatch(fetchAppConfig()); // app-level config
};
```

**Why this order?**

Think of the auth flow as answering three questions in sequence:

1. Who is this user? (identity)
2. Can we talk to our backend securely on their behalf? (API client + token)
3. What are they allowed to see/do in the app? (authorization + config)

We follow that order to keep the UI predictable, secure, and fast.

---

**1) We start by fetching identity from Asgardeo:**

- `getBasicUserInfo()` – lightweight profile info (name, email, etc.)
- `getIDToken()` – the token we’ll send with backend calls
- `getDecodedIDToken()` – the claims we can read on the client

We then store **`userInfo`** and **`decodedIdToken`** in **Redux**.

This gives the app a single source of truth for “who’s logged in” before we do anything else. Components can safely read identity without waiting for backend calls to finish.

> **Storing only what the UI needs (not the raw idToken) avoids accidental leaks and keeps identity access simple.**

---

**2) Next, we initialize `APIService(idToken, refreshAccessToken)`.**

- Every backend request now carries a **valid** token.
- If the token expires, the **refresh function** can fetch a new one behind the scenes.
- This prevents “401 loops” and messy retry logic scattered across components.

---

**3) Fetch what drives the app (with the secured client)**

Now that requests are authenticated, we load the app’s core data, usually **in parallel**:

- **User profile** (`getUserInfo`) — source-of-truth from HRIS.
- **Privileges** (`loadPrivileges`) — determines which routes/features are visible.
- **App config** (`fetchAppConfig`) — app-specific settings

---

**4) Centralized status + error handling**

Each slice tracks its own **loading/success/error** state and updates Redux. If something fails, our **`AppHandler.tsx`** handles it in one place (show a friendly message, retry, or redirect). That keeps error UX consistent across the app and stops one-off hacks from creeping into components. More about AppHandler.

### Rendering: One Function, Four States

```tsx
const renderContent = () => {
  switch (appState) {
    case "loading":
      return <PreLoader isLoading message="Loading..." />;

    case "authenticating":
      return <PreLoader isLoading message="Authenticating..." />;

    case "authenticated":
      return <AuthContext.Provider value={authContext}>{props.children}</AuthContext.Provider>;

    case "unauthenticated":
      return (
        <AuthContext.Provider value={authContext}>
          <LoginScreen />
        </AuthContext.Provider>
      );

    default:
      return null;
  }
};
```

- **`PreLoader`** keeps the UI responsive during SDK init and data fetches.
- **Authenticated** → render the app with `AuthContext` available.
- **Unauthenticated** → render `LoginScreen` (still providing context so you can call `appSignIn`).

The component returns `SessionWarningDialog` and wraps everything with **`SecureApp`**, which protects the app and shows the fallback while it’s resolving.

### Sign-In / Sign-Out Helpers

```tsx
const appSignOut = async () => {
  setAppState("loading");
  localStorage.setItem("iapm-app-state", "logout");
  await signOut();
  setAppState("unauthenticated");
};

const appSignIn = async () => {
  signIn();
  setAppState("loading");
  localStorage.setItem("iapm-app-state", "active");
};
```

These helpers let any component trigger auth transitions via the context.

### Authorization: Where It Happens

Authorization is driven by **privileges** loaded into Redux via `loadPrivileges()`.

Routes and components read those privileges and only render what the user is allowed to see. In other words:

- **Authentication** proves who you are (Asgardeo).
- **Authorization** decides what you can access (our privilege model + conditional rendering).

### Session Management (Idle Timeout)

We track inactivity and warn the user before logging them out:

```tsx
const timeout = 15 * 60 * 1000; // 15 minutes
const promptBeforeIdle = 4000; // warn 4 seconds before idle

useIdleTimer({ onPrompt, timeout, promptBeforeIdle, throttle: 500 });
```

When the user is idle, we show **`SessionWarningDialog`**:

- **Continue** → `handleContinue()` keeps the session alive.
- **Do nothing** → we call `appSignOut()`.

### Smart Redirects After Login

When a user first hits the app, we store the current path in

`localStorage['iapm-app-redirect-url']`.

After authentication completes, we can send them back **exactly where they started**, which makes deep links and bookmarks just work.

## APIService

### Imports

```tsx
import axios, { AxiosInstance, CancelTokenSource } from "axios";
import * as rax from "retry-axios";
```

- `axios` is the HTTP client we use to call our backend.
- `AxiosInstance` is the type of an Axios client (handy for TypeScript).
- `CancelTokenSource` represents a thing we can call `.cancel()` on to cancel a request.
- `retry-axios` (“rax”) is a plugin that can **automatically retry** requests when they fail with certain status codes (In our case 401).

### Class Shell

- We wrap everything in a **class** so we can encapsulate logic and share one configured Axios instance across the app.

### Static Fields (Shared Singletons)

```tsx
  private static _instance: AxiosInstance;
  private static _idToken: string;
  private static _cancelTokenSource = axios.CancelToken.source();
  private static _cancelTokenMap: Map<string, CancelTokenSource> = new Map();
  private static callback: () => Promise<{ idToken: string }>;

  private static _isRefreshing = false;
  private static _refreshPromise: Promise<{ idToken: string }> | null = null;
```

- `static` means these belong to the **class itself** (not each object). We’re building a **singleton**—one shared HTTP client for the whole app.
- `_instance`: the one **Axios client** everyone will use.
- `_idToken`: the current **JWT** we attach to every request so the server knows who we are.
- `_cancelTokenSource`: a general cancel source (not heavily used here—more important is the map below).
- `_cancelTokenMap`: remembers a **cancel token per endpoint URL**. If you call the same endpoint again before the previous one finishes, we can cancel the old one (prevents duplicate work and “race” bugs).
- `callback`: a function we got from the auth code (Asgardeo) to **refresh** the token when it expires. (When it gets a 401 or 405 from the choreo gateway) It returns `{ idToken }`.
- `_isRefreshing` + `_refreshPromise`: used to make sure we **refresh once at a time** and share the same refresh promise among all waiting requests.

### Constructor (Runs Once When You `new APIService(...)`)

```tsx
  constructor(idToken: string, callback: () => Promise<{ idToken: string }>) {
    APIService._instance = axios.create();
    rax.attach(APIService._instance);
```

- `axios.create()` makes a **fresh client** (so we don’t pollute global axios defaults).
- `rax.attach(...)` enables **retry-axios** on this client.

```tsx
APIService._idToken = idToken;
APIService.updateRequestInterceptor();
APIService.callback = callback;
```

- Save the **initial** ID token.
- Call `updateRequestInterceptor()` to install a **request interceptor** (explained later) that:
  - Adds auth headers on every request
  - Manages cancel tokens per endpoint
- Save the **refresh callback** so we can get new tokens when needed.

```tsx
    (APIService._instance.defaults as unknown as rax.RaxConfig).raxConfig = {
      retry: 3,
      instance: APIService._instance,
      httpMethodsToRetry: [
        "GET",
        "HEAD",
        "OPTIONS",
        "DELETE",
        "POST",
        "PATCH",
        "PUT",
      ],
      statusCodesToRetry: [[401, 401]],
      retryDelay: 100,
```

- This config tells retry-axios:
  - `retry: 3`: try up to **3 retries**.
  - `httpMethodsToRetry`: which HTTP methods are allowed to retry (we include most).
  - `statusCodesToRetry: [[401, 401]]`: only **401 Unauthorized** should trigger a retry (this is important—401 usually means our token expired).
  - `retryDelay: 100`: wait **100ms** between retries.

```tsx
      onRetryAttempt: async (err) => {
        if (!APIService._isRefreshing) {
          APIService._isRefreshing = true;
          APIService._refreshPromise = APIService.callback()
            .then((res) => {
              APIService.updateTokens(res.idToken);
              APIService._instance.interceptors.request.clear();
              APIService.updateRequestInterceptor();
              return res;
            })
            .finally(() => {
              APIService._isRefreshing = false;
              APIService._refreshPromise = null;
            });
        }
        return APIService._refreshPromise;
      },
```

- `onRetryAttempt` runs **when a retry is about to happen** (e.g., we just got a 401).
- If we’re **not already refreshing**:
  - Set `_isRefreshing = true`.
  - Call the `callback()` You passed in (this asks Asgardeo for a **fresh ID token**).
  - When it returns:
    - `updateTokens(res.idToken)`: store the **new** token.
    - `interceptors.request.clear()` → remove old interceptors (they may hold old tokens).
    - `updateRequestInterceptor()` → re-install a **fresh** interceptor using the **new token**.
  - Reset flags in `.finally(...)`.
- If a refresh is **already in progress**, we just **return the same promise** so all waiting requests reuse the **same refresh**.

> Why this design?
>
> - 401 probably means the token expired.
> - We **refresh once**, update headers for all next requests, and then retry.

### Public Static Helpers

```tsx
  public static getInstance(): AxiosInstance {
    return APIService._instance;
  }
```

- **How the rest of your app** gets the axios client: `APIService.getInstance().get("/users")`.

---

```tsx
  public static getCancelToken() {
    return APIService._cancelTokenSource;
  }

  public static updateCancelToken(): CancelTokenSource {
    APIService._cancelTokenSource = axios.CancelToken.source();
    return APIService._cancelTokenSource;
  }
```

- Generic helpers to fetch or replace the top-level cancel token.

---

```tsx
  private static updateTokens(idToken: string) {
    APIService._idToken = idToken;
  }
```

- Store a **fresh** token after refresh.

### The Request Interceptor (The Heartbeat)

```tsx
  private static updateRequestInterceptor() {
    APIService._instance.interceptors.request.use(
      (config) => {
        config.headers.set("Authorization", "Bearer " + APIService._idToken);
        config.headers.set("x-jwt-assertion", APIService._idToken); // Use only when locally runs
```

- A **request interceptor** runs **right before** a request is sent.
- We set two headers:
  - `Authorization: Bearer <token>` → standard way to send a JWT to the server.
  - After the choreo gateway validates the idToken, it will install a new header called `x-jwt-assertion: <token>` and will assign our idToken as its value.  

```tsx
const endpoint = config.url || "";
```

- `endpoint` is the request URL (path). If `config.url` is missing, use `""`.

```tsx
const existingToken = APIService._cancelTokenMap.get(endpoint);
if (existingToken) {
  existingToken.cancel(`Request canceled for endpoint: ${endpoint}`);
}
```

- If we’ve **already** sent a request to the **same endpoint** and it’s still in flight, **cancel it**.
- Why? Suppose a user types in a search box and triggers `/search?q=a`, then `/search?q=ab`, then `/search?q=abc`. We only want the **latest** response. Cancelling previous ones:
  - Saves bandwidth
  - Prevents old responses from flickering the UI

```tsx
        const newTokenSource = axios.CancelToken.source();
        APIService._cancelTokenMap.set(endpoint, newTokenSource);
        config.cancelToken = newTokenSource.token;
        return config;
      },
      (error) => {
        Promise.reject(error);
      }
    );
  }
```

- We create a **new** cancel token for this request and **save it** in the map keyed by the endpoint.
- Assign it to `config.cancelToken` so Axios can cancel it later if needed.
- Return the `config` to continue the request.
- In the error handler, we just **reject** (so the request fails as normal).

### How It All Works Together (Step by Step)

1. **You log in** with Asgardeo. Your app calls `new APIService(idToken, refreshTokenFn)`.
   - We create a configured Axios client.
   - We remember your **ID token**.
   - We install a **request interceptor** to attach the token and manage duplicate requests.
   - We configure **retry-axios** to handle 401s by refreshing the token and retrying.
2. We make API calls in the slices, e.g.:

   ```tsx
   export const getUserInfo = createAsyncThunk("user/getUserInfo", async () => {
     return new Promise<{
       UserInfo: UserInfoInterface;
     }>((resolve, reject) => {
       **APIService.getInstance()
         .get(AppConfig.serviceUrls.userInfo)
         .then((resp) => {
           resolve({
             UserInfo: resp.data,
           });
         })**
         .catch((error: Error) => {
           reject(error);
         });
     });
   });
   ```

   - The **request interceptor** runs:
     - Adds `Authorization` and `x-jwt-assertion` headers.
     - Cancels any previous request to the same endpoint (if still running).
     - Attaches a new cancel token for this call.

3. If the server returns **200 OK**, great—done.
4. If the server returns **401 Unauthorized**:
   - **retry-axios** triggers `onRetryAttempt`.
   - If we aren’t already refreshing:
     - Call `refreshTokenFn()` → get a **new** ID token.
     - Update the token and **reinstall** the request interceptor (so all new requests get the new token).
   - Retry the **original** request automatically with the fresh token.
   - If it still fails after max retries (3), the request is rejected, and your app can handle it (show error message, logout, etc.).

## APP Handler

> This component is the traffic controller for application UI.
>
> It watches global status (auth + app config), decides **what screen to show**, and mounts the router when everything is ready.

### What this file is responsible for

- Shows a **loader** while the app is getting ready.
- Shows a **maintenance** page if the app is in maintenance mode.
- Shows an **error** screen if something failed during startup.
- Otherwise, mounts the **router** with only the routes the current user is allowed to see.

### Imports (what each thing is)

```tsx
import { createBrowserRouter, RouterProvider } from "react-router-dom";

import { useEffect, useState } from "react";

import ErrorHandler from "@component/common/ErrorHandler";
import PreLoader from "@component/common/PreLoader";
import { RootState, useAppSelector } from "@slices/store";

import Layout from "../layout/Layout";
import Error from "../layout/pages/404";
import MaintenancePage from "../layout/pages/Maintenance";
import { getActiveRoutesV2, routes } from "../route";
```

### Local UI state: what mode are we in?

```tsx
const [appState, setAppState] = useState<"loading" | "success" | "failed" | "maintenance">(
  "loading",
);
```

- We track a **simple state machine** for top-level UI:
  - `"loading"` → show spinner
  - `"success"` → show the real app (router)
  - `"failed"` → show error screen
  - `"maintenance"` → show maintenance screen
- It **starts** as `"loading"`.

Think of this as: “what should the user see **right now**?”

### Reading global state from Redux

```tsx
const auth = useAppSelector((state: RootState) => state.auth);
const appConfig = useAppSelector((state: RootState) => state.appConfig);
```

- `auth`: your **authentication slice** (e.g., `status`, `roles`, `mode`, `statusMessage`) where we load our privileges.
- `appConfig`: your **app configuration slice** (e.g., flags, environment, loading status).

These are **global**; they’re updated by thunks like `loadPrivileges()` and `fetchAppConfig()` that you triggered earlier during authentication.

### Build the router (with allowed routes only)

```tsx
const router = createBrowserRouter([
  {
    path: "/",
    element: <Layout />,
    errorElement: <Error />,
    children: getActiveRoutesV2(routes, auth.roles),
  },
]);
```

- We create a **router tree**:
  - Root path `/` renders the `Layout`.
  - `errorElement` is a fallback for routing errors (like a 404).
  - `children` are the **actual pages**, filtered by `getActiveRoutesV2(...)` using the user’s **roles**. This is where **authorization** happens for navigation: only allowed routes are included.

### Decide what to show

```tsx
useEffect(() => {
  if (auth.status === "loading" || appConfig.state === "loading") {
    if (auth.status === "loading")
      loadingMessage = auth.statusMessage ? auth.statusMessage : "loading";
    if (appConfig.state === "loading")
      loadingMessage = auth.statusMessage ? auth.statusMessage : "loading";
    setAppState("loading");
  } else if (auth.status === "success" && appConfig.state === "success") {
    setAppState("success");
  } else if (auth.status === "failed" || appConfig.state === "failed") {
    setAppState("failed");
  } else if (auth.mode === "maintenance" && auth.status === "success") {
    setAppState("maintenance");
  }
}, [auth.status, appConfig.state]);
```

This `useEffect` runs whenever **either** `auth.status` or `appConfig.state` changes. It sets `appState` based on simple rules:

1. If **either** auth **or** app config is still **loading** → show `"loading"`.
2. If **both** succeeded → show `"success"`.
3. If **either** failed → show `"failed"`.
4. If auth.mode is **maintenance** mode **and** auth succeeded → show `"maintenance"`.

We are conditionally rendering the loading message for auth.status and appConfig.state.

### Render the right screen

```tsx
const renderApp = () => {
  switch (appState) {
    case "loading":
      return <PreLoader isLoading={true} message={loadingMessage} />;

    case "failed":
      return <ErrorHandler message={auth.statusMessage} />;

    case "success":
      return <RouterProvider router={router} />;

    case "maintenance":
      return <MaintenancePage />;
  }
};
```

- We **branch** on `appState`:
  - `"loading"` → show the spinner with a message.
  - `"failed"` → show the friendly error screen.
  - `"success"` → mount the **router** (app pages).
  - `"maintenance"` → show the maintenance page.
