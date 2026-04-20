---
name: harmonyos-atomic-dev
description: >
  HarmonyOS atomic service development expert covering full development lifecycle:
  greenfield development (creating a project from scratch), incremental development
  (adding features to an existing project), bug fixing (locating and fixing bugs),
  and knowledge lookup during development (component usage, Kit capabilities).

  TRIGGER when: user mentions HarmonyOS, ArkTS, ArkUI, atomic service,
  or asks to create a HarmonyOS project from scratch, add features to an existing project,
  fix HarmonyOS bugs, or use specific ArkUI components / Kit capabilities.

  IMPORTANT: This skill focuses on **development and bug fixing** only.
  Design-phase activities (wireframes, user research, visual design) are out of scope.
---
# HarmonyOS Atomic Service Development

> **CRITICAL: Before starting any HarmonyOS task, load the appropriate reference files:**
>
> **For Development Tasks:**
>
> - `reference/arkts.md` — ArkTS language guide, restrictions
> - `reference/review.md` — ArkTs common issues
>
> **For Code Review Tasks:**
>
> - `reference/review.md` — ArkTs common issues
>
> These files contain essential information about ArkTS restrictions (no `any`, no `for..in`, etc.)
> and ArkUI component usage that must be followed to avoid compilation errors.

---

## When to Apply

Use this skill when the task involves the **full HarmonyOS atomic service development lifecycle**. Match the corresponding scenario workflow based on the task type.

### Must Use

This skill MUST be invoked in the following situations, matching the corresponding scenario workflow:

- **Greenfield Development** (Scenario 1): User wants to create a HarmonyOS atomic service project from scratch, follow Phase 1→6 full workflow
- **Incremental Development** (Scenario 2): User is adding new features or pages to an existing project, follow Phase 1→3
- **Bug Fixing** (Scenario 3): User reports a bug or abnormal behavior in an existing feature, follow Phase 1→3
- **Knowledge Lookup**: During development, need to understand specific UI component usage or system capabilities (Kit)

### Recommended

It is recommended to use this skill in the following situations:

- Refactoring existing HarmonyOS code (treat as incremental development scenario)
- Code migration (from @Component to @ComponentV2)
- Code style unification and standardization
- Troubleshooting compilation errors or runtime exceptions

### Skip

There is no need to use this skill in the following situations:

- Product requirement analysis and feature planning (design phase)
- UI/UX design (wireframes, visual design, interaction design)
- User research and usability testing
- Project architecture design (non-code level)
- Backend or Web development unrelated to HarmonyOS

**Decision Criteria**: If the task involves **creating a HarmonyOS project from scratch, adding features to an existing project, or fixing HarmonyOS-related issues**, this skill should be used and the corresponding scenario workflow should be selected.



### Workflow

Select the corresponding workflow based on the user's task type:

| Scenario | Trigger Condition | Steps |
|----------|-------------------|-------|
| **Greenfield Development** | User wants to create a HarmonyOS atomic service project from scratch | Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 |
| **Incremental Development** | User is adding new features or pages to an existing project | Phase 1 → Phase 2 → Phase 3 → Phase 4 |
| **Bug Fixing** | User reports a bug or abnormal behavior in an existing feature | Phase 1 → Phase 2 → Phase 3 → Phase 4 |

> During development, when advanced components or Kit capabilities are needed, refer to "Knowledge Lookup" to supplement the relevant knowledge.

---

#### Scenario 1: Greenfield Development — Build a HarmonyOS Atomic Service from Scratch

**Phase 1: Requirements Collection**

Fully understand the user's requirements before starting. Confirm the following information with the user (skip if already provided):
- What are the core functions of the atomic service? Who are the target users?
- How many Tabs (feature modules) are needed? What are the core pages for each Tab?
- Are there any reference apps or design mockups?

**UI and Interaction Requirements Collection**
If the `.harmonyos/` directory contains design files (`*.html`), these files take **highest priority**. The generated code MUST strictly follow the UI layout, visual style, interaction patterns, and user experience described in the design files(`*.html`). Read all mockup files before coding and ensure every page's appearance and behavior matches the mockup specifications.

**Phase 2: Architecture Planning**

Create a development plan based on the MVVM pattern and present the project structure for user confirmation. **Do not skip this step and start writing code directly.**

```
entry/
└── src/main/ets/
    ├── entryability/          # Entry Ability
    │   └── EntryAbility.ets
    ├── common/                # Common modules
    │   ├── constants/         # Constant definitions
    │   ├── utils/             # Utility functions
    │   ├── models/            # Shared data models
    │   └── components/        # Shared UI components
    ├── home/              # Business module (one independent folder per Tab)
    │   ├── pages/             # Pages for this Tab
    │   ├── components/        # Private components for this Tab
    │   ├── models/            # Data models for this Tab
    │   └── viewmodels/        # ViewModel for this Tab
    ├── xxx/               # Other business modules, same structure as above
    │   ├── pages/
    │   ├── components/
    │   ├── models/
    │   └── viewmodels/
    └── pages/                 # Entry page (Index.ets)
```

