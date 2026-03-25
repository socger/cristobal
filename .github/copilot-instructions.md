# Imports order is this:

More common to less common. lib > common > domain > db > modules

# Very important notes from the tech lead of the project:

- Never declare the same entity in different modules with forFeature. It has to be in only one module.ts
- in module.ts different declaration have to go in alphabetical order.
- From an implementation.service.ts we con only return a .plain an Interface. Never return the entity.
- Crud Services are never exported from module.
- Always try to analize the features that are already working in the project to replicate the same architecture or logic.

## CRUD services

- can only depend on entity repositories. Encapsulate everything we do with the entity.
- one service deals with a single entity and depends only on its repository.
- prohibited: exprorting CRUD services from module
- prohibited: repositories of multiple entities in the same service. If you need it - move it into implementation service or create a separate strategy service to encapsulate the method you need.

# dto pattern ideas

## Class DTO vs Validation Schema:

**Class DTO:** ALWAYS extend from Update DTO to inherit `@ApiProperty` decorators for Swagger documentation:

```typescript
export class DeviceCategoryCreateDto extends DeviceCategoryUpdateDto {}
```

**Validation Schema:** Depends on field reuse:

### ✅ Extend update schema when you reuse most fields:

```typescript
// Update has 10 fields, create only redefines 4 as required
export const deviceCategoryCreateSchema = deviceCategoryUpdateSchema.keys({
  field1: Joi.required(), // Only override 4 fields
  field2: Joi.required(),
  field3: Joi.required(),
  field4: Joi.required(),
  // The other 6 fields are inherited as-is
});
```

### ✅ Standalone schema when redefining all/most fields:

```typescript
// Update has 4 fields, create redefines all 4
export const deviceCategoryCreateSchema = Joi.object({
  name: Joi.string().required(), // All fields redefined
  description: Joi.string().required(),
  energyType: Joi.string().required(),
  deviceClass: Joi.string().required(),
});
```

**Rule of thumb:** If you're redefining more than 50% of the fields, use a standalone schema for clarity and maintainability.

### Not use .optional() in Joi schemas in things like name since it is already like that.
