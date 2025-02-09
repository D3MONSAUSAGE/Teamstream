/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // remove field
  collection.fields.removeById("bool2604948446")

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // add field
  collection.fields.addAt(7, new Field({
    "hidden": false,
    "id": "bool2604948446",
    "name": "verified_by_manager",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }))

  return app.save(collection)
})