After clarifying the responsibilities of each module, present the plan to the user for confirmation.

**Phase 3: Develop Common Module**

Develop common module code for reuse across all business modules:
- Shared data models (models) and constants (constants)
- Common utility functions (utils), such as network request wrappers, data formatting
- Common UI components (components), such as loading indicators, empty state views

**Phase 4: Develop Business Modules**

Develop each business Tab module one by one, each following MVVM layering:
- `models/` — Define data types (interface / class)
- `viewmodels/` — Use `@ObservedV2` + `@Trace` to manage state and business logic
- `pages/` — Use `@ComponentV2` + `@Local` to bind ViewModel and render UI
- `components/` — Extract reusable UI fragments as independent `@ComponentV2`

During development, if you encounter unfamiliar components or APIs, execute "Knowledge Lookup".

**Phase 5: Integrate Entry Files**

Integrate all business modules into the entry page (MainPage.ets):
- Use `Tabs` + `TabContent` to organize each business module
- Configure `Navigation` as the root container for route management
- Verify that Tab switching and page navigation work correctly

**Phase 6: Review Generated Code Quality**

Refer to `reference/review.md` to validate and review code quality.

Note:

1. Ensure import paths are correct when generating code.

---

#### Scenario 2: Incremental Development — Develop New Features Based on Existing Project

**Phase 1: Explore the Project**

If the `.harmonyos/codebase.md` file exists, read it as reference.

Read the project's key files to understand the existing architecture and coding conventions:
1. Entry files and route configuration — Understand page structure and navigation
2. Existing business module directories — Understand module organization and naming conventions
3. Common module — Understand existing shared capabilities that can be reused directly
4. Existing ViewModel / Model — Understand state management and data layer coding patterns

After collecting information, update it to `.harmonyos/codebase.md`.

**Phase 2: Create Development Plan**

Follow the existing project's coding conventions and create an incremental development plan:
- List of new files and their directories
- Existing files that need modification
- Integration method with existing modules

Present the plan to the user for confirmation.

**Phase 3: Implement Development**

Complete the development step by step according to the plan:
- Follow the project's existing naming conventions, file organization, and state management patterns
- Use `@ComponentV2` + `@ObservedV2` for new pages, do not mix legacy `@Component`
- During development, if you encounter unfamiliar components or APIs, execute "Knowledge Lookup"
- After completion, integrate the new module into the entry file or routing

**Phase 4: Review Generated Code Quality**

Refer to `reference/review.md` to validate and review code quality.

---

#### Scenario 3: Bug Fixing — Fix Issues in Existing Projects and Features

**Phase 1: Reproduce and Locate**

1. Understand the issue described by the user, ask follow-up questions if necessary: specific error messages, reproduction steps, expected behavior
2. Read the relevant code files, trace the components, pages, and ViewModels involved
3. Identify the root cause (UI rendering, state management, lifecycle, type errors, route configuration, etc.)

**Phase 2: Create Fix Plan**

Explain the root cause to the user and propose a fix plan:
- Which specific code in which files needs to be modified
- Potential side effects of the fix
- Whether other related code needs to be updated simultaneously

Confirm before proceeding.

**Phase 3: Implement Fix**

Complete the code modifications according to the fix plan:
- Fix the issue itself
- Check if there are similar issues that should be fixed together
- Verify that the fix does not affect other features
- During development, if you encounter unfamiliar components or APIs, execute "Knowledge Lookup"

**Phase 4: Review Generated Code Quality**

Refer to `reference/review.md` to validate and review code quality.

---

#### Knowledge Lookup — Supplement Advanced Knowledge During Development

When encountering the following situations during development, proactively look up the corresponding knowledge documents:

1. **Load the index**: Read `index.md` to get the full knowledge file catalog
2. **Locate the target file**: Based on the current need (component, layout, Kit capability), find the matching file path in the index
3. **Read and integrate**: Read the located document and integrate key usage into the current development context

| Trigger Condition | Index Category | Example |
|-----------------|----------------|---------|
| Need to use a specific UI component | Component Detailed Guides | LazyForEach usage for List → `component/list/list.md` |
| Need to implement complex layout | Component Detailed Guides | Navigation route management → `component/navigation/navigation.md` |
| Need to call system capabilities (Kit) | Kit Capabilities | HTTP network request → `kit/network/network-http.ets` |
| Need to check component API reference | Reference Guides | Scroll container → `reference/scroll_component.md` |



## Hard Rules (Must Follow)

> These rules are mandatory. Violating them means the skill is not working correctly.

### 1. No Dynamic Types

