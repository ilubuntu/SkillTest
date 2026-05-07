# Contacts Kit 开发经验

## 一、元服务 API 兼容性清单

### 可用 API（无需权限）

| API | 最低 API | 元服务API | 说明 | 备注 |
|-----|---------|----------|------|------|
| `contact.selectContacts()` | API 10 | API 11 | 选择联系人（无筛选） | 通过系统UI选择，无需权限 |
| `contact.selectContacts(options)` | API 10 | API 11 | 选择联系人（带筛选） | ContactSelectionOptions 支持 isMultiSelect/maxSelectable |
| `contact.addContactViaUI()` | API 15 | API 15 | 新建联系人UI | 通过系统UI创建，无需权限 |
| `contact.saveToExistingContactViaUI()` | API 15 | API 15 | 保存到已有联系人 | 通过系统UI选择并合并，无需权限 |

### 受限 API（需系统权限，元服务可能无法获取）

| API | 最低 API | 元服务API | 说明 | 权限要求 |
|-----|---------|----------|------|---------|
| `contact.addContact()` | API 10 | API 12 | 直接添加联系人 | `WRITE_CONTACTS` (system_core) |
| `contact.queryContactsCount()` | API 22 | API 22 | 查询联系人数量 | `READ_CONTACTS` (system_core) |

### 不可用 API（需系统级权限，元服务不可用）

| API | 说明 | 权限要求 |
|-----|------|---------|
| `contact.queryContact()` | 根据key查询联系人 | `READ_CONTACTS` (system_core) |
| `contact.queryContacts()` | 查询所有联系人 | `READ_CONTACTS` (system_core) |
| `contact.queryContactsByPhoneNumber()` | 按电话号码查询 | `READ_CONTACTS` (system_core) |
| `contact.queryContactsByEmail()` | 按邮箱查询 | `READ_CONTACTS` (system_core) |
| `contact.deleteContact()` | 删除联系人 | `WRITE_CONTACTS` (system_core) |
| `contact.updateContact()` | 更新联系人 | `WRITE_CONTACTS` (system_core) |
| `contact.queryGroups()` | 查询联系人群组 | `READ_CONTACTS` (system_core) |
| `contact.queryHolders()` | 查询联系人持有者 | `READ_CONTACTS` |
| `contact.queryKey()` | 查询联系人key | `READ_CONTACTS` |
| `contact.isLocalContact()` | 判断是否本地联系人 | `READ_CONTACTS` |
| `contact.isMyCard()` | 判断是否名片 | `READ_CONTACTS` |
| `contact.queryMyCard()` | 查询名片 | `READ_CONTACTS` |

### 可用数据类型（元服务API 11+）

| 类型 | 说明 |
|------|------|
| `Contact` | 联系人对象（含 name/phoneNumbers/emails 等属性） |
| `ContactSelectionOptions` | 选择条件（isMultiSelect/maxSelectable/isDisplayedByName/filter） |
| `ContactSelectionFilter` | 过滤器（API 15+） |
| `Name` / `PhoneNumber` / `Email` | 联系人子属性 |
| `ContactAttributes` / `Attribute` | 联系人属性列表 |

## 二、各场景核心调用方式

### 2.1 选择联系人 (selectContacts)

```typescript
import { contact } from '@kit.ContactsKit'
import { BusinessError } from '@kit.BasicServicesKit'

// 基本选择
contact.selectContacts().then((data: Array<contact.Contact>) => {
  data.forEach((c: contact.Contact) => {
    console.info(`Name: ${c.name?.fullName}, Phone: ${c.phoneNumbers?.[0]?.phoneNumber}`)
  })
}).catch((err: BusinessError) => {
  // 401: 参数错误
})

// 带筛选条件选择（单选/多选）
let options: contact.ContactSelectionOptions = {
  isMultiSelect: true,    // 多选模式
  maxSelectable: 5        // 最多选5个（API 15+）
}
contact.selectContacts(options).then(...)
```

