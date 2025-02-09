/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // update field
  collection.fields.addAt(9, new Field({
    "hidden": false,
    "id": "bool989355118",
    "name": "completed",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // update field
  collection.fields.addAt(9, new Field({
    "hidden": false,
    "id": "bool989355118",
    "name": "completed",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "bool"
  }))

  return app.save(collection)
})