**ArkTS prohibits dynamic typing. Never use `any`, type assertions, or dynamic property access.**

```typescript
// ❌ FORBIDDEN: Dynamic types
let data: any = fetchData();
let obj: object = {};
obj['dynamicKey'] = value;  // Dynamic property access
(someVar as SomeType).method();  // Type assertion

// ✅ REQUIRED: Strict typing
interface UserData {
  id: string;
  name: string;
}
let data: UserData = fetchData();

// Use Record for dynamic keys
let obj: Record<string, string> = {};
obj['key'] = value;  // OK with Record type
```

### 2. Use ComponentV2 and ObservedV2

**Always use @ComponentV2 and @ObservedV2 for new development.**

```typescript
// ❌ OLD: Using legacy @Component and @State
@Component
struct HomePage {
  @State isLoading: boolean = false;
  @State dataList: Item[] = [];
}

// ✅ NEW: Using ComponentV2 and ObservedV2
@ComponentV2
struct HomePage {
  @Local vm: HomePageVM = new HomePageVM();
}

@ObservedV2
export class HomePageVM {
  @Trace isLoading: boolean = false;
  @Trace dataList: Item[] = [];

  @Monitor('isLoading')
  onLoadingChanged() {
    // Automatically called when isLoading changes
  }
}
```

### 3. State Mutation with ObservedV2

**With @ObservedV2 and @Trace, direct mutation IS allowed and triggers UI updates.**

```typescript
// ✅ CORRECT: Direct mutation with @Trace
@ObservedV2
export class UserViewModel {
  @Trace name: string = '';
  @Trace addresses: string[] = [];

  updateName(newName: string) {
    this.name = newName;  // ✅ Direct assignment works
  }

  addAddress(address: string) {
    this.addresses.push(address);  // ✅ Array mutation works
  }
}
```

### 4. Component Reusability

**Extract reusable UI into @ComponentV2. No inline complex UI in build() methods.**

```typescript
// ❌ FORBIDDEN: Monolithic build method
@Entry
@ComponentV2
struct MainPage {
  build() {
    Column() {
      // 200+ lines of inline UI...
    }
  }
}

// ✅ REQUIRED: Extract components
@ComponentV2
struct UserCard {
  @Param user: User;

  build() {
    Row() {
      Image($r('app.media.avatar'))
      Column() {
        Text(this.user.name)
        Text(this.user.email)
      }
    }
  }
}

@Entry
@ComponentV2
struct MainPage {
  @Local vm: MainPageVM = new MainPageVM();

  build() {
    Column() {
      UserCard({ user: this.vm.user })
    }
  }
}
```



## Quick Reference

### V2 Decorators (HarmonyOS 6.0+)

```
@ComponentV2  → New component decorator with better performance
@Local        → Local component state (replaces @State)
@Param        → Component parameters (replaces @Prop/@Link)
@Event        → Event callbacks from child to parent
@Provider     → Provide data to descendants
@Consumer     → Consume from ancestor
@ObservedV2   → Observable class decorator (replaces @Observed)
@Trace        → Track property changes (replaces @ObjectLink)
@Computed     → Computed properties (auto-updated)
@Monitor      → Watch property changes (replaces @Watch)
AppStorageV2  → Global state with better performance
PersistenceV2 → Persistent storage with async API
```

### ArkTS Restrictions Summary

| TypeScript Feature        | ArkTS Status    | Alternative                          |
| ------------------------- | --------------- | ------------------------------------- |
| `for..in` loop            | ❌ Not supported | `Object.keys().forEach()` or `for..of` |
| `any` type                | ❌ Not supported | Explicit types or `Record<string, T>` |
| `unknown` type            | ❌ Not supported | Explicit types or union types         |
| Indexed access `obj[key]` | ❌ Not supported | `Record<string, T>` type              |
| Type assertions `as`      | ❌ Not supported | Proper type definitions               |
| `typeof` for types        | ❌ Not supported | Type aliases                          |
| `keyof` operator          | ❌ Not supported | Explicit string types                 |
| Decorators                | ✅ Limited       | `@ComponentV2`, `@ObservedV2`, etc.   |



## See Also

### Reference Guides
- [reference/arkts.md](reference/arkts.md) — ArkTS language guide, restrictions
- [reference/review.md](reference/review.md) — ArkTS common issues must follow

### Component Reference
- [reference/basic_component.md](reference/basic_component.md) — Basic UI components (Text, Image, Button, etc.)
- [reference/layout_component.md](reference/layout_component.md) — Layout components (Column, Row, Stack, Flex, etc.)
- [reference/navigation_component.md](reference/navigation_component.md) — Navigation and route management components
- [reference/scroll_component.md](reference/scroll_component.md) — Scroll container components (Scroll, List, Grid, etc.)
- [reference/tabs_component.md](reference/tabs_component.md) — Tabs and TabContent components
