/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // add field
  collection.fields.addAt(11, new Field({
    "hidden": false,
    "id": "json1597934342",
    "maxSize": 0,
    "name": "repeat_days",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "json"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1312009135")

  // remove field
  collection.fields.removeById("json1597934342")

  return app.save(collection)
})