- 无需申请权限，通过系统UI让用户主动选择
- 用户取消操作不会触发 catch，返回空数组
- `ContactSelectionOptions` 元服务API 11+支持基本选项，15+支持高级过滤

### 2.2 新建联系人 (addContactViaUI)

```typescript
import { contact } from '@kit.ContactsKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

let context = getContext(this) as common.Context
let contactInfo: contact.Contact = {
  name: { fullName: '张三' },
  phoneNumbers: [{ phoneNumber: '13800138000' }]
}

contact.addContactViaUI(context, contactInfo).then((id: number) => {
  console.info(`Created contact id: ${id}`)
}).catch((err: BusinessError) => {
  // 16700103: 用户取消
  // 16700102: 数据设置失败
  // 16700001: 通用错误
})
```

- 无需权限，通过系统UI让用户确认创建
- 预设的联系人信息会填充到系统UI中，用户可修改
- 错误码 `16700103` 表示用户取消，需要特殊处理
- 需要 API version 15+

### 2.3 保存到已有联系人 (saveToExistingContactViaUI)

```typescript
import { contact } from '@kit.ContactsKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

let context = getContext(this) as common.Context
let contactInfo: contact.Contact = {
  name: { fullName: '李四' },
  phoneNumbers: [{ phoneNumber: '13900139000' }]
}

contact.saveToExistingContactViaUI(context, contactInfo).then((id: number) => {
  console.info(`Saved to contact id: ${id}`)
}).catch((err: BusinessError) => {
  // 16700103: 用户取消
  // 16700101: 数据读取失败
  // 16700102: 数据设置失败
})
```

- 无需权限，系统弹出联系人选择界面
- 预设信息将合并到用户选中的已有联系人中
- 错误码 `16700103` 表示用户取消
- 需要 API version 15+

### 2.4 Contact 对象结构

```typescript
let myContact: contact.Contact = {
  name: {
    fullName: 'fullName',
    givenName: 'firstName',
    familyName: 'lastName'
  },
  phoneNumbers: [{
    phoneNumber: '138xxxxxxxx'
  }],
  emails: [{
    emailAddress: 'test@example.com'
  }],
  nickName: {
    nickName: 'nickname'
  },
  organization: {
    name: 'company',
    title: 'engineer'
  }
}
```

## 三、编译问题与解决方案

1. **import 路径**: 使用 `import { contact } from '@kit.ContactsKit'`，不是 `import contact from '@ohos.contact'`（后者已废弃）
2. **context 获取**: Picker 类 API 需要传入 context，使用 `getContext(this) as common.Context` 获取
3. **编译无报错**: 所有联系人 API 在编译期不会因权限问题报错，权限问题在运行时才会体现
4. **BusinessError 类型**: 需要从 `@kit.BasicServicesKit` 导入，用于错误处理的类型断言

## 四、降级处理策略

1. **联系人查询** → 使用 `selectContacts()` 让用户通过系统UI选择，替代直接查询
2. **联系人创建** → 使用 `addContactViaUI()` 通过系统UI创建，替代直接添加
3. **联系人更新** → 使用 `saveToExistingContactViaUI()` 通过系统UI合并，替代直接更新
4. **群组管理** → 元服务无替代方案，建议应用内自行实现分组逻辑（云端数据）
5. **批量操作** → 元服务无法直接操作通讯录数据，需依赖云端服务
6. **低版本兼容** → `selectContacts` (API 11+) 可覆盖大部分场景；`addContactViaUI`/`saveToExistingContactViaUI` (API 15+) 提供创建/更新能力

## 五、关键发现

- 原有文档认为联系人 Kit 在元服务中完全不可用，实际上从 API 11 开始 `selectContacts` 已支持元服务
- API 15 新增 `addContactViaUI` 和 `saveToExistingContactViaUI` 进一步扩展了元服务的联系人操作能力
- Picker 类 API 的核心思路是：通过系统UI代理操作，用户主动确认，从而规避权限问题
- `addContact` 虽然从 API 12 标记支持元服务，但需要 `WRITE_CONTACTS` 权限（system_core），实际可用性取决于元服务能否获取该权限
