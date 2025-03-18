/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1427126806")

  // remove field
  collection.fields.removeById("text1177347317")

  // remove field
  collection.fields.removeById("select2063623452")

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1427126806")

  // add field
  collection.fields.addAt(3, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text1177347317",
    "max": 0,
    "min": 0,
    "name": "position",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "select2063623452",
    "maxSelect": 1,
    "name": "status",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "values": [
      "Upcoming",
      "Active",
      "Completed"
    ]
  }))

  return app.save(collection)
})
