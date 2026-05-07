# Particle 粒子动画组件 — 元服务开发经验

## 一、元服务 API 兼容性清单

### API 11+（可用）

| API | 说明 | 备注 |
|-----|------|------|
| `Particle(particles)` | 粒子动画组件主接口 | 元服务 API 11+ |
| `ParticleType.POINT` | 圆点粒子类型 | 配合 `PointParticleParameters.radius` |
| `ParticleType.IMAGE` | 图片粒子类型 | 配合 `ImageParticleParameters.src/size/objectFit` |
| `ParticleEmitterShape.RECTANGLE` | 矩形发射器 | 默认值 |
| `ParticleEmitterShape.CIRCLE` | 圆形发射器 | — |
| `ParticleEmitterShape.ELLIPSE` | 椭圆发射器 | — |
| `ParticleUpdater.NONE` | 无属性变化 | — |
| `ParticleUpdater.RANDOM` | 随机均匀变化 | config 为差值范围 `[min, max]` |
| `ParticleUpdater.CURVE` | 曲线动画变化 | config 为 `ParticlePropertyAnimation[]` 多段动画 |
| `ParticleColorPropertyOptions` | 颜色配置 | range + 可选 updater/distributionType |
| `ParticlePropertyOptions` | 通用属性配置 | opacity/scale/acceleration/spin |
| `ParticlePropertyAnimation` | 属性动画段 | from/to/startMillis/endMillis/curve |
| `VelocityOptions` | 粒子速度 | speed + angle 两个维度 |
| `AccelerationOptions` | 粒子加速度 | speed + angle 两个维度 |
| `EmitterOptions.emitRate` | 发射速率(每秒) | 默认 5，建议 < 5000 |
| `EmitterOptions.position` | 发射器位置 | `[x, y]` 相对组件左上角 |
| `EmitterOptions.size` | 发射窗口大小 | `[width, height]` |
| `EmitterParticleOptions.lifetime` | 粒子生命周期(ms) | -1 表示无限，慎用影响性能 |
| `EmitterParticleOptions.count` | 粒子总数 | -1 表示无限 |

### API 12+（可用）

| API | 说明 | 备注 |
|-----|------|------|
| `disturbanceFields(fields)` | 扰动场属性 | 元服务 API 12+ |
| `DisturbanceFieldOptions` | 扰动场配置 | strength/shape/size/position/feather/noise* |
| `DisturbanceFieldShape` | 扰动场形状 | RECT(0)/CIRCLE(1)/ELLIPSE(2) |
| `emitter(properties)` | 发射器动态更新 | 元服务 API 12+ |
| `EmitterProperty` | 发射器更新参数 | index/emitRate/position/size |
| `DistributionType` | 颜色分布类型 | UNIFORM(0)/GAUSSIAN(1) |
| `EmitterParticleOptions.lifetimeRange` | 生命周期随机范围 | 元服务 API 12+ |

### API 20+（不可用）

| API | 说明 | 降级策略 |
|-----|------|----------|
| `ParticleEmitterShape.ANNULUS` | 环形发射器 | 使用 CIRCLE 替代 |
| `ParticleAnnulusRegion` | 环形区域配置 | — |
| `EmitterOptions.annulusRegion` | 环形参数 | — |

### API 22+（不可用）

| API | 说明 | 降级策略 |
|-----|------|----------|
| `rippleFields(fields)` | 波动场 | 使用 disturbanceFields 替代 |
| `RippleFieldOptions` | 波动场配置 | — |
| `velocityFields(fields)` | 速度场 | 使用 disturbanceFields 或 acceleration 替代 |
| `VelocityFieldOptions` | 速度场配置 | — |
| `FieldRegion` | 场区域配置 | — |

## 二、各场景核心调用方式

### 2.1 圆点粒子基础 (particle-basic)

核心配置结构：
```
Particle({
  particles: [{
    emitter: {
      particle: { type: ParticleType.POINT, config: { radius: 5 }, count: 200, lifetime: 5000 },
      emitRate: 10,
      shape: ParticleEmitterShape.RECTANGLE,
      position: [0, 0]
    },
    color: { range: [Color.Red, Color.Yellow], updater: { type: ParticleUpdater.CURVE, config: [...] } },
    opacity: { range: [0.0, 1.0], updater: { ... } },
    scale: { range: [0.0, 0.0], updater: { ... } },
    acceleration: { speed: { range: [3, 9], updater: { ... } }, angle: { range: [90, 90] } }
  }]
}).width(300).height(300)
```

关键点：
- `color.updater` 的 CURVE config 中 `from/to` 为 `ResourceColor` 类型
- `ParticlePropertyAnimation` 的 `startMillis/endMillis` 可组合多段动画
- `acceleration.angle` 单位为角度，正数顺时针

### 2.2 图片粒子 (particle-image)

核心差异：
- `type: ParticleType.IMAGE`
- `config: { src: $r('app.media.xxx'), size: [20, 20] }`
- **图片粒子不支持设置 color 属性**（官方文档明确说明）
- `spin` 属性可实现图片旋转效果

### 2.3 发射器动态更新 (particle-emitter-dynamic)

通过 `@Local` 状态变量驱动 `emitterProperties` 数组：
```
@Local emitterProperties: Array<EmitterProperty> = [{ index: 0, emitRate: 100, position: { x: 60, y: 80 }, size: { width: 200, height: 200 } }]

Particle(...).emitter(this.emitterProperties)
```

关键点：
- `EmitterProperty.index` 对应 `particles` 数组中的发射器索引
- 修改 `this.emitterProperties` 赋值新数组即可触发更新
- `position` 和 `size` 参数需传入两个有效值，异常值不生效

### 2.4 扰动场效果 (particle-disturbance)

配置方式：
```
.disturbanceFields([{
  strength: 10,           // 正排斥/负吸引
  shape: DisturbanceFieldShape.RECT,
  size: { width: 100, height: 100 },
  position: { x: 100, y: 100 },
  feather: 15,            // 0-100 羽化值
  noiseScale: 10,
  noiseFrequency: 15,
  noiseAmplitude: 5
}])
```

关键点：
- `strength` 正数排斥朝外，负数吸引朝内
- `feather` 值越大粒子越靠近中心（柔和），0 为刚体
- 噪声参数控制粒子轨迹的自然程度

## 四、注意事项

1. **性能**: `emitRate` 超过 5000 会极大影响性能，建议控制在合理范围
2. **生命周期**: `lifetime = -1` 表示无限生命周期，可能影响性能，仅在需要持续动画时使用
3. **图片粒子**: 不支持 color 属性，图片资源使用 `$r('app.media.xxx')` 引用
4. **息屏恢复**: Particle 在息屏后再次打开或切换后台再唤起，粒子动画会自动暂停
5. **属性动画多段配置**: `ParticleUpdater.CURVE` 的 config 为数组，可按时间段设置多段动画（如 0-3s、3-5s、5-8s）
6. **RANDOM 更新器**: config 为差值范围 `[min, max]`，每秒随机生成差值叠加当前值
