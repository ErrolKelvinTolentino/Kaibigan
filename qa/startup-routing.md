# App startup routing

Startup resolves saved preferences and the current authentication state before choosing a screen.

| State | Destination |
| --- | --- |
| Preferences are loading | Loading screen |
| Password recovery link/session | Password reset; routines and setup wait |
| No session or offline choice; introduction unseen | Kai introduction, then authentication |
| No session or offline choice; introduction seen | Login/register |
| Signed in or deliberately offline; companion setup unfinished | Companion and language selection |
| Setup just completed | Home with the bottom navigation |
| Returning user; eligible routine not offered this period | Routine activity above Home |
| Other returning users | Home with Start/Resume controls |

An automatic routine must be enabled, contain an enabled activity, and have trustworthy loaded configuration and completion history. An unfinished current session takes priority; otherwise the routine must belong to the current period and have reached its preferred time. Completed routines do not auto-open.

- Morning: 05:00–12:00; midday: 12:00–17:00; night: 17:00–05:00.
- The night period crosses midnight. Its completion and offer marker remain associated with the evening that started it. Early-morning night sessions expire at 05:00.
- Startup offers are stored per identity and period before navigation. Closing a routine, relaunching during that period, rebuilding Home, or returning from the background does not repeat that automatic offer.
- Opening Routines explicitly may start an unfinished routine before its preferred time. Completed routines can be repeated manually.
- Disabling a routine or removing all its activities prevents automatic launches and stale resumes.
- Slow or failed history/configuration loading opens Home without an automatic routine. A late result cannot subsequently interrupt Home.
- Signing out, leaving offline mode, switching accounts, or entering password recovery resets the navigation stack. Previous protected screens cannot remain above the new gate.

Setup and routine offer markers currently persist on the device, separately for each identity. Completion history remains in the existing local/Supabase record flow.

Regression coverage: `startup_routing_test.dart` and `startup_pages_test.dart`, plus routine, authentication, Home, offline, navigation, and narrow-phone layout suites.
