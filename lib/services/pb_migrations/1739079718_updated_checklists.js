/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // add field
  collection.fields.addAt(9, new Field({
    "hidden": false,
    "id": "bool989355118",
    "name": "completed",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "bool"
  }))

  // add field
  collection.fields.addAt(10, new Field({
    "hidden": false,
    "id": "date1611760437",
    "max": "",
    "min": "",
    "name": "executed_at",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "date"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // remove field
  collection.fields.removeById("bool989355118")

  // remove field
  collection.fields.removeById("date1611760437")

  return app.save(collection)
})
